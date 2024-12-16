//
//  Expressions.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-06.
//

/// Properties of an expressions are what evaluators need to produce a value.
///
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
    func accept<V: ExpressionThrowingVisitor>(_ visitor: V) throws -> V.Output
}

protocol ExpressionVisitor { // For grouping functionalities together
    associatedtype Output
    func visitBinary(_ binary: Binary) -> Output
    func visitGrouping(_ grouping: Grouping) -> Output
    func visitLiteral(_ literal: Literal) -> Output
    func visitUnary(_ unary: Unary) -> Output
    func visitVariable(_ variable: Variable) -> Output
}

protocol ExpressionThrowingVisitor {
    associatedtype Output
    func visitBinary(_ binary: Binary) throws -> Output
    func visitGrouping(_ grouping: Grouping) throws -> Output
    func visitLiteral(_ literal: Literal) throws -> Output
    func visitUnary(_ unary: Unary) throws -> Output
    func visitVariable(_ variable: Variable) throws -> Output
}

struct Binary: Expression {
    let left: Expression
    let `operator`: Token
    let right: Expression
    
    func accept<V: ExpressionVisitor>(_ visitor: V) -> V.Output {
        visitor.visitBinary(self)
    }
    
    func accept<V: ExpressionThrowingVisitor>(_ visitor: V) throws -> V.Output {
        try visitor.visitBinary(self)
    }
}

struct Grouping: Expression {
    let expression: Expression
    
    func accept<V: ExpressionVisitor>(_ visitor: V) -> V.Output {
        visitor.visitGrouping(self)
    }
    
    func accept<V: ExpressionThrowingVisitor>(_ visitor: V) throws -> V.Output {
        try visitor.visitGrouping(self)
    }
}

struct Literal: Expression {
    let value: Any?
    
    func accept<V: ExpressionVisitor>(_ visitor: V) -> V.Output {
        visitor.visitLiteral(self)
    }
    
    func accept<V: ExpressionThrowingVisitor>(_ visitor: V) throws -> V.Output {
        try visitor.visitLiteral(self)
    }
}

struct Unary: Expression {
    let `operator`: Token
    let right: Expression
    
    func accept<V: ExpressionVisitor>(_ visitor: V) -> V.Output {
        visitor.visitUnary(self)
    }
    
    func accept<V: ExpressionThrowingVisitor>(_ visitor: V) throws -> V.Output {
        try visitor.visitUnary(self)
    }
}

struct Variable: Expression {
    let name: Token
    
    func accept<V: ExpressionVisitor>(_ visitor: V) -> V.Output {
        visitor.visitVariable(self)
    }
    
    func accept<V: ExpressionThrowingVisitor>(_ visitor: V) throws -> V.Output {
        try visitor.visitVariable(self)
    }
}
