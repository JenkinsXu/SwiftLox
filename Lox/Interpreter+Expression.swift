//
//  Interpreter+Expression.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-17.
//

extension Interpreter: ExpressionThrowingVisitor {
    typealias Output = Any?
    
    func visitLiteral(_ literal: Literal) throws -> Output {
        literal.value // The value is extracted by the parser.
    }
    
    func visitGrouping(_ grouping: Grouping) throws -> Output {
        try evaluate(grouping.expression)
    }
    
    func visitUnary(_ unary: Unary) throws -> Output {
        let right = try evaluate(unary.right)
        switch unary.operator.type {
        case .minus:
            return -(try numberOperand(operator: unary.operator, value: right))
        case .bang:
            return !isTruthy(right)
        default:
            break
        }
        return nil
    }
    
    func visitBinary(_ binary: Binary) throws -> Output {
        let left = try evaluate(binary.left)
        let right = try evaluate(binary.right)
        
        switch binary.operator.type {
        case .minus:
            let (left, right) = try numberOperands(operator: binary.operator, left: left, right: right)
            return left - right
        case .slash:
            let (left, right) = try numberOperands(operator: binary.operator, left: left, right: right)
            return left / right
        case .star:
            let (left, right) = try numberOperands(operator: binary.operator, left: left, right: right)
            return left * right
        case .plus:
            if let left = left as? Double, let right = right as? Double {
                return left + right
            } else if let left = left as? String, let right = right as? String {
                return left + right
            } else {
                throw RuntimeError(token: binary.operator, message: "Operands must be two numbers or two strings.")
            }
            
        case .greater:
            let (left, right) = try numberOperands(operator: binary.operator, left: left, right: right)
            return left > right
        case .greaterEqual:
            let (left, right) = try numberOperands(operator: binary.operator, left: left, right: right)
            return left >= right
        case .less:
            let (left, right) = try numberOperands(operator: binary.operator, left: left, right: right)
            return left < right
        case .lessEqual:
            let (left, right) = try numberOperands(operator: binary.operator, left: left, right: right)
            return left <= right
            
        case .bangEqual:
            return !isEqual(left, right)
        case .equalEqual:
            return isEqual(left, right)
            
        default:
            break
        }
        
        return nil
    }
    
    func visitVariable(_ variable: Variable) throws -> Output {
        return try lookUpVariable(name: variable.name, expression: variable)
    }
    
    private func lookUpVariable(name: Token, expression: Expression) throws -> Any? {
        if let distance = locals[expression] {
            return try environment.get(atDistance: distance, withName: name.lexeme)
        } else {
            return try globals.get(name)
        }
    }
    
    func visitAssign(_ assign: Assign) throws -> Output {
        let value = try evaluate(assign.value)
        
        if let distance = locals[assign] {
            try environment.assign(atDistance: distance, withName: assign.name, value: value)
        } else {
            try globals.assign(assign.name, value)
        }
        
        return value
    }
    
    func visitLogical(_ logical: Logical) throws -> Output {
        let left = try evaluate(logical.left)
        
        // Short-circuiting
        if logical.operator.type == .or {
            if isTruthy(left) {
                return left
            }
        } else {
            if !isTruthy(left) {
                return left
            }
        }
        
        return try evaluate(logical.right)
    }
    
    func visitCall(_ call: Call) throws -> Output {
        let callee = try evaluate(call.callee)
        
        var arguments: [Any?] = []
        for argument in call.arguments {
            arguments.append(try evaluate(argument))
        }
        
        guard let function = callee as? LoxCallable else {
            throw RuntimeError(token: call.paren, message: "Can only call functions and classes.")
        }
        
        if arguments.count != function.arity {
            throw RuntimeError(token: call.paren, message: "Expected \(function.arity) arguments but got \(arguments.count).")
        }
        
        return try function.call(interpreter: self, arguments: arguments)
    }
    
    func visitGet(_ get: Get) throws -> Any? {
        let object = try evaluate(get.object)
        if let instance = object as? LoxInstance {
            return try instance.get(name: get.name)
        }
        
        throw RuntimeError(token: get.name, message: "Only instances have properties.")
    }
    
    func visitSet(_ set: SetExpression) throws -> Any? {
        let object = try evaluate(set.object)
        
        guard let instance = object as? LoxInstance else {
            throw RuntimeError(token: set.name, message: "Only instances have fields.")
        }
        
        let value = try evaluate(set.value)
        instance.set(name: set.name, value: value)
        return value
    }
    
    func visitThis(_ this: This) throws -> Any? {
        return try lookUpVariable(name: this.keyword, expression: this)
    }
    
    func visitSuper(_ super: Super) throws -> Any? {
        guard let distance = locals[`super`], // super -> this -> body
              let superclass = try environment.get(atDistance: distance, withName: "super") as? LoxClass,
              let object = try environment.get(atDistance: distance - 1, withName: "this") as? LoxInstance else { // Implicitly the same current object.
            throw RuntimeError(token: `super`.keyword, message: "Can't use 'super' in a class with no superclass.")
        }
        
        guard let superMethod = superclass.findMethod(withName: `super`.method.lexeme) else {
            throw RuntimeError(token: `super`.keyword, message: "Undefined property '\(`super`.method.lexeme)'.")
        }
        
        return superMethod.bind(object)
    }
    
    // MARK: Helpers
    
    private func numberOperand(operator: Token, value: Any?) throws -> Double {
        guard let value = value as? Double else {
            throw RuntimeError(token: `operator`, message: "Operand must be a number.")
        }
        return value
    }
    
    private func numberOperands(operator: Token, left: Any?, right: Any?) throws -> (Double, Double) {
        guard let left = left as? Double, let right = right as? Double else {
            throw RuntimeError(token: `operator`, message: "Operands must be two numbers.")
        }
        return (left, right)
    }
    
    private func isEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
        if lhs == nil && rhs == nil { return true }
        
        guard let lhs, let rhs else { return false }
        guard let lhs = lhs as? any Equatable, let rhs = rhs as? any Equatable else { return false }
        
        return lhs.isEqual(to: rhs)
    }
}

fileprivate extension Equatable {
    func isEqual(to other: any Equatable) -> Bool {
        guard let other = other as? Self else { return false }
        return self == other
    }
}
