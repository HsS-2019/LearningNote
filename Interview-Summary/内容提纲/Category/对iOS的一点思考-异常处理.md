# 对iOS的一点思考：异常处理篇

本文从异常处理机制出发，探索不同语言的异常处理机制，并介绍了如何捕获Crash，分析Crash，和OOM问题分析定位

## 不同语言的异常处理机制

下面会分别分析C++、Objective-C和Swift语言的异常处理机制

#### C++语言的异常处理机制

C++提供了异常机制，使用上同别的语言类似，通过`try catch finally`语法，对一些存在异常的场景或者需要自定义异常场景，需要捕获异常处理，否则会导致未捕获异常引发应用被系统kill掉

C++语言对于未捕获的异常有兜底处理逻辑，就是`terminat`函数

当我们抛出一个异常时，异常会随着函数调用关系，一级一级往上抛出，直到被catch捕获才会停止，如果最终没有被捕获将会导致调用`terminate`函数。为了保证灵活性，C++提供了`set_terminate`函数可以用来设置自己的`terminate`函数，设置完成后，抛出的异常如果没有被捕获就会被自定义的`terminate`函数进行处理

> C++中的noexcept关键字，是用来标注函数的，将决定对应函数的code generation结果。也就是说编译器是否为一个函数生成清理执行路径，是会取决于栈空间对象分配过程之间是否有“潜在抛出异常的表达式”

#### OC语言的异常处理机制

> OC的异常处理和C++的异常处理在实现机制上很像，更严格地说，Objective-C的异常处理机制就是借助C++来实现的

对于`Objective-C`语言，可以通过`@try @catch`捕获异常，但这种方式存在以下缺点，导致使用率不高：

* `@try @catch`基于`block`处理会存在额外的开销，效率不高
* Xcode不会对`@try @catch`中的代码进行ARC管理，如果在抛出异常代码后存在内存释放的话，需要异常捕获后手动释放，否则会导致内存泄漏

但对于容易出现异常的操作，比如文件读写或需要配合使用`@throw`的情况等，适合使用异常捕获。

Objective-C中有对于未捕获的异常的兜底逻辑`NSSetUncaughtExceptionHandler`函数。

> 当异常发生时，runtime必须要按一定的路径来逐一退出栈帧到exception handler，不能将栈帧直接重置，否则就会引发资源泄漏。这个过程叫做Stack Unwinding，在macOS中，C++ABI使用了libunwind来配合实现异常处理机制



#### Stack Unwinding实现

stack unwinding（栈帧回退），是C++和Obective-C语言中异常处理机制的原理。

得到encoding才能进一步确定函数是否具有LSDA，编译器会把异常相关信息存放在这个区域中。通过encoding也可以得到personality函数指针，该函数指针会被存储起来在后面与LSDA配合一起用来判断一个栈帧是否可以处理某个异常。

在libunwind中，stack unwinding经历两个阶段：lookup、cleanup。第一个lookup阶段用于查找是否有哪个栈帧可以处理这个异常，如果没有，直接跳过第二阶段，从而执行failed——>std::terminate来结束进程。

第二阶段与第一阶段类似，都是从栈顶从新walk所有栈帧，找到是否有某个栈帧或者landing pad可以处理异常。

当栈帧清理结束后，会调用`_Unwind_Resume`继续异常处理的过程。`_Unwind_Resume`会继续执行unwinding的第二个阶段，比较类似从当前位置继续抛出异常。

> 实际上Objective-C也是借用了C++的异常处理机制来实现它的异常处理。当我们执行[NSException raise]时，CF内部会调用到Objective-C runtime的objc_exception_throw，等同于C++的throw。

对于Objective-C中使用NSException可能导致内存泄漏的问题，其实是使用不当导致的。

* MRC编译模式下，异常发生时会中断当前函数的执行路径，手动编写的release调用就会被跳过。

* ARC编译模式下，编译器有自动生成retain/release的能力，即Objective-C具有了RAII的能力，因此编译器会为每个Objective-C方法生成用于执行release的landing pad。

#### Swift的异常处理机制

Swift中有异常处理机制，但是没有兜底的异常处理逻辑，即对于未捕获的异常，语言应用层上没有对应接口统一捕获。

因为Swift的错误处理与Objective-C、C++是有本质区别的。可以认为Swift在实现上更像一种语法糖，我们需要显示处理每个可能的错误，即Swift没有Unchecked Exception。由于错误不会跨栈帧逃逸，带来的好处就是不需要stack unwinding了，不管是性能还是代码大小都会得到比较好的控制。

> 查阅了一些资料，Martin在stack overflow上post了Apple的回复，主要是考虑实现后开销过大而没有实现，由于引用计数机制的存在，想要实现类似OC统一捕获运行时错误的功能，需要对于每一个函数在编译器层面加上异常出现时对于引用计数管理的代码，这会使编译出来的代码变得臃肿

**个人存在的一些疑问：**那么为什么OC会有对应的`NSSetUncaughtExceptionHandler`函数统一捕获未捕获的异常呢，`NSSetUncaughtExceptionHandler`函数的实现原理是什么呢？（同terminate）

#### 参考阅读

[初探 Objective-C/C++ 异常处理实现机制](https://mp.weixin.qq.com/s/4Rcaee6kwWmrS3v_M9y0KQ)

[Diagnosing Issues Using Crash Reports and Device Logs](https://developer.apple.com/documentation/xcode/diagnosing_issues_using_crash_reports_and_device_logs#//apple_ref/doc/uid/DTS40008184-CH1-ANALYZING_CRASH_REPORTS-EXCEPTION_CODES)

[How should I use NSSetUncaughtExceptionHandler in Swift](https://stackoverflow.com/questions/25441302/how-should-i-use-nssetuncaughtexceptionhandler-in-swift)

[Uncaught Error/Exception Handling in Swift](https://stackoverflow.com/questions/38737880/uncaught-error-exception-handling-in-swift)



## Crash分析

#### Crash的原因以及类型

#### 捕获Crash

无论是硬件异常产生的信号，还是软件异常产生的信号，都会走到act_set_astbsd()进而唤醒收到信号的进程的某一个线程。这一机制给我们在自身进程内捕获Crash提供了可能，即通过拦截UNIX信号或Mach异常来捕获崩溃

当我们拦截信号处理之后，可以让程序不崩溃而继续运行，但是不建议这样，这时程序已经处于异常不可知状态

一般我们通过两种方式拦截异常，包括Mach异常拦截和UNIX信号拦截，虽然我们可以看到很多Mach异常都转换成了UNIX信号，但是基于以下的原因，我们仍然拦截了Mach异常

* 不是所有的Mach异常类型都映射到了UNIX信号，如EXC_GUARD异常
* UNIX信号在崩溃线程回调，如果遇到了stackoverflow问题，已经没有条件（栈空间）再执行回调代码

因为用户态的软件异常是直接走信号流程的，所以我们也不能认为直接拦截Mach异常就可以了。

> NSSetUncaughtExceptionHandler：我们可以通过注册`NSSetUncaughtExceptionHandler`，实现应用级的异常捕获（只捕获部分异常）。但`NSSetUncaughtExceptionHandler`函数存在覆盖现象，后注册的总会顶替掉前面注册的，因此当crash发生时，只触发了最后注册传入的捕获回调函数。

对于Swift中的异常捕获，NSSetUncaughtExceptionHandler只捕获了OBjective-C的错误（NSException错误），对于Swift throw出来的错误和运行时错误，NSSetUncaughtExceptionHandler无法捕获，可以通过UNIX信号捕获部分异常

##### 参考阅读

[iOS的崩溃捕获方案](http://silentcat.top/2017/11/23/iOS%E7%9A%84%E5%B4%A9%E6%BA%83%E6%8D%95%E8%8E%B7%E6%96%B9%E6%A1%88/)

[漫谈iOS Crash收集框架](http://www.cocoachina.com/articles/12301)

#### 分析Crash

Crash出现在开发者编写的代码和系统库中时，如何分析和定位

##### 符号化

对于项目中堆栈的符号化，需要项目对应版本的dsym文件。

> dsym文件：dsym文件其实是一个符号表。编译器在把项目源代码转换成机器码时，也会生成一份对应的Debug符号表。符号表是一个映射表，它把每一个藏在编译好的binary中的机器指令映射到生成它们的每一行代码中。

符号化过程：根据framework的name，从Crash Report底部找到该framework对应的uuid。根据Crash堆栈中的加载地址、framework的binary iname name、架构和该framework对应dsym文件里的DWARF文件路径，通过atos命令就可以解析出对应的源码。

同理可知，对于系统库的堆栈的符号化，我们需要有对应系统版本库的符号表，符号表的获取需要系统版本号，编译版本号定位。

对于dsym文件，我们需要注意不同构建的dsym文件是不一样的。

> dsym文件和app二进制文件是一一对应的，且每次构建都不同。即便通过相同的源码和配置，再执行一次构建，生成的dsym文件也无法和之前的crash report做符号化匹配。其原理是每次构建得到的二进制文件是不一样的（随机地址分配？）。

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

本文探讨了这样一种思路，Crash被捕获时我们可以借助于dsym文件获取崩溃现场当前方法中各个变量名和当前值。

> Crash捕获时，我们需要确定当前方法用到了什么变量，以及这些变量的值。

因为涉及符号解析，本文作者提出了两种实现的思路：

* App中带上符号文件，崩溃时实时解析
* 将整个栈区的内容dump下来，发到服务器上做具体解析（这里有个疑问，只dump栈区）

除此之外，我们需要知道，Crash捕获和解析的过程中还可以获取以下的信息

* 通过Crash收集的堆栈地址我们可以在dsym文件中找到对应的函数名、文件名和行号等信息（符号化）
* 在Crash捕获时，我们可以把崩溃现场的寄存器中的值一起上传，方便后续分析

[汇编指令学习](https://blog.cnbluebox.com/blog/2017/07/24/arm64-start/)

[iOSCrash防护](https://juejin.im/post/6874435201632583694)

### OOM问题

Jetsam机制探索，OOM问题捕获和分析，参考整理的Jetsam原理探索思维导图

> 实践是检验真理的唯一标准