//
//  Parser.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-09.
//

/// Just like a scanner, but a parser reads tokens instead.
///
/// ```
/// #Statements
///
/// program        → declaration* EOF ;
///
/// // requires this distinction because
/// // if (monday) var beverage = "espresso"; // invalid, confusing scope
/// declaration    → classDecl
///                | funDecl
///                | varDecl ;
///                | statement ; // the "higer" precedence statements, allowed in more places (fallthrough)
///
/// classDecl      → "class" IDENTIFIER ( "<" IDENTIFIER )?
///                  "{" function* "}" ;
/// funDecl        → "fun" function ;
/// function       → IDENTIFIER "(" parameters? ")" block ; // reused in class methods
/// parameters     → IDENTIFIER ( "," IDENTIFIER )* ;
///
/// varDecl        → "var" IDENTIFIER ( "=" expression )? ";" ;
///
/// statement      → exprStmt
///                | forStmt
///                | ifStmt
///                | printStmt
///                | returnStmt
///                | whileStmt
///                | block ;
///
/// forStmt        → "for" "(" ( varDecl | exprStmt | ";" ) expression? ";" expression? ")" statement ;
/// returnStmt     → "return" expression? ";" ; // default to nil for void functions
/// whileStmt      → "while" "(" expression ")" statement ;
/// ifStmt         → "if" "(" expression ")" statement ( "else" statement )? ;
/// block          → "{" declaration* "}" ;
/// exprStmt       → expression ";" ;
/// printStmt      → "print" expression ";" ;
/// ```
///
/// ```
/// # Expressions
///
/// expression     → assignment ;
/// assignment     → ( call "." )? IDENTIFIER "=" assignment
///                | logic_or ;
/// logical_or     → logical_and ( "or" logical_and )* ;
/// logical_and    → equality ( "and" equality )* ;
/// equality       → comparison ( ( "!=" | "==" ) comparison )* ;
/// comparison     → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
/// term           → factor ( ( "-" | "+" ) factor )* ;
/// factor         → unary ( ( "/" | "*" ) unary )* ;
/// unary          → ( "!" | "-" ) unary
///                | call ;
/// call           → primary ( "(" arguments? ")" | "." IDENTIFIER )* ;
/// arguments      → expression ( "," expression )* ;
/// primary        → NUMBER | STRING | "true" | "false" | "nil"
///                | "(" expression ")" | IDENTIFIER | "super" "." IDENTIFIER ; // We can't have super without properties.
/// ```
///
/// Goals of error handling (achieved with synchronization):
/// - Be fast.
/// - Report as many distinct errors as there are.
/// - Minimize cascaded errors.
///
struct Parser {
    typealias TokenType = Token.TokenType
    
    let tokens: [Token]
    var current = 0
    
    private var isAtEnd: Bool {
        peek().type == .eof
    }
    
    init(tokens: [Token]) {
        self.tokens = tokens
    }
    
    mutating func parse() -> [Statement] {
        var statements = [Statement]()
        while !isAtEnd {
            do {
                statements.append(try declaration())
            } catch {
                Lox.reportWithoutThrowing(error)
                synchronize() // Went into panic mode. Get back to trying to parse the next statement.
            }
        }
        
        return statements
    }
    
    private mutating func declaration() throws(Lox.Error) -> Statement {
        if match(.class) { return try classDeclaration() }
        if match(.fun) { return try functionDeclaration(ofKind: "function") }
        if match(.var) { return try varDeclaration() }
        return try statement()
    }
    
    private mutating func statement() throws(Lox.Error) -> Statement {
        if match(.print) { return try printStatement() }
        if match(.leftBrace) { return Block(statements: try block()) }
        if match(.if) { return try ifStatement() }
        if match(.return) { return try returnStatement() }
        if match(.while) { return try whileStatement() }
        if match(.for) { return try forStatement() }
        return try expressionStatement()
    }
    
    private mutating func returnStatement() throws(Lox.Error) -> ReturnStatement {
        let keyword = previous()
        var value: Expression?
        if !check(.semicolon) {
            value = try expression()
        }
        try consume(.semicolon, messageIfFailed: "Expect ';' after return value.")
        return ReturnStatement(keyword: keyword, value: value)
    }
    
    private mutating func classDeclaration() throws(Lox.Error) -> Class {
        let name = try consume(.identifier, messageIfFailed: "Expect class name.")
        
        var superclass: Variable? = nil
        if match(.less) {
            try consume(.identifier, messageIfFailed: "Expect superclass name.")
            superclass = Variable(name: previous())
        }
        
        try consume(.leftBrace, messageIfFailed: "Expect '{' before class body.")
        
        var methods = [FunctionStatement]()
        while !check(.rightBrace) && !isAtEnd {
            methods.append(try functionDeclaration(ofKind: "method") as! FunctionStatement)
        }
        
        try consume(.rightBrace, messageIfFailed: "Expect '}' after class body.")
        return Class(name: name, superclass: superclass, methods: methods)
    }
    
    private mutating func functionDeclaration(ofKind kind: String) throws(Lox.Error) -> Statement {
        let name = try consume(.identifier, messageIfFailed: "Expect \(kind) name.")
        try consume(.leftParen, messageIfFailed: "Expect '(' after \(kind) name.")
        var parameters = [Token]()
        if !check(.rightParen) {
            repeat {
                if parameters.count >= 255 {
                    Lox.reportWithoutThrowing(.parsingFailure(peek(), "Cannot have more than 255 parameters.")) // No need to go into panic mode.
                }
                parameters.append(try consume(.identifier, messageIfFailed: "Expect parameter name."))
            } while match(.comma)
        }
        try consume(.rightParen, messageIfFailed: "Expect ')' after parameters.")
        
        try consume(.leftBrace, messageIfFailed: "Expect '{' before \(kind) body.") // block() assumes that the left brace has been consumed.
        let body = try block()
        return FunctionStatement(name: name, parameters: parameters, body: body)
    }
    
    private mutating func varDeclaration() throws(Lox.Error) -> Statement {
        let name = try consume(.identifier, messageIfFailed: "Expect variable name.")
        
        var initializer: Expression?
        if match(.equal) {
            initializer = try expression()
        }
        
        try consume(.semicolon, messageIfFailed: "Expect ';' after variable declaration.")
        return VarStatement(name: name, initializer: initializer)
    }
    
    private mutating func printStatement() throws(Lox.Error) -> PrintStatement {
        let value = try expression()
        try consume(.semicolon, messageIfFailed: "Expect ';' after value.")
        return PrintStatement(expression: value)
    }
    
    private mutating func ifStatement() throws(Lox.Error) -> IfStatement {
        try consume(.leftParen, messageIfFailed: "Expect '(' after 'if'.")
        let condition = try expression()
        try consume(.rightParen, messageIfFailed: "Expect ')' after if condition.")
        
        let thenBranch = try statement()
        var elseBranch: Statement?
        if match(.else) {
            // The else is bound to the nearest if that precedes it to avoid the dangling else problem.
            elseBranch = try statement()
        }
        
        return IfStatement(condition: condition, thenBranch: thenBranch, elseBranch: elseBranch)
    }
    
    private mutating func whileStatement() throws(Lox.Error) -> WhileStatement {
        try consume(.leftParen, messageIfFailed: "Expect '(' after 'while'.")
        let condition = try expression()
        try consume(.rightParen, messageIfFailed: "Expect ')' after while condition.")
        
        let body = try statement()
        return WhileStatement(condition: condition, body: body)
    }
    
    /// Desugar the for loop into a while loop.
    private mutating func forStatement() throws(Lox.Error) -> Statement {
        try consume(.leftParen, messageIfFailed: "Expect '(' after 'for'.")
        
        var initializer: Statement?
        if match(.semicolon) {
            initializer = nil
        } else if match(.var) {
            initializer = try varDeclaration()
        } else {
            initializer = try expressionStatement()
        }
        
        var condition: Expression?
        if !check(.semicolon) { // Check if the clause is omitted.
            condition = try expression()
        }
        try consume(.semicolon, messageIfFailed: "Expect ';' after loop condition.")
        
        var increment: Expression?
        if !check(.rightParen) { // Check if the clause is omitted.
            increment = try expression()
        }
        try consume(.rightParen, messageIfFailed: "Expect ')' after for clauses.")
        
        var body = try statement()
        
        // Desugar the for loop into a while loop.
        if let increment {
            body = Block(statements: [body, ExpressionStatement(expression: increment)])
        }
        
        if condition == nil {
            condition = Literal(value: true)
        }
        
        body = WhileStatement(condition: condition!, body: body)
        
        if let initializer {
            body = Block(statements: [initializer, body])
        }
        
        return body
    }
    
    private mutating func block() throws(Lox.Error) -> [Statement] {
        var statements = [Statement]()
        
        while !check(.rightBrace) && !isAtEnd {
            statements.append(try declaration())
        }
        
        try consume(.rightBrace, messageIfFailed: "Expect '}' after block.")
        return statements
    }
    
    private mutating func expressionStatement() throws(Lox.Error) -> ExpressionStatement {
        let value = try expression()
        try consume(.semicolon, messageIfFailed: "Expect ';' after expression.")
        return ExpressionStatement(expression: value)
    }
    
    /// Check for the current token type and advance if it matches any of the types.
    /// This is usually used to check for an optional token. For required tokens, use `consume(_:messageIfFailed:)` instead.
    /// Note that the matching token will be consumed, so please use `previous()` to get the token.
    private mutating func match(_ types: TokenType...) -> Bool {
        for type in types {
            if check(type) {
                advance()
                return true
            }
        }
        return false
    }
    
    /// Check if the current token type matches any of the types.
    /// Essentailly a `peek()` that checks for types.
    private func check(_ type: TokenType) -> Bool {
        if isAtEnd {
            return false
        }
        return peek().type == type
    }
    
    @discardableResult
    private mutating func advance() -> Token {
        if !isAtEnd {
            current += 1
        }
        return previous()
    }
    
    private func peek() -> Token {
        tokens[current]
    }
    
    private func previous() -> Token {
        tokens[current - 1]
    }
    
    private mutating func expression() throws(Lox.Error) -> Expression {
        return try assignment()
    }
    
    private mutating func assignment() throws(Lox.Error) -> Expression {
        // The left-hand side of the assignment isn't an expression that evaluates to a value. We don't evaluate `a` in `a = 1`.
        // Other expressions produce r-values.
        // An l-value "evaluates" to a storage location that you can assign to.
        // A single token of lookahead is not enough for cases like
        // `makeList().head.next = node;`
        let expression = try logicalOr()
        
        if match(.equal) {
            let equals = previous()
            let value = try assignment() // Right-associative.
            
            if let variable = expression as? Variable {
                let name = variable.name // Convert r-value to l-value.
                return Assign(name: name, value: value)
            } else if let get = expression as? Get {
                return SetExpression(object: get.object, name: get.name, value: value)
            }
            
            Lox.reportWithoutThrowing(.parsingFailure(equals, "Invalid assignment target.")) // No need to go into panic mode.
        }
        
        return expression
    }
    
    private mutating func logicalOr() throws(Lox.Error) -> Expression {
        var expression = try logicalAnd()
        
        while match(.or) {
            let `operator` = previous()
            let right = try logicalAnd()
            expression = Logical(left: expression, operator: `operator`, right: right)
        }
        
        return expression
    }
    
    private mutating func logicalAnd() throws(Lox.Error) -> Expression {
        var expression = try equality()
        
        while match(.and) {
            let `operator` = previous()
            let right = try equality()
            expression = Logical(left: expression, operator: `operator`, right: right)
        }
        
        return expression
    }
    
    // equality → comparison ( ( "!=" | "==" ) comparison )* ;
    private mutating func equality() throws(Lox.Error) -> Expression {
        var expression = try comparison()
        
        while match(.bangEqual, .equalEqual) {
            let `operator` = previous()
            let right = try comparison()
            expression = Binary(left: expression, operator: `operator`, right: right)
        }
        
        return expression
    }
    
    private mutating func comparison() throws(Lox.Error) -> Expression {
        var expression = try term()
        
        while match(.greater, .greaterEqual, .less, .lessEqual) {
            let `operator` = previous()
            let right = try term()
            expression = Binary(left: expression, operator: `operator`, right: right)
        }
        
        return expression
    }
    
    private mutating func term() throws(Lox.Error) -> Expression {
        var expression = try factor()
        
        while match(.minus, .plus) {
            let `operator` = previous()
            let right = try factor()
            expression = Binary(left: expression, operator: `operator`, right: right)
        }
        
        return expression
    }
    
    private mutating func factor() throws(Lox.Error) -> Expression {
        var expression = try unary()
        
        while match(.slash, .star) {
            let `operator` = previous()
            let right = try unary()
            expression = Binary(left: expression, operator: `operator`, right: right)
        }
        
        return expression
    }
    
    private mutating func unary() throws(Lox.Error) -> Expression {
        if match(.bang, .minus) {
            let `operator` = previous()
            let right = try unary()
            return Unary(operator: `operator`, right: right)
        }
        
        return try call()
    }
    
    private mutating func call() throws(Lox.Error) -> Expression {
        var expression = try primary() // The callee initially.
        
        while true {
            if match(.leftParen) {
                expression = try finishCall(expression)
            } else if match(.dot) {
                let name = try consume(.identifier, messageIfFailed: "Expect property name after '.'.")
                expression = Get(object: expression, name: name)
            } else {
                break
            }
        }
        
        return expression
    }
    
    private mutating func finishCall(_ callee: Expression) throws(Lox.Error) -> Expression {
        var arguments = [Expression]()
        if !check(.rightParen) {
            repeat {
                if arguments.count >= 255 {
                    throw .parsingFailure(peek(), "Cannot have more than 255 arguments.")
                }
                arguments.append(try expression())
            } while match(.comma)
        }
        
        let paren = try consume(.rightParen, messageIfFailed: "Expect ')' after arguments.")
        return Call(callee: callee, paren: paren, arguments: arguments)
    }
    
    private mutating func primary() throws(Lox.Error) -> Expression {
        if match(.false) {
            return Literal(value: false)
        }
        if match(.true) {
            return Literal(value: true)
        }
        if match(.nil) {
            return Literal(value: nil)
        }
        
        if match(.number, .string) {
            return Literal(value: previous().literal)
        }
        
        if match(.super) {
            let keyword = previous()
            try consume(.dot, messageIfFailed: "Expect '.' after 'super'.")
            let method = try consume(.identifier, messageIfFailed: "Expect superclass method name.")
            return Super(keyword: keyword, method: method)
        }
        
        if match(.this) {
            return This(keyword: previous())
        }
        
        if match(.identifier) {
            return Variable(name: previous())
        }
        
        if match(.leftParen) {
            let expression = try expression()
            if !match(.rightParen) {
                try consume(.rightParen, messageIfFailed: "Expect ')' after expression.")
            }
            return Grouping(expression: expression)
        }
        
        throw .parsingFailure(peek(), "Expect expression.")
    }
    
    /// Essentailly an `advance()` with a type check.
    @discardableResult
    private mutating func consume(_ type: TokenType, messageIfFailed message: String) throws(Lox.Error) -> Token {
        if check(type) {
            return advance()
        }
        
        let error = Lox.Error.parsingFailure(peek(), message)
        print(error.localizedDescription)
        throw error
    }
    
    /// https://chatgpt.com/share/675a6d6b-6978-8009-9d16-a8adc9531653
    private mutating func synchronize() {
        advance()
        
        // Discards tokens until it finds a statement boundary.
        while !isAtEnd {
            // If the previous token is a semicolon, we have found a statement boundary.
            if previous().type == .semicolon {
                return
            }
            
            switch peek().type {
            case .class, .fun, .var, .for, .if, .while, .print, .return:
                // If the current token is a statement keyword, we have found a statement boundary.
                return
            default:
                // Otherwise, keep discarding tokens.
                advance()
            }
        }
    }
}
