#iOS常见开发问题

这里总结了一些在开发过程中遇到的常见问题。这些总结不涉及具体的原理剖析和系统讲解，是散乱的，希望能从更好的角度解决问题的解法。

### 收回键盘

####1. TableView内嵌的TextView
对于TextView，我们无法像TextField那样

##### a. 滚动收回键盘

`tableView.keyboardDisMissMode = .onDrag`

##### b. 通过按键收回键盘
```
	// 当检测到"\n"，执行收回键盘操作
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n"{
            textView.resignFirstResponder()
            return false
        }else{
            return true
        }
    }
```

#### 2. 其它问题
##### a. 键盘遮挡
iOS 11中，多行文本在输入时可能会被键盘遮挡，TableView也不会自动向上移动，解决方法参考如下：

#### 参考资料
[iOS 11 TableViewCell 内嵌 TextView 的一些问题](https://blog.csdn.net/weixin_33725270/article/details/86997584)