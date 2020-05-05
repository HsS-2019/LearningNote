# ARC的思考

## ARC的规则

所有权修饰符

-  strong
- weak

weak提供对对象的弱引用，即指向对象，却不持有对象。若对象被废弃，则指向该对象的弱引用都将自动失效并处于nil被赋值的状态。

- autorelease

替代autorelease方法，对象赋值给带有autorelease修饰符的变量等价于ARC无效时调用对象的autorelease方法，即该变量并不持有对象

但是。。即使不使用autorelease修饰变量，同样可以达到同样的效果。

- 取得非自己生成并持有的对象时，因为编译器会检查方法名是否为alloc/new/copy/mutableCopy开头，不是的话自动将返回值的对象注册到autoreleasepool。需要注意的是，init方法返回值的对象不注册到autoreleasepool。

弱引用实质上有用到autorelease

id指针的原理也是借助了autorelease

autoreleasepool块在ARC有效、ARC无效和swift中的使用

- unsafe_unretained

不安全的所有权修饰符，使用该修饰符的变量不属于编译器的内存管理对象。对象被废弃后，不会自动置nil，跟swift中的强制绑定`!`原理类似？为什么需要使用这个修饰符呢？



为什么需要所有权修饰符？

为什么修饰符是这四个呢？

#### 属性声明的属性和对应的所有权修饰符

注意copy，assign的使用