//
//  main.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-04.
//

import Foundation

Lox.main()

/* Test ASTPrinter
let expression = Binary(
    left: Unary(
        operator: Token(type: .minus, lexeme: "-", literal: nil, line: 1),
        right: Literal(value: 123)),
    operator: Token(type: .star, lexeme: "*", literal: nil, line: 1),
    right: Grouping(
        expression: Literal(value: 45.67)
    )
)

print(ASTPrinter().print(expression))
*/
