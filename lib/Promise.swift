//
//  Promise.swift
//  EasySwift
//
//  Created by Serge Kutny on 1/25/18.
//  Copyright © 2018 skutnii. All rights reserved.
//

import Foundation


class Promise {

    typealias Handler = (Any?) throws -> Any?

    private var _main : Handler
    private var _rescue: Promise?
    private var _next: Promise?
    
    private init(main: @escaping Handler) {
        _main = main
    }
    
    convenience init() {
        self.init(main: { res in return res })
    }
    
    private func chain(_ next: Promise?) -> Promise {
        guard nil != _next else {
            _next = next
            return _next!
        }
        
        return _next!.chain(next)
    }
    
    private func next(value: Any?) -> Any? {
        do {
            
            let result = try _main(value)
            let deferred = result as? Promise
            guard nil == deferred else {
                return deferred!.chain(_next)
            }
            
            guard nil != _next else {
                return result
            }
            
            return _next!.next(value:result)
        } catch {
            reject(error)
            return nil
        }
    }
    
    func resolve(_ value: Any?) {
        _ = next(value: value)
    }
    
    func reject(_ error: Any?) {
        if (nil != _rescue) {
            _rescue!.resolve(error)
            return
        }
        
        if (nil != _next) {
            _next!.reject(error)
            return
        }
        
        var description = "Unknown error"
        if (nil != error as? String) {
            description = error as! String
        }
        
        print("\(description) uncaught in promise")
    }
    
    func then(_ block: @escaping Handler) -> Promise {
        return self.chain(Promise(main:block))
    }
    
    func rescue(_ block: @escaping Handler) -> Promise {
        _rescue = Promise(main:block)
        return _rescue!
    }
    
    typealias Resolver = (Any?) -> ()
    convenience init(_ block: @escaping (@escaping Resolver, @escaping Resolver) ->()) {
        self.init()
        DispatchQueue.main.async {
            block(self.resolve, self.reject)
        }
    }
    
    class func resolve(_ res: Any?) -> Promise {
        return Promise {
            resolve, reject in
            resolve(res)
        }
    }
    
    class func reject(_ res: Any?) -> Promise {
        return Promise {
            resolve, reject in
            reject(res)
        }
    }
    
    class func all(_ promises: [Promise]) -> Promise {
        guard promises.count > 0 else {
            return Promise.resolve(true)
        }
        
        class Semaphore {
            let max : Int

            var resolved : Int = 0
            var rejected: Bool = false
            
            var results = [Any]()
            
            init(_ count: Int) {
                max = count
            }
        }
        
        let semaphore = Semaphore(promises.count)
        let combo = Promise()
        
        promises.forEach {
            promise in
            _ = promise.then {
                result in
                if (!semaphore.rejected) {
                    if (nil != result) {
                        semaphore.results.append(result!)
                    }
                    
                    semaphore.resolved += 1
                    if (semaphore.resolved == semaphore.max) {
                        combo.resolve(semaphore.results)
                    }
                }
                
                return result
            } .rescue {
                error in
                if (!semaphore.rejected) {
                    semaphore.rejected = true
                    combo.reject(error)
                }
                
                return error
            }
        }
        
        return combo
    }
    
    class func race(_ promises: [Promise]) -> Promise {
        guard promises.count > 0 else {
            return Promise.resolve(true)
        }
        
        class Semaphore {
            var resolved = false
            var rejected: Int = 0
            let max: Int
            
            var errors = [Any]()
            init(_ count: Int) {
                max = count
            }
        }
        
        let semaphore = Semaphore(promises.count)
        let combo = Promise()
        
        promises.forEach {
            promise in
            _ = promise.then {
                result in
                if (!semaphore.resolved) {
                    semaphore.resolved = true
                    combo.resolve(result)
                }
                
                return result
            } .rescue {
                error in
                if (!semaphore.resolved) {
                    if (nil != error) {
                        semaphore.errors.append(error!)
                    }
                    
                    semaphore.rejected += 1
                    if (semaphore.max == semaphore.rejected) {
                        combo.reject(semaphore.errors)
                    }
                }
                
                return error
            }
        }
        
        return combo
    }
}
