//
//  Interpreter+Statement.swift
//  Lox
//
//  Created by Yongqi Xu on 2024-12-17.
//

extension Interpreter: StatementThrowingVisitor {
    func visitExpressionStatement(_ statement: ExpressionStatement) throws {
        try evaluate(statement.expression)
    }
    
    func visitPrintStatement(_ statement: PrintStatement) throws {
        let value = try evaluate(statement.expression)
        print(stringify(value))
    }
    
    func visitVarStatement(_ statement: VarStatement) throws {
        var value: Any? = nil
        if let initializer = statement.initializer {
            value = try evaluate(initializer)
        }
        
        // This makes the following possible
        // var a;
        // print a; // nil
        environment.define(statement.name.lexeme, value)
    }
    
    func visitBlock(_ block: Block) throws {
        try executeBlock(block.statements, Environment(enclosing: self.environment))
    }
    
    private func executeBlock(_ statements: [Statement], _ environment: Environment) throws {
        let previous = self.environment
        defer { self.environment = previous }
        
        self.environment = environment
        for statement in statements {
            try execute(statement)
        }
    }
    
    func visitIfStatement(_ statement: IfStatement) throws {
        if isTruthy(try evaluate(statement.condition)) {
            try execute(statement.thenBranch)
        } else if let elseBranch = statement.elseBranch {
            try execute(elseBranch)
        }
    }
    
    func visitWhileStatement(_ statement: WhileStatement) throws {
        while isTruthy(try evaluate(statement.condition)) {
            try execute(statement.body)
        }
    }
}
