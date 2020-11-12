# 对iOS的一点思考-NSObject篇

> 前言：为了更好地理解NSObject，这一篇的内容其实大部分我都做成了思维导图。但是后来想了一下，后面如果读到好的文章，导图收藏的链接不够直观，多端同步想打开链接瞅一眼还得下个导图软件，还是另开一篇比较方便。**本文大部分内容可以参考iOS目录下原理系列中的思维导图。**

Objective-C中实例、类对象、元类对象之间的关系

> 主要是isa和superClass指向

实例isa指针指向类对象、类对象的isa指针指向元类，所有元类的isa指针指向根元类（根元类指向自身）

类对象的superClass往上递归查找，最终都指向NSObject，NSObject的superClass为nil。元类的superClass关系类似对应的类对象，子类元类的superClass指向父类元类，最终指向根元类，而根元类的superClass指针指向NSObject

所以对于方法查找，可能会出现这样一种情况，NSObject分类实现了实例方法，子类以类方法形式调用不会Crash

参考文章： [深入理解Objective-C中实例、类对象、元类对象之间的关系](https://juejin.im/post/6844903878605946893)

##### Objective-C中的多态性分析

本文厘清重载、重写和隐藏等常被误读概念的同时，分析了Objective-C、C++和Swift语言对重载、多态的支持，以及不同语言对多继承实现的策略。是一篇不错的新手向文章。

[Objective-C中的多态](https://blog.csdn.net/cordova/article/details/52939189)

##### Objective-C中对象的初始化

[带你深入了解OC对象创建过程](https://mp.weixin.qq.com/s/cyNCgBNO9nigvfzDpjzR2g)

本文分析了NSObject的初始化流程，详细地解读了NSObject的alloc函数底层开辟空间和isa初始化的过程。

##### Objective-C中Category的剖析

本文行文思路清晰，把底层的Category实现讲的通俗易懂，是一篇很好的了解Category原理的文章。

[深入理解Objective-C：Category](https://tech.meituan.com/2015/03/03/diveintocategory.html)

##### Objective-C中Block的一些理解

首先来看几个问题

1. Block是如何捕获外部id对象的，外部id对象用不用`__block`修饰符的区别。

   ARC下，用不用`__block`修饰符，id对象都会被Block持有（这里只针对强引用对象）。而Block本身也是一个对象，所以可能会出现循环引用问题

   需要注意的是，在MRC下，`__block`根本不会对指针指向的对象执行copy操作，而只是把指针进行的复制（这是否指没有发送retain消息呢？）

2. Block捕获外部强引用、捕获外部弱引用，以及Block内部成员变量持有外部强引用（弱引用）有什么区别

   Block捕获外部引用时，本质上是Block对象内部生成了对应的成员变量。强引用表示指向并持有，引用计数加一；弱引用表示指向但不持有，引用计数不变。

   如果Block捕获的是id对象的弱引用，由于Block不是强引用该id对象，因此可以避免上面的循环引用问题。但这会引入一个新的问题，即无法在Block的作用域内确保弱引用对象不会为nil。（如果弱引用指向的对象被释放了，弱引用会被置nil，在Block内部访问到的弱引用可能为空。）

   因此有的时候为了确保我们在Block内访问的弱引用不为nil，我们会在Block内部用一个**局部变量**强引用该弱引用指向的对象。这样保证了弱引用指向的对象不会再闭包范围内被释放。但由于局部变量的作用域仅在闭包范围内，当跳出该闭包时，局部变量被释放，避免了循环引用的问题。

3. 对于多层嵌套的Block，最里层的Block捕获可外层Block强引用的id对象，为什么会导致循环引用

   经过上面的论述，我们大概知道了Block捕获id对象和Block闭包范围内的局部变量指向id对象的区别。

上面的几个问题，是由**多层Block嵌套使用的场景中为什么要每一层都先weak指向，再在里面Block中strong持有**这一问题倒推出来的。

首先，我们需要知道，Block本质上是一个对象，Block捕获外部变量的本质是将对应变量的值/指针存储在Block的内存布局中。

[深入研究 Block 捕获外部变量和 __block 实现原理](https://halfrost.com/ios_block/)

[聊聊循环引用的检测](https://triplecc.github.io/2019/08/15/%E8%81%8A%E8%81%8A%E5%BE%AA%E7%8E%AF%E5%BC%95%E7%94%A8%E7%9A%84%E6%A3%80%E6%B5%8B/)

> 实践是检验真理的唯一标准