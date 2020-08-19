import Foundation

public enum OCValue{
    case number(OCNumber)
    case operation(OCBinOPType)
    case string(String)
    case none
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

///Token类型节点
public enum OCToken{
    case operation(OCOperation)
    case constant(OCConstant)
    case paren(OCDirection)
    case eof
    case whiteSpaceAndNewLines
    
    //OC关键字类型
    case brace(OCBrace)
    case asterisk
    case interface
    case property
    case comma
    case end
    case implementation
    case id(String)
    case comments(String)
    case semi
    case assign
    case `return`
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

//二元运算符
public enum OCBinOPType{
    case plus
    case minus
    case mult
    case intDiv
}

///单元运算符
public enum OCUnaryOperationType: OCAST{
    case plus
    case minus
}

public enum OCBrace{
    case left
    case right
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
            
        case let (.brace(left), .brace(right)):
            return left == right
        case (.asterisk, asterisk):
            return true
        case (.interface, .interface):
            return true
        case (.end, .end):
            return true
        case (.implementation, .implementation):
            return true
        case let (.id(left), .id(right)):
            return left == right
        case (.semi, semi):
            return true
        case (.assign, assign):
            return true
        case (.return, .return):
            return true
        default:
            return false
        }
    }
}
