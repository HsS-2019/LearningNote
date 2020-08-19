//: [Previous](@previous)

import Foundation

let interpreter = OCInterpreter("(33 - 4 )* -4")
let op = interpreter.expr()
let result = interpreter.eval(node: op)
print(op)
