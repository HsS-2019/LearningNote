# 对iOS的一点思考-性能监控篇

在阅读iOS性能监控相关文章的过程中，发现可以将一些性能指标和其他知识串联起来，这篇笔记的目的正是在于此。

### CPU使用率

> Mach Task:  任务（task）是一种容器对象，虚拟内存空间和其他资源都是通过这个容器对象管理的，这些资源包括设备和其他句柄。严格地说，Mach层的任务并不是其他操作系统中所谓的进程，因为Mach作为一个微内核的操作系统，并没有提供“进程”的逻辑，而只是提供了最基本的实现（怎么理解只提供基本实现？）。不过在BSD的模型中，这两个概念有1:1的简单映射，每一个BSD进程（即OS X进程）都在底层关联了一个Mach任务对象。

上文引用自《OS X and Kernel Programming》对Mach task的描述。Mach task可以看作是一个机器无关的thread执行环境的抽象：一个task包含它的线程列表。内核提供了`task_threads`API调用获取指定task的线程列表，然后可以通过`thread_info`API调用来查询指定线程的信息。

在获取机器总体的CPU使用率时，可以通过`host_statistics`函数拿到`host_cpu_load_info`的值，这个结构体的成员变量`cpu_ticks`包含了CPU运行的时钟脉冲的数量。`cpu_ticks`是一个数组，里面分别包含了`CPU_STATE_USER`、`CPU_STATE_SYSTEM`、`CPU_STATE_IDLE`、`CPU_STATE_NICE`模式下的时钟脉冲。除`idle`以外都属于CPU被占用的情况，最后就能求出CPU的占用率。

##### 关联知识

线程的CPU占用、资源管理

### Memory

##### App使用内存

通过代码获取App使用的内存很方便，直接通过`task_info` API获取`mach_task_basic_info`结构体，并取出`phys_footprint`变量值即可。

可以看到我们这里是通过获取Mach层的当前task的信息，从而拿到App的使用内存。

##### 获取设备使用的内存

获取内存页大小，并乘于使用页数（`vm_statistics64_data_t`的`wire_count`和`active_count`）

##### 获取设备剩余内存

获取内存页的大小，并乘于剩余页数（`vm_statistics64_data_t`的`free_count`和`inactive_count`）

##### 关联知识

Jetsam机制，iOS系统低内存事件处理，OOM和FOOM的监控和分析

### 卡顿监控

卡顿的产生：VSync+双缓冲机制的缺点。

一般有两种方法监控：

* FPS监控：使用和屏幕刷新率一致的`CADisplayLink`，缺点是无法完全检测出当前`CoreAnimation`的性能情况，只能检测出当前`Runloop`的帧率。
* 主线程卡顿监控：通过开辟一个子线程监控主线程的Runloop，当两个状态区域之间的耗时大于阈值时，就记为发生一次卡顿。

由于FPS和主线程卡顿监控都会发生抖动，所以微信读书团队给出一种综合方案，结合主线程监控、FPS监控以及CPU使用率等指标，作为判断卡顿的标准。

关联知识点：iOS的渲染流程，UIView的draw函数，runloop流程。

[京东商城APP卡顿监控及优化实践](https://mp.weixin.qq.com/s/aJeAUAjcKOMvznDMGj2UUA)

### 应用启动时间

冷启动时间的计算，从点击图标开始，到应用程序的第一帧图像Render Commit。

#### 关联知识

了解main函数执行前和main函数执行后做了什么，简单的应用启动优化思路。

##### **main函数执行前**

main函数执行前，主要包括以下阶段：

* 创建进程

* mmap主二进制，找到dylb的路径

* mmap dylb，执行dylb_start，完成剩下的动态库的load

  这个阶段，如果是重启手机/更新/下载App的第一次启动，dylb3会创建启动闭包并缓存到沙盒里，其他时候应用启动直接读取缓存去查找闭包

  闭包做的事情蛮多的，主要包括

  * 递归获取动态库的依赖关系，动态库的依赖是树状的结构
  * 加载Class和Category，初始化objc的类方法等信息
  * 初始化的调用顺序

* 把没有加载的动态库mmap进来（这个阶段还有没加载的动态库？）
* Fix-up，对每个二进制做rebase（重定向）和bind（符号绑定），主要耗时在Page In，影响Page In 数量的是objc的元数据（类的加载）
* 初始化objc（Swift）的运行时，前面的闭包已经完成大半，所以这里主要是SEL的注册（建立SEL表）和装载Category
* Load & Static Initializer，主要包括类和分类的+load方法执行和静态初始化。对于在编译期间能确定的static变量编译器会直接inline，其它的会留到运行时，也就是现在，执行初始化。

main函数执行前主要的耗时是在Mach-O文件的Page-In（Page-In发生在rebase阶段？），以及将页读取到内存后对页的解密和签名验证。

##### **main函数执行后**

main函数执行到第一帧渲染出来前，主要包括以下阶段

* 初始化UIApplication，启动Main Runloop（主线程的Runloop）
* 执行will/didFinishLaunch，部分业务需要注册（App的Life Cycle）
* iOS渲染流程直到第一个CA Transaction commit，包括以下步骤
  * Layout：viewDIdLoad和Layoutsubviews会在这里调用，应尽量减少视图层次，减少约束
  * Display：Root Layer调用CALayer 的display方法，如果UIView实现了drawRect方法，也会在这里调用
  * Prepare：附加步骤，图片解码会发生在这一步
  * Commit：将首帧渲染数据打包，发给Render Server进程，启动结束

##### 应用启动思路分析

上面所说的是基于dylb3的应用启动流程，dylb2相对于dylb3的主要区别是没有启动闭包和解密优化这些，导致每次启动要：

* 解析动态库的依赖关系
* 解析LINKEDIT，找到bind & rebase的指针地址，找到bind符号的地址
* 注册objc的Class/Method等元数据

通过阅读不同公司的启动优化方案，我们可以看到一些成功的应用启动优化实践

* 二进制重排，减少Page-In的次数。
* 插桩，llvm编译过程给记录调用的函数方法

##### 参考文章：

[iOS性能监控方案Wedjat](https://github.com/aozhimin/iOS-Monitor-Platform#%E9%A1%B9%E7%9B%AE%E5%90%8D%E7%A7%B0%E7%9A%84%E6%9D%A5%E6%BA%90)

[微信读书iOS性能优化总结](https://wereadteam.github.io/2016/05/03/WeRead-Performance/)

[深入理解iOS App的启动过程](https://blog.csdn.net/Hello_Hwc/article/details/78317863?locationNum=9&fps=1)

[抖音品质建设—iOS启动优化《原理篇》](https://juejin.im/post/6887741815529832456)

> 实践是检验真理的唯一标准