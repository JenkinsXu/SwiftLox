//
//  LoxInstance.swift
//  Lox
//
//  Created by Yongqi Xu on 2025-01-16.
//

class LoxInstance: CustomStringConvertible {
    let `class`: LoxClass
    var fields = [String: Any]()
    
    // MARK: CustomStringConvertible
    var description: String {
        `class`.name + " instance"
    }
    
    init(class: LoxClass) {
        self.class = `class`
    }
    
    func get(name: Token) throws -> Any {
        if let field = fields[name.lexeme] {
            return field
        } else {
            throw Interpreter.RuntimeError(token: name, message: "Undefined property \(name.lexeme).")
        }
    }
    
    func set(name: Token, value: Any?) {
        fields[name.lexeme] = value
    }
}
