//: [Previous](@previous)
/**
 *示例2: 构建支持多个整型元素进行四项简单运算的计算器。
 *相对上面做的仅支持整型的四项简单运算（且仅只支持两个元素，不支持负数运算）
 * 本次实现基于上面的代码，添加了支持多个元素运算，和括号运算的特性.
 */

import Foundation

public enum OCConstant{
    case integer(Int)
    case float(Float)
    case boolean(Bool)
    case string(String)
}

public enum OCOperation{
    case plus
    case minus
    case mult
    case intDiv
}

public enum OCDirection{
    case left
    case right
}

public enum OCToken{
    case operation(OCOperation)
    case constant(OCConstant)
    case paren(OCDirection)
    case eof
    case whiteSpaceAndNewLines
}

extension OCConstant: Equatable{
    public static func ==(lhs: OCConstant, rhs: OCConstant) -> Bool{
        switch (lhs, rhs) {
        case let (.integer(left), .integer(right)):
            return left == right
        case let (.float(left), .float(right)):
        return left == right
        case let (.boolean(left), .boolean(right)):
        return left == right
        case let (.string(left), .string(right)):
        return left == right
        default:
            return false
        }
    }
}

extension OCOperation: Equatable{
    public static func ==(lhs: OCOperation, rhs: OCOperation) -> Bool{
        switch (lhs, rhs) {
        case (.plus, plus):
            return true
        case (.minus, minus):
        return true
        case (.mult, mult):
        return true
        case (.intDiv, intDiv):
        return true
        default:
            return false
        }
    }
}

extension OCDirection: Equatable{
    public static func ==(lhs: OCDirection, rhs: OCDirection) -> Bool{
        switch (lhs, rhs) {
        case (.left, .left):
            return true
        case (.right, .right):
            return true
        default:
            return false
        }
    }
}

extension OCToken: Equatable{
    public static func ==(lhs: OCToken, rhs: OCToken) -> Bool{
        switch (lhs, rhs) {
        case let (.constant(left), .constant(right)):
            return left == right
        case let (.operation(left), .operation(right)):
            return left == right
        case let (.paren(left), .paren(right)):
            return left == right
        case (.eof, eof):
            return true
        case (.whiteSpaceAndNewLines, .whiteSpaceAndNewLines):
            return true
        default:
            return false
        }
    }
}

public class OCInterpreter{
    private var lexer: OCLexer
    private var currentTK: OCToken
    
    public init(_ input: String){
        lexer = OCLexer(input)
        
        //输入字符串不能以空格开头
        currentTK = lexer.nextTK()
    }
    
    public func expr() -> Int{
        var result = term()
        
        while [.operation(.plus), .operation(.minus)].contains(currentTK) {
            let tk = currentTK
            eat(currentTK)
            if tk == .operation(.plus){
                result = result + term()
            }else if tk == .operation(.minus){
                result = result - term()
            }
        }
        
        return result
    }
    
    private func term() -> Int{
        var result = factor()
        
        while [.operation(.mult), .operation(.intDiv)].contains(currentTK) {
            let tk = currentTK
            eat(currentTK)
            if tk == .operation(.mult){
                result = result * term()
            }else if tk == .operation(.intDiv){
                result = result / term()
            }
        }
        
        return result
    }
    
    private func factor() -> Int{
        let tk = currentTK
        
        switch tk {
        case let .constant(.integer(result)):
            eat(currentTK)
            return result
        case .paren(.left):
            eat(.paren(.left))
            let result = expr()
            eat(.paren(.right))
            return result
        default:
            return 0
        }
    }
    
    private func eat(_ token: OCToken){
        if token == currentTK{
            currentTK = lexer.nextTK()
            if currentTK == .whiteSpaceAndNewLines{
                currentTK = lexer.nextTK()
            }
        }else{
            error()
        }
    }
    
    private func error(){
        fatalError("error occur in OCInterpreter")
    }
}

/// 词法分析器
public class OCLexer{
    private var text: String
    private var currentIndex: Int
    private var currentCharacter: Character?
    
//    private var currentTK: OCToken
    
    init(_ input: String) {
        if input.isEmpty{
            fatalError("input String can't be empty")
        }
        
        text = input
        currentIndex = 0
        currentCharacter = text[text.startIndex]
    }

    fileprivate func nextTK() -> OCToken{
        guard currentIndex < text.count else{
            return .eof
        }
        
        if CharacterSet.whitespacesAndNewlines.contains(currentCharacter!.unicodeScalars.first!){
            skipWhitespaceAndNewlines()
            return .whiteSpaceAndNewLines
        }
        
        if CharacterSet.decimalDigits.contains(currentCharacter!.unicodeScalars.first!){
            return numbers()
        }
        
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
            advance()
            return .operation(.intDiv)
        }
        if currentCharacter == "("{
            advance()
            return .paren(.left)
        }
        if currentCharacter == ")"{
            advance()
            return .paren(.right)
        }
        advance()
        return .eof
    }
    
    private func advance(){
        currentIndex += 1
        guard currentIndex < text.count else{
            currentCharacter = nil
            return
        }
        
        currentCharacter = text[text.index(text.startIndex, offsetBy: currentIndex)]
    }
    
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
    
    private func skipWhitespaceAndNewlines(){
        while CharacterSet.whitespacesAndNewlines.contains(currentCharacter!.unicodeScalars.first!) {
            advance()
        }
    }
}

let interpreter = OCInterpreter("(33 - 4 )* 4")
interpreter.expr()



