import Foundation

///语法分析器，根据输入的语法内容，将其解析成对应关系的节点
public class OCParser{
    private var tkIndex = 0
    private var tks: [OCToken]      //获取输入文本的所有节点
    
    private var currentTK: OCToken{
        return tks[tkIndex]
    }
    
    private var nextTK: OCToken{
        guard tkIndex < tks.count - 1 else{
            fatalError("Error: nextTK out of range")
        }
        return tks[tkIndex + 1]
    }
    
    ///初始化
    init(_ input: String) {
        let lexer = OCLexer(input)
        var tk = lexer.nextTK()
        var all = [tk]
        while tk != .eof {
            tk = lexer.nextTK()
            switch tk {
            case let .comments(cmStr):
                print(cmStr)        //注释不加入Token节点集合，直接输出
            default:
                all.append(tk)      //其余加入Token节点集合，用于构建AST抽象语法树
            }
        }
        
        tks = all
    }
    
    ///调试用函数
    public func debug(){
        let pgm = program()
        print(pgm)
    }
    
    ///语法分析，构建AST语法树
    public func parse() -> OCAST{
        let node = program()
        if currentTK != .eof{
            fatalError("Error: no reached end")
        }
        
        return node
    }
    
    ///程序的解析，解析成OCProgram节点
    private func program() -> OCProgram{
        return OCProgram(interface: interface(), implementation: implementation())
    }
    
    ///获取声明的节点
    private func interface() -> OCInterface{
        eat(.interface)
        guard case let .id(name) = currentTK else{
            fatalError("Error, imterface")
        }
        eat(.id(name))
        let pList = propertyList()
        eat(.end)
        return OCInterface(name: name, propertyList: pList)
    }
    
    ///获取实现的节点
    private func implementation() -> OCImplementation{
        eat(.implementation)
        guard case let .id(name) = currentTK else{
            fatalError("Error, implementation")
        }
        eat(.id(name))
        let methodListNode = methodList()
        eat(.end)
        return OCImplementation(name: name, methodList: methodListNode)
    }
    
    ///获取属性列表
    private func propertyList() -> [OCPropertyDeclaration] {
        var properties = [OCPropertyDeclaration]()
        while currentTK == .property {
            eat(.property)
            eat(.paren(.left))
            let pa = propertyAttributes()
            eat(.paren(.right))
            guard case let .id(pType) = currentTK else{
                fatalError("Error: property type wrong")
            }
            
            eat(.id(pType))
            guard case let .id(name) = currentTK else{
                fatalError("Error: property name wrong")
            }
            eat(.id(name))
            let pd = OCPropertyDeclaration(propertyAttributesList: pa, type: pType, name: name)
            properties.append(pd)
            eat(.semi)
        }
        return properties
    }
    
    ///获取属性列表
    private func propertyAttributes() -> [OCPropertyAttribute]{
        let p = propertyAttribute()
        var pa = [p]
        
        while currentTK == .comma {
            eat(.comma)
            pa.append(propertyAttribute())
        }
        return pa
    }
    
    ///获取属性节点
    private func propertyAttribute() -> OCPropertyAttribute{
        guard case let .id(name) = currentTK else{
            fatalError("Error: propertyAttribute wrong")
        }
        eat(.id(name))
        return OCPropertyAttribute(name: name)
    }
    
    ///实现的方法列表
    private func methodList() -> [OCMethod]{
        var methods = [OCMethod]()
        while currentTK == .operation(.plus) || currentTK == .operation(.minus) {
            eat(currentTK)
            methods.append(method())
        }
        return methods
    }
    
    ///获取方法
    private func method() -> OCMethod{
        eat(.paren(.left))
        guard case let .id(reStr) = currentTK else{
            fatalError("Error reStr")
        }
        eat(.id(reStr))
        eat(.paren(.right))
        guard case let .id(methodName) = currentTK else{
            fatalError("Error MethodName")
        }
        eat(.id(methodName))
        eat(.brace(.left))
        let statementsNode = statements()
        eat(.brace(.right))
        return OCMethod(returnIdentifier: reStr, methodName: methodName, statements: statementsNode)
    }
    
    ///获取函数体内容
    private func statements() -> [OCAST]{
        let sNode = statement()
        var statements = [sNode]
        while currentTK == .semi {
            eat(.semi)
            statements.append(statement())
        }
        return statements
    }
    
    ///获取函数体中单行代码的对应节点
    private func statement() -> OCAST{
        switch currentTK {
        case .id:
            if case .id = nextTK{
                guard case let .id(name) = currentTK else{
                    fatalError("Error: statement parser wrong")
                }
                eat(.id(name))
                let v = variable()
                if currentTK == .assign{
                    eat(.assign)
                    let right = expr()
                    return OCVariableDeclaration(variable: v, type: name, right: right)
                }else{
                    fatalError("Error: assign parser wrong")
                }
            }
            return assignStatement()
        default:
            return empty()
        }
    }
    
    private func assignStatement() -> OCAssign{
        let left = variable()
        eat(.assign)
        let right = expr()
        return OCAssign(left: left, right: right)
    }
    
    private func variable() -> OCVar{
        guard case let .id(name) = currentTK else{
            fatalError("Error: var is wrong")
        }
        eat(.id(name))
        
        return OCVar(name: name)
    }
    
    private func empty() -> OCAST{
        return OCVar(name: "")
    }
    
    /*
     ****************************
     *----------运算符------------
     ****************************
     */
    
    //文本解析成抽象树或节点
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
    
    private func term() -> OCAST{
        var node = factor()
        
        while [.operation(.mult), .operation(.intDiv)].contains(currentTK) {
            let tk = currentTK
            eat(currentTK)
            if tk == .operation(.mult){
                node = OCBinOP(left: node, operation: .mult, right: factor())
            }else if tk == .operation(.intDiv){
                node = OCBinOP(left: node, operation: .intDiv, right: factor())
            }
        }
        
        return node
    }
    
    private func factor() -> OCAST{
        let tk = currentTK
        
        switch tk {
        case .operation(.plus):
            eat(.operation(.plus))
            return OCUnaryOperation(operation: .plus, operand: factor())
        case .operation(.minus):
            eat(.operation(.minus))
            return OCUnaryOperation(operation: .minus, operand: factor())
        case let .constant(.integer(result)):
            eat(currentTK)
            return OCNumber.integer(result)
        case let .constant(.float(result)):
            eat(currentTK)
            return OCNumber.float(result)
        case .paren(.left):
            eat(.paren(.left))
            let result = expr()
            eat(.paren(.right))
            return result
        default:
            return variable()
        }
    }
    
    func eat(_ token: OCToken){
        if token == currentTK{
            tkIndex += 1
        }else{
            error()
        }
    }
    
    private func error(){
        fatalError("error occur in OCParser")
    }
}
