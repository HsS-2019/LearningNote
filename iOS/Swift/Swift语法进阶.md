Swift进阶

### 语法进阶

* #### `fileter`、`map`、`flatmap`、`reduce`的使用

* #### 初始化（以安全为目的）

  **初始化顺序**

  1. 设置子类自己需要初始化的变量
  2. 调用父类对应的初始化方法
  3. 对父类中的需要改变的成员进行设定
  
  **初始化方法分类**
  
  1. **`designated`**
  
     即不加修饰的init方法，主要使用的初始化方法，分为自定义和从父类继承两种。Swift强制在这类方法中保证所有非Optional的实例变量被赋值初始化，而在子类中也强制（显式或隐式地）调用super版本的designated初始化，确保被初始化对象可以完成完整的初始化。
  
     ```swift
     init(with frame: CGRect){
       //子类成员初始化
       
       //父类成员初始化
       super.init()
       
       //父类成员变量修改值
       
     }
     ```
  
   
  
  2. **`convenience`**
  
     在init前加`convenience`关键字修饰的初始化方法，作为补充和提供使用上的方便。所有的`covenience`初始化方法都必须调用同一个类中的`designated`初始化完成设置。
  
     另外，`convenience`初始化方法不能被子类重写或者是从子类中以super方式调用（除非加了`convenience`关键字），所以需要在子类中实现重写了父类`convenience`方法所需要的`init`方法，我们才能直接使用父类的`convenience`方法完成子类的初始化。
  
     ```swift
     convenience init(){
       
       //调用这个类的designated初始化方法
       self.init()
     }
     ```
  
     
  
  3. **`required`**
  
     对于希望子类中一定实现的`designated`初始化方法，我们可以通过添加`required`关键字进行限制，强制子类必须重写实现这个方法。
  
     对于父类中的`convenience`初始化方法，我们也可以加上`required`以确保子类对其进行实现。
     
     ```swift
     required init(){
       //强制子类实现的初始化方法
     }
     ```
     
     
     
  4. **可失败构造器**
  
     初始化失败时返回`nil`，所以通过`Optional Binding`，我们就能知道初始化是否成功了。我们还可以在这类初始化方法中对`self`进行赋值
  
     ```swift
     init?(){
       
       //初始化fail
       return nil
     }
     ```
  
     
  
  **和OC的区别**
  
  1. OC中init方法无法保证只被调用一次。Swift确保只调用一次。
  2. OC中无法保证在初始化方法调用以后实例的所有变量都完成初始化。Swift通过强制调用`designated`初始化方法确保被初始化对象总是可以完成完成的初始化。
  3. OC中如果在初始化里使用属性进行设置的话会触发各种问题。Swift中属性只分为存储属性和计算属性？
  4. OC中初始化方法返回self或者nil，Swift中初始化方法没有返回值（除了可失败构造器）。
  
* #### `String`中的`Index`结构

  #### 不等长的元素

  String中元素使用UTF8(Unicode)编码，所以每个元素的长度为1～4字节，所以没法简单地通过Int值下标，直接索引到对应元素。

  ##### Index的内部结构和设计思路

  #### 绝对索引和相对索引

  #### 数组越界处理

  PS：

  1. 不同字符串的`Index`不应混用
  2. `Index`不一定从0开始

* #### `Array`动态增加Size

* #### `Hash`值的使用

### 工程进阶

#### 任务调度器的实现

先学知识

* 相关数据结构：queue、stack、deque、priority_queue
* 相关设计模式：命令模式、策略模式
* iOS相关：runloop、线程安全

### 参考资料

- [Swift的字符串为什么这么难用？](https://kemchenj.github.io/2019-10-07/)
- [iOS 任务调度器：为CPU和内存减负](https://mp.weixin.qq.com/s/3LaZYNoqy_UawY81PyT9pQ)



