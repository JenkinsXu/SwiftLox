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
        return try environment.get(variable.name)
    }
    
    func visitAssign(_ assign: Assign) throws -> Output {
        let value = try evaluate(assign.value)
        try environment.assign(assign.name, value)
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
