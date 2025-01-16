//
//  Statements.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-15.
//

/// There is no place in the grammar where both an expression and a statement are allowed.
/// Since the two syntaxes are disjoint, we don't need a single base class that they all inherit from.
protocol Statement { // Commonly written as "Stmt"
    func accept<V: StatementVisitor>(_ visitor: V)
    func accept<V: StatementThrowingVisitor>(_ visitor: V) throws
}

protocol StatementVisitor {
    func visitExpressionStatement(_ statement: ExpressionStatement)
    func visitPrintStatement(_ statement: PrintStatement)
    func visitFunctionStatement(_ statement: FunctionStatement)
    func visitVarStatement(_ statement: VarStatement)
    func visitBlockStatement(_ statement: Block)
    func visitClassStatement(_ statement: Class)
    func visitIfStatement(_ statement: IfStatement)
    func visitWhileStatement(_ statement: WhileStatement)
    func visitReturnStatement(_ statement: ReturnStatement)
}

protocol StatementThrowingVisitor {
    func visitExpressionStatement(_ statement: ExpressionStatement) throws
    func visitPrintStatement(_ statement: PrintStatement) throws
    func visitFunctionStatement(_ statement: FunctionStatement) throws
    func visitVarStatement(_ statement: VarStatement) throws
    func visitBlockStatement(_ statement: Block) throws
    func visitClassStatement(_ statement: Class) throws
    func visitIfStatement(_ statement: IfStatement) throws
    func visitWhileStatement(_ statement: WhileStatement) throws
    func visitReturnStatement(_ statement: ReturnStatement) throws
}

struct Block: Statement {
    let statements: [Statement]
    
    func accept<V: StatementVisitor>(_ visitor: V) {
        visitor.visitBlockStatement(self)
    }
    
    func accept<V: StatementThrowingVisitor>(_ visitor: V) throws {
        try visitor.visitBlockStatement(self)
    }
}

struct Class: Statement {
    let name: Token
    let methods: [FunctionStatement]
    
    func accept<V: StatementVisitor>(_ visitor: V) {
        visitor.visitClassStatement(self)
    }
    
    func accept<V: StatementThrowingVisitor>(_ visitor: V) throws {
        try visitor.visitClassStatement(self)
    }
}

struct ExpressionStatement: Statement {
    let expression: Expression
    
    func accept<V: StatementVisitor>(_ visitor: V) {
        visitor.visitExpressionStatement(self)
    }
    
    func accept<V: StatementThrowingVisitor>(_ visitor: V) throws {
        try visitor.visitExpressionStatement(self)
    }
}

struct IfStatement: Statement {
    let condition: Expression
    let thenBranch: Statement
    let elseBranch: Statement?
    
    func accept<V: StatementVisitor>(_ visitor: V) {
        visitor.visitIfStatement(self)
    }
    
    func accept<V: StatementThrowingVisitor>(_ visitor: V) throws {
        try visitor.visitIfStatement(self)
    }
}

struct PrintStatement: Statement {
    let expression: Expression
    
    func accept<V: StatementVisitor>(_ visitor: V) {
        visitor.visitPrintStatement(self)
    }
    
    func accept<V: StatementThrowingVisitor>(_ visitor: V) throws {
        try visitor.visitPrintStatement(self)
    }
}

/// This is a syntax structure. For runtime, see `LoxFunction`.
struct FunctionStatement: Statement {
    let name: Token
    let parameters: [Token]
    let body: [Statement]
    
    func accept<V: StatementVisitor>(_ visitor: V) {
        visitor.visitFunctionStatement(self)
    }
    
    func accept<V: StatementThrowingVisitor>(_ visitor: V) throws {
        try visitor.visitFunctionStatement(self)
    }
}

struct VarStatement: Statement {
    let name: Token
    let initializer: Expression?
    
    func accept<V: StatementVisitor>(_ visitor: V) {
        visitor.visitVarStatement(self)
    }
    
    func accept<V: StatementThrowingVisitor>(_ visitor: V) throws {
        try visitor.visitVarStatement(self)
    }
}

struct WhileStatement: Statement {
    let condition: Expression
    let body: Statement
    
    func accept<V: StatementVisitor>(_ visitor: V) {
        visitor.visitWhileStatement(self)
    }
    
    func accept<V: StatementThrowingVisitor>(_ visitor: V) throws {
        try visitor.visitWhileStatement(self)
    }
}

struct ReturnStatement: Statement {
    let keyword: Token // The return token, used for error reporting.
    let value: Expression?
    
    func accept<V: StatementVisitor>(_ visitor: V) {
        visitor.visitReturnStatement(self)
    }
    
    func accept<V: StatementThrowingVisitor>(_ visitor: V) throws {
        try visitor.visitReturnStatement(self)
    }
}
