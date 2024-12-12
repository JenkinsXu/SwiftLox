//
//  Scanner.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-04.
//

struct Scanner {
    private let source: String
    private var tokens: [Token] = []
    
    /// Points to the first character in the lexeme being scanned.
    private var startIndex: String.Index
    /// Points to the character currently being considered.
    private var currentIndex: String.Index
    /// Tracks what source line the current character is on.
    private var line: UInt = 1
    
    private var isAtEnd: Bool {
        currentIndex >= source.endIndex
    }
    
    var hadError = false
    
    init(source: String) {
        self.source = source
        self.startIndex = source.startIndex
        self.currentIndex = source.startIndex
    }
    
    mutating func scanTokens() -> (Bool, [Token]) {
        while !isAtEnd {
            startIndex = currentIndex
            scanToken()
        }
        
        tokens.append(Token(type: .eof, lexeme: "", literal: nil, line: line))
        return (hadError, tokens)
    }
    
    mutating func scanToken() {
        let character = advance()
        switch character {
        case "(": addToken(.leftParen)
        case ")": addToken(.rightParen)
        case "{": addToken(.leftBrace)
        case "}": addToken(.rightBrace)
        case ",": addToken(.comma)
        case ".": addToken(.dot)
        case "-": addToken(.minus)
        case "+": addToken(.plus)
        case ";": addToken(.semicolon)
        case "*": addToken(.star)
        case "!": addToken(match("=") ? .bangEqual : .bang)
        case "=": addToken(match("=") ? .equalEqual : .equal)
        case "<": addToken(match("=") ? .lessEqual : .less)
        case ">": addToken(match("=") ? .greaterEqual : .greater)
        case "/":
            if match("/") {
                while peek() != "\n" && !isAtEnd { // Use `peek()` to ensure that we don't consume the newline character.
                    advance()
                }
            } else {
                addToken(.slash)
            }
        case " ", "\r", "\t": break // Ignore whitespace.
        case "\n": line += 1
        case "\"": string()
        default:
            if isDigit(character) {
                number()
            } else if isAlpha(character) {
                identifier()
            } else {
                // Instead of throwing the error, we keep scanning, as there might be more errors.
                let error: Lox.Error = .unexpectedCharacter(character, line)
                hadError = true
                print(error.localizedDescription)
            }
        }
    }
    
    private mutating func identifier() {
        while isAlphaNumeric(peek()) { // maximal munch
            advance()
        }
        
        let text = String(source[startIndex..<currentIndex])
        let type = Token.TokenType(keyword: text)
        addToken(type)
    }
    
    private func isDigit(_ character: Character) -> Bool {
        character >= "0" && character <= "9"
    }
    
    private func isAlpha(_ character: Character) -> Bool {
        (character >= "a" && character <= "z") || (character >= "A" && character <= "Z") || character == "_"
    }
    
    private func isAlphaNumeric(_ character: Character) -> Bool {
        isAlpha(character) || isDigit(character)
    }
    
    private mutating func number() {
        while isDigit(peek()) {
            advance()
        }
        
        // Look for a fractional part.
        if peek() == "." && isDigit(peekNext()) {
            // Consume the "."
            advance()
            
            while isDigit(peek()) {
                advance()
            }
        }
        
        addToken(.number, literal: Double(source[startIndex..<currentIndex]))
    }
    
    private func peekNext() -> Character {
        if source.index(after: currentIndex) >= source.endIndex { return "\0" }
        return source[source.index(after: currentIndex)]
    }
    
    private mutating func string() {
        while peek() != "\"" && !isAtEnd {
            if peek() == "\n" { line += 1 }
            advance()
        }
        
        if isAtEnd {
            let error: Lox.Error = .untermindatedString(line)
            hadError = true
            print(error.localizedDescription)
            return
        }
        
        // The closing ".
        advance()
        
        // Trim the surrounding quotes.
        let value = String(source[source.index(after: startIndex)..<source.index(before: currentIndex)])
        addToken(.string, literal: value) // If support escape characters, we need to unescape them here.
    }
    
    /// Consume the current character if it matches the expected character.
    /// `match()` combines the functionality of `peek()` and `advance()`.
    private mutating func match(_ expected: Character) -> Bool {
        if isAtEnd { return false }
        if source[currentIndex] != expected { return false }
        
        currentIndex = source.index(after: currentIndex)
        return true
    }
    
    /// One character look ahead.
    private func peek() -> Character {
        if isAtEnd { return "\0" }
        return source[currentIndex]
    }
    
    @discardableResult
    private mutating func advance() -> Character {
        defer { currentIndex = source.index(after: currentIndex) }
        return source[currentIndex]
    }
    
    private mutating func addToken(_ type: Token.TokenType, literal: Any? = nil) {
        let text = String(source[startIndex..<currentIndex])
        tokens.append(Token(type: type, lexeme: text, literal: literal, line: line))
    }
}
