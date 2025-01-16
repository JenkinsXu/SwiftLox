//
//  LoxClass.swift
//  Lox
//
//  Created by Yongqi Xu on 2025-01-15.
//

/// A runtime representation of a class.
struct LoxClass: CustomStringConvertible, LoxCallable {
    let name: String
    
    /// Where an instance stores state, the class stores behavior. `LoxInstance` has its map of fields, and `LoxClass` gets a map of methods.
    let methods: [String: LoxFunction]
    
    // MARK: CustomStringConvertible
    var description: String { name }
    
    // MARK: LoxCallable
    var arity: Int { 0 }
    func call(interpreter: Interpreter, arguments: [Any?]) throws -> Any? {
        return LoxInstance(class: self)
    }
    
    func findMethod(withName name: String) -> LoxFunction? {
        methods[name]
    }
}
