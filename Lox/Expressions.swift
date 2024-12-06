//
//  Expressions.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-06.
//

/// ```
/// expression     → literal
///                | unary
///                | binary
///                | grouping ;
///
/// literal        → NUMBER | STRING | "true" | "false" | "nil" ;
/// grouping       → "(" expression ")" ;
/// unary          → ( "-" | "!" ) expression ;
/// binary         → expression operator expression ;
/// operator       → "==" | "!=" | "<" | "<=" | ">" | ">="
///                | "+"  | "-"  | "*" | "/" ;
/// ```
protocol Expression {
    func accept<V: ExpressionVisitor>(_ visitor: V) -> V.Output
}

protocol ExpressionVisitor { // For grouping functionalities together
    associatedtype Output
    func visitBinary(_ binary: Binary) -> Output
    func visitGrouping(_ grouping: Grouping) -> Output
    func visitLiteral(_ literal: Literal) -> Output
    func visitUnary(_ unary: Unary) -> Output
}

struct Binary: Expression {
    let left: Expression
    let `operator`: Token
    let right: Expression
    
    func accept<V: ExpressionVisitor>(_ visitor: V) -> V.Output {
        visitor.visitBinary(self)
    }
}

struct Grouping: Expression {
    let expression: Expression
    
    func accept<V: ExpressionVisitor>(_ visitor: V) -> V.Output {
        visitor.visitGrouping(self)
    }
}

struct Literal: Expression {
    let value: Any?
    
    func accept<V: ExpressionVisitor>(_ visitor: V) -> V.Output {
        visitor.visitLiteral(self)
    }
}

struct Unary: Expression {
    let `operator`: Token
    let right: Expression
    
    func accept<V: ExpressionVisitor>(_ visitor: V) -> V.Output {
        visitor.visitUnary(self)
    }
}
