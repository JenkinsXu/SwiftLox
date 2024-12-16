//
//  Parser.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-09.
//

// Just like a scanner, but a parser reads tokens instead.
/// ```
/// expression     → equality ;
/// equality       → comparison ( ( "!=" | "==" ) comparison )* ;
/// comparison     → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
/// term           → factor ( ( "-" | "+" ) factor )* ;
/// factor         → unary ( ( "/" | "*" ) unary )* ;
/// unary          → ( "!" | "-" ) unary
///                | primary ;
/// primary        → NUMBER | STRING | "true" | "false" | "nil"
///                | "(" expression ")" ;
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
                statements.append(try statement())
            } catch {
                // synchronize()
            }
        }
        
        return statements.isEmpty ? nil : statements
    }
    
    private mutating func statement() throws -> Statement {
        if match(.print) {
            return try printStatement()
        } else {
            return try expressionStatement()
        }
    }
    
    private mutating func printStatement() throws(Lox.Error) -> PrintStatement {
        let value = try expression()
        try consume(.semicolon, messageIfFailed: "Expect ';' after value.")
        return PrintStatement(expression: value)
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
        return try equality()
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
