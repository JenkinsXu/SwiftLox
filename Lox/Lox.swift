//
//  Lox.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-04.
//

import Foundation

public struct Lox {
    enum ExecutionError: Error {
        case invalidArgument
        case unexpectedCharacter(UInt)
        case untermindatedString(UInt)
        
        // TODO: Find correct exit codes.
        var exitCode: Int32 {
            switch self {
            case .invalidArgument:
                return 64
            case .unexpectedCharacter:
                return 64
            case .untermindatedString:
                return 64
            }
        }
        
        var localizedDescription: String {
            switch self {
            case .invalidArgument:
                return "Error: Invalid argument."
            case .unexpectedCharacter(let lineNumber):
                return "Error: Unexpected character at line \(lineNumber)."
            case .untermindatedString(let lineNumber):
                return "Error: Unterminated string at line \(lineNumber)."
            }
        }
    }
    
    public static func main() {
        do {
            let arguments = CommandLine.arguments
            if arguments.count > 2 {
                print("Usage: slox [script]")
            } else if arguments.count == 2 {
                try runFile(arguments[1])
            } else {
                try runPrompt()
            }
        } catch {
            print(error.localizedDescription)
            exit((error as? ExecutionError)?.exitCode ?? 1)
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
        let tokens = scanner.scanTokens()
        
        // TODO: Make sure to check for errors. Consider returning the errors as well.
        // Or do we even want to keep track of all the errors? As we are already reporting them. Maybe just a boolean?
        
        for token in tokens {
            print(token)
        }
    }
}
