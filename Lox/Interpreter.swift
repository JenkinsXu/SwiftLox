//
//  Interpreter.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-12.
//

/// Does a post-order traversal - each node evaluates its children before doing its own work.
class Interpreter {
    private var environment = Environment()
    
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
    
    private func execute(_ statement: Statement) throws {
        try statement.accept(self)
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
    
    @discardableResult
    private func evaluate(_ expression: Expression) throws -> Any? {
        try expression.accept(self)
    }
}

// MARK: - Expressions

extension Interpreter: ExpressionThrowingVisitor {
    typealias Output = Any?
    
    func visitLiteral(_ literal: Literal) throws -> Output {
        literal.value
    }
    
    func visitGrouping(_ grouping: Grouping) throws -> Output {
        try evaluate(grouping.expression)
    }
    
    func visitUnary(_ unary: Unary) throws -> Output {
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

// MARK: - Statements

extension Interpreter: StatementThrowingVisitor {
    func visitExpressionStatement(_ statement: ExpressionStatement) throws {
        try evaluate(statement.expression)
    }
    
    func visitPrintStatement(_ statement: PrintStatement) throws {
        let value = try evaluate(statement.expression)
        print(stringify(value))
    }
    
    func visitVarStatement(_ statement: VarStatement) throws {
        var value: Any? = nil
        if let initializer = statement.initializer {
            value = try evaluate(initializer)
        }
        
        // This makes the following possible
        // var a;
        // print a; // nil
        environment.define(statement.name.lexeme, value)
    }
    
    func visitBlock(_ block: Block) throws {
        try executeBlock(block.statements, Environment(enclosing: self.environment))
    }
    
    private func executeBlock(_ statements: [Statement], _ environment: Environment) throws {
        let previous = self.environment
        defer { self.environment = previous }
        
        self.environment = environment
        for statement in statements {
            try execute(statement)
        }
    }
    
    func visitIfStatement(_ statement: IfStatement) throws {
        if isTruthy(try evaluate(statement.condition)) {
            try execute(statement.thenBranch)
        } else if let elseBranch = statement.elseBranch {
            try execute(elseBranch)
        }
    }
    
    func visitWhileStatement(_ statement: WhileStatement) throws {
        while isTruthy(try evaluate(statement.condition)) {
            try execute(statement.body)
        }
    }
}
