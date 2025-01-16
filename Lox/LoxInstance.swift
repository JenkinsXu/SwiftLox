//
//  LoxInstance.swift
//  Lox
//
//  Created by Yongqi Xu on 2025-01-16.
//

struct LoxInstance: CustomStringConvertible {
    let `class`: LoxClass
    
    // MARK: CustomStringConvertible
    var description: String {
        `class`.name + " instance"
    }
}
