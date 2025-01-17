//
//  Resolver.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-18.
//

/// If we can ensure a variable lookup always
/// walked the same number of links in the environment chain,
/// that would ensure that it found the same variable in the
/// same scope every time.
///
/// In the C Version, it would be implemented by the parser.
/// Optimization and type-checking would be done in similar time
/// (as they are work that doesn't rely on state that's only available at runtime).
///
/// A static analysis is different from a dynamic execution.
/// - There are no side effects.
/// - There is no control flow. All branches are taken once.
///
/// Only a few kinds of nodes are interesting to the resolver:
/// - A block statement introduces a new scope.
/// - A function declaration introduces a new scope and binds its parameters in that scope.
/// - A variable declaration binds a variable in the current scope.
/// - Variable & assignment expressions need to have their variables resolved.
///
/// We may also handle some checks here, like checking if a `break` is inside a loop (not implemented).
class Resolver {
    private let interpreter: Interpreter
    
    /// The stack of scopes.
    ///
    /// Each element represents a single block scope.
    /// - The scope stacks are only used for local block scopes.
    /// - If we can't find a variable in the current scope,
    /// - we assume it must be a global variable.
    ///
    /// Keys, as in the environment, are variable names.
    ///
    /// Values are `true` for fully initialized variables.
    var scopes: [Dictionary<String, Bool>] = []
    
    var currentFunctionType: FunctionType = .none
    enum FunctionType {
        case none
        case function
        case initializer // To prevent `init() { return "something else" }`.
        case method
    }
    
    var currentClassType: ClassType = .none
    enum ClassType {
        case none
        case `class`
        case subclass
    }
    
    init(interpreter: Interpreter) {
        self.interpreter = interpreter
    }
    
    func resolve(statements: [Statement]) {
        for statement in statements {
            resolve(statement: statement)
        }
    }
    
    /// Similar to `evaluate(_:)`.
    private func resolve(statement: Statement) {
        statement.accept(self)
    }
    
    /// Similar to `execute(_:)`.
    private func resolve(expression: Expression) {
        expression.accept(self)
    }
}

extension Resolver: ExpressionVisitor {
    typealias Output = Void
    
    func visitVariable(_ variable: Variable) {
        if !scopes.isEmpty, let initialized = scopes.last?[variable.name.lexeme], !initialized {
            // Example: `var a = a;`
            Lox.reportWithoutThrowing(.resolutionFailure(variable.name, "Cannot read local variable in its own initializer."))
        }
        
        resolveLocal(variable, withName: variable.name)
    }
    
    func visitAssign(_ assign: Assign) {
        resolve(expression: assign.value)
        resolveLocal(assign, withName: assign.name)
    }
    
    private func resolveLocal(_ expression: Expression, withName name: Token) {
        for (depth, scope) in scopes.reversed().enumerated() {
            if scope.keys.contains(name.lexeme) {
                interpreter.resolve(expression: expression, depth: depth)
                return
            }
        }
    }
    
    func visitBinary(_ binary: Binary) {
        resolve(expression: binary.left)
        resolve(expression: binary.right)
    }
    
    func visitCall(_ call: Call) {
        resolve(expression: call.callee)
        for argument in call.arguments {
            resolve(expression: argument)
        }
    }
    
    func visitGet(_ get: Get) {
        resolve(expression: get.object) // Since properties are looked up dynamically, they don't get resolved
    }
    
    func visitSet(_ set: SetExpression) {
        resolve(expression: set.value)
        resolve(expression: set.object) // Since properties are looked up dynamically, they don't get resolved
    }
    
    func visitSuper(_ super: Super) {
        if currentClassType == .none {
            Lox.reportWithoutThrowing(.resolutionFailure(`super`.keyword, "Can't use 'super' outside of a class."))
        } else if currentClassType != .subclass {
            Lox.reportWithoutThrowing(.resolutionFailure(`super`.keyword, "Can't use 'super' in a class with no superclass."))
        }
        
        resolveLocal(`super`, withName: `super`.keyword)
    }
    
    func visitThis(_ this: This) {
        guard currentClassType != .none else {
            Lox.reportWithoutThrowing(.resolutionFailure(this.keyword, "Can't use 'this' outside of a class."))
            return
        }
        resolveLocal(this, withName: this.keyword)
    }
    
    func visitGrouping(_ grouping: Grouping) {
        resolve(expression: grouping.expression)
    }
    
    func visitLiteral(_ literal: Literal) {}
    
    func visitLogical(_ logical: Logical) {
        resolve(expression: logical.left)
        resolve(expression: logical.right)
    }
    
    func visitUnary(_ unary: Unary) {
        resolve(expression: unary.right)
    }
}

extension Resolver: StatementVisitor {
    func visitClassStatement(_ class: Class) {
        let enclosingClassType = currentClassType
        currentClassType = .class
        
        declare(name: `class`.name)
        define(name: `class`.name)
        
        if let superclass = `class`.superclass {
            if `class`.name.lexeme == superclass.name.lexeme {
                Lox.reportWithoutThrowing(.resolutionFailure(superclass.name, "A class can't inherit from itself."))
            }
            
            currentClassType = .subclass
            
            resolve(expression: superclass)
        }
        
        if `class`.superclass != nil {
            beginScope()
            scopes[scopes.count - 1]["super"] = true
        }
        
        beginScope()
        scopes[scopes.count - 1]["this"] = true // Declare before resolution.
        for method in `class`.methods {
            resolveFunction(method, ofType: method.name.lexeme == "init" ? .initializer : .method)
        }
        endScope()
        
        if `class`.superclass != nil {
            endScope()
        }
        
        currentClassType = enclosingClassType
    }
    
    func visitBlockStatement(_ block: Block) {
        beginScope()
        resolve(statements: block.statements)
        endScope()
    }
    
    private func beginScope() {
        scopes.append([:])
    }
    
    private func endScope() {
        _ = scopes.popLast()
    }
    
    /// We split binding into two steps: declaration and definition, in order to handle edge cases like:
    /// ```
    /// var a = "global";
    /// {
    ///     var a = a;
    /// }
    /// ```
    /// As we visit expressions, we need to know if we're inside the initializer for some variable.
    func visitVarStatement(_ statement: VarStatement) {
        declare(name: statement.name)
        if let initializer = statement.initializer {
            resolve(expression: initializer)
        }
        define(name: statement.name)
    }
    
    private func declare(name: Token) {
        guard !scopes.isEmpty else { return }
        if scopes[scopes.count - 1].keys.contains(name.lexeme) {
            Lox.reportWithoutThrowing(.resolutionFailure(name, "Variable with this name already declared in this scope."))
        }
        scopes[scopes.count - 1][name.lexeme] = false
    }
    
    private func define(name: Token) {
        guard !scopes.isEmpty else { return }
        scopes[scopes.count - 1][name.lexeme] = true
    }
    
    func visitFunctionStatement(_ statement: FunctionStatement) {
        declare(name: statement.name)
        define(name: statement.name)
        resolveFunction(statement, ofType: .function)
    }
    
    /// `type` is used to prevent top-level return statements. See `visitReturnStatement(_:)` for details.
    private func resolveFunction(_ statement: FunctionStatement, ofType type: FunctionType) {
        let enclosingFunctionType = currentFunctionType
        currentFunctionType = type
        
        beginScope()
        for parameter in statement.parameters {
            declare(name: parameter)
            define(name: parameter)
        }
        resolve(statements: statement.body)
        endScope()
        
        currentFunctionType = enclosingFunctionType
    }
    
    func visitExpressionStatement(_ statement: ExpressionStatement) {
        resolve(expression: statement.expression)
    }
    
    func visitIfStatement(_ statement: IfStatement) {
        resolve(expression: statement.condition)
        resolve(statement: statement.thenBranch)
        if let elseBranch = statement.elseBranch {
            resolve(statement: elseBranch)
        }
    }
    
    func visitPrintStatement(_ statement: PrintStatement) {
        resolve(expression: statement.expression)
    }
    
    func visitReturnStatement(_ statement: ReturnStatement) {
        guard currentFunctionType != .none else {
            Lox.reportWithoutThrowing(.resolutionFailure(statement.keyword, "Cannot return from top-level code."))
            return
        }
        
        if let value = statement.value {
            // We only prevent returning in initializer when there is a value. `return;` is still allowed.
            if currentFunctionType == .initializer {
                Lox.reportWithoutThrowing(.resolutionFailure(statement.keyword, "Can't return a value from an initializer."))
            }
            
            resolve(expression: value)
        }
    }
    
    func visitWhileStatement(_ statement: WhileStatement) {
        resolve(expression: statement.condition)
        resolve(statement: statement.body)
    }
}

