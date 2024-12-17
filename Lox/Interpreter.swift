//
//  Interpreter.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-12.
//

import Foundation

/// Does a post-order traversal - each node evaluates its children before doing its own work.
class Interpreter {
    var globals = Environment()
    var environment: Environment
    
    init() {
        // Native functions
        struct Clock: LoxCallable {
            var arity: Int { 0 }
            
            func call(interpreter: Interpreter, arguments: [Any?]) throws -> Any? {
                Date()
            }
        }
        
        globals.define("clock", Clock())
        environment = globals
    }
    
    struct RuntimeError: Error {
        let token: Token
        let message: String
        let exitCode: Int32 = 70
        
        var localizedDescription: String {
            "RuntimeError: \(message) at line \(token.line)."
        }
    }
    
    func interpret(_ statements: [Statement]) throws {
        for statement in statements {
            try execute(statement)
        }
    }
    
    func execute(_ statement: Statement) throws {
        try statement.accept(self)
    }
    
    func stringify(_ value: Any?) -> String {
        guard let value else { return "nil" }
        
        if let value = value as? Double {
            var text = String(value)
            if text.hasSuffix(".0") {
                text.removeLast(2)
            }
            return text
        }
        
        return "\(value)"
    }
    
    @discardableResult
    func evaluate(_ expression: Expression) throws -> Any? {
        try expression.accept(self)
    }
    
    /// Lox follows Ruby's rule: only `false` and `nil` are falsey.
    func isTruthy(_ value: Any?) -> Bool {
        if let value = value as? Bool {
            return value
        }
        return value != nil
    }
}
