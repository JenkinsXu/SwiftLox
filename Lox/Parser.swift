//
//  Parser.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-09.
//

// Just like a scanner, but a parser reads tokens instead.
/// ```
/// expression     → assignment ;
/// assignment     → IDENTIFIER "=" assignment
///                | equality ;
/// equality       → comparison ( ( "!=" | "==" ) comparison )* ;
/// comparison     → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
/// term           → factor ( ( "-" | "+" ) factor )* ;
/// factor         → unary ( ( "/" | "*" ) unary )* ;
/// unary          → ( "!" | "-" ) unary
///                | primary ;
/// primary        → NUMBER | STRING | "true" | "false" | "nil"
///                | "(" expression ")" | IDENTIFIER ;
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
    
    mutating func parse() -> [Statement]? {
        var statements = [Statement]()
        while !isAtEnd {
            do {
                statements.append(try declaration())
            } catch {
                // Went into panic mode. Get back to trying to parse the next statement.
                synchronize()
            }
        }
        
        return statements.isEmpty ? nil : statements
    }
    
    private mutating func declaration() throws(Lox.Error) -> Statement {
        return match(.var) ? try varDeclaration() : try statement()
    }
    
    private mutating func statement() throws(Lox.Error) -> Statement {
        if match(.print) { return try printStatement() }
        if match(.leftBrace) { return try block() }
        if match(.if) { return try ifStatement() }
        return try expressionStatement()
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
    
    private mutating func block() throws(Lox.Error) -> Block {
        var statements = [Statement]()
        
        while !check(.rightBrace) && !isAtEnd {
            statements.append(try declaration())
        }
        
        try consume(.rightBrace, messageIfFailed: "Expect '}' after block.")
        return Block(statements: statements)
    }
    
    private mutating func expressionStatement() throws(Lox.Error) -> ExpressionStatement {
        let value = try expression()
        try consume(.semicolon, messageIfFailed: "Expect ';' after expression.")
        return ExpressionStatement(expression: value)
    }
    
    /// Check for the current token type and advance if it matches any of the types.
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
        let expression = try equality()
        
        if match(.equal) {
            let equals = previous()
            let value = try assignment() // Right-associative.
            
            if let variable = expression as? Variable {
                let name = variable.name // Convert r-value to l-value.
                return Assign(name: name, value: value)
            }
            
            throw .parsingFailure(equals, "Invalid assignment target.")
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
        
        return try primary()
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
