# Git使用技巧总结

### 分支

对于规模较大、开发时间较长的模块，应创建新分支并在新分支环境中开发，完全实现并测试完毕后再合并到master。

#### 创建分支

1. 登录到GitLab网站创建分支

<img src="/Users/edraw/Documents/GitHub/LearningNote/iOS/Resource/newBranch.png" alt="image-20191120120143510" style="zoom:50%;" />

2. 本地通过命令行创建分支

   暂无实践

3. 本地通过GUI界面创建分支

   ![image-20191120144033738](/Users/edraw/Documents/GitHub/LearningNote/iOS/Resource/newBranchLocal.png)
   
   本地创建的分支，Push代码时，会自动地在远程的仓库创建对应分支（如果远程仓库没有的话），Push后我们就可以在Git上看到这个分支了。

#### 分支的拉取

一般而言，如果一台电脑之前已经从仓库中clone了，**不需要再去重新Clone代码下来**，在Commit的时候选择特定的分支即可**（切换分支）**。

1. **Clone分支：**GitLab上创建的分支，我们可以点击左侧菜单中的Project，在正上方的项目详情中，点击Open in Xcode。然后选择想要的分支并clone下来。

2. **Xcode提交：**提交到分支同样可以通过Xcode菜单栏中SourceControl栏操作。Commit时记得选择合适的分支，如下图：

   ![image-20191120141537740](/Users/edraw/Documents/GitHub/LearningNote/iOS/Resource/xcodeCommit.png)

3. **命令行提交：**暂未实践

4. **Github提交：**通过Github提交时，可直接提交到对应的分支，如下图：

   ![屏幕快照 2019-11-20 下午3.04.55](/Users/edraw/Documents/GitHub/LearningNote/iOS/Resource/chooseBranch.png)

#### 分支的合并

1. GitLab上合并分支

   登录进GitLab网站，在项目首页左侧查看对应操作

   <img src="/Users/edraw/Documents/GitHub/LearningNote/iOS/Resource/mergeRequest.png" style="zoom:50%;" />

   选择Merge Request后点击New Merge Request，新建一个合并请求，如下图

   ![newMerge](/Users/edraw/Documents/GitHub/LearningNote/iOS/Resource/newMerge.png)

2. 本地通过命令行合并分支

   暂未实践

3. 本地GUI界面合并分支

   直接选择对应的分支进行合并

   ![image-20191120152501819](/Users/edraw/Documents/GitHub/LearningNote/iOS/Resource/mergeBranch.png)

#### 分支的删除

同理，三种途径都可以进行操作。