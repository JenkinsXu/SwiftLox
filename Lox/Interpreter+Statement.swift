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
        environment.define(name: statement.name.lexeme, value: value)
    }
    
    func visitClassStatement(_ statement: Class) throws {
        // TODO: The two-stage variable binding process allows references to the class inside its own methods.
        environment.define(name: statement.name.lexeme, value: nil)
        
        let methods = Dictionary(uniqueKeysWithValues: statement.methods.map { method in
            (method.name.lexeme, LoxFunction(declaration: method, closure: environment, isInitializer: method.name.lexeme == "init"))
        })
        
        let `class` = LoxClass(name: statement.name.lexeme, methods: methods)
        try environment.assign(statement.name, `class`)
    }
    
    func visitBlockStatement(_ block: Block) throws {
        try executeBlock(block.statements, Environment(enclosedBy: self.environment))
    }
    
    func executeBlock(_ statements: [Statement], _ environment: Environment) throws {
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
    
    func visitFunctionStatement(_ statement: FunctionStatement) throws {
        let function = LoxFunction(declaration: statement, closure: environment, isInitializer: false)
        environment.define(name: statement.name.lexeme, value: function) // compile-time representation to runtime representation
    }
    
    func visitReturnStatement(_ statement: ReturnStatement) throws {
        var returnValue: Any? = nil
        if let valueExpression = statement.value {
            returnValue = try evaluate(valueExpression)
        }
        throw ReturnValue(value: returnValue)
    }
}
