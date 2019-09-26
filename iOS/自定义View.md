# 自定义View

由于业务需要，这次尝试了一下使用纯代码构建自定义View。在自定义实现的过程，对View的生命周期和工作流程也得到了进一步的认识，在此记录一下。

### View的生命周期

layoutSubviews、setNeedDisplay，init和init(frame: CGRect)、draw()等方法的作用、如何重写和何时调用（加载流程）

### 使用纯代码构建自定义View

使用纯代码构建View，所以选择了SnapKit实现View之间的约束。需要注意的是，使用SnapKit编写约束的过程中需要确保subview或superview的约束实现完整（例如宽高）。

约束代码应该写在哪？

### 使用DataSource&Delegate模式扩展View

#### DataSource

作用是数据传输

问题在于DataSource会在View的哪个阶段触发呢？

#### Delegate

作用是事件回调

问题在于一个多层的View最终要怎么回调到最上层呢？

### 内存优化

懒加载和无用时remove

remove是使用removeFromSuperview么，如何确保remove成功并释放掉对应部分内存。