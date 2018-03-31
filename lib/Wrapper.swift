//
//  Wrapper.swift
//  EasySwift
//
//  Created by Serge Kutny on 3/31/18.
//  Copyright © 2018 skutnii. All rights reserved.
//

import Foundation

infix operator <<<: AssignmentPrecedence
infix operator >>>: AssignmentPrecedence
prefix operator **

///A generic wrapper class
class Wrapper<Value> {
    var value: Value
    
    init(_ value: Value) {
        self.value = value
    }
    
    static func <<< (left: Wrapper<Value>, right: Value) {
        left.value = right
    }
    
    static func <<< (left: inout Value, right: Wrapper<Value>) {
        left = right.value
    }
    
    static func >>> (left: Wrapper<Value>, right: inout Value) {
        right = left.value
    }
    
    static func >>> (left: Value, right: Wrapper<Value>) {
        right.value = left
    }
    
    static prefix func **(_ wrapper: Wrapper<Value>) -> Value {
        return wrapper.value
    }
}
