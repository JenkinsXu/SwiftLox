//
//  LoxFunction.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-17.
//

struct LoxFunction: LoxCallable, CustomStringConvertible {
    let declaration: FunctionStatement
    var arity: Int { declaration.parameters.count }
    
    var description: String { "<fn \(declaration.name.lexeme)>" }
    
    func call(interpreter: Interpreter, arguments: [Any?]) throws -> Any? {
        let environment = Environment(enclosedBy: interpreter.environment)
        for (parameter, argument) in zip(declaration.parameters, arguments) {
            environment.define(parameter.lexeme, argument)
        }
        
        try interpreter.executeBlock(declaration.body, environment)
        return nil // TODO: Add return statement.
    }
}
