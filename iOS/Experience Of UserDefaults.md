# UserDefault在Swift中的实践

文章翻译自Vadim Bulavin的[The Advanced Guide to UserDefaults in Swift](https://www.vadimbulavin.com/advanced-guide-to-userdefaults-in-swift/)



在人们的记忆中，`UserDefaults`很早就已经存在于iOS SDK。Swift语言发展迅速，为游戏带来了新功能的同时，也改变了我们以前所习惯的与现有功能配合使用的方式。Swift 5中引入的属性包装器（property wrappers）就为我们提供了一个很好的机会，去回顾`UserDefaults`的常规实现并更新一直以来所学习的基础知识。

在这篇文章中，我们将会谈及以下内容：

* 什么是`UserDefaults`？
* 我们应该把哪些类型的数据存储到`UserDefaults`中？
* `UserDefaults`内部是如何实现的？
* 基于`UserDefaults`和Swift的属性包装器（property wrappers），设计状态安全的键值存储
* 如何观察`UserDefaults`的值变化

---

### UserDefaults概览

`UserDefaults`管理着键值对在.plist文件中的持久性存储

`UserDefaults`存储仅作用于所谓的`property-list` [1]数据类型：` Data`、`String`、`Date`、`Int`,`Double`,`Float`,`Array`, `Dictionary` 和`URL`（唯一的非`property-list` 类型）。同时我们也可以先将任意的对象编码成`Data`实例，再存储进`UserDefaults`。

> `UserDefaults`的源码中列出了支持的所有类型：Swift的[普通类型](https://github.com/apple/swift-corelibs-foundation/blob/ef6f96ee82ea0f54252071c0ecadf5f01be9aecc/Foundation/UserDefaults.swift#L58)、[非普通类型](https://github.com/apple/swift-corelibs-foundation/blob/ef6f96ee82ea0f54252071c0ecadf5f01be9aecc/Foundation/UserDefaults.swift#L63)、[NS -/CF - 桥接类型](https://github.com/apple/swift-corelibs-foundation/blob/e49beda4e4bd49e8ab541015d78b82a0a1957bc5/Foundation/Bridging.swift)、还有`NSNumber`（不是桥接类型，但依然支持）

对于我们可以存多大的数据进`UserDefaults`，这并没有强制的要求，除了[tvOS平台](https://developer.apple.com/documentation/foundation/userdefaults/1617187-sizelimitexceedednotification)上限制了不能超过1M。

不管怎样，其实不推荐存储大容量数据，因为`UserDefaults`存储的内容越多，读写耗时越高。其背后的原理是每个domain（通常每个应用）默认只使用了一个`.plist`文件，如果存储大量数据将导致该文件变得臃肿。

由于以下原因，同样也不推荐存储自定义对象：

1. 即使可以通过转换成`Data`类型实例存储进`UserDefaults`，但不管是存储还是读取，都要与`Data`类型互转，开销较大。

2. b.当App版本更新后，很可能由于改变了自定义数据类型，导致与旧数据出现冲突（无法读取等）。

根据苹果的官方文档描述，使用`UserDefaults`的最佳方法是将用户偏好和app配置存储为简单值。
### UserDefaults的内部实现

参考苹果开源的Swift源码，观察`UserDefaults`是怎么在幕后工作的。

`UserDefaults`在不同的域（domain）中存储数据，这意味着每个域都有一个保证域内一致性的`.plist`文件，用来存储持久性数据。

*Domain* 只是一个`String`类型变量，如果你曾经偶然看到过`UserDefaults`的内部实现源码，你会发现这个变量叫做`suite`。两个不同的名字都指向了同一个概念，所以我们不妨继续称之为域（domain）。

默认情况下，每个APP有八个域，这八个域组成了搜索的列表（list）。当我们第一次读或写值（与文件系统交互）时，该搜索列表就会被初始化出来。另外，需要注意的是，如果想要对`UserDefault`拥有更细粒度的控制， 我们可以自由地添加更多的域。

搜索列表中的域会合并成一个字典，这是一个耗时高的操作。每次当我们对`UserDefaults`执行添加键值对、更新键值对或移除某个键值对时，字典都会重新计算。这也使我们能从另一个角度了解`UserDefaults`的性能：

> UserDefaults有两层cache：域（domain）层和app层



### 键值对存储的实现

现在我们知道了`UserDefaults`是什么，接下来让我们做一些实践，尝试基于`UserDefaults`和**Property wrappers**实现键值存储。

> 这部分的实践要求读者对property wrappers有基本的认识，推荐阅读🚧[The Complete Guide to Property Wrappers in Swift 5](https://www.vadimbulavin.com/swift-5-property-wrappers/)

首先，这是一个封装器（wrapper）的实现，作用是保存键值对到`UserDefaults`和从`UserDefaults`加载值。

```swift
@propertyWrapper
struct UserDefault<T: PropertyListValue> {
    let key: Key

    var wrappedValue: T? {
        get { UserDefaults.standard.value(forKey: key.rawValue) as? T }
        set { UserDefaults.standard.set(newValue, forKey: key.rawValue) }
    }
}
```

注意我们给`T`设置了约束，`T`必须为`PropertyListValue`类型 。`PrropertyListValue`是我们为所有符合要求的数据类型所创建的标记协议：

> 受[Burritos](https://github.com/guillermomuntaner/Burritos/tree/master/Sources/UserDefault)实现的`UserDefaults`的启发，而使用了如下代码的做法

```swift
// The marker protocol
protocol PropertyListValue {}

extension Data: PropertyListValue {}
extension String: PropertyListValue {}
extension Date: PropertyListValue {}
extension Bool: PropertyListValue {}
extension Int: PropertyListValue {}
extension Double: PropertyListValue {}
extension Float: PropertyListValue {}

// Every element must be a property-list type
extension Array: PropertyListValue where Element: PropertyListValue {}
extension Dictionary: PropertyListValue where Key == String, Value: PropertyListValue {}
```



### 观察UserDefaults的值变化

由于`UserDefaults`通常作为系统范围的首选项，通常会在你的app的不同部分响应它的变化。所以在这一部分，我们会扩展`UserDefaults`属性封装器以能够观察值的变化。

我们首先实现`DefaultsObservation`，通过KVO来监听`UserDefaults`的变化

```swift
class DefaultsObservation: NSObject {
    let key: Key
    private var onChange: (Any, Any) -> Void

    // 1
    init(key: Key, onChange: @escaping (Any, Any) -> Void) {
        self.onChange = onChange
        self.key = key
        super.init()
        UserDefaults.standard.addObserver(self, forKeyPath: key.rawValue, options: [.old, .new], context: nil)
    }
    
    // 2
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let change = change, object != nil, keyPath == key.rawValue else { return }
        onChange(change[.oldKey] as Any, change[.newKey] as Any)
    }
    
    // 3
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: key.rawValue, context: nil)
    }
}
```

1. 观察者接受一个类型安全的`Key`变量，和一个`onChange`闭包，最早开始监听`USerDefaults`的值变化（通过key指定）
2. 当通过key指定的值被改变时，KVO系统自动调用observeValue()方法，这个方法接受了一个`change`字典，从这个字典中我们可以取出**new Value**和**old Value**，并把这两者传递给`onChange`闭包
3. 当观察者对象被销毁后，从KVO注销监听。

我们在property warpper中添加了一个observe()方法，该方法可以返回观察者的实例。为了能够在`Storage`结构外调用这一方法，我们通过`prohectedValue`变量把wrapper类型自身暴露出来：

```swift
@propertyWrapper
struct UserDefault<T: PropertyListValue> {
    var projectedValue: UserDefault<T> { return self }
    
    func observe(change: @escaping (T?, T?) -> Void) -> NSObject {
        return DefaultsObservation(key: key) { old, new in
            change(old as? T, new as? T)
        }
    }

    // The rest of the code is unchanged
}
```

现在我们可以像下面这样订阅UserDefaults的值的变化了：

```swift
var storage = Storage()

var observation = storage.$isFirstLaunch.observe { old, new in
    print(old, new)
}

storage.isFirstLaunch = false

// Prints `nil false`
```



### 总结

一些关于如何理解`UserDefaults`的关键点，如下所示：

* `UserDefaults`创建了字典和.`plist`文件用来存储键值对
* `UserDefaults`非常适合小体积的data数据和简单数据类型的存储
* `UserDefaults`的性能达到最优，当写操作尽可能少，而读操作尽可能多的时候

Swift 5 改变了`UserDefaults`。在Property Wrapper的帮助下，我们能够设计类型安全的键值存储，并且可以观察值的变化。

