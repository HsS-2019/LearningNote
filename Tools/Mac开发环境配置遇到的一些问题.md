记录Mac开发环境配置中遇到的一些问题。

#### Homebrew安装和更新

安装流程，建议通过官方的命令安装homebrew，然后再使用国内中科大/清华的镜像源安装homebrew-core。

* 官方安装参考homebrew[官网](https://brew.sh/index_zh-cn)
* 使用国内源安装homebrew-core，[安装教程](https://liujiacai.gitee.io/wiki/mac/)
* git clone速度太慢，可修改系统的hosts文件，[修改hosts](https://www.jianshu.com/p/a9e1fd5dff68)
* [卸载homebrew](https://blog.csdn.net/qq_41234116/article/details/79366454)
* 增加git缓存大小，避免clone失败，[修改git缓存](https://github.com/lanlin/notes/issues/41)
* 更新git版本，使用命令：`brew install git`
* 更换镜像地址，使用国内的镜像，[更换镜像](https://zhuanlan.zhihu.com/p/104153214)，[更换仓库源](https://www.jianshu.com/p/ff2ad9599a06)，[替换相关源](https://blog.csdn.net/lwplwf/article/details/79097565)
* 使用VPN科学上网

#### Carthage安装和使用

* Carthage安装，[安装教程](https://www.jianshu.com/p/a734be794019)
* Carthage的几个tips
* bootstrap和update的选择