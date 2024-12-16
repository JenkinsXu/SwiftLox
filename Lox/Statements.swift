//
//  Statements.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-15.
//

/// There is no place in the grammar where both an expression and a statement are allowed.
/// Since the two syntaxes are disjoint, we don't need a single base class that they all inherit from.
///
/// ```
/// program        → declaration* EOF ;
///
/// // requires this distinction because
/// // if (monday) var beverage = "espresso"; // invalid, confusing scope
/// declaration    → varDecl
///                | statement ; // the "higer" precedence statements, allowed in more places (fallthrough)
///
/// varDecl        → "var" IDENTIFIER ( "=" expression )? ";" ;
///
/// statement      → exprStmt
///                | printStmt
///                | block ;
///
/// block          → "{" declaration* "}" ;
/// exprStmt       → expression ";" ;
/// printStmt      → "print" expression ";" ;
/// ```
protocol Statement { // Commonly written as "Stmt"
    func accept<V: StatementThrowingVisitor>(_ visitor: V) throws
}

protocol StatementThrowingVisitor {
    func visitExpressionStatement(_ statement: ExpressionStatement) throws
    func visitPrintStatement(_ statement: PrintStatement) throws
    func visitVarStatement(_ statement: VarStatement) throws
    func visitBlock(_ block: Block) throws
}

struct Block: Statement {
    let statements: [Statement]
    
    func accept<V: StatementThrowingVisitor>(_ visitor: V) throws {
        for statement in statements {
            try statement.accept(visitor)
        }
    }
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

struct VarStatement: Statement {
    let name: Token
    let initializer: Expression?
    
    func accept<V: StatementThrowingVisitor>(_ visitor: V) throws {
        try visitor.visitVarStatement(self)
    }
}
