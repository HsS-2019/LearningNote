# iOS的生命周期

## APP的启动过程
编译、加载到内存、main函数之前，到main函数执行。

### main函数

- 初始化UIApplication
- 初始化UIApplication的delegate
- 建立并开启runloop

### main函数之后

#### 执行顺序

- 执行上述初始化的delegate的代理方法，即`didFinishLaunchingWithOptions`和`applicationDidBecomeActive`
- 初始化Window，初始化基础的ViewController（未使用Storyboard指定初始界面的用法）
- 获取数据，并展示给用户

### 优化
1. 能延迟初始化的尽量延迟初始化，提高APP的启动速度。

### 参考资料
1. [深入理解iOS APP的启动过程](https://www.jianshu.com/p/a51fcabc9c71)

## APP的生命周期
APP自启动后，便在一个runloop中循环处理程序的逻辑，而程序的逻辑可抽象地概括为多种不同的状态。
### APP的各种状态

#### 1. Inactive
未激活
#### 2. Active
已激活
#### 3. Background
前台
#### 4. Suspended
后台
#### 5. 其它
##### NotRunning
APP还没运行
##### Terminate
在前台或者在后台但尚未被挂起的时候，用户主动kill或者系统kill才会执行。  

##### .
**如下图所示，为iOS APP的生命周期**
![APP声明周期](https://upload-images.jianshu.io/upload_images/128529-679617e8e1265a9a.jpg)
### 参考资料
1. [iOS App声明周期](https://www.jianshu.com/p/4190418c3994)


## UIView的生命周期  
  
UIViewController中的UIView的生命周期主要与`initWithNib`、`awakeFromNib`、`loadView`、`viewDidLoad`、`viewWillAppear`、`viewWillLayoutSubviews`、
`viewDidLayoutSubviews`、`viewDidAppear`、`viewWillDisappear`、`viewDidDisappear`等方法相关联。

### 视图的加载方式

#### 通过Storyboard加载  
storyboard的视图会序列化并以文件形式存储下来，在需要加载的时候再反序列化解密出来。
#### 通过Nib文件加载  
调用initWithNibName方法，
#### 代码构建，通过`loadView`加载  
若不重写loaddView方法，代码构建的方式下默认该View是一个空白的View

### 方法的具体使用
#### initWithNib方法
#### awakeFromNib方法
#### loadView方法
#### viewDidLoad方法
#### viewWillAppear方法
#### viewWillLayoutSubviews方法

### 视图的加载过程
1. 执行`initWithCoder`或者`initWithNibName`方法，从归档文件中加载viewController对象
2. 执行`awakeFromNib`方法，处理viewController对象的额外配置
3. 执行`loadView`方法，创建或加载一个view，并赋值到viewController对象的view
4. 执行`viewDidLoad`方法，已加载视图层次到内存中。
5. 执行`viewWillAppear`方法
6. 执行`viewWillLayoutSubviews`方法
7. 执行`viewDidLayoutSubviews`方法
8. 执行`viewDidAppear`方法，  
......
9. 执行`viewWillDisappear`方法
10. 执行`viewDidDisappear`方法

### 总结
1. 纯代码构建视图需重写`loadView`方法，但不要在重写的`loadView`方法中调用父类的`loadView`方法。

### 参考资料
1. [UIView声明周期详解](https://bestswifter.com/uiviewlifetime/)

## UIViewController的生命周期
UIViewController采用懒加载的方式，即第一次访问到这个控制器的view时才加载。
### UIViewController和UIVIew的区别
