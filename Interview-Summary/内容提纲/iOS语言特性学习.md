# 记录iOS上不同语言的特性

学习过程中发现，在iOS平台上的使用的两门语言：Objective-C和Swift，既有着不同，也存在着很多的共性。

## Objective-C和Swift的比较

不同点在于：

* 方法派送方式。OC是在C上加了一层很薄的支持面向对象范式的封装，是一门动态语言，具有运行时特性，对象方法调用采用的是消息转发机制。而Swift是一门类型安全的静态语言，对象方法派发方式有直接派发、函数表派发和消息转发三种
* OC支持轻量级的范型和范型约束，但Swift对范型支持的更好，集合类遵循的Collection协议底层实现了类型擦除
* 对于多态、多继承，OC可使用分类、Runtime实现，Swift可通过协议扩展实现
* 对于Autoreleasepool的使用，反映出两门语言在设计上的一些选择（相对于工厂方法带来的延迟释放需求，Swift更希望开发者直接初始化类并使用）
* 编译的中间产物不一致，Swift编译中间产物是SIL，Objective-C的编译中间产物是C/C++

且OC不支持元组、可选类型（但是这其实是一个语法糖）等特性。不同于OC，Swift的String、Collection衍生出的Array和Dictionary这些集合类型都是值类型。

相同点在于：

* Swift 和OC都是使用引用计数管理机制管理内存，即ARC。底层实现都是依靠哈希表和isa指针存储和管理强引用和若引用的引用计数。
* Swift可以通过继承NSObject类型，借助于OC，Swift间接可以使用运行时特性。这里要注意的是，Swift的类类型Class是和NSObject同级的根类，都是基于runtime库相似的内容构建出来的。

## Swift

> 理解Swift中一些特性的原理，有助于我们更好地应用Swift这门语言

#### 引用类型和值类型

比较经典的是class和struct的比较，参考维度：内存分配、引用计数和方法派送

#### 写时复制机制

Swift中的值类型拥有写时复制的特性，但是这一特性的原理是什么呢

我们主要通过以下几个问题探讨一下：

* 容器类型的写时复制
* 当值类型变量A赋值给B，A、B都指向了同一块内存，A被置nil时，会发生什么

#### 方法的派送机制

Swift中方法的派送机制比较复杂，且有可能发生改变，比如SwiftUI出现后，Class含有dynamic关键字时的方法派送方式就由消息派发变成了函数表派发。

Swift支持静态派发、函数表派发和消息派发三种方法派发方式，编译器会根据不同的情况选择不同的派发方式，基于性能考虑优先选择性能高的派发方式

下面的一些思考过程可以反映出基于性能考虑在不同情况下采取不同派发方式的策略：

* 静态派发无法解决多态的问题，所以我们引入了函数表的动态派发方式

* 但函数表派发方式又无法解决extension中添加方法的需求，所以我们又用了静态派发作为这种情况下的派发方式

不得不说，Swift的方法派送方式丰富而又灵活，因此可以支持许多新的语言特性，但也正是因为此，我们更需要细细探索明白Swift中这一精细而巧妙的设计

具体还可以看下四娘之前翻译的一篇讲Swift方法派发方式的文章以及关注Swift社区

#### 参考阅读

[理解Swift中struct和class在不同情况下性能的差异](https://www.jianshu.com/p/394e4fe614a0)

[Swift - 结构体优化 - 写时复制](https://www.jianshu.com/p/568cf6003dd4)

[Swift中copy on write的研究](https://peteruncle.com/2018/03/05/swift%E4%B8%ADcopy%20on%20write%E7%9A%84%E7%A0%94%E7%A9%B6/#%E4%BB%80%E4%B9%88%E6%98%AF%E5%86%99%E6%97%B6%E5%A4%8D%E5%88%B6-copy-on-write)

[Writing High-Performance Swift Code](https://github.com/apple/swift/blob/main/docs/OptimizationTips.rst)

这是Swift的一篇官方文档，讲述了如何通过一些策略编写高质量的Swift代码，其中就有讲解了写时复制的底层实现机制，强烈建议深入理解本文

[浅谈Swift方法派发机制](https://blog.bombox.org/2020-05-23/swift-method-dispatch/)

本文简单描述了Swift在方法派发中采取多种派发方法灵活选择的策略，并概括了每一种派发方式的限定范围，是一篇不错的了解Swift方法派送机制的文章

## Objective-C

这里主要记录一些OC相关的特性

##### OC对范型的支持

Objective-C支持轻量级的范型

> 逆变与协变

协变，`__covariant`。通过协变，我们能够解决，一个容纳子类的Box（Box使用了范型），也是容纳父类的Box。协变常用于容器类型，系统的`NSArray`、`NSDictionary`、`NSSet`都采用了协变

逆变，`__contravariant`。如果变量A的占位符是父类，那么可以把它赋值给占位符类型是子类的B。逆变侧重行为，要求父类和子类能够提供同样的行为，所以通过父类的接口创建的范型类，可以用来处理子类

在OC中，主要受限制的是占位符的使用，.m文件和分类中无法使用占位符

参考文章：

[Objective-C范型](https://mp.weixin.qq.com/s/hY49YSBAvK8l7tp9rMDpxg)

Objective-C对Autoreleasepool的运用

##### ARC和MRC的一些区别

> ARC所做的，只是在代码编译时，为你自动在合适的位置插入release或autorelease。

ARC的加入，一方面是为了提高开发者的工作效率，避免手动管理内存带来的复杂计算问题；个人觉得另一方面也是希望加入了ARC后，从不同角度优化软件的运行性能。

ARC和MRC的一些区别如下：

* ARC相当于编译器自动帮你填写了retain、release等方法。但是ARC不是真的填写`retain/release`，因为`retain/release`是objc的消息，ARC会直接调用runtime的C函数，这会快很多。

* 对于autorelease方法的调用，ARC不但可以简化写法，还可以让它更快，原因在于它可以消除不必要的入池操作。

  ARC时代针对返回的对象，编译器实现了这样一种最优化处理机制

  * 执行`objc_autoreleaseReturnValue`时，根据查看后续调用的方法列表是否包含`objc_retainAutoreleaseReturnValue`方法，以判断是否走优化流程
  * 如果走优化流程，则将一个标志位存储在TLS（Thread Local Storage）中后直接返回对象。否则加入`autoreleasepool`
  * 执行后续方法`objc_retainAutoreleaseReturnValue`时检查TLS的标志位判断是否处于优化流程，如果处于优化流程则直接返回对象，并且将TLS的状态还原。

* 在ARC和MRC下，Block的表现也有所不同，ARC下赋值时Block自动调用copy方法。且`__block`变量在ARC和MRC下的处理也有所不同，详见霜神关于Block的一篇博文

* 在ARC下，CF和OC之间的转化桥梁是__bridge_transfer，它们之间互相转化的原则是：

  * CF转OC时，并且对象的所有者发生改变，则使用`CFBridgingRelease()`或`__bridge_transfer`
  * OC转化为CF时，并且对象的所有者发生改变，则使用`CFBridgingRetain()`或`__bridge_retained`
  * 当一个类型转化到另一个类型时，但是对象所有者没有发生改变，则使用`__bridge`

ARC相比于MRC的不足：

* 如果一个开发者完全清晰地掌握某个对象的生命周期，那么他完全可以只retain一次，然后在最后不需要的时候release掉，在这种情况下MRC比ARC快，这也是MRC的一个优点
* 使用 ARC时，XCode在compile的时候，它对代码的记忆管理时采取较保守的态度，这可能也是OC后续版本中预设property的原因
* 由于ARC对代码内存管理采取的态度较保守，所以相较于MRC，ARC的速度可能会慢上几倍

ARC的注意点：

* 重写dealloc方法不调用`[super dealloc]`方法，另外`__weak`、`__strong`和`__autorelease`应该写在指针后边，变量名前面。
* ARC对Core Foundation无效，需要自己控制内存，包括释放，并且需要cast的时候需要用`__bridge`、`__bridge_transfer`、`__bridge_retained`等修饰符来控制对应内存
* ARC在使用Block的时候需要注意循环引用的问题（其实MRC应该也会存在这一问题）
* 和C混编时需要注意，先将对象赋nil再free掉相关内存，避免使用C的memcpy和reallc函数等。

MRC相比于ARC的不足：

* 编写和维护时需要时间思考内存维护是否正确，因此而导致的编写时和维护时的代价



参考文章：

1. [ARC vs MRC，这不是一个编程习惯问题](http://www.beyondabel.com/blog/2014/03/05/mrc-arc/)
2. [Objective-C高级编程——iOS与OS X多线程和内存管理]()
3. [深入研究Block捕获外部变量和__block实现原理—霜神](https://halfrost.com/ios_block/)

> 实践是检验真理的唯一标准