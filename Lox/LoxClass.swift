//
//  LoxClass.swift
//  Lox
//
//  Created by Yongqi Xu on 2025-01-15.
//

/// A runtime representation of a class.
class LoxClass: CustomStringConvertible, LoxCallable {
    let name: String
    
    let superclass: LoxClass?
    
    /// Where an instance stores state, the class stores behavior. `LoxInstance` has its map of fields, and `LoxClass` gets a map of methods.
    let methods: [String: LoxFunction]
    
    // MARK: CustomStringConvertible
    var description: String { name }
    
    // MARK: LoxCallable
    var arity: Int {
        if let initializer = findMethod(withName: "init") {
            return initializer.arity
        } else {
            return 0
        }
    }
    
    init(name: String, superclass: LoxClass?, methods: [String : LoxFunction]) {
        self.name = name
        self.superclass = superclass
        self.methods = methods
    }
    
    func call(interpreter: Interpreter, arguments: [Any?]) throws -> Any? {
        let instance = LoxInstance(class: self)
        if let initializer = findMethod(withName: "init") {
            try initializer.bind(instance).call(interpreter: interpreter, arguments: arguments)
        }
        
        return instance
    }
    
    func findMethod(withName name: String) -> LoxFunction? {
        methods[name] ?? superclass?.findMethod(withName: name)
    }
}
