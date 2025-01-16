//
//  LoxInstance.swift
//  Lox
//
//  Created by Yongqi Xu on 2025-01-16.
//

struct LoxInstance: CustomStringConvertible {
    let `class`: LoxClass
    let fields = [String: Any]()
    
    // MARK: CustomStringConvertible
    var description: String {
        `class`.name + " instance"
    }
    
    func get(name: Token) throws -> Any {
        if let field = fields[name.lexeme] {
            return field
        } else {
            throw Interpreter.RuntimeError(token: name, message: "Undefined property \(name.lexeme).")
        }
    }
}
