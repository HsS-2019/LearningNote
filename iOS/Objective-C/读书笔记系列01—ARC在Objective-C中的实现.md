# 读书笔记系列01—Objective-C中的内存管理（1）

我们都知道，为了方便编译器进行内存管理，苹果在Objective-C和后来推出的Swift中都采用了自动引用计数机制（ARC）。那么什么是内存管理，引用计数又是什么？本文主要从Objective-C的引用计数实现出发，结合一些资料，尝试思考当初开发者是怎么设计并实现这一机制的。

> ARC，自动引用计数（Automatic Reference Counting）的缩写，是指在内存管理中对引用采取自动计数的技术。值得一提的是，为了方便管理内存，C++ 11也引进了智能指针的概念，而智能指针的原理正是自动引用计数。

## 什么是内存布局

在了解什么是引用计数之前，我们先来回顾一下一些基础知识。

程序的源代码经过下面的四个阶段

- 预处理
- 编译
- 汇编
- 链接

可以得到可被计算机/智能设备识别并运行的可执行文件。

而计算机或智能设备运行程序的过程，实际上也可以简单地分为以下几步

- 将可执行文件（预先编译好的指令和数据集合）装载进计算机的一块独立虚拟地址空间中
- 创建并启动程序主进程
- 按开发者给程序设计的逻辑运行，一般包括以下操作：创建各种类类型和值类型常量/变量，读取和修改数据（包括本地和网络请求）、渲染界面、软件交互...

需要注意的是，虚拟地址空间在逻辑上是连续分布的，即逻辑地址是连续的，但**连续的逻辑地址对应的却是离散的物理地址**。另外，关于上面的编译链接和程序装载知识，推荐感兴趣的同学阅读一下[程序员的自我修养 —链接、装载与库]()，这本书比较详细地解答了我在上面所说的两个过程，按照计划我应该也会写一下这本书的读书笔记，如果有时间的话🤣。

本文中，我们需要关注的正是上面所说的每个程序都拥有的独立的虚拟地址空间，这个虚拟地址空间的大小由计算机的硬件平台决定，比如32位的硬件平台决定了虚拟地址空间的地址为0到2^32 -1。我们的程序装载在这个地址空间上，按照块来划分，块的分布正是程序的内存布局，如下图

![Objective-C中的内存布局](https://img-blog.csdn.net/20160605161814358)

在iOS系统中，程序启动后，栈区，全局区和代码区的大小都是固定的了。栈区大小一般为几M，主要用来存储函数参数和非动态申请的大部分局部变量等；代码区存储程序源码，类对象和字面值；全局区存储全局变量/常量，和类变量等。但是堆区的大小是不固定的，由系统分配，程序共享，一般用来存储我们动态申请内存创建的对象等；

为什么要学习内存管理呢，一方面是因为计算机或智能设备的内存都是有限的，每个程序一般都会申请大量对象，如果能**避免内存泄漏**或者在对象不再被使用的情况下**及时释放对象内存**，可以优化程序的内存占用。为什么很多苹果应用都能做到如丝般顺滑，在本文后面提到的用于及时释放对象内存的autoreleasePool起了很大一部分作用。另一方面是因为堆区是时刻变化的，如果我们使用了一个指针指向僵尸对象（一个已被释放内存的对象）并访问已被释放的内存，会造成crash（野指针报错导致），也就是软件崩溃。

## 认识MRC和ARC

我们再来了解一下MRC，毕竟在早期的Objective-C程序中，我们都是使用MRC来手动管理对象的引用计数。

>MRC，在ARC出现之前，Objective-C早期使用的是一种叫做MRC（Mannul Reference Counting）的手动管理内存的机制。通过键入上面所提到的retain、release、autorelease、retainCount等方法，开发者们能够手动控制对象引用计数的加1、减1等操作。

内存管理是一种繁琐的工作，即使引入了引用计数这一简洁的概念，我们仍要添加许多管理引用计数的代码，以确保对象在不被使用的情况下及时被释放，避免内存泄漏。

那么有没有更好的办法呢？毕竟要是没严格按照如下规范编写，漏了一个release都会觉得头大。

1. 谁创建的谁release
2. 谁retain谁就release

作为开发者，对于这种麻烦的工作，我们应该想办法避免，把工作交给机器自动完成，进而达到解放双手，将更多精力放到思考（<del> 摸鱼 </del>）上面。

## 了解引用计数

假设有一个只有一盏灯的教室，为了保证教室里有人的时候，灯必须开着照明，因此要求班上来的最早的同学需要开灯，班上走的最晚的同学需要关灯。而为了判断教室里是否还有同学，这里引入了引用计数的概念来计算“教室里还有多少同学”。

- 第一个同学进入教室，“教室里的同学数量”加1，数值从0变为1，因此需要开灯
- 之后，每当有同学进入教室，“教室里的同学数量”就加1
- 每当有同学离开教室，“教室里的同学数量”就减1
- 当最后一个同学离开教室后，“教室里的同学数量”变为0，因此需要关灯

在这个例子里，我们简单了解了引用计数的工作原理。回到Objective-C中，类比一下，可以发现其实对象就相当于教室里的灯，而教室里的同学就相当于持有该对象的实例。而在Objective-C中，可以将工作原理抽象成一些系统行为，我们主要是通过以下四个对对象的操作实现内存管理。

- 生成并持有对象
- 持有对象
- 释放对象
- 废弃对象

这里可以通过下面的一张表，更好地理解不同操作所代表的含义。

|对象操作		|对象的状态						    |对应例子        |
|:-----------	|:-----------------------------|:-------------|
|生成并持有对象	|申请内存，对象的引用计数从0变为1   |开灯           |
|持有对象 		|对象的引用计数加1				    |教室里同学数量加1|
|释放对象		|对象的引用计数减1				    |教室里同学数量减1|
|废弃对象		|对象的引用计数变为0时，销毁对象    |关灯           |

## Objective-C中的引用计数

在上文中，我们了解到，Objective-C主要通过四个对对象的操作来实现引用计数式内存管理。可是对于这些操作，我们并不确定应该按照怎样的顺序来使用；或者说怎么教会计算机，什么时候应该执行哪个操作，从而得到一个健壮性良好的系统/机制。这需要更具体的设计，也是我们所需要思考的方向。

为了后面的使用方便，在这里列下Objective-C中这四个对象操作的对应方法

|对象操作		|对应的Objective-C方法		     |
|:-----------	|:------------------------------|
|生成并持有对象	|alloc/new/copy/mutableCopy等方法|
|持有对象		|retain方法					     |
|释放对象		|release方法					     |
|废弃对象		|dealloc方法					     |

需要注意的是，这些内存管理方法都是包含在Cocoa框架的Foundation类库中，实际上不包括在Objective-C这门语言上。而本文中的对象，如无特别说明，一般指的是`NSObject`类的对象或继承自`NSObject`类的子类对象。

### 设计中的四条规则

顺着上面的方向思考，我们可以得到四条比较明显的规则。

- 自己生成的对象，自己所持有
- 非自己生成的对象，自己也能持有
- 不再需要自己持有的对象时释放
- 非自己持有的对象无法释放

#### 1. 自己生成的对象，自己所持有

在Objective-C中，使用以下名称开头的方法意味着自己生成的对象只有自己所持有

- alloc
- new
- copy
- mutableCopy

使用上面的四个方法其实都能自己生成并持有对象，但这四个方法的用法并不太一样。在`NSObject`类中，我们常通过`[[NSObject alloc] init]`的方式声明并初始化一个`NSObject`对象，这与`[NSObject new]`方法的效果一致，但`alloc`方法只是创建了对象，并把指向生成并持有对象的指针赋给对应的变量，而不能对对象进行初始化。

`copy`方法和`mutableCopy`方法都会生成并持有对象的副本，用这些方法生成的对象，虽然是对象的副本，但同样属于自己生成并持有对象。不同的是`copy`方法生成的是不可变对象，而`mutableCopy`方法生成的是可变对象。

这里需要注意的是，`copy`方法和`mutableCopy`方法生成并持有对象的副本指的是都生成了新对象，但对于不可变对象调用`copy`方法，得到的新对象和原对象是指向同一地址的，而对容器类对象如NSMutableArray调用`mutableCopy`方法会出现单层深拷贝的情况。所以这两个函数其实挺好玩的，根据不同的情况可能会得到不同的结果。对这里感兴趣的同学可以参考[iOS开发之copy和mutableCopy](https://juejin.im/entry/57b15244a633bd00570955be)和[iOS深浅拷贝](https://juejin.im/entry/58b1065fb123db0052c2e0a9)并动手实践一下，做为知识的扩展。补充说明一下，两篇文章在不可变对象调用`copy`方法得到的结果这里出现了一些分歧。

根据上述“使用以下名称开头的方法名”，下列名称代表的方法也意味着自己生成并持有对象

- allocMyObject
- newThatObject
- copyThis
- mutableCopyYourObject

但是对于下列名称，即使用alloc/new/copy/mutableCopy名称开头，也并不属于同一类方法

- allocate
- newer
- copying
- mutableCopyed

当对象被声明出来时（申请内存），因为一开始就把指向生成并持有对象的指针赋给了一个实例变量/常量，相当于第一个同学进入了教室，所以该对象的引用计数从0变为1。

```
/*
 *OC对象的声明和初始化
 */
id obj = [[NSObject alloc] init]
```

#### 2. 非自己生成的对象，自己也能持有

对于不是自己生成并持有的对象，对应类型的变量也可以指向并持有该对象，该对象的引用计数会继续+1，此时该对象的引用计数变为2。

```
/*
 * 取得非自己生成的对象
 * 此时instance仍未持有该对象
 */
id instance = obj

/*
 *执行完retain方法后
 *instance持有obj指向的对象
 */
[instance retain]
```

#### 3. 不再需要自己持有的对象时释放

对于自己持有的对象，一旦不再需要，持有者有义务释放该对象，释放后，该对象的引用计数也会-1，此时该对象的引用计数变为0。

```
/*
 *instance不再需要持有该对象，释放对象
 */
 [instance release]
```

其实还可以通过另外一种方式释放对象，这种方式就是调用`autorelease`方法将生成对象注册到autoreleasePool，待到pool结束时pool自动调用对象的`release`方法释放已注册的对象。

>autoreleasePool，自动释放池，

下面我们来看下autorelease的具体使用。

```
//假设这是NSObject中的object实例方法
- (id) object
{
	id autoObj = [[NSObject alloc] init];

	/*
	 *autoObj生成并持有对象
	 */
	 
	[autoObj autorelease];
		 
	/*
	 *将autoObj持有的对象注册到当前的autoreleasePool上
	 *注册完成后
	 *autoObj仍能取得对象
	 *但不再持有该对象
	 */
	  
	return autoObj;
}
```

接下来看下怎么使用已注册到autorelease中的实例对象。

```
//普通函数
- (Void) test{

	id obj1 = [[NSObject alloc] init];
	
	/*
	 *obj1生成并持有对象
	 */
	 
	id obj2 = [obj1 object];
	
	/*
	 *取得新对象，但obj2并不持有对象
	 *新对象并非obj1所持有的对象
	 */
	
    [obj2 retain];
	
	/*
	 *obj2持有对象
	 */
 
	...
	 
    [obj2 release];
	 
	/*
	 *obj2释放对象
	 *但被释放的对象此时仍未被dealloc
	 */
}
```
等到当前autoreleasePool结束时，pool会为注册在上面的所有对象调用release函数。

上面仅仅是简单地说了一下autoreleasePool的使用，但事实上autoreleasePool是一个很有用的东西，在优化内存和理解iOS系统部分机制上都能起到很好的帮助。由于篇幅有限，这里就不展开说了，感兴趣的同学可自行搜索学习，后面有空的话，我也会另外写一篇总结一下autoreleasePool和runloop的知识。

#### 4. 无法释放非自己持有的对象

当持有者已经释放了自己持有的对象时，该持有者不可再次调用`release`二次释放同一对象

```
 /*
  *当不再需要使用obj操作该对象时
  *obj也需要释放对象
  */
  
 [obj release];

/*
 *对象已释放
 */
 
 [obj release];
 
/*
 *释放之后再次释放已非自己持有的对象
 *应用程序会出现崩溃（crash）
 */
```

### 回收对象内存
最后当对象的引用计数变为0时，系统会调用对象的dealloc函数，销毁对象，回收对象内存。

```
/*
 *在规则3的示例中释放了对象之后
 *该对象的引用计数已经变为0
 *系统调用dealloc方法废弃对象，回收对象内存
 *开发者可以重写该方法，但不能手动调用
 */
```

### 引用计数的实现

假如这是在设计一个系统，通过上文的讨论，我们已经将抽象出来的系统行为和系统规则写出来了，系统行为就是“对对象的四个操作”，而系统规则就是“四个规则”，但是我们似乎还缺了点什么。细想一下，对于引用计数系统，有了系统行为和规则，怎么能缺少其中的关键数据“引用计数”呢。

我们在上面说到，内存管理的引用计数机制其实就是通过管理对象的引用计数，进而管理对象内存的释放时间，那么下面这些关于引用计数的问题需要怎么解决呢

1. 每个对象的引用计数应该以什么结构存在，并存储在哪里呢？
2. 引用计数从0到1这个阶段发生了什么？
3. 加1操作和减一操作又是怎么实现的呢？

接下来，我们通过引用计数在GNU框架和Apple的Cocoa框架中的实现，来解决上面的问题。

苹果虽然开源了Core Foundation框架和rumtime部分源码，但是包含NSObject类的Foundation框架却是没有公开的，所以我们很难去了解到NSObject类的内部实现。因此在下面个别部分的实现我们会比较开源框架GNUstep进行说明。

#### 在GNUstep框架中的实现

GNUstep是Cocoa的互换框架，也就是说，GNUstep的源码虽不能说与苹果的Cocoa框架实现完全一致，但从使用者角度来看，两者的行为和实现方式是一样的，或者说是非常相似的。因此了解了GNUstep源码的也就相当于了解了苹果的Cocoa实现。

##### 引用计数的结构和存储

在GNU框架中，我们可以通过以下的简化`alloc`函数代码，了解引用计数的存储

```
//引用计数的数据结构
struct obj_layout{
	NSUInteger retained;
}

//NSObject的分配内存函数
+ (id) alloc{
	int size = sizeof(struct obj_layout) + 对象大小;
	struct obj_layout *p = (struct obj_layout *) calloc(1,size);
	return (id)(p+1);
}
```
引用计数记录了每个对象被引用的次数，因此引用计数应该是作为一个变量，在对象创建的同时被创建出来。像上面的代码中，引用计数和对象的都放在同一内存块中，且引用计数存放在内存块头部。

##### 管理引用计数

 由于引用计数存放在内存块头部，当需要管理对象的引用计数时，可以直接通过指针获取，因此索引的效率更高。我们管理引用计数一般是通过`retain`，`release`，`retainCount`等函数实现，当知道了引用计数是如何存储的，我们便不难知道这些函数的原理。

 ```Objc
 //简化的NSObject的retain实例方法
 - (id) retain{
 	NSIncrementExtraRefCount(self);
 	return self;
 }
 
 NSIncrementExtraRefCount(id anObject){
 	if (((struct obj_layout *) anObject)[-1].retained == UINT_MAX - 1)
 	{
 		//抛出异常
 	}
 	((struct obj_layout *) anObject)[-1].retained
 }
 ```

 `retain`方法通过指针前移，获取对象的引用计数所在地址并进行操作，同理可知`retainCount`和`release`内部实现。不同的是在`release`方法内部，当引用计数减一后变为0时，会调用`dealloc`方法。

#### 苹果的实现

在苹果的Cocoa框架中，通过阅读runtime部分关于引用计数的源码，我们可以发现当对象的引用计数较少，或者是没有弱引用时，苹果使用了对象的isa指针中的`extra_rc`（这一变量在armv7k，x86_64、arm64等架构下的大小均不同。x86_64为8位）存放了部分的引用计数，这与GNUstep的做法类似，不过这一做法仅支持Objective-C 2.0及以上。当`extra_rc`属性溢出，苹果会将`extra_rc`的值减掉一半，并将减掉的值放入SideTable变量中，我们会在后面说明SideTable这一结构体是怎么存储对象引用计数的。

>弱引用，Weak Reference，主要为了解决引用计数机制中，两个对象互相持有导致无法释放成功的循环强引用问题。

##### 存放对象引用的全局变量的声明

对于需要存放在SideTable中的所有对象的引用计数信息，为了方便管理，苹果其实在底层维护了一个StripedMap< SideTable>类型的全局变量SideTableBuf用来存放多张SideTable，通过下面的源码我们可以看到，StripedMap< SideTable>这一全局变量是如何被声明出来的。

```Objc
//NSObject.mm文件

//为了内存对齐，声明一个uint8_t数组类型的全局变量SideTableBuf
alignas(StripedMap<SideTable>) static uint8_t 
    SideTableBuf[sizeof(StripedMap<SideTable>)];

//声明一个StripedMap<SideTable>类型的变量，并存放在SideTableBuf的内存块中
static void SideTableInit() {
    new (SideTableBuf) StripedMap<SideTable>();
}

//将SideTableBuf强转为StripedMap<SideTable>类型并返回
static StripedMap<SideTable>& SideTables() {
    return *reinterpret_cast<StripedMap<SideTable>*>(SideTableBuf);
}
```

通过上面的代码，我们可以看到苹果其实是用一个uint8_t数组类型的全局变量SideTableBuf去存放StripedMap< SideTable>类型的变量，估计是为了内存对齐。但是在获取全局变量使用时，一般使用的是SideTables函数，这个函数将SideTableBuf强转为 StripedMap< SideTable>类型再返回，因此我们可以将SideTableBuf看作是StripedMap< SideTable>类型的全局变量。

##### StripedMap< SideTable>类模板的实现

StripedMap< SideTable>是C++中的类模板类型，我们来了解一下这个类模板的内部是怎样实现的。

```
//objc-private.h文件

template<typename T>
class StripedMap {
#if TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR
    enum { StripeCount = 8 };
#else
    enum { StripeCount = 64 };
#endif

    struct PaddedT {
        T value alignas(CacheLineSize);
    };

    PaddedT array[StripeCount];

    static unsigned int indexForPointer(const void *p) {
        uintptr_t addr = reinterpret_cast<uintptr_t>(p);
        return ((addr >> 4) ^ (addr >> 9)) % StripeCount;
    }

 public:
    T& operator[] (const void *p) { 
        return array[indexForPointer(p)].value; 
    }
    ...
}
```

进到StripedMap的定义中，我们可以发现这里其实声明了一个大小为8或者64的array数组，数组元素的类型为PaddedT，也就是传进来的SideTable。再看下面重载的下标操作符函数，可以知道在StripedMap类型的内部其实是数组形式的散列表，而`indexForPointer`方法就是散列表对应的Hash函数，**传入对象的地址后，根据`indexForPointer`方法得到对象对应SideTable的下标。**

但是奇怪的是，这里的StripedMap类内部的array数组大小最大为64，但是我们在应用程序所创建的对象肯定远远不止64个，那多余的对象的引用计数存到哪里了呢。这个其实从上面的`indexForPointer`的实现可以看到，传入的对象地址在经过右移、异或等操作后对StripeCount取余才得到最后的对应元素下标。所以我们可以推断，**一个对象对应一个SideTable**，因为对象地址经过相同的运算得到的值是一样的；**但是一个SideTable却对应多个对象**，因为不同的对象地址经过相同的运算，得到的值可能是一样的，毕竟这里我们也没有解决哈希冲突。

##### SideTable结构体的实现

为了证实我们的推断，我们来看下SideTable的实现。

```
struct SideTable {
    spinlock_t slock; //操作内部数据的锁，保证线程安全
    RefcountMap refcnts;//哈希表[伪装的对象指针 : retainCoint]
    weak_table_t weak_table;//存放对象弱引用指针的结构体
}

//下面说明了refcnts是DenseMap模板类型的别名
// RefcountMap disguises its pointers because we 
// don't want the table to act as a root for `leaks`.
typedef objc::DenseMap<DisguisedPtr<objc_object>,size_t,true> RefcountMap;
```
从上面可以看到，SideTable结构中维护了三个变量，slock是一个自旋锁，用来保护SideTable的线程安全的，毕竟SideTable存在全局变量中，需要防止多线程造成的数据竞争。refcnts是一个散列表，key为对象伪装成的指针，value为对象对应的引用计数值（64位），这意味着SideTable确实可以存放多个对象的引用计数。weak_table是一个结构体，但是其内部也维护了一个动态数组（用作哈希表），用来存放不同对象的弱引用指针，其实存放对象的弱引用指针用的也是哈希表，可见这个结构是真滴好用。对于SideTable的几个成员变量，和弱引用的相关知识，篇幅有限，这里就不展开说了，后面有空会再写一篇来说下。

了解了对象引用计数在苹果中的存储，我们也就知道了怎么拿到对象的引用计数值并进行操作，也就想到了retainCount，retain，release等方法的大概实现。

#### 两者的对比

通过内存块头部管理引用计数的好处

- 引用计数实现所需代码较少，实现简洁
- 能够统一管理引用计数用内存块与对象用内存块

通过引用计数表管理引用计数的好处

- 分配对象内存时，无需考虑内存块头部
- 引用计数表各记录中存有内存块地址，可从各个记录追溯到各对象的内存块。
- 在利用工具检测内存泄漏时，引用计数表的各记录也有助于检测各对象的持有者是否还存在

尤其是第二点，由于使用引用计数表的情况下，引用计数的内存与对象内存并不在一起，所以在调试时，即使由于出现crash导致对象内存被损坏，但只要引用计数表没被损坏，就能确认各内存块的位置。而引用计数位于内存块的情况下，引用计数可能随着对象内存一块被损坏了。

## 总结

从上面的描述中，我们学习了什么是引用计数，看起来这个东西还挺简单的吧，是的你没看错，好的技术本来就是简洁而又巧妙的（虽然我上面写了挺多，但是它的确挺简单的🤣）。

这是一篇在阅读[《Objective-C 高级编程 ——iOS与OSX多线程和内存管理》]()一书的过程中，尝试思考内存管理到底是什么而产生的读书笔记。要完善这个思考，我估计内存管理系列应该还会写3-4篇，不过后面写的不会再局限于书中的内容，除了ARC的相关使用外，更多的是从源码出发，谈谈Objective-C中的引用计数原理、对象模型、runloop和runtime的其它特性。

第一次写文，叙述之中难免会有所错漏，有需要纠正或者对文中观点有不同意见的，可以直接在留言区讨论。

感谢观看，我们有时间再见👋

### 参考资料

- [程序员的自我修养 —链接、装载与库]()
- [《Objective-C 高级编程 ——iOS与OSX多线程和内存管理》]()
- [runtime源码（objc4-750）](https://opensource.apple.com/source/objc4/objc4-750/)
- [iOS开发之copy和mutableCopy](https://juejin.im/entry/57b15244a633bd00570955be)
- [iOS深浅拷贝](https://juejin.im/entry/58b1065fb123db0052c2e0a9)
- [Objective-C runtime机制(7)——SideTables, SideTable, weak_table, weak_entry_t](https://www.jianshu.com/p/34625a722699)
- [从runtime源码解读oc对象的引用计数原理](https://juejin.im/post/5c85d6cef265da2dd37c533a#heading-4)

