//
//  LoxClass.swift
//  Lox
//
//  Created by Yongqi Xu on 2025-01-15.
//

/// A runtime representation of a class.
struct LoxClass: CustomStringConvertible, LoxCallable {
    let name: String
    
    // MARK: CustomStringConvertible
    var description: String { name }
    
    // MARK: LoxCallable
    var arity: Int { 0 }
    func call(interpreter: Interpreter, arguments: [Any?]) throws -> Any? {
        return LoxInstance(class: self)
    }
}
