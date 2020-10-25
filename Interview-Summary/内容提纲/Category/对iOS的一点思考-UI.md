# 对iOS的一点思考：UI篇

对于iOS的UI，这里放个图提醒一下自己

![img](https://tva1.sinaimg.cn/large/0081Kckwly1gk0e1txaqej30aa07p3yz.jpg)



### iOS中的绘制框架

#### UIKit

iOS最常用的框架，但不具备成像能力，主要负责用户操作事件的响应，事件响应的传递大体是经过逐层的视图树遍历实现的。

事件响应依赖于**事件响应链**

#### Core Animation

Core Animation作为图形渲染和动画的基础库，是一个复合引擎，职责是尽可能快地组合屏幕上不同的可视内容。这些可视内容被分解成独立的图层，存储在一个叫图层树的体系之中。Core Animation直接作用于CALayer，并非直接作用于UIView，且动画执行过程是在后台操作，不会阻塞主线程。

#### Core Graphics

Core Graphics基于Quartz高级绘图引擎，主要用于**运行时绘制图像**。

我们在UIView中重写的drawRect就是依赖于Core Graphics，所以会创建一张视图尺寸大小的寄存图，并且Core Graphics的内容是提交给CPU进行绘制，所以相对于Core Animation，Core Graphics在CPU和内存上会消耗更多。

#### Core Image

用来**处理运行前创建的图像**。Core Image框架拥有一系列现成的图像过滤器，能对已存在的图像进行高效的处理，如降采样。

#### OpenGL ES或Metal

绘制的底层框架。OpenGL ES是由GPU厂商实现的一套第三方标准，Metal也是一套第三方标准，但是由苹果实现。**Apple已实现一套机制将OpenGL命令无缝桥接到Metal上**，由Metal执行真正与硬件交互的工作。当前苹果所推动的趋势也是更多地使用Metal而不是OpenGL ES。

#### 

#### 层级关系的梳理

视图树，UIView的视图层级结构

图层树，CALayer的层级结构

呈现树

渲染树

### iOS中的渲染流程

CPU处理，然后提交给GPU处理，布局和渲染都会在Runloop的同一个阶段统一执行

VSync垂直信号 + 双缓冲机制，解决屏幕撕裂问题，但是导致了当前的卡顿问题

#### 参考阅读

* [iOS图像渲染原理](http://chuquan.me/2018/09/25/ios-graphics-render-principle/)
* [计算机图形图像渲染原理](http://chuquan.me/2018/08/26/graphics-rending-principle-gpu/)

### 

### 事件处理

#### 事件响应链

事件传递过程，以及响应事件链

#### 视图生命周期

AppDelegate 的生命周期，主要可以涉及应用启动优化，前后台切换的状态备份，墓碑机制，内存警告

UIViewController的生命周期，可以涉及视图控制器的加载，以及布局、转场的管理

UIView的生命周期，涉及视图的加载、绘制，布局等

### UI绘制原理

CAlayer的绘制流程

### iOS动画原理

iOS动画的原理与实现方式

##### 参考阅读

[解析iOS动画原理与实现](https://www.jianshu.com/p/13c231b76594)

### UI中的一些设计思想

* [浅谈UITableViewCell重用机制](http://sharonhu1990.github.io/%E6%B5%85%E6%9E%90UITableViewCell%E9%87%8D%E7%94%A8%E6%9C%BA%E5%88%B6.html)
* [UITableView复用机制的底层探秘](https://www.desgard.com/iOS-Source-Probe/Objective-C/Foundation/%E5%A4%8D%E7%94%A8%E7%9A%84%E7%B2%BE%E5%A6%99%20-%20UITableView%20%E5%A4%8D%E7%94%A8%E6%8A%80%E6%9C%AF%E5%8E%9F%E7%90%86%E5%88%86%E6%9E%90.html)



### 