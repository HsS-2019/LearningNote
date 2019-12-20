Experience Of UserDefault

---

### 什么是UserDefaults

`UserDefaults`管理着键值对在.plist文件中的存储

可存储以下类型：

1. ` Data`、`String`、`Date`、`Int`,`Double`,`Float`,`Array`, `Dictionary` 和`URL`
2. 对象可编码成`Data`实例再存储进`UserDefaults`
3. 推荐只存储用户偏好设置和软件配置。

不支持以下类型的存储：

1. `Double`, `Int16`....[uncommon Swift types](https://github.com/apple/swift-corelibs-foundation/blob/ef6f96ee82ea0f54252071c0ecadf5f01be9aecc/Foundation/UserDefaults.swift#L63)
2. 对数据大小无强制限制，除了tvOS限制在1M以下
3. 由于读写限制（存储容量越大，读写耗时越高），不推荐存储大容量数据
4. 不建议存储自定义对象，即使可以通过转换成`Data`类型实例存储进`UserDefaults`.理由如下：a .不管是存储还是读取，都要与`Data`类型互转，开销较大。b.当App版本更新后，很可能由于改变了自定义数据类型，导致与旧数据出现冲突（无法读取等）。
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

注意我们需要给`T`设置约束，使`T`符合上文说到的

