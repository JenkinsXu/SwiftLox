//
//  LoxFunction.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-17.
//

struct LoxFunction: LoxCallable, CustomStringConvertible {
    let declaration: FunctionStatement
    let closure: Environment // The environment when the function was declared, not when called.
    var arity: Int { declaration.parameters.count }
    
    var description: String { "<fn \(declaration.name.lexeme)>" }
    
    func call(interpreter: Interpreter, arguments: [Any?]) throws -> Any? {
        let environment = Environment(enclosedBy: closure)
        for (parameter, argument) in zip(declaration.parameters, arguments) {
            environment.define(parameter.lexeme, argument)
        }
        
        do {
            try interpreter.executeBlock(declaration.body, environment)
        } catch let returnValue as Interpreter.ReturnValue {
            return returnValue.value
        }
        
        return nil
    }
}
