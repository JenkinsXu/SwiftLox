//
//  Statements.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-15.
//

/// There is no place in the grammar where both an expression and a statement are allowed.
/// Since the two syntaxes are disjoint, we don't need a single base class that they all inherit from.
protocol Statement { // Commonly written as "Stmt"
    func accept<V: StatementThrowingVisitor>(_ visitor: V) throws
}

protocol StatementThrowingVisitor {
    func visitExpressionStatement(_ statement: ExpressionStatement) throws
    func visitPrintStatement(_ statement: PrintStatement) throws
}

struct ExpressionStatement: Statement {
    let expression: Expression
    
    func accept<V: StatementThrowingVisitor>(_ visitor: V) throws {
        try visitor.visitExpressionStatement(self)
    }
}

struct PrintStatement: Statement {
    let expression: Expression
    
    func accept<V: StatementThrowingVisitor>(_ visitor: V) throws {
        try visitor.visitPrintStatement(self)
    }
}
