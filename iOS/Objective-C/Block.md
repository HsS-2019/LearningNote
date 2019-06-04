# Block
即带有自动变量值的匿名函数

### 1.匿名函数

### 2.自动变量
Block表达式可截获表达式范围上方的变量，被截获的变量为自动变量。

#### 2.1 对于值类型

##### 无`__block`修饰符
Block捕获并保存的只是该变量的的瞬间值。因为保存了该变量的瞬间值，所以在Block表达式后修改该变量的值，并不会影响到Block执行该变量的值。如下：

```
    int val = 0;
    
    printf("1:addres = %p\n",&val);
    val = 10;
    void (^one)(void) = ^{
        printf("3:val = %d\n",val);
        printf("4:addres = %p\n",&val);

    };
    
    printf("2:addres = %p\n",&val);
    val = 20;
    one();
    
    printf("5:val = %d\n",val);
    printf("6:addres = %p\n",&val);

/*
1:addres = 0x7ffeefbff58c
2:addres = 0x7ffeefbff58c
3:val = 10
4:addres = 0x1006002e0
5:val = 20
6:addres = 0x7ffeefbff58c
*/

```
从结果上可以看到，对于整型变量，Block捕获该变量时，对该变量做了一次深拷贝，值为捕获时该整型变量的值。所以Block表达式中同名变量的地址与该整型变量的地址不同，导致在后续修改该整型变量，对Block中的同名变量无影响；Block执行完后，同名变量的值也无法同步给该整型变量。

Block中同名变量的值无法修改，这一点的原理暂不清楚。

##### 有`__block`修饰符

默认情况下，Block的值捕获的效果如上。但有些时候，我们想要在Block的表达式中，修改同名变量的值，并在Block执行完后将同名变量的值赋回给在Block语法外声明的自动变量。为了实现这种效果，我们需要在该自动变量上附加`__block`修饰符。如下：

```
    __block int val = 0;
    
    val = 10;
    printf("1:addres = %p\n",&val);
    
    void (^one)(void) = ^{
        printf("3:val = %d\n",val);
        val = 30;
        printf("4:addres = %p\n",&val);
        
    };
    printf("2:addres = %p\n",&val);

    val = 20;
    one();
    printf("5:val = %d\n",val);
    printf("6:addres = %p\n",&val);
    
/*
代码执行结果为：

1:addres = 0x7ffeefbff588
2:addres = 0x100600358
3:val = 20
4:addres = 0x100600358
5:val = 30
6:addres = 0x100600358
*/
```


可以看到，当使用`__block`修饰符修饰自动变量时，同样对该变量进行了深拷贝。

不同于无`__block`修饰符的情况，这里在进行深拷贝后，释放了原变量，并将捕获的同名变量作为原变量使用。所以捕获变量的值，可能在Block未执行前变化。并且，在Block中，同名变量可以被赋值，Block执行完后整型变量的值会发生了同样的变化。

#### 2.2 对于Objective-C对象

##### 无`__block`修饰符
当Objective-C对象作为变量时，若没有`__block`修饰符，Block表达式捕获变量时对该变量进行浅拷贝。所以同名变量和该变量的地址不同，但同样指向该对象的内存地址，并且不能将同名变量指向其它内存空间（同名变量不能被赋值），类似于引用。值得注意的是，同名变量可以修改指向的对象成员变量的值。实践如下：

```
    id man = [[Person alloc]init];
    printf("1: addres = %p\n",&man);
    NSLog(@"2: addres = %@",man);
    
    [man setName:@"james"];
    void (^three)(void) = ^{
        printf("5: addres = %p\n",&man);
        NSLog(@"6: addres = %@",man);
        NSLog(@"7: name = %@", [man name]);
        
        //查看对象的引用计数
        printf("PS: retain count = %ld\n",CFGetRetainCount((__bridge CFTypeRef)(man)));
        
        [man setName:@"jack"];

    };
    printf("3: addres = %p\n",&man);
    NSLog(@"4: addres = %@",man);

    [man setName:@"mary"];
    
    three();
    NSLog(@"8: name = %@",[man name]);
    printf("9: addres = %p\n",&man);
    NSLog(@"10: addres = %@",man);
    
/*
1: addres = 0x7ffeefbff588
2019-06-05 01:08:48.084900+0800 Block[22887:4880642] 2: addres = <Person: 0x100611530>
3: addres = 0x7ffeefbff588
2019-06-05 01:08:48.085046+0800 Block[22887:4880642] 4: addres = <Person: 0x100611530>
5: addres = 0x10064cb40
2019-06-05 01:08:48.085082+0800 Block[22887:4880642] 6: addres = <Person: 0x100611530>
2019-06-05 01:08:48.085143+0800 Block[22887:4880642] 7: name = mary
PS: retain count = 3
2019-06-05 01:08:48.085178+0800 Block[22887:4880642] 8: name = jack
9: addres = 0x7ffeefbff588
2019-06-05 01:08:48.085278+0800 Block[22887:4880642] 10: addres = <Person: 0x100611530>
*/
```
**疑问1：**可以看到，Block中显示对象的引用计数为3次，第三个引用计数是怎么出现的？

##### 有`__block`修饰符
我们可以看一下，当Objective-C对象加了`__block`修饰符后，跟上面有什么不同。

```
   __block id man = [[Person alloc]init];
    printf("1: addres = %p\n",&man);
    NSLog(@"2: addres = %@",man);
    
    [man setName:@"james"];
    void (^four)(void) = ^{
        printf("5: addres = %p\n",&man);
        NSLog(@"6: addres = %@",man);
        NSLog(@"7: name = %@", [man name]);
        
        //查看对象的引用计数
        printf("PS: retain count = %ld\n",CFGetRetainCount((__bridge CFTypeRef)(man)));
        
        man = [[Person alloc]init];
        [man setName:@"jack"];
        
        printf("PS: retain count = %ld\n",CFGetRetainCount((__bridge CFTypeRef)(man)));
    };
    printf("3: addres = %p\n",&man);
    NSLog(@"4: addres = %@",man);
    
    [man setName:@"mary"];
    
    four();
    NSLog(@"8: name = %@",[man name]);
    printf("9: addres = %p\n",&man);
    NSLog(@"10: addres = %@",man);
    
/*
结果如下：
1: addres = 0x7ffeefbff588
2019-06-05 01:08:48.085337+0800 Block[22887:4880642] 2: addres = <Person: 0x10051ee20>
3: addres = 0x100502238
2019-06-05 01:08:48.085376+0800 Block[22887:4880642] 4: addres = <Person: 0x10051ee20>
5: addres = 0x100502238
2019-06-05 01:08:48.085400+0800 Block[22887:4880642] 6: addres = <Person: 0x10051ee20>
2019-06-05 01:08:48.085414+0800 Block[22887:4880642] 7: name = mary
PS: retain count = 1
PS: retain count = 1
2019-06-05 01:08:48.085431+0800 Block[22887:4880642] 8: name = jack
9: addres = 0x100502238
2019-06-05 01:08:48.085451+0800 Block[22887:4880642] 10: addres = <Person: 0x1005010f0>
*/
```
从上面的结果可以看到，对于有`__block`修饰符的变量：  

- Block表达式在捕获变量时，对变量进行了浅拷贝，并修改了原变量的地址（非对象地址）
- 原变量不再持有对象，同名变量持有对象，所以对象的引用计数为1
- 在Block中，可以修改同名变量指向的对象的成员变量的值
- 在Block中，也可以修改同名变量指向别的对象地址，这时，原对象的引用计数为0，原对象被释放，新对象的引用计数为1
- 综上，Block表达式捕获的同名变量类似于对象指针


### 3.block的声明

```
int multiplier = 7;
int (^myBlock)(int) = ^(int num) {
    return num * multiplier;
}

```
