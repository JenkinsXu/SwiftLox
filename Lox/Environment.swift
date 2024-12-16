//
//  Environment.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-16.
//

struct Environment {
    private var values: [String: Any?] = [:]
    
    func get(_ name: Token) throws -> Any? {
        if let value = values[name.lexeme] {
            return value
        } else {
            // Note: It should not be a static syntax error because
            // using a variable isn't the same as referring to it.
            // Mentioning a variable before it's been declared is allowed.
            throw Interpreter.RuntimeError(token: name, message: "Undefined variable \"\(name.lexeme)\".")
        }
    }
    
    mutating func define(_ name: String, _ value: Any?) {
        if value == nil {
            values[name] = Any?.none // Directly setting nil will remove the key.
        } else {
            values[name] = value
        }
    }
}
