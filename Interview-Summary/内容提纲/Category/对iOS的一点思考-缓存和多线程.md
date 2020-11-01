# 对iOS的一点思考-缓存和多线程篇

### 本地缓存

对于文件缓存的理解

文件内的沙盒机制，自定义内存缓存、磁盘缓存策略。缓存命中机制

### 缓存机制设计

主要参考了YYCache和Kingfisher的缓存设计思路进行分析。

缓存设计的一些注意点

* 多级缓存，考虑是否需要内存缓存和磁盘缓存

* 数据存取的安全性，考虑多线程下数据存取的原子性

* 缓存淘汰策略，根据给定的标准，当数据超过一定量后执行缓存淘汰策略

#### 对于内存缓存

在了解不同的内存缓存设计之前，我们先来了解一下iOS底层两种内存缓存的区别。

##### NSCache和NSDictionary的比较

NSCache和NSDictionary都是苹果提供的内存缓存。不同的是NSCache是线程安全的，其中性能安全是由pthread_mutex完成，但是性能和key的相似度有关，如果有大量相似的key，NSCache存取性能会下降得很厉害。

NSDictionary是非线程安全的，所以在理想情况下速度很快。

在iOS 内存详解中我们推荐使用NSCache，因为NSCache含有各种自动回收策略，当其它应用需要内存，NSCache会从缓存中删除部分，减少其内存占用，而NSDictionary并没有提供这种策略。

如果自定义的对象类型具有不使用时可以丢弃的特性，可以遵循NSDiscardableContent协议来获得自动回收缓存的特性。

##### 在不同框架中的实践

Kingfisher的内存缓存底层借助了NSCache，NSCache是线程安全的，提供了设置最大缓存个数和最大缓存大小的配置、Kingfisher添加了存活时间等其它管理配置。（ImageCache中监听了三个通知：收到内存警告、应用即将被kill、应用已经进入到后台，这三种情况都会清空内存缓存，异步清除过期磁盘缓存，超限缓存）

而YYCache的内存缓存YYMemoryCache是作者自己实现的一个内存缓存，通过同步访问，用OSSpinLock保证线程安全，另外缓存内部用双向链表和NSDictionary实现了LRU淘汰算法。

#### 磁盘缓存

YYCache对于磁盘缓存的设计思路是：把SQLite和文件存储结合起来，key-value信息保存在SQLite中，而value数据则根据大小不同选择SQLite或文件存储。这样既能在小文件的情况下，使用SQLite保证读取的高性能，也能在大文件的情况下，依靠SQLite存储的元数据（key-value），实现LRU淘汰算法，更快的数据统计，更多的容量控制选项。

对比YYCache中SQlite+文件实现磁盘缓存的思路，微医团队文章中分析了mmap+临时文件的另一种思路

> mmap：通常文件读取过程会先将磁盘数据先读取到一个内核缓存中，然后程序内存缓存再从内核缓存中读数据。而mmap会直接将磁盘数据映射到程序的内存地址，少了一步内核缓存的交换。

后续看YYCache作者ibireme的设计思路文章，发现作者也调研了mmap文件内存映射的方式，作者分享了没有采用mmap的原因

> mmap的缺陷包括：热数据的文件不要超过物理内存大小，不然mmap会导致内存交换严重影响性能；另外内存中的数据是定时flush到文件的，如果数据还未同步时程序挂掉，就会导致数据错误。抛开这些问题来说，mmap性能非常高。

如果能解决上述的缺点，mmap或许确实是一个不错的选择。

ibireme分析了一些基于文件系统的磁盘缓存开源库，发现含有同样的缺点：不方便扩展、没有元数据、难以实现好的淘汰算法，数据统计缓慢。

分析Kingfisher的磁盘缓存部分……

另外，ibireme在阐述YYCache设计思路的文章中还分享了为了把性能优化做到极致而做的一些其它的技术调研（很值得学习）

* SQLite和Realm数据库的比较，这里说到Realm的底层使用了mmap把文件映射到内存，所以才在较大数据读取时获得很好的性能，说明大文件使用mmap这一思路确实可行。
* OSSpinLock、dispatch_semphone信号量做锁（信号量为1时可以作为互斥锁）和pthread_mutex锁的的比较

#### YYCache和Kingfisher的一些比较

部分比较在上面已有说明，这里列举阅读源码过程看到的一些区别：

* Kingfisher的磁盘缓存：可设置磁盘缓存大小限制，如果缓存实际大小超限会清理至最大值的一半，在清理过程也使用了LRU算法，先把所有文件按最后修改时间排序，再将最久未被访问的文件清除。需要注意的是，Kingfisher的磁盘缓存清理都是手动调用或者接收到对应通知才执行，并不会自动检测

* Kingfisher的内存缓存：底层实现是NSCache，另外还有一些细节：

  * 自定义了keys属性（方便在删除缓存的时候遍历NSCache？）
  * 定时器。默认时间是五分钟，定期清理过期的内存缓存（类似LRU的思想，清理最久未访问的）。另外在监听到系统对应通知时也会执行清除。
  * NSLock普通锁。存、移除缓存过程中使用了NSLock确保数据安全。NSLock在unlock时，必须确保和lock是在同一线程执行，从其它线程解锁可能导致未定义行为发生。另外不能用该锁实现递归锁，NSLock在同一线程连续调用两次锁会导致线程永久被锁定。
  * 令人疑惑的是，我并没有看到内存缓存Backend的maxCount和maxCostCount属性有对应的处理逻辑，除了测试用例中有使用。更新：后续看到了对应逻辑，作者将这两个属性赋值给NSCache的同名属性，NSCache内部有对应的自动回收逻辑。

* YYCache的内存缓存：底层存储使用了NSDictionary，另外还有一些细节：

  * 定时器。默认时间同样是五分钟，另外提供了选项，是否在监听到对应通知时清除缓存。
  * 对于多线程，提供了releaseOnMainThread和releaseAsynchronously，控制释放操作是否放到子线程和是否异步执行。
  * 对于锁，在查看源码的时候发现，YYMemoryCache并没有用到OSSpinLock锁，这与作者分享YYCache设计思路文章中的阐述有所出入，google了一下发现是因为OSSpinLock锁不再保证多线程数据安全，所以作者使用了pthread_mutex_lock锁替代弃用OSSPinLock锁

* YYCache的磁盘缓存：SQLite+文件系统。一些设计细节如下：

  * autoTrimInterval属性，默认值为1分钟，自动检测磁盘缓存是否达到限制，如果达到，会自动执行释放操作。

  ![image-20201101093836864](https://tva1.sinaimg.cn/large/0081Kckwgy1gk9fasmit0j317n0u0ad2.jpg)

#### 参考阅读

[iOS本地缓存总结](https://www.jianshu.com/p/a8251c8c0298)

介绍了iOS的沙盒机制和一些常用的本地缓存

[iOS文件缓存](https://ctinusdev.github.io/2017/07/29/FileCache/)

[iOSCache整理](https://juejin.im/post/6844903522106867726)

[iOS缓存设计之YYCache](https://www.infoq.cn/article/V3J6HrWtrzjUmGOz66f5)

本文是贝壳团队的分享，

[YYCache的设计思路—YYCache作者ibireme分享自己的设计思路](https://blog.ibireme.com/2015/10/26/yycache/)

这个是YYCache作者分享自己设计YYCache思路的文章，质量很高，值得细读，可能是网络问题，有时候很难加载出来，换了VPN也不行

[YYCache设计分析-微医团队](https://juejin.im/post/6885605205380562952)

微医团队对YYCache分析的一篇文章，在分析的同时串联知识，也提出了自己的一些扩展思路，很好的一篇文章。

[从YYCache源码Get到如何设计一个优秀的缓存](https://lision.me/yycache/)

暂时未读，一直以来都很喜欢从实现的角度去读已有的设计这种技巧，有空细细读下

[认真分析mmap](https://www.cnblogs.com/huxiao-tee/p/4660352.html)

认识mmap

### 数据库

#### realme数据库

#### SQLite数据库

#### CoreData数据库

# 多线程

对于多线程，有一些基本概念需要先梳理清楚

* 串行、并发和并行
* 同步和异步
* 线程和队列
* 数据竞争、原子性和锁

数据安全如何保证，不同锁的选择

##### 参考阅读

[主线程和主队列的关系](https://mp.weixin.qq.com/s/OWya_IW3isFHEysPUOkEvA)

[iOS多线程到底不安全在哪](https://zhuanlan.zhihu.com/p/24102640)

本文从内存读写角度清晰地阐述了iOS多线程再哪些场景下是不安全的，同时还探讨了atomic的线程安全性，是一篇比较好的新手向文章

[iOS中不同锁的比较](https://github.com/bestswifter/blog/blob/master/articles/ios-lock.md)

[优先级反转问题]()

[不再安全的OSSpinLock](https://blog.ibireme.com/2016/01/16/spinlock_is_unsafe_in_ios/)

[深入了解GCD](https://github.com/bestswifter/blog/blob/master/articles/objc-gcd.md)

[多个网络请求成功返回再执行另外任务的思路分析](https://www.cnblogs.com/SUPER-F/p/7365699.html)

[为什么必须在主线程操作UI](https://juejin.im/post/6844903763011076110)

[多线程-奇怪的GCD](https://mp.weixin.qq.com/s/GnKqRWcfLn2GQZLb5GUyKA)

本文针对两个问题进行了验证

* 主线程只会执行主队列的任务吗
* 同样，主队列只会在主线程上被执行吗

对于第一个问题，通过观察，发现非主队列的情况下，大部分队列调用sync的结果，都是在当前线程执行了任务，猜测是Apple为了节省切换线程的开销而做的优化。

对于第二个问题，基于下面的两个设定，我们一般认为这个说法是成立的

* 主队列总是可以调用UIKit的API
* 同时只有一条线程能够执行串行队列的任务

在后续的验证中，我们可以看到，如果没有UIApplicationMain函数调用，主队列任务不一定运行在主线程。UIApplicationMain函数的调用会使得主线程的Runloop启动，提出了主队列并不总是在同一个线程上执行的猜想。最终验证的结果也很有趣

> 运行结果说明了并不存在什么Runloop启动线程，一旦Runloop启动后，主队列就会一直执行在同一个线程上，而这个线程就是主线程。由于Runloop本身是一个不断循环处理事件的死循环，这才是它启动后主队列一直运行在一个主线程上的原因



很好的一篇文章，细读可以加深对GCD机制的理解

> 实践是检验真理的唯一标准