对于iOS的UI，这里放个图提醒一下自己

![img](https://tva1.sinaimg.cn/large/0081Kckwly1gk0e1txaqej30aa07p3yz.jpg)

Core Animation是一个图形渲染和动画的基础库，是一个复合引擎，职责是尽可能快地组合屏幕上不同的可视内容。这个内容被分解成独立的图层，存储在一个叫图层树的体系之中。Core Animation直接作用于CALayer，并非直接作用于UIView，且动画执行过程是在后台操作，不会阻塞主线程。