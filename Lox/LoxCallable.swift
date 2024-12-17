//
//  LoxCallable.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-17.
//

protocol LoxCallable {
    var arity: Int { get }
    func call(interpreter: Interpreter, arguments: [Any?]) throws -> Any?
}
