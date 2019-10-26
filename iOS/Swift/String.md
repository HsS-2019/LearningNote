# String

不同于其它语言可以根据下标直接得到对应的字符，Swift使用Index和Range获取对应的字符。

## Index
对应`String`的下标，Swift中`String`根据index定位到具体Character，但`String.index`独立于`String`存在。

## Range
`Range<T>`表示一个T类型的范围

Range一般分四种，`ClosedRange`、`CountableClosedRange`、`Range`和`CountableRange`。区别在于Range为不可计数的，即不能用于循环获取Range内的值，但新版本的Swift对于该特性有改变，两者均可计数。

- Swift4增加了单侧区间的概念

对于字符串，我们应使用`String[Range<String.index>]`来截取子串。

## Sequence
表示序列

### 参考资料
- [Swift字符串截取与Range使用](https://www.jianshu.com/p/2308703b50e4)
- [String为什么这么难用？](https://kemchenj.github.io/2019-10-07/)
