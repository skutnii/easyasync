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

public class Promise<ValueType>  {
    
    public enum State {
        case pending
        case fulfilled
        case rejected
    }
    
    //Thread safety
    private var _lock = Synchronizer()
    
    /// Promise state
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
    public private(set) var value: ValueType?
    
    private var fulfillCallbacks = [(ValueType) -> ()]()
    private var rejectCallbacks = [(Any?) -> ()]()
    
    public func resolve(_ value: ValueType) {
        _lock.synchronized {
            guard state == .pending else {
                return
            }
            
            self.value = value
            state = .fulfilled
        }
    }
    
    public func reject(_ reason: Any?) {
        _lock.synchronized {
            guard state == .pending else {
                return
            }
            
            rejectReason = reason
            state = .rejected
        }
    }
    
    /// Chain the promise after another, so that it will get resolved/rejected when the argument is resolved/rejected
    ///
    /// - Parameter promise: the promise to chin after
    public func chain(after promise: Promise<ValueType>) {
        _lock.synchronized {
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
    }
    
    /// Basic `then` method that adds success/error handlers. The handlers are stored by the promise to be executed upon resolve/reject
    ///
    /// - Parameters:
    ///   - onSuccess: success handler to be executed when the promise is fulfilled
    ///   - onFailure: reject handler to be executed when the promise is rejected
    public func then(_ onSuccess: ((ValueType) throws -> ())?, _ onFailure: ((Any?) -> ())? = nil) {
        _lock.synchronized {
            guard .rejected != state else {
                onFailure?(self.rejectReason)
                return
            }
            
            let callback = {
                (value: ValueType) -> () in
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
    }
    
    /// Add a handler block to be executed anyway, whether the callee is resolved or rejected
    ///
    /// - Parameter handler: the handler
    /// - Returns: a promise to be resolved with the handler's return value
    public func anyway<OutType>(_ handler: @escaping (ValueType?) throws -> OutType) -> Promise<OutType> {
        let resultPromise = Promise<OutType>()
        
        let wrappedHandler = {
            (result: ValueType?) in
            do {
                resultPromise.resolve(try handler(result))
            } catch {
                resultPromise.reject(error)
            }
        }
        
        then({
            result in
            wrappedHandler(result)
        }, {
            _ in
            wrappedHandler(nil)
        })
        
        return resultPromise
    }

    /// Add an asynchronous handler block to be executed anyway, whether the callee is resolved or rejected
    ///
    /// - Parameter handler: the handler
    /// - Returns: a promise to be chained after with the handler's return value
    public func anyway<OutType>(async handler: @escaping (ValueType?) throws -> Promise<OutType>) -> Promise<OutType> {
        let resultPromise = Promise<OutType>()
        
        let wrappedHandler = {
            (result: ValueType?) in
            do {
                resultPromise.chain(after: try handler(result))
            } catch {
                resultPromise.reject(error)
            }
        }
        
        then({
            result in
            wrappedHandler(result)
        }, {
            _ in
            wrappedHandler(nil)
        })
        
        return resultPromise
    }
    
    /// Add an asynchronous fulfilment handler (i.e. handler returning a promise).
    ///
    /// - Parameter onSuccess: the handler
    /// - Returns: a promise. When the callee gets fulfilled, `onSuccess` is fired and `then` return value is chained after the one of the handlers
    public func then<OutType>(async onSuccess: @escaping (ValueType) throws -> Promise<OutType>) -> Promise<OutType> {
        let next = Promise<OutType>()
        self.then({
            (value: ValueType) -> () in
            let deferred = try onSuccess(value)
            next.chain(after: deferred)
        }, {
            reason in
            next.reject(reason)
        })
        
        return next
    }
    
    /// Add a synchronous fulfilment handler
    ///
    /// - Parameter onSuccess: the handler to be fired when the callee is fulfilled
    /// - Returns: a promise that will be resolved with the handler's return value
    public func then<OutType>(_ onSuccess: @escaping (ValueType) throws -> OutType) -> Promise<OutType> {
        let next = Promise<OutType>()
        self.then({
            (value: ValueType) -> () in
            let nextValue = try onSuccess(value)
            next.resolve(nextValue)
        }, {
            reason in
            next.reject(reason)
        })
        
        return next
    }
    
    /// Basic rescue method. Add a rejection handler.
    ///
    /// - Parameter onError: handler to be executed when the callee is rejected with the reason of `ErrorType`
    public func rescue<ErrorType>(_ onError: @escaping (ErrorType) -> ()) {
        self.then(nil, {
            reason in
            guard reason is ErrorType else {
                return
            }
            
            onError(reason as! ErrorType)
        })
    }
    
    /// Add an `OutType`-returning rejection handler
    ///
    /// - Parameter onError: the handler to be executed when the callee is rejected with the reason of `ErrorType`
    /// - Returns: a promise, that will be fulfilled with the handler's return value if the handler is fired
    public func rescue<ErrorType, OutType>(_ onError: @escaping (ErrorType) throws -> OutType) -> Promise<OutType> {
        let next = Promise<OutType>()
        self.then(nil, {
            reason in
            guard reason is ErrorType else {
                next.reject(reason)
                return
            }
            
            do {
                let value = try onError(reason as! ErrorType)
                next.resolve(value)
            } catch {
                next.reject(error)
            }
        })
        
        return next
    }
    
    /// Add an asynchronous `Promise<OutType>`-returning rejection handler
    ///
    /// - Parameter onError: the handler to be executed when the callee is rejected with the reason of `ErrorType`
    /// - Returns: a promise, that will be chained after the handler's return value if the handler is fired
    public func rescue<ErrorType, OutType>(async onError: @escaping (ErrorType) throws -> Promise<OutType>) -> Promise<OutType> {
        let next = Promise<OutType>()
        self.then(nil, {
            reason in
            guard reason is ErrorType else {
                next.reject(reason)
                return
            }
            
            do {
                let deferred = try onError(reason as! ErrorType)
                next.chain(after: deferred)
            } catch {
                next.reject(error)
            }
        })
        
        return next
    }
    
    public typealias Discarder = () -> ()
    private var _discard: Discarder?
    
    ///Convenience asynchronous initializer
    public typealias Initializer = (@escaping (ValueType) -> (), @escaping (Any?) -> ()) -> ()
    public convenience init(_ initializer: @escaping Initializer) {
        self.init()
        
        DispatchQueue.main.async {
            initializer(self.resolve, self.reject)
        }
    }
    
    /// Initialize the promise with a discard block
    ///
    /// - Parameter block: the block that will be called when the promise is discarded (see `discard()`).
    /// The block is supposed to cancel the underlying asynchronous operations
    public convenience init(discard block: @escaping Discarder) {
        self.init()
        _discard = block
    }
    
    public enum Rejection {
        case discarded
    }
    
    /// Discard the promise
    public func discard() {
        _lock.synchronized {
            guard .pending == state else {
                return
            }
            
            self.reject(Rejection.discarded)
            _discard?()
        }
    }
    
    /// Convenience method for creating a resolved promise
    ///
    /// - Parameter value: value to resolve the promise with.
    /// - Returns: a promise resolved with `value`
    public class func resolve(_ value: ValueType) -> Promise<ValueType> {
        let promise = Promise<ValueType>()
        promise.resolve(value)
        return promise
    }
    
    /// Convenience method for creating a rejected promise
    ///
    /// - Parameter reason: reason to reject the promise with.
    /// - Returns: a promise rejected with `reson`
    public class func reject(_ reason: Any?) -> Promise<ValueType> {
        let promise = Promise<ValueType>()
        promise.reject(reason)
        return promise
    }
    
    /// "Promise and a value" operator
    ///
    /// - Parameters:
    ///   - left: a promise
    ///   - right: a value
    /// - Returns: a promise to be fulfilled with (left.value!, value) tuple upon `left` fulfilment
    public static func &&&<OtherValueType>(left: Promise<ValueType>, right: OtherValueType) -> Promise<(ValueType, OtherValueType)> {
        let promise = Promise<(ValueType, OtherValueType)>()
        left.then({
            value in
            promise.resolve((value, right))
        }, {
            reason in
            promise.reject(reason)
        })
        
        return promise
    }

    /// "Value and a promise" operator
    ///
    /// - Parameters:
    ///   - left: a value
    ///   - right: a promise
    /// - Returns: a promise to be resolved with (value, right.value!) tuple upon `right` resolution
    public static func &&&<OtherValueType>(left: OtherValueType, right: Promise<ValueType>) -> Promise<(OtherValueType, ValueType)> {
        let promise = Promise<(OtherValueType, ValueType)>()
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

/// Promise "and" operator
///
/// - Parameters:
///   - left:  a promise
///   - right: another promise
/// - Returns: a promise that will be fulfilled with `(left.value!, right.value!)` tuple when both are fulfilled.
public func &&&<Value1, Value2>(left: Promise<Value1>, right: Promise<Value2>) -> Promise<(Value1, Value2)> {
    let promise = Promise<(Value1, Value2)>()
    var values: (Value1?, Value2?) = (nil, nil)
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

/// Promise "or" operator
///
/// - Parameters:
///   - left:  a promise
///   - right: another promise
/// - Returns: a promise that will be fulfilled with value of the first promise to fulfill.
public func |||<Value1, Value2>(left: Promise<Value1>, right: Promise<Value2>) -> Promise<Any> {
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

