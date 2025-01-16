//
//  Expressions.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-06.
//

/// Properties of an expressions are what evaluators need to produce a value.
/// Expressions are requried to be hashable because the interpreter uses them as keys in `locals`.
class Expression: Hashable {
    func accept<V: ExpressionVisitor>(_ visitor: V) -> V.Output {
        fatalError("Subclasses must override this method.")
    }
    
    func accept<V: ExpressionThrowingVisitor>(_ visitor: V) throws -> V.Output {
        fatalError("Subclasses must override this method.")
    }

    static func == (lhs: Expression, rhs: Expression) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

protocol ExpressionVisitor { // For grouping functionalities together
    associatedtype Output
    func visitBinary(_ binary: Binary) -> Output
    func visitGrouping(_ grouping: Grouping) -> Output
    func visitLiteral(_ literal: Literal) -> Output
    func visitUnary(_ unary: Unary) -> Output
    func visitVariable(_ variable: Variable) -> Output
    func visitAssign(_ assign: Assign) -> Output
    func visitLogical(_ logical: Logical) -> Output
    func visitCall(_ call: Call) -> Output
    func visitGet(_ get: Get) -> Output
    func visitSet(_ set: SetExpression) -> Output
}

protocol ExpressionThrowingVisitor {
    associatedtype Output
    func visitBinary(_ binary: Binary) throws -> Output
    func visitGrouping(_ grouping: Grouping) throws -> Output
    func visitLiteral(_ literal: Literal) throws -> Output
    func visitUnary(_ unary: Unary) throws -> Output
    func visitVariable(_ variable: Variable) throws -> Output
    func visitAssign(_ assign: Assign) throws -> Output
    func visitLogical(_ logical: Logical) throws -> Output
    func visitCall(_ call: Call) throws -> Output
    func visitGet(_ get: Get) throws -> Output
    func visitSet(_ set: SetExpression) throws -> Output
}

class Assign: Expression {
    let name: Token
    let value: Expression
    
    init(name: Token, value: Expression) {
        self.name = name
        self.value = value
    }
    
    override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.Output {
        visitor.visitAssign(self)
    }
    
    override func accept<V: ExpressionThrowingVisitor>(_ visitor: V) throws -> V.Output {
        try visitor.visitAssign(self)
    }
}

class Binary: Expression {
    let left: Expression
    let `operator`: Token
    let right: Expression
    
    init(left: Expression, operator: Token, right: Expression) {
        self.left = left
        self.operator = `operator`
        self.right = right
    }
    
    override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.Output {
        visitor.visitBinary(self)
    }
    
    override func accept<V: ExpressionThrowingVisitor>(_ visitor: V) throws -> V.Output {
        try visitor.visitBinary(self)
    }
}

class Grouping: Expression {
    let expression: Expression
    
    init(expression: Expression) {
        self.expression = expression
    }
    
    override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.Output {
        visitor.visitGrouping(self)
    }
    
    override func accept<V: ExpressionThrowingVisitor>(_ visitor: V) throws -> V.Output {
        try visitor.visitGrouping(self)
    }
}

class Literal: Expression {
    let value: Any?
    
    init(value: Any?) {
        self.value = value
    }
    
    override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.Output {
        visitor.visitLiteral(self)
    }
    
    override func accept<V: ExpressionThrowingVisitor>(_ visitor: V) throws -> V.Output {
        try visitor.visitLiteral(self)
    }
}

/// Essentially the same fields as Binary. Separated to handle short-circuiting.
class Logical: Expression {
    let left: Expression
    let `operator`: Token
    let right: Expression
    
    init(left: Expression, operator: Token, right: Expression) {
        self.left = left
        self.operator = `operator`
        self.right = right
    }
    
    override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.Output {
        visitor.visitLogical(self)
    }
    
    override func accept<V: ExpressionThrowingVisitor>(_ visitor: V) throws -> V.Output {
        try visitor.visitLogical(self)
    }
}

class SetExpression: Expression {
    let object: Expression
    let name: Token
    let value: Expression
    
    init(object: Expression, name: Token, value: Expression) {
        self.object = object
        self.name = name
        self.value = value
    }
    
    override func accept<V>(_ visitor: V) -> V.Output where V : ExpressionVisitor {
        visitor.visitSet(self)
    }
    
    override func accept<V>(_ visitor: V) throws -> V.Output where V : ExpressionThrowingVisitor {
        try visitor.visitSet(self)
    }
}

class Unary: Expression {
    let `operator`: Token
    let right: Expression
    
    init(`operator`: Token, right: Expression) {
        self.operator = `operator`
        self.right = right
    }
    
    override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.Output {
        visitor.visitUnary(self)
    }
    
    override func accept<V: ExpressionThrowingVisitor>(_ visitor: V) throws -> V.Output {
        try visitor.visitUnary(self)
    }
}

class Variable: Expression {
    let name: Token
    
    init(name: Token) {
        self.name = name
    }
    
    override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.Output {
        visitor.visitVariable(self)
    }
    
    override func accept<V: ExpressionThrowingVisitor>(_ visitor: V) throws -> V.Output {
        try visitor.visitVariable(self)
    }
}

class Call: Expression {
    let callee: Expression
    let paren: Token // Token for the closing parenthesis. Used for error reporting.
    let arguments: [Expression]
    
    init(callee: Expression, paren: Token, arguments: [Expression]) {
        self.callee = callee
        self.paren = paren
        self.arguments = arguments
    }
    
    override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.Output {
        visitor.visitCall(self)
    }
    
    override func accept<V: ExpressionThrowingVisitor>(_ visitor: V) throws -> V.Output {
        try visitor.visitCall(self)
    }
}

class Get: Expression {
    let object: Expression
    let name: Token
    
    init(object: Expression, name: Token) {
        self.object = object
        self.name = name
    }
    
    override func accept<V>(_ visitor: V) -> V.Output where V : ExpressionVisitor {
        visitor.visitGet(self)
    }
    
    override func accept<V>(_ visitor: V) throws -> V.Output where V : ExpressionThrowingVisitor {
        try visitor.visitGet(self)
    }
}
