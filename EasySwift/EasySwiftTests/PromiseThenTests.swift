//
//  PromiseThenTests.swift
//  EasySwiftTests
//
//  Created by Serge Kutny on 2/18/18.
//  Copyright © 2018 skutnii. All rights reserved.
//

import XCTest

class PromiseThenTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    /**
     doc/Promise.md - 3.1.1.2
    */
    func testOnSuccessCalledAfterResolve() {
        let resolveValue = 1
        var successCalled = false
        let promise = Promise<Int>()
        promise.then({
            (value) -> () in
            XCTAssert(resolveValue == value, "Success block must be called with the promise's value")
            successCalled = true
        }, {
            reason in
            XCTFail("Error block must not be called")
        })
        
        XCTAssert(false == successCalled, "Success block must not be called prematurely")
        
        promise.resolve(resolveValue)
        XCTAssert(true == successCalled, "Success block must have been called at this point")
    }
    
    /**
     doc/Promise.md - 3.1.1.4
    */
    func testOnSuccessCalledWhenPromiseAlreadyFulfilled() {
        let promise = Promise<Int>()
        var successCalled = false
        promise.resolve(1)
        promise.then({
            (value) -> () in
            XCTAssert(1 == value, "Success block must be called with the promise's value")
            successCalled = true
        }, {
            reason in
            XCTFail("Error block must not be called")
        })
        
        XCTAssert(true == successCalled, "Success block must have been called at this point")
    }
    
    /**
     doc/Promise.md - 3.1.1.3
    */
    func testOnFailureCalledWhenRejected() {
        let promise = Promise<Any>()
        let rejectionReason = "My rejection reason"
        var onErrorCalled = false
        promise.then({
            _ in
            XCTFail("Success block must not be called")
        }, {
            reason in
            guard let theReason = reason as? String else {
                XCTFail("Reason must be present")
                return
            }
            
            XCTAssert(rejectionReason == theReason, "Argument must be promise's rejection reason")
            onErrorCalled = true
        })
        
        XCTAssert(false == onErrorCalled, "Error block must not be called prematurely")
        promise.reject(rejectionReason)
        
        XCTAssert(true == onErrorCalled, "Error block must have been called at this point")
    }
    
    /**
     doc/Promise.md - 3.1.1.5
    */
    func testOnFailureCalledWhenPromiseAlreadyRejected() {
        let promise = Promise<Any>()
        let rejectionReason = "My rejection reason"
        promise.reject(rejectionReason)
        
        var onErrorCalled = false
        promise.then({
            _ in
            XCTFail("Success block must not be called")
        }, {
            reason in
            guard let theReason = reason as? String else {
                XCTFail("Reason must be present")
                return
            }
            
            XCTAssert(rejectionReason == theReason, "Argument must be promise's rejection reason")
            onErrorCalled = true
        })
        
        XCTAssert(true == onErrorCalled, "Error block must have been called at this point")
    }
    
    enum PromiseTestError: Error {
        case simulated
        case other
    }
    
    /**
     doc/Promise.md - 3.1.1.6
    */
    func testOnFailureCalledWhenOnSuccessThrows() {
        let promise = Promise<String>()
        var onErrorCalled = false
        promise.then({
            _ in
            throw PromiseTestError.simulated
        }, {
            reason in
            guard let error = reason as? PromiseTestError else {
                XCTFail("Error thrown in onSuccess must be passed as an argument")
                return
            }
            
            XCTAssert(.simulated == error, "Error thrown in onSuccess must be passed as an argument")
            
            onErrorCalled = true
        })
        
        XCTAssert(false == onErrorCalled, "onFailure must not be called prematurely")
        promise.resolve("A")
        
        XCTAssert(true == onErrorCalled, "onFailure must have been called at this point")
    }

    /**
     doc/Promise.md - 3.1.1.6
     */
    func testOnFailureCalledWhenOnSuccessThrowsAndPromiseAlreadyFulfilled() {
        let promise = Promise<String>()
        promise.resolve("A")
        var onErrorCalled = false
        promise.then({
            _ in
            throw PromiseTestError.simulated
        }, {
            reason in
            guard let error = reason as? PromiseTestError else {
                XCTFail("Error thrown in onSuccess must be passed as an argument")
                return
            }
            
            XCTAssert(.simulated == error, "Error thrown in onSuccess must be passed as an argument")
            
            onErrorCalled = true
        })
        
        XCTAssert(true == onErrorCalled, "onFailure must have been called at this point")
    }
    
    /**
    doc/Promise.md - 3.1.2.1
    */
    func testTypedThenResolution() {
        let promise1 = Promise<Int>()
        let promise2 = promise1.then {
            value -> String in
            return (1 == value) ? "A" : "B"
        }
        
        XCTAssert(.pending == promise2.state, "Returned promise must not be resolved prematurely")
        promise1.resolve(1)
        
        XCTAssert(.fulfilled == promise2.state, "Returned promise must be fulfilled")
        XCTAssert("A" == promise2.value, "Returned promise must be resolved with the success block's return value")
    }
    
    /**
     doc/Promise.md - 3.1.2.2
    */
    func testTypedThenOnFulfilledPromise() {
        let promise1 = Promise<Int>()
        promise1.resolve(1)
        let promise2 = promise1.then {
            value -> String in
            return (1 == value) ? "A" : "B"
        }

        XCTAssert(.fulfilled == promise2.state, "Returned promise must be fulfilled")
        XCTAssert("A" == promise2.value, "Returned promise must be resolved with the success block's return value")
    }
    
    /**
     doc/Promise.md - 3.1.2.5
    */
    func testTypedThenRejection() {
        let promise1 = Promise<Any>()
        let promise2 = promise1.then {
            value -> String in
            XCTFail("Success block must not be called")
            return ""
        }
        
        XCTAssert(.pending == promise2.state, "Returned promise must not be resolved prematurely")
        promise1.reject("A")
        
        XCTAssert(.rejected == promise2.state, "Returned must be rejected")
        guard let reason = promise2.rejectReason as? String else {
            XCTFail("Returned promise must have a rejection reason")
            return
        }
        
        XCTAssert("A" == reason, "Returned promise must have the same rejection reason as callee")
    }
    
    /**
     doc/Promise.md - 3.1.2.5
     */
    func testTypedThenOnARejectedPromise() {
        let promise1 = Promise<Any>()
        promise1.reject("A")
        let promise2 = promise1.then {
            value -> String in
            XCTFail("Success block must not be called")
            return ""
        }
        
        XCTAssert(.rejected == promise2.state, "Returned promise must be rejected")
        guard let reason = promise2.rejectReason as? String else {
            XCTFail("Returned promise must have a rejection reason")
            return
        }
        
        XCTAssert("A" == reason, "Returned promise must have the same rejection reason as callee")
    }
    
    /**
     doc/Promise.md - 3.1.2.4
    */
    func testTypedThenThrow() {
        let promise1 = Promise<Any>()
        let promise2 = promise1.then {
            _ in
            throw PromiseTestError.simulated
        }
        
        XCTAssert(.pending == promise2.state, "Returned promise must not be resolved prematurely")
        promise1.resolve(1)
        
        XCTAssert(.rejected == promise2.state, "Returned promise must be rejected")
        guard let reason = promise2.rejectReason as? PromiseTestError else {
            XCTFail("Returned promise must have a rejection reason")
            return
        }
        
        XCTAssert(.simulated == reason, "Returned promise must be rejected with the error thrown in handler")
    }
    
    /**
    doc/Promise.md - 3.1.3.1
    */
    func testTypedAsyncThenResolution() {
        let promise1 = Promise<Int>()
        let resolveValue = 1
        var successCalled = false
        let promise2 = promise1.then {
            value -> Promise<Bool> in
            XCTAssert(resolveValue == value, "Handler block must be called with the promise's value")
            successCalled = true
            return Promise<Bool>()
        }
        
        XCTAssert(.pending == promise2.state, "Returned promise must not be resolved prematurely")
        promise1.resolve(resolveValue)
        
        XCTAssert(true == successCalled, "Handler block must have been called")
    }
    
    /**
    doc/Promise.md - 3.1.3.2
    */
    func testTypedAsyncThenOnAFulfilledPromise() {
        let promise1 = Promise<Int>()
        promise1.resolve(1)
        var successCalled = false
        let _ = promise1.then {
            value -> Promise<Bool> in
            XCTAssert(1 == value, "Handler block must be called with the promise's value")
            successCalled = true
            return Promise<Bool>()
        }
        
        XCTAssert(true == successCalled, "Handler block must have been called")
    }
    
    /**
    doc/Promise.md - 3.1.3.5
    */
    func testTypedAsyncThenRejection() {
        let promise1 = Promise<Any>()
        let promise2 = promise1.then {
            value -> Promise<Bool> in
            XCTFail("Success block must not be called")
            return Promise<Bool>()
        }
        
        XCTAssert(.pending == promise2.state, "Returned promise must not be resolved prematurely")
        promise1.reject("A")
        
        XCTAssert(.rejected == promise2.state, "Returned promise must have been rejected at this point")
        guard let reason = promise2.rejectReason as? String else {
            XCTFail("Returned promise must have a rejection reason")
            return
        }
        
        XCTAssert("A" == reason, "Returned promise must have the same rejection reason as callee")
    }
    
    /**
     doc/Promise.md - 3.1.3.5
     */
    func testTypedAsyncThenOnARejectedPromise() {
        let promise1 = Promise<Any>()
        promise1.reject("A")
        let promise2 = promise1.then {
            value -> Promise<Bool> in
            XCTFail("Success block must not be called")
            return Promise<Bool>()
        }
        
        XCTAssert(.rejected == promise2.state, "Returned promise must have been rejected at this point")
        guard let reason = promise2.rejectReason as? String else {
            XCTFail("Returned promise must have a rejection reason")
            return
        }
        
        XCTAssert("A" == reason, "Returned promise must have the same rejection reason as callee")
    }
    
    /**
     doc/Promise.md - 3.1.3.4
    */
    func testTypedAsyncThenThrow() {
        let promise1 = Promise<Any>()
        let promise2 = promise1.then {
            value -> Promise<Bool> in
            throw PromiseTestError.simulated
            return Promise<Bool>()
        }
        
        XCTAssert(.pending == promise2.state, "Returned promise must not be resolved prematurely")
        promise1.resolve(1)
        
        XCTAssert(.rejected == promise2.state, "Returned promise must have been rejected at this point")
        guard let reason = promise2.rejectReason as? PromiseTestError else {
            XCTFail("Returned promise must have a rejection reason")
            return
        }
        
        XCTAssert(.simulated == reason, "Returned promise's rejection reason must be the error thrown")
    }
    
    /**
     doc/Promise.md - 3.1.3.3
    */
    func testTypedAsyncThenChainedResolve() {
        let promise1 = Promise<Any>()
        let promise2 = Promise<String>()
        let promise3 = promise1.then {
            _ -> Promise<String> in
            return promise2
        }
        
        XCTAssert(.pending == promise3.state, "Returned promise must not be resolved prematurely")
        promise1.resolve(1)

        XCTAssert(.pending == promise3.state, "Returned promise must not be resolved prematurely")
        promise2.resolve("A")
        
        XCTAssert(.fulfilled == promise3.state, "Returned promise must be fulfilled at this point")
        XCTAssert("A" == promise3.value, "Returned promise must be resolved with the intermediate promise's value")
    }
    
    /**
    doc/Promise.md - 3.1.3.3
    */
    func testTypedAsyncThenChainedImmediateResolve() {
        let promise1 = Promise<Any>()
        let promise3 = promise1.then {
            _ -> Promise<String> in
            let promise2 = Promise<String>()
            promise2.resolve("A")
            return promise2
        }
        
        XCTAssert(.pending == promise3.state, "Returned promise must not be resolved prematurely")
        promise1.resolve(1)
        
        XCTAssert(.fulfilled == promise3.state, "Returned promise must be fulfilled at this point")
        XCTAssert("A" == promise3.value, "Returned promise must be resolved with the intermediate promise's value")
    }
    
    /**
     doc/Promise.md - 3.1.3.3
     */
    func testTypedAsyncThenChainedReject() {
        let promise1 = Promise<Any>()
        let promise2 = Promise<String>()
        let promise3 = promise1.then {
            _ -> Promise<String> in
            return promise2
        }
        
        XCTAssert(.pending == promise3.state, "Returned promise must not be resolved prematurely")
        promise1.resolve(1)
        
        XCTAssert(.pending == promise3.state, "Returned promise must not be resolved prematurely")
        promise2.reject("A")
        
        XCTAssert(.rejected == promise3.state, "Returned promise must be rejected at this point")
        guard let reason = promise3.rejectReason as? String else {
            XCTFail("Returned promise must have a rejection reason")
            return
        }
        
        XCTAssert("A" == reason, "Returned promise must be rejected with the intermediate promise's rejection reason")
    }
    
    /**
     doc/Promise.md - 3.1.3.3
     */
    func testTypedAsyncThenChainedImmediateReject() {
        let promise1 = Promise<Any>()
        let promise3 = promise1.then {
            _ -> Promise<String> in
            let promise2 = Promise<String>()
            promise2.reject("A")
            return promise2
        }
        
        XCTAssert(.pending == promise3.state, "Returned promise must not be resolved prematurely")
        promise1.resolve(1)
                
        XCTAssert(.rejected == promise3.state, "Returned promise must be rejected at this point")
        guard let reason = promise3.rejectReason as? String else {
            XCTFail("Returned promise must have a rejection reason")
            return
        }
        
        XCTAssert("A" == reason, "Returned promise must be rejected with the intermediate promise's rejection reason")
    }

}
