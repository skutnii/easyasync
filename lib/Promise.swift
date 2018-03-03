//
//  Promise.swift
//  EasySwift
//
//  Created by Serge Kutny on 1/25/18.
//  Copyright © 2018 skutnii. All rights reserved.
//

import Foundation

infix operator &&&: MultiplicationPrecedence
infix operator |||: AdditionPrecedence

public class Promise<T>  {
    
    public enum State {
        case pending
        case fulfilled
        case rejected
    }
    
    private var _state: State = .pending
    public private(set) var state: State  {
        get {
            return _state
        }
        
        set(aState) {
            guard .pending == _state else {
                return
            }
            
            _state = aState
            
            if .fulfilled == state {
                while fulfillCallbacks.count > 0 {
                    let callback = fulfillCallbacks.remove(at: 0)
                    callback(value!)
                }
                
                rejectCallbacks.removeAll()
            }
            
            if .rejected == state {
                while rejectCallbacks.count > 0 {
                    let callback = rejectCallbacks.remove(at: 0)
                    callback(rejectReason)
                }
                
                fulfillCallbacks.removeAll()
            }

        }
        
    }
    
    public private(set) var rejectReason: Any?
    public private(set) var value: T?
    
    private var fulfillCallbacks = [(T) -> ()]()
    private var rejectCallbacks = [(Any?) -> ()]()
    
    public func resolve(_ value: T) {
        guard state == .pending else {
            return
        }
        
        self.value = value
        state = .fulfilled
    }
    
    public func reject(_ reason: Any?) {
        guard state == .pending else {
            return
        }
        
        rejectReason = reason
        state = .rejected
    }
    
    public func chain(after promise: Promise<T>) {
        guard state == .pending else {
            return
        }
        
        promise.then({
            value in
            self.resolve(value)
        }, {
            reason in
            self.reject(reason)
        })
    }
    
    public func then(_ onSuccess: ((T) throws -> ())?, _ onFailure: ((Any?) -> ())? = nil) {
        guard .rejected != state else {
            onFailure?(self.rejectReason)
            return
        }
        
        let callback = {
            (value: T) -> () in
            do {
                try onSuccess?(value)
            } catch {
                onFailure?(error)
            }
        }
        
        guard .fulfilled != state else {
            callback(value!)
            return
        }
        
        fulfillCallbacks.append(callback)
        
        rejectCallbacks.append {
            reason in
            onFailure?(reason)
        }
    }
    
    public func then<O>(async onSuccess: @escaping (T) throws -> Promise<O>) -> Promise<O> {
        let next = Promise<O>()
        self.then({
            (value: T) -> () in
            let deferred = try onSuccess(value)
            next.chain(after: deferred)
        }, {
            reason in
            next.reject(reason)
        })
        
        return next
    }
    
    public func then<O>(_ onSuccess: @escaping (T) throws -> O) -> Promise<O> {
        let next = Promise<O>()
        self.then({
            (value: T) -> () in
            let nextValue = try onSuccess(value)
            next.resolve(nextValue)
        }, {
            reason in
            next.reject(reason)
        })
        
        return next
    }
    
    public func rescue<E>(_ onError: @escaping (E) -> ()) {
        self.then(nil, {
            reason in
            guard reason is E else {
                return
            }
            
            onError(reason as! E)
        })
    }
    
    public func rescue<E, O>(_ onError: @escaping (E) throws -> O) -> Promise<O> {
        let next = Promise<O>()
        self.then(nil, {
            reason in
            guard reason is E else {
                next.reject(reason)
                return
            }
            
            do {
                let value = try onError(reason as! E)
                next.resolve(value)
            } catch {
                next.reject(error)
            }
        })
        
        return next
    }
    
    public func rescue<E, O>(async onError: @escaping (E) throws -> Promise<O>) -> Promise<O> {
        let next = Promise<O>()
        self.then(nil, {
            reason in
            guard reason is E else {
                next.reject(reason)
                return
            }
            
            do {
                let deferred = try onError(reason as! E)
                next.chain(after: deferred)
            } catch {
                next.reject(error)
            }
        })
        
        return next
    }
    
    public typealias Discarder = () -> ()
    private var _discard: Discarder?
    
    public typealias Initializer = (@escaping (T) -> (), @escaping (Any?) -> ()) -> ()
    public convenience init(_ initializer: @escaping Initializer) {
        self.init()
        
        DispatchQueue.main.async {
            initializer(self.resolve, self.reject)
        }
    }
    
    public convenience init(discard block: @escaping Discarder) {
        self.init()
        _discard = block
    }
    
    public enum Rejection {
        case discarded
    }
    
    public func discard() {
        guard .pending == state else {
            return
        }
        
        self.reject(Rejection.discarded)
        _discard?()
    }
    
    public class func resolve(_ value: T) -> Promise<T> {
        let promise = Promise<T>()
        promise.resolve(value)
        return promise
    }
    
    public class func reject(_ reason: Any?) -> Promise<T> {
        let promise = Promise<T>()
        promise.reject(reason)
        return promise
    }
    
    public static func &&&<V>(left: Promise<T>, right: V) -> Promise<(T, V)> {
        let promise = Promise<(T, V)>()
        left.then({
            value in
            promise.resolve((value, right))
        }, {
            reason in
            promise.reject(reason)
        })
        
        return promise
    }

    public static func &&&<V>(left: V, right: Promise<T>) -> Promise<(V, T)> {
        let promise = Promise<(V, T)>()
        right.then({
            value in
            promise.resolve((left, value))
        }, {
            reason in
            promise.reject(reason)
        })
        
        return promise
    }

}

public func &&&<V1, V2>(left: Promise<V1>, right: Promise<V2>) -> Promise<(V1, V2)> {
    let promise = Promise<(V1, V2)>()
    var values: (V1?, V2?) = (nil, nil)
    var counter = 0
    func incrementCounter() {
        counter += 1
        if 2 == counter {
            let (value1, value2) = values
            promise.resolve((value1!, value2!))
        }
    }
    
    left.then {
        value in
        values.0 = value
        incrementCounter()
    } .rescue {
        reason in
        promise.reject(reason)
    }
    
    right.then {
        value in
        values.1 = value
        incrementCounter()
    } .rescue {
        reason  in
        promise.reject(reason)
    }
    
    return promise
}

public func |||<V1, V2>(left: Promise<V1>, right: Promise<V2>) -> Promise<Any> {
    let promise = Promise<Any>()
    var errors: (Any?, Any?) = (nil, nil)
    var counter = 0
    func incrementCounter() {
        counter += 1
        if 2 == counter {
            promise.reject(errors)
        }
    }
    
    left.then {
        value in
        promise.resolve(value)
    } .rescue {
        (reason: Any?) in
        errors.0 = reason
        incrementCounter()
    }
    
    right.then {
        value in
        promise.resolve(value)
    } .rescue {
        (reason: Any?) in
        errors.1 = reason
        incrementCounter()
    }
    
    return promise
}

