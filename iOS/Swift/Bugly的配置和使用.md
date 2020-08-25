# Bugly的配置和使用

引入Bugly是为了更清楚、全面地监控到项目的crash、自定义异常和卡顿等情况。对于Bugly的使用以及如何定位问题，我们主要将其分为三步：

* 集成和配置
* 符号表配置
* 查看和定位Bug

#### 集成和配置

Bugly的集成和配置使用都有多种方法可供选择，可根据自身需要选择。对于集成，由于项目没有使用`Cocoapods`，所以直接这里选择的是手动集成，对于配置，为了调试和定位问题更方便，我们也选择了通过代码的方式配置和开启Bugly服务。

##### 手动集成

这里使用的是手动集成方式，将`Bugly.framework`和对应系统库添加到项目里后。即可通过代码配置和开启Bugly的异常收集。具体可参考[官方文档:Bugly的集成]()。

##### 代码配置Bugly

我们可以将配置过程封装成函数调用，方便后续的修改和替换。

```swift
private func setupBugly(){
        let config = BuglyConfig()
        
        config.version = EDDevice.current.appVersion        //版本号
        config.blockMonitorEnable = true                    //卡顿监控开关，默认关闭
        config.blockMonitorTimeout = 5
        config.unexpectedTerminatingDetectionEnable = true  //非正常退出事件记录开关。默认关闭
        config.delegate = self                              //配置BuglyDelegate，可以在系统崩溃时上传自定义数据。
        
        #if DEBUG
        config.channel = "debug"                            //app的渠道
//        config.debugMode = true                             //debug信息模式开关，默认关闭
        config.reportLogLevel = .silent                    //控制自定义日记上传，设置为warn时，崩溃时会上传warn、error接口打印的日志
        #else
        config.channel = "AppSotre"                         //app的渠道
//        config.debugMode = false
        config.reportLogLevel = .warn
        #endif
                 
        Bugly.start(withAppId: "XXXXXXXX", config: config)
    }
```

这个函数应该在`AppDelegate`的`didFinishLaunchingWithOptions`阶段调用，在应用启动时就开启对异常情况的监控。

#### 手动上传符号表

> **注：2.5.0及以上版本的Bugly支持dSYM文件的上传。**

通过上面步骤集成了Bugly后，我们现在已经可以在Bugly的后台看到App上传的crash和异常。但这个时候我们看到的只有**地址的堆栈信息**，无法判断具体错在哪一行。想把对应地址转化为我们熟悉的函数名、文件名和行数等信息，需要借助App对应版本的`dSYM`文件。

> dSYM文件，指具有调试信息的目标文件。为了方便找回Crash对应的dSYM文件和还原堆栈，建议每次构建或者发布APP版本的时候，备份好dSYM文件。

当需要定位具体版本的crash时，我们可通过下面步骤，**根据对应版本的dSYM文件提取出对应符号表，并将符号表上传。**

> 符号表，是内存地址与函数名、文件名、行号的映射表。

1. ##### 下载[符号表工具](https://bugly.qq.com/v2/sdk?id=15343657-638a-4569-a220-8689b090be65)，解压，获得

* buglySymboliOS.jar
* dSYMUpload.sh

第二个文件用于自动上传符号表方式，这里略过。主要是第一个文件，我们将`buglySymboliOS.jar`文件拖到用户根目录的bin目录下。

![截屏2020-07-10下午4.56.06](https://tva1.sinaimg.cn/large/007S8ZIlgy1gglzgck2znj316q0oewus.jpg)

2. ##### 打开终端，输入`java -version`命令，查看电脑是否安装了Java环境。

![image-20200710165121749](https://tva1.sinaimg.cn/large/007S8ZIlgy1gglz5ver17j30jo03c408.jpg)

如果安装了，会打印出当前java环境版本号等信息，上图是没安装java环境的截图。安装Java环境可通过[官网](https://www.oracle.com/java/technologies/javase-jdk14-downloads.html)下载。

3. ##### Java环境安装成功后，定位具体版本的dSYM文件。

Xcode Release编译默认会生成dSYM文件，而Debug编译默认不会生成，对应的Xcode配置如下：

`XCode -> Build Settings -> Code Generation -> Generate Debug Symbols -> Yes`

`XCode -> Build Settings -> Build Option -> Debug Information Format -> DWARF with dSYM File`

**定位对应版本的dSYM文件**有以下几种方法：

* 右键点击Xcode左边文件列表栏中，编译生成的XXX.app。选择show in Finder，找到对应的dSYM文件。
* 在Xcode的`Organizer—>Archive`中可以看到对应版本的dSYM文件。
* 在`AppStore Connect—>我的App—>活动——>对应构建版本`中可以看到对应版本的dSYM文件

这里有一点需要注意，最后如果找到的dSYM文件不是和项目同名，可通过判断。

4. 通过命令提取符号表

根据Crash的UUID信息，需确保是从UUID一致的dSYM文件中提取出符号表。

把对应dSYM文件放在和buglySymboliOS.jar同一个目录下。

打开终端，进到这两个文件所在的目录，并输入以下命令：

```shell
//通用公式
java -jar buglySymbolIOS.jar -i <input> [-o <output>]

//方便的做法
java -jar buglySymboliOS.jar -i xx.app.dSYM/ （xx.app.dSYM代表使用的dSYM文件）
```

* -jar 参数后面带的是jar包的路径
* -input，dSYM文件的路径
* -output，生成的符号表的路径

如果不指定输出，符号表文件将生成在dSYM文件所在目录

##### 5. 在Bugly后台上传符号表

将上面生成的符号表，拖到这里上传。

![截屏2020-07-10下午5.03.19](https://tva1.sinaimg.cn/large/007S8ZIlgy1ggm0gkceyjj31bu0u0afo.jpg)

#### 查看和定位Bug

参考[dSYM文件分析](https://www.jianshu.com/p/5ab21d6c0c22)

### 参考文档

*  [Bugly官方文档](https://bugly.qq.com/docs/user-guide/instruction-manual-ios/?v=20200622202242)
* [Bugly接入与填坑](https://www.jianshu.com/p/4f856b519cc6)

上传异常时添加附加信息，以及保存对应log日志到本地。

* [集成Bugly二三事](https://www.jianshu.com/p/465e21cc27f6)

对第三方库依赖进行抽象化和封装，方便后期的统一修改、替换和维护。

* [Swift关于Crash的一些看法](https://www.jianshu.com/p/18f48aefafda)

里面对iOS crash的一些概念有所提及，比如版本管理、LLDB调试技巧、dSYM文件分析以及crash定位、异常处理（同OC中的避免异常导致的程序崩溃）等。

* [iOSCrash分析攻略](https://mp.weixin.qq.com/s/hVj-j61Br3dox37SN79fDQ)