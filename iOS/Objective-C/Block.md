# Block
即带有自动变量值的匿名函数

### 匿名函数

### 2.自动变量
Block表达式可截获表达式范围上方的变量，被截获的变量为自动变量。

#### 2.1 对于值类型
Block捕获并保存的只是该变量的的瞬间值。因为保存了该变量的瞬间值，所以在Block表达式后修改该变量的值，并不会影响到Block执行该变量的值。如下：

```
int a = 0;

void(^two)(void) = ^{
	printf("a = %d\n" , a);
};

a = 10;
two();

//打印结果为a = 0

```

默认情况下，保存变量的瞬间值后，该瞬间值只能在Block中执行，即不会赋值回Block表达式外对应的变量。另外，在Block中也不能再修改该值。  

要想在Block语法的表达式中将值赋给在Block语法外声明的自动变量，需要在该自动变量上附加`__block`修饰符。如下：

```
     __block int val = 0;
    
    void(^one)(void) = ^{
        printf("1:val = %d\n", val);
        val = 20;
    };
    
    val = 10;
    one();
    printf("2:val = %d\n", val);
    
//打印结果为:
1:val = 10
2:val = 20
```
可以看到，当使用`__block`修饰符修饰自动变量时，捕获的不是瞬间值，而是**变量地址**。

#### 2.2 对于Objective-C对象
当Objective-C对象作为自动变量时，若没有`__block`修饰符，可看做Block表达式中使用的该变量的引用，同样不能直接被赋值，但可以修改内部元素的值。

### block的声明

```
int multiplier = 7;
int (^myBlock)(int) = ^(int num) {
    return num * multiplier;
}

```
