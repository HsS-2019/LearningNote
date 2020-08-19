import Foundation

//MARK: - AST抽象树的模型
public protocol OCAST{ }
public protocol OCDeclaration: OCAST { }

///程序根节点
public class OCProgram: OCAST{
    let interface: OCInterface
    let implementation: OCImplementation
    init(interface: OCInterface, implementation: OCImplementation) {
        self.interface = interface
        self.implementation = implementation
    }
}

///类声明的节点
public class OCInterface: OCAST{
    let name: String
    let propertyList: [OCPropertyDeclaration]
    init(name: String, propertyList: [OCPropertyDeclaration]) {
        self.name = name
        self.propertyList = propertyList
    }
}

///属性列表节点（一个变量的所有属性）
public class OCPropertyDeclaration: OCAST{
    let propertyAttributesList: [OCPropertyAttribute]
    let type: String
    let name: String
    init(propertyAttributesList: [OCPropertyAttribute], type: String, name: String) {
        self.propertyAttributesList = propertyAttributesList
        self.type = type
        self.name = name
    }
}

///属性节点
public class OCPropertyAttribute: OCAST{
    let name: String
    init(name: String) {
        self.name = name
    }
}

///类实现的节点
public class OCImplementation: OCAST{
    let name: String
    let methodList: [OCMethod]
    
    init(name: String, methodList: [OCMethod]) {
        self.name = name
        self.methodList = methodList
    }
}

///方法实现的节点
class OCMethod: OCAST{
    let returnIdentifier: String
    let methodName: String
    let statements: [OCAST]
    
    init(returnIdentifier: String, methodName: String, statements: [OCAST]) {
        self.returnIdentifier = returnIdentifier
        self.methodName = methodName
        self.statements = statements
    }
}

///复合参数
class OCCompoundStatement: OCAST {
    let children: [OCAST]
    init(children: [OCAST]) {
        self.children = children
    }
}

///临时变量声明节点
class OCVariableDeclaration: OCDeclaration {
    let variable: OCVar
    let type: String
    let right: OCAST
    
    init(variable: OCVar, type: String, right: OCAST) {
        self.variable = variable
        self.type = type
        self.right = right
    }
}

class OCIdentifier: OCAST {
    let identifier: String
    init(identifier: String) {
        self.identifier =  identifier
    }
}

///赋值的节点
class OCAssign: OCAST{
    let left: OCVar
    let right: OCAST
    
    init(left: OCVar, right: OCAST) {
        self.left = left
        self.right = right
    }
}

//MARK: OC语法Model
///变量的节点
class OCVar: OCAST{
    let name: String
    
    init(name: String) {
        self.name = name
    }
}

class OCNoOp: OCAST {}

/*----------------运算符----------------*/
///二元运算的节点
public class OCBinOP: OCAST{
    let left: OCAST
    let operation: OCBinOPType
    let right: OCAST
    
    init(left: OCAST, operation: OCBinOPType, right: OCAST) {
        self.left = left
        self.operation = operation
        self.right = right
    }
}

///数值的字面量，包括整型和浮点型
public enum OCNumber: OCAST{
    case integer(Int)
    case float(Float)
}

///单元运算的节点
class OCUnaryOperation: OCAST{
    let operation: OCUnaryOperationType
    let operand: OCAST
    
    init(operation: OCUnaryOperationType, operand: OCAST) {
        self.operation = operation
        self.operand = operand
    }
}

//MARK: Extension
extension OCNumber: Equatable{
    public static func == (lhs: OCNumber, rhs: OCNumber) -> Bool{
        switch (lhs, rhs) {
        case let (.integer(left), .integer(right)):
            return left == right
        case let (.float(left), .float(right)):
            return left == right
        case let (.integer(left), .float(right)):
            return Float(left) == right
        case let (.float(left), .integer(right)):
            return left == Float(right)
        }
    }
}
