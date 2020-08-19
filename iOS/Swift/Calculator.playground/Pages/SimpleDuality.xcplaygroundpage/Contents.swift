//: [Previous](@previous)
/**
 * 示例1，构建一个仅支持整型四项简单运算的计算器
 *仅只支持两个元素运算，不支持负数运算
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

public enum OCToken{
    case operation(OCOperation)
    case constant(OCConstant)
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

extension OCToken: Equatable{
    public static func ==(lhs: OCToken, rhs: OCToken) -> Bool{
        switch (lhs, rhs) {
        case let (.constant(left), .constant(right)):
            return left == right
        case let (.operation(left), .operation(right)):
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
    private var text: String
    private var currentIndex: Int
    private var currentCharacter: Character?
    
    private var currentTK: OCToken
    
    init(_ input: String) {
        if input.isEmpty{
            fatalError("input String can't be empty")
        }
        
        text = input
        currentIndex = 0
        currentCharacter = text[text.startIndex]
        currentTK = .eof
    }
    
    private func error(){
        fatalError("error occur in OCInterpreter")
    }
    
    private func nextTK() -> OCToken{
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
        advance()
        return .eof
    }
    
    public func expr() -> Int{
        //输入字符串不能以空格开头
        currentTK = nextTK()
        
        guard case let .constant(.integer(left)) = currentTK else{
            return 0
        }
        eat(currentTK)
        
        let op = currentTK
        eat(currentTK)
        
        guard case let .constant(.integer(right)) = currentTK else{
            return 0
        }
        eat(currentTK)
        
        if op == .operation(.plus){
            return left + right
        }else if op == .operation(.minus){
            return left - right
        }else if op == .operation(.mult){
            return left * right
        }else if op == .operation(.intDiv){
            return left / right
        }
        return left + right
    }
    
    private func eat(_ token: OCToken){
        if token == currentTK{
            currentTK = nextTK()
            if currentTK == .whiteSpaceAndNewLines{
                currentTK = nextTK()
            }else{
                error()
            }
        }
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

let interpreter = OCInterpreter("33 - 4")
interpreter.expr()
