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

[iOS文件缓存](https://ctinusdev.github.io/2017/07/29/FileCache/)

[iOSCache整理](https://juejin.im/post/6844903522106867726)

[iOS缓存设计之YYCache](https://www.infoq.cn/article/V3J6HrWtrzjUmGOz66f5)

[YYCache的设计思路—YYCache作者ibireme分享自己的设计思路](https://blog.ibireme.com/2015/10/26/yycache/)

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

数据安全如何保证，不同锁的选择

##### 参考阅读

[主线程和主队列的关系](https://mp.weixin.qq.com/s/OWya_IW3isFHEysPUOkEvA)

[atomic一定线程安全吗]()



> 实践是检验真理的唯一标准