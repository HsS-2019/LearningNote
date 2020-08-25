import UIKit

//var str = "Hello, playground"

public enum OCToken{
    case constant(OCConstant)
    case operation(OCOperation)
    case eof
    case whiteSpaceAndNewLines
}

extension OCToken: Equatable{
    public static func ==(lhs: OCToken, rhs: OCToken) -> Bool{
        switch (lhs, rhs) {
        case let (.constant(left), .constant(right)):
            return left == right
        case let (.operation(left), .operation(right)):
            return left == right
        case (.eof, .eof):
            return true
        case (.whiteSpaceAndNewLines, .whiteSpaceAndNewLines):
            return true
        default:
            return false
        }
    }
}

public enum OCConstant{
    case integer(Int)
    case float(Float)
    case boolean(Bool)
    case string(String)
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

public enum OCOperation{
    case plus
    case minus
    case multi
    case intDiv
}

extension OCOperation: Equatable{
    public static func ==(lhs: OCOperation, rhs: OCOperation) -> Bool{
        switch (lhs, rhs) {
        case (.plus, .plus):
            return true
        case (.minus, minus):
            return true
        case (.multi, multi):
            return true
        case (.intDiv, .intDiv):
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
            fatalError("Error! input can't be empty")
        }
        text = input
        currentIndex = 0
        currentCharacter = text[text.startIndex]
        currentTK = .eof
    }
    
    func expr() -> Int{
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
        }else if op == .operation(.multi){
            return left * right
        }else if op == .operation(.intDiv){
            return left / right
        }
        return left + right
    }
    
    private func advance(){
        currentIndex += 1
        guard currentIndex < text.count else {
            currentCharacter = nil
            return
        }
        
        currentCharacter = text[text.index(text.startIndex, offsetBy: currentIndex)]
    }
    
    private func nextTK() -> OCToken{
        guard currentIndex < text.count else{
            return .eof
        }
        
        if CharacterSet.whitespacesAndNewlines.contains((currentCharacter?.unicodeScalars.first!)!){
            skipWhiteSpaceAndNewLines()
            return .whiteSpaceAndNewLines
        }
        
        if CharacterSet.decimalDigits.contains((currentCharacter?.unicodeScalars.first!)!){
            let tk = number()
            return tk
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
            return .operation(.multi)
        }
        if currentCharacter == "/"{
            advance()
            return .operation(.intDiv)
        }
        
        advance()
        return .eof
    }
    
    private func eat(_ token: OCToken){
        if currentTK == token {
            currentTK = nextTK()
            if currentTK == .whiteSpaceAndNewLines{
                currentTK = nextTK()
            }
        }else{
            fatalError("Error: eat error")
        }
    }
    
    private func skipWhiteSpaceAndNewLines(){
        while CharacterSet.whitespacesAndNewlines.contains((currentCharacter?.unicodeScalars.first!)!){
            advance()
        }
    }
    
    private func number() -> OCToken{
        var numStr = ""
        while let character = currentCharacter, CharacterSet.decimalDigits.contains(character.unicodeScalars.first!) {
            numStr += String(character)
            advance()
        }
        
        if let character = currentCharacter, character == "."{
            numStr += "."
            advance()
            while let character = currentCharacter, CharacterSet.decimalDigits.contains(character.unicodeScalars.first!) {
                numStr += String(character)
                advance()
            }
            return .constant(.float(Float(numStr)!))
        }
        
        return .constant(.integer(Int(numStr)!))
    }
}

//text
let interpreter = OCInterpreter("41 * 8")
let result = interpreter.expr()


