# ARC的思考

实际上ARC仍是采用引用计数管理的原理，但是就像“自动引用计数”这个名字一般，使用ARC意味着编译器会自动帮助我们处理“引用计数”的相关部分，无需我们再手动键入`retain`，`release`和`retainCount`等代码。

### ARC的配置与使用

一个应用程序中可以混合ARC有效或无效的二进制形式，换而言之，我们可以在同一程序的不同模块中分别设置是否支持ARC，另外还可以在同一模块的不同文件中设置是否支持ARC。

修改工程中文件是否支持ARC，可以通过Targets->build phases->Compile Sources修改文件的**compiler Flags**实现，如下：

* 在ARC工程中禁用文件使用ARC
  * 指定该文件的编辑器属性为：-fno-objc-arc
* 在非ARC工程中启动文件支持ARC
  * 确保使用clang（LLVM编译器）3.0或以上版本
  * 指定该文件的编辑器属性为：-fobjc-arc

需要注意的是，不管在不在ARC下，类对象都有强引用和弱引用之分，**且Xcode 4.2以上版本默认设定为对所有的文件ARC有效**。

## ARC的规则

### 所有权修饰符

#### `__storng`修饰符

`__strong`是id类型和对象类型默认的所有权修饰符，表示对对象的强引用，持有强引用的变量在超出其作用域时被废弃，随着强引用的实效，引用的对象会随之释放。代码示例如下：

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

附有`__strong`修饰符的变量不仅可以取得自己生成并持有的对象，也可以取得非自己生成并持有的对象。

```objective-c
{
	id __strong obj = [[NSObject alloc]init];
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

通过上面，我们可以看到，附有`__strong`修饰符的变量不仅可以通过作用域管理对象的所有者，也可以通过赋值管理对象的所有者（引用计数）。

#### 四条原则

回忆一下我们在上一篇说到的引用计数的**四条原则**

1. 自己生成的对象，自己所持有
2. 非自己生成的对象，自己也能持有
3. 不再需要自己持有的对象时释放
4. 非自己持有的对象无法释放

可以发现，附有`__strong`修饰符的变量完美符合上面这四条原则。前两条原则在上面已经举例说明了，原则3“不再需要自己持有的对象时释放”通过作用域和附有相同修饰符的变量间赋值实现，而原则4，由于不再需要手动键入`release`，因此这一原则也满足。ARC的魅力正在于此，在简化了引用计数管理代码（不必手动键入`retain`和`release`等）的同时，也让开发者更容易编写出符合内存管理规范的代码。

需要注意的是，`__strong`修饰符同后面要讲的`__weak`修饰符和`__autoreleasing`修饰符一起，可以保证附有这些修饰符的变量在**声明时初始化**为`nil`。



### `__weak`修饰符

weak提供对对象的弱引用，即指向对象，却不持有对象。若对象被废弃，则指向该对象的弱引用都将自动失效并处于nil被赋值的状态。

- `__autoreleasing`修饰符

替代autorelease方法，对象赋值给带有autorelease修饰符的变量等价于ARC无效时调用对象的autorelease方法，即该变量并不持有对象

但是。。即使不使用autorelease修饰变量，同样可以达到同样的效果。

- 取得非自己生成并持有的对象

- 弱引用

- 指向id指针的指针

  #### 取得非自己生成并持有的对象 

  因为编译器会检查方法名是否为alloc/new/copy/mutableCopy开头，不是的话自动将返回值的对象注册到autoreleasepool。需要注意的是，init方法返回值的对象不注册到autoreleasepool。

  ```objective-c
  @autoreleasepool{
  	id _strong obj = [NSMutableArray array];
  	/**
  	 *变量obj为强引用，所以自己持有对象
  	 *另外，该对象由编译器判断其方法名后
  	 *自动注册到autoreleasepool
  	 *所以这里的对象的引用计数变为2
  	 */
  }
  /**
   *obj变量超出作用域后，强引用失效，释放对象
   *另外，由于超出autoreleasepool块范围，autoreleasepool块结束
   *所以注册到autoreleasepool上的对象被释放，上述对象的引用计数变为0，对象被废弃
   */
  ```

  需要注意的是，这里的自动注册到autoreleasepool上的做法，是为了得到方法返回的对象（非自己生成并持有），对于类似下述这种操作实际上并不会执行自动注册到autoreleasepool，除非将对象赋值给附有`_autoreleasing`修饰符的变量。

  ```objective-c
  	id obj = [[NSObject alloc] init];
  	id obj1 = obj;
  	/**
  	 *这里的obj1由于没有显式指定所有权修饰符
  	 *所以默认附有_strong修饰符
  	 *因此obj1持有该对象，属于强引用
  	 */
  	id _autoreleasing obj2 = obj
      /**
       *这里的obj2显式指定了_autoreleasing修饰符
       *所以这一赋值操作意味着将该对象注册到autoreleasepool
       *obj2指向该对象，却不持有该对象
       */
  ```



#### 弱引用

弱引用实质上有用到autorelease

#### 指向id指针的指针

id指针的原理也是借助了autorelease

autoreleasepool块在ARC有效、ARC无效和swift中的使用

- unsafe_unretained

不安全的所有权修饰符，使用该修饰符的变量不属于编译器的内存管理对象。对象被废弃后，不会自动置nil，跟swift中的强制绑定`!`原理类似？为什么需要使用这个修饰符呢？



为什么需要所有权修饰符？

为什么修饰符是这四个呢？

#### 属性声明的属性和对应的所有权修饰符

注意copy，assign的使用