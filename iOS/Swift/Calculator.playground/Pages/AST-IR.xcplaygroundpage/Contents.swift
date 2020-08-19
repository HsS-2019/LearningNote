//: [Previous](@previous)
/**
 *示例3: 构建IR层AST树的生成器
 */
import Foundation

//MARK: - AST抽象树的模型
public protocol OCAST{ }

public enum OCValue{
    case number(OCNumber)
    case operation(OCBinOPType)
    case none
}

public enum OCBinOPType{
    case plus
    case minus
    case mult
    case intDiv
}

public enum OCNumber: OCAST{
    case integer(Int)
    case float(Float)
}

class OCBinOP: OCAST{
    let left: OCAST
    let operation: OCBinOPType
    let right: OCAST
    
    init(left: OCAST, operation: OCBinOPType, right: OCAST) {
        self.left = left
        self.operation = operation
        self.right = right
    }
}

public enum OCUnaryOperationType: OCAST{
    case plus
    case minus
}

class OCUnaryOperation: OCAST{
    let operation: OCUnaryOperationType
    let operand: OCAST
    
    init(operation: OCUnaryOperationType, operand: OCAST) {
        self.operation = operation
        self.operand = operand
    }
}

extension OCNumber{
    static func + (left: OCNumber, right: OCNumber) -> OCNumber{
        switch (left, right) {
        case let (.integer(left), integer(right)):
            return .integer(left + right)
        case let (.float(left), float(right)):
            return .float(left + right)
        case let (.integer(left), float(right)):
            return .float(Float(left) + right)
        case let (.float(left), integer(right)):
            return .float(left + Float(right))
        }
    }
    
    static func - (left: OCNumber, right: OCNumber) -> OCNumber{
        switch (left, right) {
        case let (.integer(left), integer(right)):
            return .integer(left - right)
        case let (.float(left), float(right)):
            return .float(left - right)
        case let (.integer(left), float(right)):
            return .float(Float(left) - right)
        case let (.float(left), integer(right)):
            return .float(left - Float(right))
        }
    }
    
    static func * (left: OCNumber, right: OCNumber) -> OCNumber{
        switch (left, right) {
        case let (.integer(left), integer(right)):
            return .integer(left * right)
        case let (.float(left), float(right)):
            return .float(left * right)
        case let (.integer(left), float(right)):
            return .float(Float(left) * right)
        case let (.float(left), integer(right)):
            return .float(left * Float(right))
        }
    }
    
    static func / (left: OCNumber, right: OCNumber) -> OCNumber{
        switch (left, right) {
        case let (.integer(left), integer(right)):
            return .integer(left / right)
        case let (.float(left), float(right)):
            return .float(left / right)
        case let (.integer(left), float(right)):
            return .float(Float(left) / right)
        case let (.float(left), integer(right)):
            return .float(left / Float(right))
        }
    }
    
    //一元运算符
    static prefix func + (left: OCNumber) -> OCNumber{
        switch left {
        case let .integer(value):
            return .integer(+value)
        case let .float(value):
            return .float(+value)
        }
    }
    
    static prefix func - (left: OCNumber) -> OCNumber{
        switch left {
        case let .integer(value):
            return .integer(-value)
        case let .float(value):
            return .float(-value)
        }
    }
}

//MARK: - 计算器的模型
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

/// 词法解析器
public class OCInterpreter{
    private var lexer: OCLexer
    private var currentTK: OCToken
    
    public init(_ input: String){
        lexer = OCLexer(input)
        
        //输入字符串不能以空格开头
        currentTK = lexer.nextTK()
    }
    
    public func expr() -> OCAST{
        var node = term()
        
        while [.operation(.plus), .operation(.minus)].contains(currentTK) {
            let tk = currentTK
            eat(currentTK)
            if tk == .operation(.plus){
                node = OCBinOP(left: node, operation: .plus, right: term())
            }else if tk == .operation(.minus){
                node = OCBinOP(left: node, operation: .minus, right: term())
            }
        }
        
        return node
    }
    
    public func eval(node: OCAST) -> OCValue{
        switch node {
        case let number as OCNumber:
            return eval(number: number)
        case let binOP as OCBinOP:
            return eval(binOP: binOP)
        case let unaryOperation as OCUnaryOperation:
            return eval(unaryOperation: unaryOperation)
        default:
            return .none
        }
    }
    
    func eval(number: OCNumber) -> OCValue{
        return .number(number)
    }
    
    func eval(binOP: OCBinOP) -> OCValue{
        guard case let .number(leftResult) = eval(node: binOP.left),
            case let .number(rightResult) = eval(node: binOP.right) else{
            fatalError("Error! binOP is wrong")
        }
        
        switch binOP.operation {
        case .plus:
            return .number(leftResult + rightResult)
        case .minus:
        return .number(leftResult - rightResult)
        case .mult:
        return .number(leftResult * rightResult)
        case .intDiv:
        return .number(leftResult / rightResult)
        }
    }
    
    func eval(unaryOperation: OCUnaryOperation) -> OCValue{
        guard case let .number(result) = eval(node: unaryOperation.operand) else{
            fatalError("Error: eval unaryOperation")
        }
        switch unaryOperation.operation {
        case .plus:
            return .number(+result)
        case .minus:
            return .number(-result)
        }
    }
    
    private func term() -> OCAST{
        var node = factor()
        
        while [.operation(.mult), .operation(.intDiv)].contains(currentTK) {
            let tk = currentTK
            eat(currentTK)
            if tk == .operation(.mult){
                node = OCBinOP(left: node, operation: .mult, right: term())
            }else if tk == .operation(.intDiv){
                node = OCBinOP(left: node, operation: .intDiv, right: term())
            }
        }
        
        return node
    }
    
    private func factor() -> OCAST{
        let tk = currentTK
        
        switch tk {
        case let .constant(.integer(result)):
            eat(currentTK)
            return OCNumber.integer(result)
        case .paren(.left):
            eat(.paren(.left))
            let result = expr()
            eat(.paren(.right))
            return result
        case .operation(.plus):
            eat(.operation(.plus))
            return OCUnaryOperation(operation: .plus, operand: factor())
        case .operation(.minus):
            eat(.operation(.minus))
            return OCUnaryOperation(operation: .minus, operand: factor())
        default:
            return OCNumber.integer(0)
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

let interpreter = OCInterpreter("(33 - 4 )* -4")
let op = interpreter.expr()
let result = interpreter.eval(node: op)
print(op)

