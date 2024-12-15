//
//  Interpreter.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-12.
//

/// Does a post-order traversal - each node evaluates its children before doing its own work.
struct Interpreter: ExpressionThrowingVisitor {
    typealias Output = Any?
    
    struct RuntimeError: Error {
        let token: Token
        let message: String
        let exitCode: Int32 = 70
        
        var localizedDescription: String {
            "RuntimeError: \(message) at line \(token.line)."
        }
    }
    
    func interpret(_ expression: Expression) throws {
        let value = try evaluate(expression)
        print(stringify(value))
    }
    
    private func stringify(_ value: Any?) -> String {
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
    
    func visitLiteral(_ literal: Literal) throws -> Output {
        literal.value
    }
    
    func visitGrouping(_ grouping: Grouping) throws -> Output {
        try evaluate(grouping.expression)
    }
    
    func visitUnary(_ unary: Unary) throws -> Any? {
        let right = try evaluate(unary.right)
        switch unary.operator.type {
        case .minus:
            if let right = right as? Double {
                return -right
            }
        case .bang:
            return !isTruthy(right)
        default:
            break
        }
        return nil
    }
    
    func visitBinary(_ binary: Binary) throws -> Any? {
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
    
    private func evaluate(_ expression: Expression) throws -> Any? {
        try expression.accept(self)
    }
    
    /// Lox follows Ruby's rule: only `false` and `nil` are falsey.
    private func isTruthy(_ value: Any?) -> Bool {
        if let value = value as? Bool {
            return value
        }
        return value != nil
    }
}

fileprivate extension Equatable {
    func isEqual(to other: any Equatable) -> Bool {
        guard let other = other as? Self else { return false }
        return self == other
    }
}
