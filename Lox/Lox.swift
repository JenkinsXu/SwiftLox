//
//  Lox.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-04.
//

import Foundation

public struct Lox {
    private static var interpreter = Interpreter()
    
    enum Error: Swift.Error {
        case invalidArgument
        case unexpectedCharacter(Character, UInt)
        case untermindatedString(UInt)
        case parsingFailure(Token, String)
        
        // TODO: Find correct exit codes.
        var exitCode: Int32 {
            switch self {
            case .invalidArgument:
                return 64
            case .unexpectedCharacter:
                return 64
            case .untermindatedString:
                return 64
            case .parsingFailure:
                return 64
            }
        }
        
        var localizedDescription: String {
            switch self {
            case .invalidArgument:
                return "Error: Invalid argument."
            case .unexpectedCharacter(let character, let lineNumber):
                return "Error: Unexpected character \"\(character)\" at line \(lineNumber)."
            case .untermindatedString(let lineNumber):
                return "Error: Unterminated string at line \(lineNumber)."
            case .parsingFailure(let token, let message):
                return "Error: \(message) at line \(token.line)."
            }
        }
    }
    
    public static func main() {
        do {
            let arguments = CommandLine.arguments
            if arguments.count > 2 {
                print("Usage: slox [script]")
            } else if arguments.count == 2 {
                // To test in Xcode, choose the Lox-File scheme,
                // then change the path in "Edit Scheme" -> "Arguments Passed On Launch"
                try runFile(arguments[1])
            } else {
                try runPrompt()
            }
        } catch {
            print(error.localizedDescription)
            exit((error as? Error)?.exitCode ?? 1)
        }
    }
    
    private static func runFile(_ path: String) throws {
        let source = try String(contentsOfFile: path, encoding: .utf8)
        run(source)
    }

    private static func runPrompt() throws {
        var line = readLine()
        while line != nil {
            run(line!)
            line = readLine()
        }
    }

    private static func run(_ source: String) {
        var scanner = Scanner(source: source)
        let (hadError, tokens) = scanner.scanTokens()
        
        var parser = Parser(tokens: tokens)
        let statements = parser.parse()
        
        guard !hadError, let statements else { return }
        
        do {
            try interpreter.interpret(statements)
        } catch {
            print(error.localizedDescription)
            exit((error as? Interpreter.RuntimeError)?.exitCode ?? 1)
        }
    }
}
