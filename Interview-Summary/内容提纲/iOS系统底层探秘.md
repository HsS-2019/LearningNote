在阅读iOS性能监控相关文章的过程中，发现可以将一些性能指标和其他知识串联起来，这篇笔记的目的正是在于此。

### CPU使用率

> Mach Task:  任务（task）是一种容器对象，虚拟内存空间和其他资源都是通过这个容器对象管理的，这些资源包括设备和其他句柄。严格地说，Mach层的任务并不是其他操作系统中所谓的进程，因为Mach作为一个微内核的操作系统，并没有提供“进程”的逻辑，而只是提供了最基本的实现（怎么理解只提供基本实现？）。不过在BSD的模型中，这两个概念有1:1的简单映射，每一个BSD进程（即OS X进程）都在底层关联了一个Mach任务对象。

上文引用自《OS X and Kernel Programming》对Mach task的描述。Mach task可以看作是一个机器无关的thread执行环境的抽象：一个task包含它的线程列表。内核提供了`task_threads`API调用获取指定task的线程列表，然后可以通过`thread_info`API调用来查询指定线程的信息。

在获取机器总体的CPU使用率时，可以通过`host_statistics`函数拿到`host_cpu_load_info`的值，这个结构体的成员变量`cpu_ticks`包含了CPU运行的时钟脉冲的数量。`cpu_ticks`是一个数组，里面分别包含了`CPU_STATE_USER`、`CPU_STATE_SYSTEM`、`CPU_STATE_IDLE`、`CPU_STATE_NICE`模式下的时钟脉冲。除`idle`以外都属于CPU被占用的情况，最后就能求出CPU的占用率。

关联知识：线程的CPU占用、资源管理

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

### 应用启动时间

冷启动时间的计算

##### 关联知识

main函数执行前和main函数执行后做了什么，应用启动优化。



##### 参考文章：

[iOS性能监控方案Wedjat](https://github.com/aozhimin/iOS-Monitor-Platform#%E9%A1%B9%E7%9B%AE%E5%90%8D%E7%A7%B0%E7%9A%84%E6%9D%A5%E6%BA%90)

[微信读书iOS性能优化总结](https://wereadteam.github.io/2016/05/03/WeRead-Performance/)