//
//  ASTPrinter.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-06.
//

struct ASTPrinter: ExpressionVisitor {
    typealias Output = String
    
    func print(_ expression: Expression) -> String {
        return expression.accept(self)
    }
    
    func parenthesize(_ name: String, _ expressions: Expression...) -> String {
        var result = "(\(name)"
        for expression in expressions {
            result += " \(expression.accept(self))"
        }
        result += ")"
        return result
    }
    
    func visitBinary(_ binary: Binary) -> String {
        parenthesize(binary.operator.lexeme, binary.left, binary.right)
    }
    
    func visitGrouping(_ grouping: Grouping) -> String {
        parenthesize("group", grouping.expression)
    }
    
    func visitLiteral(_ literal: Literal) -> String {
        if let value = literal.value {
            return "\(value)"
        } else {
            return "nil"
        }
    }
    
    func visitUnary(_ unary: Unary) -> String {
        parenthesize(unary.operator.lexeme, unary.right)
    }
    
    func visitVariable(_ variable: Variable) -> String {
        variable.name.lexeme
    }
    
    func visitAssign(_ assign: Assign) -> String {
        parenthesize("assign \(assign.name.lexeme)", assign.value)
    }
    
    func visitLogical(_ logical: Logical) -> String {
        parenthesize(logical.operator.lexeme, logical.left, logical.right)
    }
    
    func visitCall(_ call: Call) -> String {
        parenthesize("call \(call.callee)") // TODO: Include arguments.
    }
    
    func visitGet(_ get: Get) -> String {
        parenthesize("get \(get.object).\(get.name)")
    }
    
    func visitSet(_ set: SetExpression) -> String {
        parenthesize("set \(set.object).\(set.name)", set.value)
    }
}
