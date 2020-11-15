# Xcode Video 

观看Xcode 的官方视频是我们了解和学习iOS开发相关知识的一个重要途径，下面记录了一些个人观看的视频和心得，在学习新知识之余，也是对已掌握的开发流程和技能做一个查漏补缺。

### Developing Process 

* [Getting started With Xcode](https://developer.apple.com/videos/play/wwdc2019/404/)

  主要对创建项目、编写代码、运行和调试、集成第三方框架、测试和发布的iOS开发流程做了一个简要的讲解。通过这个视频，我们可以大致了解iOS开发的完整流程，从而针对自己不熟悉的地方进行针对性学习。

* [Testing in Xcode](https://developer.apple.com/videos/play/wwdc2019/413)

  单元测试是验证你的代码是否运行良好的基本工具，通过这个这个视频你将了解如果通过Xcode中的XCTest构建单元测试，制定测试计划，并对你的应用中的功能进行自动化测试。




### Design & mechanism

关注语言层面上一些机制的底层实现

#### Swift

##### Understanding Swift Performance

> 本视频后半部分也阐述了写时复制的原理

前半部分从内存分配、引用计数和方法派送等角度分析怎么设计实现，才能编写出更高效的Swift代码。

主要是比较值类型和引用类型，以及Swift更提倡优先使用值类型实现的说明

后半部分从协议，泛型角度分析，怎么才能编写更高性能的代码

需要注意的地方有

* 协议中使用了value witness table和protocol witness table机制，值类型也可以扩展实现动态多态

* 对于Protocol类型，Swift 底层实现了inline value buffer机制，对于三个字以内长度内容直接放在栈上，超过则放在堆上，栈上只存储指向堆的引用地址（原理上跟taggedpointer有点儿像？）

* 泛型和协议的比较，泛型支持多态的更静态的形式，也称参数多态性（静态多态）

  静态多态的每个调用上下文只有一种类型，并且在调用链中会通过类型降级进行类型取代

  静态多态前提下还可以进行特定泛型优化

* whole module optimization

  用于编辑器的优化机制，默认打开。机制通过跨函数优化，可以进行内联等优化操作，对于泛型，可以通过获取类型的具体实现来进行推断优化，进行类型降级方法内联，删除多余方法等操作

遗留问题

* inline value Buffer是只有protocol类型才有的吗
* value witness table的应用场景以及原理
* protocol witness table的应用场景以及原理

[Understanding Swift Performance](https://developer.apple.com/videos/play/wwdc2016/416/)

#### Objective-C

### Learning New 

* [Introducing SwiftUI: Building Your First APP](https://developer.apple.com/videos/play/wwdc2019/404/)

  本视频主要介绍了如何通过Apple新推出的一个声明式UI框架—SwiftUI，构建你的APP。

* 