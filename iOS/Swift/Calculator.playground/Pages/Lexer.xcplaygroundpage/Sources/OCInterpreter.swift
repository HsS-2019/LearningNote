import Foundation
import UIKit

/// 词法解析器
//@discardableResult
public class OCInterpreter{
    private var ast: OCAST
    private var scopes: [String: OCValue]
    
    public init(_ input: String){
        let parser = OCParser(input)
        ast = parser.parse()                //语法分析，构建AST抽象语法树
        scopes = [String:OCValue]()         //符号表初始化
        print(ast)
        eval(node: ast)                     //解释程序
        print("scope is:")
        print(scopes)
        
        let sa = OCStaticAnalyzer()
        let symtb = sa.analyze(node: ast)   //静态分析
        
        print(symtb)
    }
    
    ///节点解释
    public func eval(node: OCAST) -> OCValue{
        switch node {
        case let program as OCProgram:
            return eval(program: program)
        case let implementation as OCImplementation:
            return eval(implementation: implementation)
        case let method as OCMethod:
            return eval(method: method)
        case let assign as OCAssign:
            return eval(assign: assign)
        case let variable as OCVar:
            return eval(variable: variable)
        case let variableDeclaration as OCVariableDeclaration:
            return eval(variableDeclaration: variableDeclaration)
        
        case let number as OCNumber:
            return eval(number: number)
        case let unaryOperation as OCUnaryOperation:
            return eval(unaryOperation: unaryOperation)
        case let binOP as OCBinOP:
            return eval(binOP: binOP)
        default:
            return .none
        }
    }
    
    ///程序的AST树解释，包括实现文件和声明文件
    func eval(program: OCProgram) -> OCValue{
        return eval(implementation: program.implementation)
    }
    
    ///实现文件的解析
    func eval(implementation: OCImplementation) -> OCValue{
        for method in implementation.methodList {
            eval(method: method)
        }
        return .none
    }
    
    ///方法节点的解析
    func eval(method: OCMethod) -> OCValue{
        for statement in method.statements {
            eval(node: statement)
        }
        return .none
    }

    ///赋值运算符的解析
    func eval(assign: OCAssign) -> OCValue{
        //scopes字典表示变量对应的值
        scopes[assign.left.name] = eval(node: assign.right)
        return .none
    }
    
    ///变量节点的解析
    func eval(variable: OCVar) -> OCValue{
        guard let value = scopes[variable.name] else{
            fatalError("Error: eval name")
        }
        return value
    }
    
//    ///声明文件的解析
//    func eval(interface: OCInterface) -> OCValue {
//
//    }
    
    ///声明节点的解析
    func eval(variableDeclaration: OCVariableDeclaration) -> OCValue {
        scopes[variableDeclaration.variable.name] = eval(node: variableDeclaration.right)
        return .none
    }
    
    //------------eval 运算符------------
    ///数字字面量节点的解析
    func eval(number: OCNumber) -> OCValue{
        return .number(number)
    }
    
    ///操作节点的解析
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
    
    ///单元运算操作的解析
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
}
