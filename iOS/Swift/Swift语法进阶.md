Swift进阶

### 语法进阶

* #### `fileter`、`map`、`flatmap`、`reduce`的使用

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

### 参考资料

- 参考资料：[Swift的字符串为什么这么难用？](https://kemchenj.github.io/2019-10-07/)



