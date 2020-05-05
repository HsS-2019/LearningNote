# iOS适配

### AutoLayout适配

为了简化对越来越多的苹果设备的适配，苹果对设备尺寸抽象出一个概念sizeclass。sizeclass将任何设备的长、宽都分为三种情况：Regular（普通）、Compact（紧密）和Any（任意），这样，根据长宽的搭配，我们最多只需要对九种不同尺寸设备的autolayout做适配就行了。

需要注意的是，考虑横屏的情况下，一种机型可能有两种尺寸。

|		 |wRegular|wCompact|wAny|
|:------|:------|:------|:---|
|hRegular||iPhone 4S/SE/6/6Plus/X竖屏||
|hCompact|iPhone 6Plus|iPhone 4S/SE/6/X横屏||
|hAny|||所有类型|

### 机型适配

写一个独立的类，用以获取当前设备信息，包括设备机型

## 图标尺寸适配
### AppIcon

### 启动页

### 应用内图标


