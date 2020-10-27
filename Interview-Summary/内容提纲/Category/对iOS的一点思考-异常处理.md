# 对iOS的一点思考：异常处理篇

本文从异常处理机制出发，探索不同语言的异常处理机制，并介绍了如何捕获Crash，分析Crash，和OOM问题分析定位

### iOS的异常处理机制

#### Swift上的异常处理

探索Swift的异常处理机制

#### Objective-C的异常处理

探索Objective-C/C++的异常处理机制

参考阅读

[初探 Objective-C/C++ 异常处理实现机制](https://mp.weixin.qq.com/s/4Rcaee6kwWmrS3v_M9y0KQ)

### Crash分析

#### Crash的原因以及类型

#### 捕获Crash

无论是硬件异常产生的信号，还是软件异常产生的信号，都会走到act_set_astbsd()进而唤醒收到信号的进程的某一个线程。这一机制给我们在自身进程内捕获Crash提供了可能，即通过拦截UNIX信号或Mach异常来捕获崩溃。

当我们拦截信号处理之后，可以让程序不崩溃而继续运行，但是不建议这样，这时程序已经处于异常不可知状态。

一般我们通过两种方式拦截异常，包括Mach异常拦截和UNIX信号拦截，虽然我们可以看到很多Mach异常都转换成了UNIX信号，但是基于以下的原因，我们仍然拦截了Mach异常

* 不是所有的Mach异常类型都映射到了UNIX信号，如EXC_GUARD异常
* UNIX信号在崩溃线程回调，如果遇到了stackoverflow问题，已经没有条件（栈空间）再执行回调代码

因为用户态的软件异常是直接走信号流程的，所以我们也不能认为直接拦截Mach异常就可以了。

> NSSetUncaughtExceptionHandler：我们可以通过注册`NSSetUncaughtExceptionHandler`，实现应用级的异常捕获（只捕获部分异常）。但`NSSetUncaughtExceptionHandler`函数存在覆盖现象，后注册的总会顶替掉前面注册的，因此当crash发生时，只触发了最后注册传入的捕获回调函数。

对于Swift中的异常捕获，NSSetUncaughtExceptionHandler只捕获了OBjective-C的错误（NSException错误），对于Swift throw出来的错误和运行时错误，NSSetUncaughtExceptionHandler无法捕获，可以通过UNIX信号捕获部分异常

##### 参考阅读

[iOS的崩溃捕获方案](http://silentcat.top/2017/11/23/iOS%E7%9A%84%E5%B4%A9%E6%BA%83%E6%8D%95%E8%8E%B7%E6%96%B9%E6%A1%88/)

[Diagnosing Issues Using Crash Reports and Device Logs](https://developer.apple.com/documentation/xcode/diagnosing_issues_using_crash_reports_and_device_logs#//apple_ref/doc/uid/DTS40008184-CH1-ANALYZING_CRASH_REPORTS-EXCEPTION_CODES)

[How should I use NSSetUncaughtExceptionHandler in Swift](https://stackoverflow.com/questions/25441302/how-should-i-use-nssetuncaughtexceptionhandler-in-swift)

[Uncaught Error/Exception Handling in Swift](https://stackoverflow.com/questions/38737880/uncaught-error-exception-handling-in-swift)

#### 分析Crash

Crash出现在开发者编写的代码和系统库中时，如何分析和定位

##### 符号化

对于项目中堆栈的符号化，需要项目对应版本的dsym文件。

> dsym文件：dsym文件其实是一个符号表。编译器在把项目源代码转换成机器码时，也会生成一份对应的Debug符号表。符号表是一个映射表，它把每一个藏在编译好的binary中的机器指令映射到生成它们的每一行代码中。

而对于系统库的堆栈的符号化，我们需要有对应系统版本库的符号表，符号表的获取需要系统版本号，编译版本号定位。

##### 汇编定位法

有时候，哪怕我们符号化了，但是经过编译器的翻译，有时候也无法通过符号化之后匹配到的代码行来定位最精确的原因，因为一行源代码可能包含很多逻辑而被编译为大段汇编，或者编译优化将多行代码合并优化等操作

根据Crash堆栈，找到Binary Image的起始地址，算出对应的代码偏移，找到代码行

##### 现场勘探法

这是基于汇编法的一种分析方法，有时候我们发现即使定位到了具体的汇编行，问题还是比较难分析，因为只拿到了代码信息，而运行时的各种状态都是丢失的。

对于能够重现的crash，我们可以打符号断电或者地址断点到具体的Crash地方附近进行分析，哪怕是无法复现的Crash，我们也可以到现场看下正常情况的栈、寄存器是怎么样的，对比找出问题

##### 参考阅读

[iOSCrash分析攻略](https://mp.weixin.qq.com/s/hVj-j61Br3dox37SN79fDQ)

我们可以通过拦截异常和信号捕获Crash，通过上述三种方法定位到具体的Crash位置。

[了解和分析iOS Crash](https://juejin.im/post/6844903774780145678)

[App崩溃现场取变量名和其实际值对应关系（不只是寄存器）](https://juejin.im/post/6883160410736820231#comment)

[汇编指令学习](https://blog.cnbluebox.com/blog/2017/07/24/arm64-start/)

[iOSCrash防护](https://juejin.im/post/6874435201632583694)

### OOM问题

Jetsam机制探索，OOM问题捕获和分析，参考整理的Jetsam原理探索思维导图

