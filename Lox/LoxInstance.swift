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
    
    /// When accessing a property, you might get a field—a bit of state stored on the instance—or you could hit a method defined on the instance’s class.
    func get(name: Token) throws -> Any {
        if let field = fields[name.lexeme] {
            return field
        } else if let method = `class`.findMethod(withName: name.lexeme) {
            return method
        } else {
            throw Interpreter.RuntimeError(token: name, message: "Undefined property \(name.lexeme).")
        }
    }
    
    func set(name: Token, value: Any?) {
        fields[name.lexeme] = value
    }
}
