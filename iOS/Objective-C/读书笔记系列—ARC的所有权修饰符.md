# ARC的所有权修饰符

实际上ARC仍是采用引用计数管理的原理，但是就像“自动引用计数”这个名字一般，使用ARC意味着**编译器会自动帮助我们处理**“引用计数”的相关部分，**无需我们再手动键入**`retain`，`release`和`retainCount`等代码。

## ARC的配置与使用

一个应用程序中可以混合ARC有效或无效的二进制形式，换而言之，我们可以在同一程序的不同模块中分别设置是否支持ARC，另外还可以在同一模块的不同文件中设置是否支持ARC。

修改工程中文件是否支持ARC，可以通过Targets->build phases->Compile Sources修改文件的**compiler Flags**实现，如下：

* 在ARC工程中禁用文件使用ARC
  * 指定该文件的编辑器属性为：-fno-objc-arc
* 在非ARC工程中启动文件支持ARC
  * 确保使用clang（LLVM编译器）3.0或以上版本
  * 指定该文件的编辑器属性为：-fobjc-arc

需要注意的是，不管在不在ARC下，类对象都有强引用和弱引用之分，**且Xcode 4.2以上版本默认设定为对所有的文件ARC有效**。

## 所有权修饰符

### `__storng`修饰符

`__strong`是id类型和对象类型默认的所有权修饰符，表示对对象的强引用。持有强引用的变量在超出其作用域时被废弃，随着强引用的失效，引用的对象会随之释放。代码示例如下：

```objective-c
{
  /*
   *自己生成并持有对象
   */
  id obj = [[NSObject alloc]init];
  
  /*
   *其中obj变量实际上被附加了__strong修饰符
   *等同于下面的语句
   */
  
  //id __strong obj = [[NSObject alloc]init];
}

	/*
 	 *变量obj超出其作用域，强引用实效
 	 *自动释放自己所持有的对象
 	 *引用计数为0，对象的所有者不存在，废弃该对象
 	 */
```

附有`__strong`修饰符的变量不仅可以如上面的例子一般取得自己生成并持有的对象，也可以取得非自己生成并持有的对象。

```objective-c
{
	id __strong obj = [NSMutableArray array];
}
```



当然，附有`__strong`修饰符的变量之间也可以相互赋值。

```objective-c
{
	id __strong obj1 = [[NSObject alloc]init];	//对象1
	id __strong obj2 = [[NSObject alloc]init];	//对象2
	id __strong obj3 = nil;

	obj1 = obj2;
  /*
   *对象2的引用计数加1，变为2
   *对象1的引用计数减一，变为0
   *对象1的所有者不存在，对象1被废弃
   */
  obj3 = obj1;
  /*
   *对象2的引用计数加1，变为3
   */
  obj2 = nil;
  /*
   *对象2的引用计数减1，变为2
   */
  obj1 = nil;
  /*
   *对象2的引用计数减1，变为1
   */
  obj3 = nil;
  /*
   *对象2的引用计数减1，变为0
   *对象的所有者不存在，对象2被废弃
   */
}
```

通过上面，我们可以看到，附有`__strong`修饰符的变量主要通过以下两种方式管理释放所持有对象的时机。

* 通过作用域管理，作用域结束则自动释放当前持有的对象
* 通过赋值管理，赋值当前变量的值为别的对象的指针或nil，使得变量释放当前持有的对象

#### 四条原则

回忆一下我们在上一篇说到的引用计数的**四条原则**

1. 自己生成的对象，自己所持有
2. 非自己生成的对象，自己也能持有
3. 不再需要自己持有的对象时释放
4. 非自己持有的对象无法释放

可以发现，附有`__strong`修饰符的变量完全符合上面这四条原则。前两条原则在上面已经举例说明了，原则3“不再需要自己持有的对象时释放”通过作用域和附有相同修饰符的变量间赋值实现，而原则4，由于不再需要手动键入`release`，因此这一原则也得以符合。ARC的魅力正在于此，在简化了引用计数管理代码（不必手动键入`retain`和`release`等）的同时，也让开发者更容易编写出符合内存管理规范的代码。

需要注意的是，`__strong`修饰符同后面要讲的`__weak`修饰符和`__autoreleasing`修饰符一样，可以保证附有这些修饰符的变量在**声明时初始化**为`nil`。

### `__weak`修饰符

从上面的论述可以发现，通过`__strong`修饰符已经基本实现了引用计数管理功能，但在管理对象引用的过程中仍存在着一些常见的问题，比如循环引用。

> 循环引用：一般指两个及以上对象相互引用（持有对方的强引用），形成引用环，导致所有对象都无法被废弃的现象。单个强引用指向自身称为自引用，也会导致引用对象无法被废弃。值得注意的是，循环引用和自引用都容易引起内存泄漏，所以应尽量避免循环引用或自引用的出现。

```objective-c
//对象的声明
@interface Test：NSObject
{
  id __strong obj_;
}
//对象的实现
- (void) setObject:(id __strong)obj;
@end
  
@inplementation Test
- (id) init
{
  self = [super init];
  return self;
}
- (void) setObject:(id __strong)obj
{
  obj_ = obj;
}

//主函数
main()
{
  id test = [[Test alloc] init];	//test持有对象A的强引用，A引用计数为1
  id test1 = [[Test alloc] init];	//test1持有对象B的强引用，B引用计数为1
  [test setObject: test1];
  /*
   *对象A中的obj_变量持有对象B的强引用，B引用计数为2
   */
  [test1 setObject: test];
  /*
   *对象B中的obj_变量持有对象A的强引用，A引用计数为2
   */
}
/*
 *test和test1变量的作用域结束，持有的对象A和对象B被释放
 *此时对象A和对象B的引用计数均为1
 *由于对象A和对象B仍互相持有对方的强引用，且等待对方释放对本方的强引用，形成循环引用关系
 *对象A和对象B无法被废弃，导致内存泄漏
 */
```

为了解决循环引用问题，Objective-C引入了`__weak`修饰符。附有`__weak`修饰符的变量指向对象时，持有对对象的**弱引用**，而不是强引用，**即指向对象，却不持有对象，引用计数不加1**。若对象被废弃，则指向该对象的弱引用都将自动失效并处于被赋值nil的状态（这部分判断逻辑包括在`release`方法的底层实现里，有空的同学可以搜索来看下）。

那么`__weak`修饰符又是如何通过弱引用解决循环引用问题的呢。

事实上，对于会出现循环引用的两个对象A、B，我们可以假设对象A持有对象B的弱引用，而对象B（成员）持有对象A的强引用。这样，在被持有弱引用的对象B的所有强引用都被释放后，对象B被废弃，因此，对象B持有的对象A被释放，对象A的引用计数减1，对象A也被废弃。简单地说，就是**谁持有弱引用，谁后释放**。

弱引用的使用示例如下：

```objective-c
{
  id __strong obj = [[NSObject alloc] init];
  /*
   *obj变量指向并持有对象，对象引用计数加1 ，目前为1
   */
  
  id __weak obj1 = obj;
  /*
   *obj1变量指向但不持有对象，对象引用计数不变，仍为1
   */
}
	/*
	 *因为obj变量超出作用域，强引用失效
	 *所以自动释放自己持有的对象
	 *对象的引用计数减1，值为0，因此废弃对象
	 */
```

但是，使用弱引用的时候需要注意：声明的弱引用变量不能用下面这种方法直接初始化(事实上编译器也会对这种情况给出警告)

```objective-c
{
  id __weak obj = [[NSObject alloc] init];
  /*
   *因为带weak修饰符的变量只指向对象。却不持有对象
   *所以在执行完这条语句后，新生成的对象由于没有强引用，引用计数为0，被废弃
   *带weak修饰符的变量被置为nil
   */
}
```

#### 使用场景

为了更好的理解`__weak`修饰符，我们来看下带`__weak`修饰符的变量的使用场景

* 对于控件，为了保证及时释放控件对象和避免，我们一般参考这样的规则：从storyboard拖下来的对象使用`__weak`修饰，自定义对象用`__strong`修饰。具体可以参考知乎的[为什么 iOS 开发中，控件一般为 weak 而不是 strong？](https://www.zhihu.com/question/29927614?sort=created)问题中网友**高大大编译没有通过**的答案。
* 对于`delegate`，为了避免循环引用，我们一般提倡把`delegate`声明为带`__weak`修饰符的变量。常见的例子譬如`UITableView`的`delegate`和`datasource`属性，首先`Controller`通过`__strong`指针（`self.view`）持有并指向`UITableView`类型变量，然后UITableView变量的`delegate`属性通过`__weak`指针指向`Controller`。

最后，需要注意的是，`__weak`修饰符只能用于iOS5以上及OS X Lion以上版本的应用程序，在iOS4以及OS X Snow Leopard的应用程序中可使用`__unsafe_unretained`修饰符来代替。

**PS：**在`Swift`中除了弱引用外，还引入了无主引用的概念，用以在一个属性的值允许为`nil`，而另一个属性的值不允许为`nil`的场景中，解决循环引用问题。

### `__unsafe_unretained`修饰符

正如名字带有的unsafe部分所示，这是一个不安全的所有权修饰符。需要注意的是，**尽管ARC式的内存管理是编译器的工作，但附有`__unsafe_unretained`修饰符的变量不属于编译器的内存管理对象。**

附有`__unsafe_unretained`修饰符的变量同附有`__weak`修饰符的变量一样，**指向而不持有对象**，所以如果使用下面的方式声明并初始化一个附有`__unsafe_unretained`修饰符的变量，编译器同样会给出警告

```objective-c
id __unsafe_unretained obj = [[NSObject alloc] init];
```

正确的使用方式如下

```objective-c
{
  id __strong obj = [[NSObject alloc] init];
  id __unsafe_unretained obj1 = obj;
}
```

但`__weak`修饰符和`__unsafe_unretained`修饰符并不是完全一样的，以上面的代码为例子

1. 附有`__unsafe_unretained`修饰符的obj1变量指向了`NSObject`对象，但**既不持有对象的强引用，也不持有对象的弱引用**。

2. 附有`__unsafe_unretained`修饰符的obj1变量指向的对象被废弃后，变量并不会被置为nil，所以可能会出现野指针问题（由于变量指向的对象被废弃，如果继续访问该变量指向的地址，程序崩溃）。

3. 附有`__unsafe_unretained`修饰符的变量在被声明时并不会被初始化为`nil`。如果像下面这样声明`obj1`变量，我们会得到一个未初始化的警告，为了避免警告，我们一般在声明附有`__unsafe_unretained`修饰符变量时手动初始化该变量的值为`nil`，如`obj2`变量。

   ```objective-c
     id __unsafe_unretained obj1;
     id __unsafe_unretained obj2 = nil;
   ```

#### 使用场景

下面我们来看下`__unsafe_unretained`修饰符的使用场景

* 在iOS4以及OS X Snow Leopard的应用程序中，必须使用`__unsafe_unretained`修饰符替代`__weak`修饰符。
*  赋值给附有`__unsafe_unretained`修饰符变量的对象在通过该变量使用时，如果没有对象不存在，则应用崩溃。（不是很懂，错误处理的场景？）

需要注意的是，在swift中已经去掉了这一修饰符，场景2中可使用swift中的特性`!`代替。

### `__autoreleasing`修饰符

ARC有效时，我们不能继续使用`autorelease`方法和`NSAutoreleasePool`类，但可以通过别的方法实现相同的效果。

- ARC有效时，将对象赋值给附有`__autoreleasing`修饰符的变量等价于在ARC无效时调用对象的`autorelease`方法，即对象被注册到autoreleasepool中。
- ARC有效时，可以使用`@autoreleasepool`块来替代`NSAutoreleasePool`类对象的生成、持有以及废弃

但是，显式地附加`__autoreleasing`修饰符同显式地附加`__strong`修饰符一样罕见，因为很多时候，我们都是非显式地使用`__autoreleasing`修饰符。

#### 使用场景

非显式地使用`__autoreleasing`修饰符的主要应用场景如下

- 取得非自己生成并持有的对象

- 弱引用

- 指向id指针的指针


##### 取得非自己生成并持有的对象 

  因为编译器会检查方法名是否为alloc/new/copy/mutableCopy开头，不是的话自动将返回值的对象注册到autoreleasepool。需要注意的是，init方法返回的对象不注册到autoreleasepool。

  ```objective-c
  @autoreleasepool{
  	id _strong obj = [NSMutableArray array];
  	/**
  	 *变量obj为强引用，所以自己持有对象
  	 *并且，该对象由编译器判断其方法名后
  	 *自动注册到autoreleasepool
  	 */
  }
  /**
   *obj变量超出作用域后，强引用失效，释放对象
   *另外，由于超出autoreleasepool块范围，autoreleasepool块结束
   *所以注册到autoreleasepool上的对象被释放，上述对象的引用计数变为0，对象被废弃
   */
  
  + (id) array
{
    id obj = [[NSMutableArray alloc] init];
  /*
     *obj默认附有__strong修饰符，持有并指向对象，对象引用计数为1
     */
    return obj;
  }
  	/*
  	 *obj变量超出作用域，释放对象
  	 *对象作为函数的返回值，编译器会自动将其注册到autoreleasepool上
  	 *确保在obj指向对象前，对象不会被释放
  	 */
  ```

像上面的`obj`对象就是自动注册到了autoreleasepool中。

  ##### 弱引用

虽然`__weak`修饰符是为了避免循环引用而使用的，但在访问附有`__weak`修饰符的变量指向的对象时，实际上必定要访问注册到`autoreleasepool`的对象。

  ```objective-c
  id __weak obj1 = obj0;
  NSLog(@"class=%@",[obj1 class]);
  ```

等同于以下代码

  ```objective-c
  id __weak obj1 = obj0;
  id __autoreleasing tmp = obj1;
  NSLog(@"class=%@",[tmp class]);
  ```

可以看到，访问附有`__weak`的变量指向的对象时，必须访问注册到`autoreleasepool`的对象。因为`__weak`修饰符只持有对象的弱引用，而**在访问引用对象的过程中，该对象有可能被废弃**，而如果把要访问的对象注册到`autoreleasepool`中，那么在`@autoreleasepool`块结束之前都能确保该对象存在。

但是，我们会想到，如果只是访问附有`__weak`修饰符的变量自身呢？

  ```objective-c
  id __weak obj1 = obj0;
  NSLog(@"adress=%p",obj1);
  ```

把`autoreleasepool`打印出来可以看到，这时，变量指向的对象并不会注册到`autoreleasepool`中。

因此我们可以得出这样一个结论：**访问附有`__weak`修饰符指向的对象时，该对象必定会注册到`autoreleasepool`中，但若只是访问附有`__weak`修饰符的变量自身，变量指向的对象并不会注册到`autoreleasepool`中**

  ##### 指向`id`指针的指针

首先，对于`id`指针，譬如`id obj`，默认实现其实是`id __strong obj`。但对于`id`类型的指针或对象的指针，譬如`id *obj`,其默认实现却是`id __autoreleasing *obj`。

最常见的应用场景便是错误传递，在Cocoa和Cocoa Touch的类中，有些方法不是直接抛出错误，而是把错误对象赋给方法的参数指针。

  ```objective-c
  - (BOOL) performOperationWithError:(NSError **)error;
  ```

参数中对象的指针隐式使用了`__autoreleasing`修饰符，即上述声明的方法的实现如下

  ```objective-c
  - (BOOL) performOperationWithError:(NSError * __autoreleasing *)error{
  	/*
  	 *错误发生
  	 */
    *error = [[NSError alloc] initWithDomain: MyAppDomain code: errorCode userInfo: nil];
    return No;
  }
  ```

  我们可以发现，`error`是带有`__autoreleasing`修饰符的对象指针，所以在方法内部将`NSError`对象赋值给`error`时，会把对象注册到`autoreleasepool`中。思考一下，如果隐式表示的不是`__autoreleasing`，而是`__strong`，我们会得到以下实现，这会有什么问题呢？

  ```objective-c
  - (BOOL) performOperationWithError:(NSError * __strong *)error{
  	/*
  	 *错误发生
  	 */
    *error = [[NSError alloc] initWithDomain: MyAppDomain code: errorCode userInfo: nil];
    return No;
  }
  ```

对象作为参数的传递时，传递的是值（对象副本），所以在方法内部对传进来的对象所做的修改无法同步到外部。对象指针作为参数的传递时，传递的是地址（指向对象的变量地址）。通过传递进来的对象指针，我们可以对指向的对象进行调用/修改，而这些修改可以同步到作为参数传递的方法外部对象上。从这一点上来看，使用`__strong`修饰符和使用`__autoreleasing`修饰符可以得到相同的效果。

但是如上面代码这种情况，在方法内部生成对象并将该对象赋值给参数变量（对象指针）时，由于参数变量是方法内部的局部变量，所以使用附有`__strong`修饰符的参数变量可能面临对象在方法结束时被废弃的问题，而使用附有`__autoreleasing`修饰符的参数变量则会将对象注册到`autoreleasepool`中，这一场景同通过除`alloc/new/copy/mutableCopy`外其它方法的返回值取得对象一样。

### 总结

从上面可以看到，每个所有权修饰符都有它们独有的使用场景。`__strong`修饰符是自动引用计数的基础，完美遵守了**四个原则**；`__weak`修饰符主要解决了引用计数管理过程中出现的**循环引用/自引用**问题，避免了内存泄漏的情况出现；`__unsafe_unretained`修饰符主要在iOS4以及OS X Snow Leopard的应用程序中**替代`__weak`修饰符**使用，主要解决循环引用/自引用问题；`__autlreleasing`修饰符主要替代了对象的`autorelease`方法，作用是**把对象注册到`autoreleasepool`中**，避免了对象在使用前被废弃的情况发生，同样也是引用计数实现中不可缺少的一环。

尝试使用思维导图总结了一下上面说的东西

![image-20191006214959693](https://tva1.sinaimg.cn/large/006y8mN6ly1g7otizk6bjj31510gs0xp.jpg)