//
//  Environment.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-16.
//

class Environment {
    var enclosing: Environment? // Parent-pointer tree.
    private var values: [String: Any?] = [:]
    
    init(enclosedBy enclosing: Environment? = nil) {
        self.enclosing = enclosing
    }
    
    func get(_ name: Token) throws -> Any? {
        if let value = values[name.lexeme] {
            return value
        } else if let enclosing {
            return try enclosing.get(name)
        } else {
            // Note: It should not be a static syntax error because
            // using a variable isn't the same as referring to it.
            // Mentioning a variable before it's been declared is allowed.
            throw Interpreter.RuntimeError(token: name, message: "Undefined variable \"\(name.lexeme)\".")
        }
    }
    
    func define(_ name: String, _ value: Any?) {
        if value == nil {
            values[name] = Any?.none // Directly setting nil will remove the key.
        } else {
            values[name] = value
        }
    }
    
    func assign(_ name: Token, _ value: Any?) throws {
        if values.keys.contains(name.lexeme) {
            values[name.lexeme] = value
        } else if let enclosing {
            try enclosing.assign(name, value)
        } else {
            throw Interpreter.RuntimeError(token: name, message: "Undefined variable \"\(name.lexeme)\".")
        }
    }
}
