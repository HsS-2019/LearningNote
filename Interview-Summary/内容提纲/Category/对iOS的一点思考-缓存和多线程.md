# 对iOS的一点思考-缓存和多线程篇

### 本地缓存

对于文件缓存的理解

文件内的沙盒机制，自定义内存缓存、磁盘缓存策略。缓存命中机制

### NSCache和NSDictionary的比较

NSCache和NSDictionary都是苹果提供的内存缓存。不同的是NSCache是线程安全的，其中性能安全是由pthread_mutex完成，但是性能和key的相似度有关，如果有大量相似的key，NSCache存取性能会下降得很厉害。

在iOS 内存详解中我们推荐使用NSCache，因为它是purged memory

#### 缓存机制设计

多级缓存，考虑是否需要内存缓存和磁盘缓存

数据存取的安全性，考虑多线程下数据存取的原子性

缓存淘汰策略，根据给定的标准，当数据超过一定量后执行缓存淘汰策略

对比SQlite+文件缓存的思路，文章中分析了mmap+临时文件的另一种思路，未经实践，所以这里仅作参考

> mmap：通常文件读取过程会先将磁盘数据先读取到一个内核缓存中中，然后程序内存缓存再从内核缓存中读数据。而mmap会直接将磁盘数据映射到程序的内存地址，少了一步内核缓存的交换。

但mmap是定时将存在程序内存的数据刷回到磁盘，可能存在的问题是，如果等待自动刷回磁盘的阈值没到之前，进程被kill，会导致内存中的数据丢失

##### 参考阅读

[iOS本地缓存总结](https://www.jianshu.com/p/a8251c8c0298)

介绍了iOS的沙盒机制和一些常用的本地缓存

[iOS文件缓存](https://ctinusdev.github.io/2017/07/29/FileCache/)

[iOSCache整理](https://juejin.im/post/6844903522106867726)

[iOS缓存设计之YYCache](https://www.infoq.cn/article/V3J6HrWtrzjUmGOz66f5)

本文是贝壳团队的分享，

[YYCache的设计思路—YYCache作者ibireme分享自己的设计思路](https://blog.ibireme.com/2015/10/26/yycache/)

这个是YYCache作者分享的自己设计YYCache的思路，文章肯定很好，可能是网络问题，很难加载出来，换了VPN也不行，后面再细读

[YYCache设计分析](https://juejin.im/post/6885605205380562952)

微医团队对YYCache分析的一篇文章，在分析的同时串联知识，也提出了自己的一些扩展思路，很好的一篇文章

[从YYCache源码Get到如何设计一个优秀的缓存](https://lision.me/yycache/)

暂时未读，一直以来都很喜欢从实现的角度去读已有的设计这种技巧，有空细细读下

[认真分析mmap](https://www.cnblogs.com/huxiao-tee/p/4660352.html)

认识mmap

### 数据库

#### realme数据库

#### SQLite数据库

#### CoreData数据库

### 多线程

对于多线程，有一些基本概念需要先梳理清楚

* 串行、并发和并行
* 同步和异步
* 线程和队列
* 数据竞争、原子性和锁

数据安全如何保证，不同锁的选择

##### 参考阅读

[主线程和主队列的关系](https://mp.weixin.qq.com/s/OWya_IW3isFHEysPUOkEvA)

[atomic一定线程安全吗]()

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