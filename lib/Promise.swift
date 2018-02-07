//
//  Promise.swift
//  EasySwift
//
//  Created by Serge Kutny on 1/25/18.
//  Copyright © 2018 skutnii. All rights reserved.
//

import Foundation

public protocol Thenable {
    associatedtype Value
    func then<O, E>(_ onSuccess: ((Value) throws -> O)?, _ onError: ((E) throws -> O)?) -> Promise<O>
}

public class Promise<T> : Thenable {
    
    public enum State {
        case pending
        case fulfilled
        case rejected
    }
    
    private var resolveCallbacks = [(T) -> ()]()
    private var rejectCallbacks = [(Any?) -> ()]()
    
    public private(set) var state: State = .pending
    public private(set) var result: T? {
        didSet {
            if (nil != result) {
                state = .fulfilled
                for onResolve in resolveCallbacks {
                    onResolve(result!)
                }
            }
        }
    }
    
    public private(set) var rejectionReason: Any? {
        didSet {
            if (nil != rejectionReason) {
                state = .rejected
                for onReject in rejectCallbacks {
                    onReject(rejectionReason)
                }
            }
        }
    }
    
    public func resolve(_ value: T) {
        do {
            
        } catch {
            reject(error)
        }
    }
    
    public func reject(_ reason: Any?) {
        
    }
    
    enum TypeError : Error {
        case rescueMismatch
        case typeMismatch
    }
    
    public func then<O, E>(_ onSuccess: ((T) throws -> O)? = nil, _ onError: ((E) throws -> O)? = nil) -> Promise<O> {
        let next =  Promise<O>()
        let onFulfilled = {
            (value: T) -> () in
            do {
                guard nil != onSuccess else {
                    guard value is O else {
                        throw TypeError.typeMismatch
                    }
                    
                    next.resolve(value as! O)
                    return
                }
                
                let nextValue = try onSuccess!(value)
                next.resolve(nextValue)
            } catch {
                next.reject(error)
            }
        }
        
        let onRejected = {
            (reason: Any?) -> () in
            do {
                guard reason is E else {
                    throw TypeError.rescueMismatch
                }
                
                guard nil != onError else {
                    next.reject(reason)
                    return
                }
                
                let nextValue = try onError!(reason as! E)
                next.resolve(nextValue)
            } catch TypeError.rescueMismatch {
                next.reject(reason)
            } catch {
                next.reject(error)
            }
        }

        if State.pending == state {
            resolveCallbacks.append(onFulfilled)
            rejectCallbacks.append(onRejected)
        } else if (State.fulfilled == state) {
            onFulfilled(result!)
        } else {
            onRejected(rejectionReason)
        }
        
        return next
    }
    

}
