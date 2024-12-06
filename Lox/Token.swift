//
//  Token.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-05.
//

struct Token: CustomStringConvertible {
    let type: TokenType
    let lexeme: String
    let literal: Any?
    let line: UInt
    
    var description: String {
        "\(type) \(lexeme) \(literal ?? "")"
    }
}

extension Token {
    enum TokenType {
        // Single-character tokens.
        case leftParen
        case rightParen
        case leftBrace
        case rightBrace
        case comma
        case dot
        case minus
        case plus
        case semicolon
        case slash
        case star
        
        // One or two character tokens.
        case bang
        case bangEqual
        case equal
        case equalEqual
        case greater
        case greaterEqual
        case less
        case lessEqual
        
        // Literals.
        case identifier
        case string
        case number
        
        // Keywords.
        case and
        case `class`
        case `else`
        case `false`
        case `fun`
        case `for`
        case `if`
        case `nil`
        case `or`
        case `print`
        case `return`
        case `super`
        case `this`
        case `true`
        case `var`
        case `while`
        
        case eof
        
        static let keywords: [String: TokenType] = [
            "and": .and,
            "class": .class,
            "else": .else,
            "false": .false,
            "fun": .fun,
            "for": .for,
            "if": .if,
            "nil": .nil,
            "or": .or,
            "print": .print,
            "return": .return,
            "super": .super,
            "this": .this,
            "true": .true,
            "var": .var,
            "while": .while
        ]
        
        init(keyword: String) {
            self = TokenType.keywords[keyword] ?? .identifier
        }
    }
}
