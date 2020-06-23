#### removeFromSuperview()

我们将当前视图从其父视图上移除时，通常是通过调用当前视图的removeFromSuperview()方法实现。调用该方法后，将当前view从它的父view和窗口中移除，同时也把它从响应事件操作的响应者链上移除。

需要注意的是：

* 执行了removeFromSuperview方法后，Superview在移除view时也会释放对该view的强引用，此时如果没有其它地方对该view持有强引用，则会从内存中移除。可以根据需要考虑以下两点
  * **野指针：**不存在其它强引用时，在Superview释放对视图的强引用后，根据**ARC自动引用计数机制**，视图将从内存中移除。此时如果**通过弱引用访问**该视图对象，会得到一个nil的结果；而**通过无主引用访问**时，会导致crash。
  * **可复用：**如果还存在其它强引用，**视图仍存在内存中**，需要使用时不需要再次创建，直接addSubview就可以了。这种情况下，不要忘记在恰当的时候释放其它地方对视图的强引用，避免发生内存泄漏。
* 在ARC和MRC下，多次执行removeFromSuperview方法都不会影响结果，这对于addSubviews方法也是一样的。但需要注意，同一视图多次被addSubviews方法添加到不同的视图下时，**以最后一次操作为准**。另外，**在MRC下**多次release是会导致crash的。
  * 其实，对于同一父视图和同一子视图，重复使用addSubviews添加，或者使用removeFromSuperview移除，跟执行一次的效果是一样的，因为这种情况下重复调用不会导致重复添加和释放。
* 永远不要在view的**draw(rect:)方法**中调用removeFromSuperview方法，这一点在苹果官方API描述中也有注明。



参考：

1. [随便说说removeFromSuperview方法](https://www.jianshu.com/p/b817c94cac0b)

2. [关于removeFromSuperview和addSubview](https://www.jianshu.com/p/e7460104f0a7)



