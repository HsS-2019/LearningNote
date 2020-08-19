import Foundation

public class OCStaticAnalyzer: OCVisitor{
//    private var symbolTable = OCSymbolTable(name: "global")
    
    private var currentScope: OCSymbolTable?
    private var scopes: [String: OCSymbolTable] = [:]
    
    public init() {
        
    }
    
    public func analyze(node: OCAST) -> OCSymbolTable{
        visit(node: node)
        return scopes
    }
    
    func visit(program: OCProgram){
        //构建顶层的全局符号表
        let grobalScope = OCSymbolTable(name: "grobal", level: 1, enclosingScope: nil)
        scopes[grobalScope.name] = globalScope
        currentScope = globalScope
        visit(interface: program.interface)
        visit(implementation: program.implementation)
        currentScope = nil
    }
    
    func visit(variableDeclaration: OCVariableDeclaration) {
        guard let scope = currentScope else {
            fatalError("Error: out of a scope")
        }
        
        guard scope.lookup(variableDeclaration.variable.name, currentScopeOnly: true) == nil else {
            fatalError("Error: Duplicate identifier")
        }
        
        guard let symbolType = scope.lookup(variableDeclaration.type) else {
            fatalError("Error: type not found")
        }
        
        //插入变量的声明
        scope.define(OCVariableSymbol(name: variableDeclaration.variable.name, type: symbolType))
        visit(node: variableDeclaration.variable)
        visit(node: variableDeclaration.right)
    }
    
    func visit(method: OCMethod) {
        //声明新的符号表，每个方法内部拥有一个较低层次的符号表
        let scope = OCSymbolTable(name: method.methodName, level: (currentScope?.level ?? 0) + 1, enclosingScope: currentScope)
        scopes[scope.name] = scope
        currentScope = scope
        
        for statement in method.statements {
            visit(node: statement)
        }
        
        //当前符号表回到上一层
        currentScope = currentScope?.enclosingScope
    }
    
    ///访问属性声明节点，并检查属性名是否重复定义
    ///并把该属性声明节点的属性添加到符号表中，只执行一次
    func visit(propertyDeclaration: OCPropertyDeclaration){
        guard let scope = currentScope else {
            fatalError("Error: out of a scope")
        }
        guard scope.lookup(propertyDeclaration.name) == nil else {
            fatal("Error: duplicate identifier \(propertyDeclaration.name) found")
        }

        guard let symbolType = scope.lookup(propertyDeclaration.type) else {
            fatal("Errror: \(propertyDeclaration.type) type not found")
        }

        //插入属性的声明
        scope.define(OCVariableSymbol(name: propertyDeclaration.name, type: symbolType))
    }
    
    ///访问变量节点，检查变量是否被声明
    func visit(variable: OCVar){
        guard let scope = currentScope else {
            fatalError("Error: cannot acess")
        }
        
        //访问前查找符号表，使用前变量需声明
        guard scope.lookup(variable.name) != nil else{
            fatal("Error: \(variable.name) variable not found")
        }
    }
    
    ///给变量赋值时，检查该变量是否已经被声明
    func visit(assign: OCAssign){
        guard scope.lookup(assign.left.name) != nil else{
            fatal("Error: \(assign.left.name) not found")
        }
    }
}
