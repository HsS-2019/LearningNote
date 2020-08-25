import Foundation

/// 词法分析器
public class OCLexer{
    private var text: String
    private var currentIndex: Int
    private var currentCharacter: Character?
    
    let keywords: [String: OCToken] = [
        "return": .return
    ]
    
    init(_ input: String) {
        if input.isEmpty{
            fatalError("input String can't be empty")
        }
        
        text = input
        currentIndex = 0
        currentCharacter = text[text.startIndex]
    }

    func nextTK() -> OCToken{
        //到文件末
        guard currentIndex < text.count else{
            return .eof
        }
        
        //处理空格和换行符
        if CharacterSet.whitespacesAndNewlines.contains(currentCharacter!.unicodeScalars.first!){
            skipWhitespaceAndNewlines()
//            return .whiteSpaceAndNewLines
        }
        
        //处理数字
        if CharacterSet.decimalDigits.contains(currentCharacter!.unicodeScalars.first!){
            return numbers()
        }
        
        //处理identifier
        if CharacterSet.alphanumerics.contains((currentCharacter?.unicodeScalars.first!)!) {
            return id()
        }
        
        //处理符号
        if currentCharacter == "+"{
            advance()
            return .operation(.plus)
        }
        if currentCharacter == "-"{
            advance()
            return .operation(.minus)
        }
        if currentCharacter == "*"{
            advance()
            return .operation(.mult)
        }
        if currentCharacter == "/"{
            //处理可能的注释的情况
            if peek() == "/"{
                advance()
                advance()
                return commentsFromDoubleSlash()
            }else if peek() == "*"{
                advance()
                advance()
                return commentsFromSlashAsterisk()
            }else{
                advance()
                return .operation(.intDiv)
            }
        }
        if currentCharacter == "("{
            advance()
            return .paren(.left)
        }
        if currentCharacter == ")"{
            advance()
            return .paren(.right)
        }
        if currentCharacter == "@"{
            return at()
        }
        if currentCharacter == ";"{
            advance()
            return .semi
        }
        if currentCharacter == "="{
            advance()
            return .assign
        }
        if currentCharacter == "{"{
            advance()
            return .brace(.right)
        }
        if currentCharacter == "}"{
            advance()
            return .brace(.right)
        }
        if currentCharacter == "*"{
            advance()
            return .asterisk
        }
        if currentCharacter == ","{
            advance()
            return .comma
        }
        
        advance()
        return .eof
    }
    
    ///id类型节点，开发者自定义的一些变量？
    private func id() -> OCToken{
        var idStr = ""
        while let character = currentCharacter, CharacterSet.alphanumerics.contains(character.unicodeScalars.first!) {
            idStr += String(character)
            advance()
        }
        
        if let token = keywords[idStr]{
            return token
        }
        
        return .id(idStr)
    }
    
    ///at类型节点，后接关键字interface、implementation、end之类
    private func at() -> OCToken{
        advance()
        var atStr = ""
        while let character = currentCharacter, CharacterSet.alphanumerics.contains(character.unicodeScalars.first!) {
            atStr += String(character)
            advance()
        }
        
        if atStr == "interface"{
            return .interface
        }
        if atStr == "end"{
            return .end
        }
        if atStr == "implementation"{
            return .implementation
        }
        
        if atStr == "property"{
            return .property
        }
        
        fatalError("Error: as string not support")
    }
    
    ///获取整型、浮点型数字节点
    private func numbers() -> OCToken{
        var numStr = ""
        while let charater = currentCharacter, CharacterSet.decimalDigits.contains(charater.unicodeScalars.first!) {
            numStr += String(charater)
            advance()
        }
        
        if currentCharacter == "." {
            numStr += "."
            advance()
            while let charater = currentCharacter, CharacterSet.decimalDigits.contains(charater.unicodeScalars.first!) {
                numStr += String(charater)
                advance()
            }
            //如果字符串以“.”符号结尾，转Float过程是否会失败
            return .constant(.float(Float(numStr)!))
        }
        
        return .constant(.integer(Int(numStr)!))
    }
    
    //------------辅助函数------------
    ///获取当前字符
    private func advance(){
        currentIndex += 1
        guard currentIndex < text.count else{
            currentCharacter = nil
            return
        }
        
        currentCharacter = text[text.index(text.startIndex, offsetBy: currentIndex)]
    }
    
    ///在currentIndex不变的情况下，获取更前面一个字符
    private func peek() -> Character?{
        let peekIndex = currentIndex + 1
        guard peekIndex < text.count else {
            return nil
        }
        return text[text.index(text.startIndex, offsetBy: peekIndex)]
    }
    
    ///获取//形式的注释
    private func commentsFromDoubleSlash() -> OCToken{
        var cStr = ""
        while let character = currentCharacter, !CharacterSet.newlines.contains(character.unicodeScalars.first!) {
            advance()
            cStr += String(character)
        }
        return .comments(cStr)
    }
    
    ///获取/**/形式的注释
    private func commentsFromSlashAsterisk() -> OCToken{
        var cStr = ""
        while let character = currentCharacter {
            if character == "*" && peek() == "/"{
                advance()
                advance()
                break
            }else{
                advance()
                cStr += String(character)
            }
        }
        return .comments(cStr)
    }
    
    ///忽略空格
    private func skipWhitespaceAndNewlines(){
        while CharacterSet.whitespacesAndNewlines.contains(currentCharacter!.unicodeScalars.first!) {
            advance()
        }
    }
}
