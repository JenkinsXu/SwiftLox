//
//  Environment.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-16.
//

// We can't directly change this to a struct because it would be a recursive type,
// which would cause problems when calculating the size of the struct.
class Environment {
    var enclosing: Environment? // Parent-pointer tree.
    private var values: [String: Any?] = [:]
    
    init(enclosedBy enclosing: Environment? = nil) {
        self.enclosing = enclosing
    }
    
    func get(_ name: Token) throws -> Any? {
        // The variable gets re-resolved every time it's used.
        // We can avoid this with Semantic Analysis.
        // Static scope means that a vairable usage always
        // resolves to the same declaration.
        // A more efficient implementation is explored in the C interpreter.
        if let value = values[name.lexeme] {
            return value
        } else if let enclosing {
            return try enclosing.get(name)
        } else {
            // Note: It should not be a static syntax error because
            // using a variable isn't the same as referring to it.
            // For example, when referring to a variable in a function.
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
    
    func get(atDistance distance: Int, withName name: String) throws -> Any? {
        try ancestor(distance).values[name] ?? nil
    }
    
    func assign(atDistance distance: Int, withName name: Token, value: Any?) throws {
        try ancestor(distance).values[name] = value
    }
    
    private func ancestor(_ distance: Int) throws -> Environment {
        var environment = self
        for _ in 0..<distance {
            guard let enclosing = environment.enclosing else {
                throw Interpreter.RuntimeError(token: Token(type: .eof, lexeme: "", literal: nil, line: 0), message: "Environment not found.")
            }
            environment = enclosing
        }
        return environment
    }
}
