# iOS推荐阅读

<!--[toc]-->

## Swift

### 教程和书籍
#### 语法
 - [官方文档（中文版）](https://www.cnswift.org/)
 - [官方文档（中文版-SwiftGG）]()

#### 视频教程
- [Stanford iOS开发课程](https://www.bilibili.com/video/av42035892)
  围绕怎么开发一个翻牌游戏，讲解使用swift开发iOS的基本流程  

- [泊学]()

  对于Swift原理的探索，iOS编程实践的总结，另外还讲解了怎么使用Swift实现基于MVVM的iOS App

#### 扩展阅读
- [Swifter-Swift开发者必备Tips](https://objccn.io/products/)-出自Objc中国，Swift的一些技巧,实用  
- [函数式Swift](https://objccn.io/products/)-出自Objc中国  
- [CoreData](https://objccn.io/products/)-出自Objc中国  
- [Swift进阶](https://objccn.io/products/)-出自Objc中国  
- [集合类型优化](https://objccn.io/products/)-出自Objc中国  
- [App架构](https://objccn.io/products/)-出自Objc中国  
- [Swift:面向协议编程]()  
- [精通Swift设计模式]()
- [Using Combine](https://heckj.github.io/swiftui-notes/)-
- [跟戴铭学iOS编程—理顺核心知识点]()

### 其它学习资源
#### 英文
* [官网资料](https://developer.apple.com/swift/resources/)-官方学习教程
* [Swift的官方网站](https://swift.org)
* [Swift开源源码](https://github.com/apple/swift-evolution)
* [SwiftDoc-系统标准库文档](http://swiftdoc.org/)-更方便查看swift系统库的文档

#### 中文
* [中文的Swift学习资源](https://github.com/ipader/SwiftGuide)-学习资源偏旧，现已专注于Swift开源精选资源方向
* [优秀的Swift开源库汇总](https://github.com/SwiftOldDriver/SwiftMarch)-介绍常用于实际项目的开源库
* [SwiftGG翻译组](http://swift.gg)-定期翻译Swift的相关文章
* [Objc中国](https://objccn.io/products/)-Swift专业书籍的汉化版，电子版提供更新


### 实战项目
- demo推荐，道长的[Swift30Projects](https://github.com/soapyigu/Swift30Projects)。

>需要注意的是，demo是只维护到swift3的，所以需要更新源码至swift5才可以正常运行。


## Objective-C
### 教程和书籍
#### 语法  
- [官方文档](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html#//apple_ref/doc/uid/TP40011210)

#### 基础教程
- [Objective-C语法视频-黑马程序员](https://search.bilibili.com/all?keyword=Objective-C&from_source=nav_search)

#### 进阶阅读
- [Objective-C高级编程：iOS与OS X多线程和内存管理]()
这本书是必看的，专注于讲ARC、Blocks、GCD的使用方法和原理，多线程方面也讲的很清楚

- [Effective Objective-C 2.0：编写高质量iOS与OS X代码的52个有效方法]()
这本书也是必看的，很多面试题有涉及，Objective-C的一些技巧

### 其它学习资源
#### 源码阅读
- [runtime部分源码阅读](https://opensource.apple.com/source/objc4/v)
了解ARC、KVC、Runtime等的底层实现
- [coreFoundation源码阅读](https://opensource.apple.com/source/CF/)
了解runloop的底层实现

## Flutter
点击进入[官方网站](https://flutter.dev/)

### 其它学习资源



## 进阶阅读

* [美团 iOS 端开源框架 Graver 在动态化上的探索与实践](https://mp.weixin.qq.com/s/PD9hnWv8B32ZCYj1UokUBA)

  主要讨论了在iOS端对动态化布局和渲染优化进行的探索，渲染流程由系统UIKit的“拼控件”，变成了自定义的“画控件”。两者都是线程安全的，不同的是UIKit只能在主线程进行绘制，而Graver可以在非主线程进行绘制，直到需要显示时才转到主线程，这有利于减小主线程的资源开销，提高渲染性能。

* [Understanding the iOS 13 Scene Delegate](https://www.donnywals.com/understanding-the-ios-13-scene-delegate/)

  本文主要围绕Xcode 11以上新建的项目自带的新文件`SceneDelegate.swift`，讨论了`SceneDelegate.swift`的用途、怎么更有效率地实现`SceneDelegate.swift`，以及为什么说`SceneDelegate.swift`是iOS 13的重要部分

* 



New Story