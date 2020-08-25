# 自定义View

由于业务需要，这次尝试了一下使用纯代码构建自定义View。在自定义实现的过程，对View的生命周期和工作流程也得到了进一步的认识，在此记录一下。

自定义UI可以用Core Graphics和Core Animation绘制，也可以用传统的UIKit实现绘制。

### View的生命周期

layoutSubviews、setNeedDisplay，init和init(frame: CGRect)、draw()等方法的作用、如何重写和何时调用（加载流程）

#### 了解View的加载

在纯代码构建view时，我们常常这样初始化一个`view`

```swift
//1>. 默认初始化
let view1 = UIView()

//2>. 继承的方法
let size = CGSize(width: 20, height: 20)
let view2 = UIVIew(frame: CGRect(origin: .zero, size: size))

//3>. 自定义方法
let titles = ["形状", "样式", "文本"]
let view3 = CustomView(items: titles)
```

这一阶段我们完成了控件最简单的初始化。

### 自定义数据结构

使用自定义的数据结构来表示自定义UI的信息。

### 使用纯代码构建自定义View

使用纯代码构建View，所以选择了SnapKit实现View之间的约束。需要注意的是，使用SnapKit编写约束的过程中需要确保subview或superview的约束实现完整（例如宽高）。

约束代码应该写在哪？

### 容器View

定义专门的UIView，作为容器，管理绘制自定义的需要展示的UI。自定义UI的元素应可以良好的支持单元测试，每一个单元尽量内聚。和外部通过数据连接，自身的逻辑可以独立的运行。

容器View可能有多层，需要注意的是不同层次的划分和管理应尽量清晰。

### 使用DataSource&Delegate模式扩展View

#### DataSource

作用是数据传输

问题在于DataSource会在View的哪个阶段触发呢？

#### Delegate

作用是事件回调

问题在于一个多层的View最终要怎么回调到最上层呢？

#### 交互事件处理



### 内存优化

懒加载和无用时remove

remove是使用removeFromSuperview么，如何确保remove成功并释放掉对应部分内存。