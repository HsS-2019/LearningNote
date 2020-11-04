# 对iOS的一点思考-NSObject篇

> 前言：为了更好地理解NSObject，这一篇的内容其实大部分我都做成了思维导图。但是后来想了一下，后面如果读到好的文章，导图收藏的链接不够直观，多端同步想打开链接瞅一眼还得下个导图软件，还是另开一篇比较方便。**本文大部分内容可以参考iOS目录下原理系列中的思维导图。**

##### Objective-C中的多态性分析

本文厘清重载、重写和隐藏等常被误读概念的同时，分析了Objective-C、C++和Swift语言对重载、多态的支持，以及不同语言对多继承实现的策略。是一篇不错的新手向文章。

[Objective-C中的多态](https://blog.csdn.net/cordova/article/details/52939189)

##### Objective-C中对象的初始化

[带你深入了解OC对象创建过程](https://mp.weixin.qq.com/s/cyNCgBNO9nigvfzDpjzR2g)

本文分析了NSObject的初始化流程，详细地解读了NSObject的alloc函数底层开辟空间和isa初始化的过程。

Objective-C中Category的剖析

本文行文思路清晰，把底层的Category实现讲的通俗易懂，是一篇很好的了解Category原理的文章。

[深入理解Objective-C：Category](https://tech.meituan.com/2015/03/03/diveintocategory.html)

> 实践是检验真理的唯一标准