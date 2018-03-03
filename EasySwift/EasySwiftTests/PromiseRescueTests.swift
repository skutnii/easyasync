//
//  PromiseRescueTests.swift
//  EasySwiftTests
//
//  Created by Serge Kutny on 2/18/18.
//  Copyright © 2018 skutnii. All rights reserved.
//

import XCTest

class PromiseRescueTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    /**
     doc/Promise.md - 3.2.1.1.1
    */
    func testRescueMeetingCondition() {
        let promise = Promise<Any>()
        var handlerCalled = false
        let theError = "Error"
        promise.rescue {
            (error: String) in
            XCTAssert(theError == error, "Rescue block must be called with the rejection reason")
            handlerCalled = true
        }
        
        promise.reject(theError)
        XCTAssert(true == handlerCalled, "Rescue block must have been called")
    }

    /**
     doc/Promise.md - 3.2.1.1.2
     */
    func testRescueNotMeetingCondition() {
        let promise = Promise<Any>()
        promise.rescue {
            (error: Bool) in
            XCTFail("Rescue block must not be called")
        }
        
        promise.reject("Error")
    }
    
    /**
     doc/Promise.md - 3.2.1.2.1
    */
    func testImmediateRescueMeetingCondition() {
        let promise = Promise<Any>()
        var handlerCalled = false
        promise.reject("Error")
        promise.rescue {
            (error: String) in
            XCTAssert("Error" == error, "Rescue block must be called with the rejection reason")
            handlerCalled = true
        }
        
        XCTAssert(true == handlerCalled, "Rescue block must have been called")
    }

    /**
     doc/Promise.md - 3.2.1.2.2
     */
    func testImmediateRescueNotMeetingCondition() {
        let promise = Promise<Any>()
        promise.reject("Error")
        promise.rescue {
            (error: Int) in
            XCTFail("Rescue block must not be called")
        }
    }
    
    /**
     doc/Promise.md - 3.2.2.1
     doc/Promise.md - 3.2.2.3
    */
    func testTypedRescueMeetingCondition() {
        let promise1 = Promise<Any>()
        var handlerCalled = false
        let theError = "Error"
        let promise2 = promise1.rescue {
            (error: String) -> Int in
            XCTAssert(theError == error, "Rescue block must be called with the rejection reason")
            handlerCalled = true
            return 1
        }
        
        XCTAssert(.pending == promise2.state, "Returned promise must not be rejected prematurely")
        promise1.reject(theError)
        XCTAssert(true == handlerCalled, "Rescue block must have been called")
        XCTAssert(.fulfilled == promise2.state, "Returned promise must be fulfilled at this point")
        XCTAssert(1 == promise2.value, "Returned promise must be resolved with the value of handler block")
    }

    /**
     doc/Promise.md - 3.2.2.2
     doc/Promise.md - 3.2.2.3
     */
    func testImmediateTypedRescueMeetingCondition() {
        let promise1 = Promise<Any>()
        promise1.reject("Error")
        let promise2 = promise1.rescue {
            (error: String) -> Int in
            XCTAssert("Error" == error, "Rescue block must be called with the rejection reason")
            return 1
        }
        
        XCTAssert(.fulfilled == promise2.state, "Returned promise must be fulfilled at this point")
        XCTAssert(1 == promise2.value, "Returned promise must be resolved with the value of handler block")
    }
    
    enum RescueError: Error {
        case simulated
        case other
    }
    
    /**
    doc/Promise.md - 3.2.2.4
    */
    func testTypedRescueThrow() {
        let promise1 = Promise<Any>()
        let promise2 = promise1.rescue {
            (error: String) -> Int in
            throw RescueError.simulated
            return 1
        }
        
        promise1.reject("Error")
        XCTAssert(.rejected == promise2.state, "Returned promise must have been rejected")
        guard let error = promise2.rejectReason as? RescueError else {
            XCTFail("Returned promise must have a rejection reason")
            return
        }
        
        XCTAssert(.simulated == error, "Returned promise must be rejected with the error thrown as reason")
    }

    /**
     doc/Promise.md - 3.2.2.4
     */
    func testTypedImmediateRescueThrow() {
        let promise1 = Promise<Any>()
        promise1.reject("Error")
        
        let promise2 = promise1.rescue {
            (error: String) -> Int in
            throw RescueError.simulated
            return 1
        }
        
        XCTAssert(.rejected == promise2.state, "Returned promise must have been rejected")
        guard let error = promise2.rejectReason as? RescueError else {
            XCTFail("Returned promise must have a rejection reason")
            return
        }
        
        XCTAssert(.simulated == error, "Returned promise must be rejected with the error thrown as reason")
    }
    
    /**
    doc/Promise.md - 3.2.2.5
    */
    func testTypedRescueErrorPropagation() {
        let promise1 = Promise<Any>()
        let promise2 = promise1.rescue {
            (error: Int) -> String in
            XCTFail("Rescue block must not be called")
            return ""
        }
        
        promise1.reject("Error")
        XCTAssert(.rejected == promise2.state, "Returned promise must have been rejected")
        guard let error = promise2.rejectReason as? String else {
            XCTFail("Returned promise must have a rejection reason")
            return
        }
        
        XCTAssert("Error" == error, "Returned promise must be rejected with the same reason as the callee")
    }

    /**
     doc/Promise.md - 3.2.2.5
     */
    func testTypedImmediateRescueErrorPropagation() {
        let promise1 = Promise<Any>()
        promise1.reject("Error")
        
        let promise2 = promise1.rescue {
            (error: Int) -> String in
            XCTFail("Rescue block must not be called")
            return ""
        }
        
        XCTAssert(.rejected == promise2.state, "Returned promise must have been rejected")
        guard let error = promise2.rejectReason as? String else {
            XCTFail("Returned promise must have a rejection reason")
            return
        }
        
        XCTAssert("Error" == error, "Returned promise must be rejected with the same reason as the callee")
    }
    
    /**
     doc/Promise.md - 3.2.3.1
    */
    func testTypedAsyncRescueMeetingCondition() {
        let promise1 = Promise<Any>()
        var handlerCalled = false
        let theError = "Error"
        let promise2 = promise1.rescue {
            (error: String) -> Promise<Int> in
            XCTAssert(theError == error, "Handler must be called with the rejection reason as an argument")
            handlerCalled = true
            return Promise<Int>()
        }
        
        XCTAssert(.pending == promise2.state, "Returned promise must not be resolved prematurely")
        
        promise1.reject(theError)
        XCTAssert(true == handlerCalled, "Handler block must have been called")
    }
    
    /**
     doc/Promise.md - 3.2.3.2
     */
    func testImmediateTypedAsyncRescueMeetingCondition() {
        let promise1 = Promise<Any>()
        let theError = "Error"
        promise1.reject(theError)
        var handlerCalled = false
        _ = promise1.rescue {
            (error: String) -> Promise<Int> in
            XCTAssert(theError == error, "Handler must be called with the rejection reason as an argument")
            handlerCalled = true
            return Promise<Int>()
        }
        
        XCTAssert(true == handlerCalled, "Handler block must have been called")
    }
    
    /**
     doc/Promise.md - 3.2.3.4
     */
    func testTypedAsyncRescueThrow() {
        let promise1 = Promise<Any>()
        let promise2 = promise1.rescue {
            (error: String) -> Promise<Int> in
            throw RescueError.simulated
            return Promise<Int>()
        }
        
        XCTAssert(.pending == promise2.state, "Returned promise must not be resolved prematurely")
        
        promise1.reject("Error")
        XCTAssert(.rejected == promise2.state, "Returned promise must have been rejected")

        guard let error = promise2.rejectReason as? RescueError else {
            XCTFail("Returned promise must have a rejection reason")
            return
        }
        
        XCTAssert(.simulated == error, "Returned promise must be rejected with the error thrown as reason")
    }

    /**
     doc/Promise.md - 3.2.3.4
     */
    func testImmediateTypedAsyncRescueThrow() {
        let promise1 = Promise<Any>()
        promise1.reject("Error")
        
        let promise2 = promise1.rescue {
            (error: String) -> Promise<Int> in
            throw RescueError.simulated
            return Promise<Int>()
        }
        
        XCTAssert(.rejected == promise2.state, "Returned promise must have been rejected")
        
        guard let error = promise2.rejectReason as? RescueError else {
            XCTFail("Returned promise must have a rejection reason")
            return
        }
        
        XCTAssert(.simulated == error, "Returned promise must be rejected with the error thrown as reason")
    }
    
    /**
     doc/Promise.md - 3.2.3.5
    */
    func testTypedAsyncRescuePropagation() {
        let promise1 = Promise<Any>()
        let promise2 = promise1.rescue {
            (error: Int) -> Promise<Int> in
            XCTFail("Handler block must not be called")
            return Promise<Int>()
        }
        
        XCTAssert(.pending == promise2.state, "Returned promise must not be resolved prematurely")
        
        promise1.reject("Error")
        XCTAssert(.rejected == promise2.state, "Returned promise must have been rejected")
        
        guard let error = promise2.rejectReason as? String else {
            XCTFail("Returned promise must have a rejection reason")
            return
        }
        
        XCTAssert("Error" == error, "Returned promise must be rejected with the error thrown as reason")
    }

    /**
     doc/Promise.md - 3.2.3.5
     */
    func testImmediateTypedAsyncRescuePropagation() {
        let promise1 = Promise<Any>()
        promise1.reject("Error")

        let promise2 = promise1.rescue {
            (error: Int) -> Promise<Int> in
            XCTFail("Handler block must not be called")
            return Promise<Int>()
        }
        
        XCTAssert(.rejected == promise2.state, "Returned promise must have been rejected")
        
        guard let error = promise2.rejectReason as? String else {
            XCTFail("Returned promise must have a rejection reason")
            return
        }
        
        XCTAssert("Error" == error, "Returned promise must be rejected with the error thrown as reason")
    }
    
    /**
     doc/Promise.md - 3.2.3.3
     */
    func testTypedAsyncRescueChainedResolution() {
        let promise1 = Promise<Any>()
        let promise2 = Promise<String>()
        let promise3 = promise1.rescue {
            (error: String) -> Promise<String> in
            return promise2
        }
        
        XCTAssert(.pending == promise3.state, "Returned promise must not be resolved prematurely")
        
        promise1.reject("Error")
        XCTAssert(.pending == promise3.state, "Returned promise must not be resolved prematurely")
        
        promise2.resolve("A")
        XCTAssert(.fulfilled == promise3.state, "Returned promise must have been resolved")
        XCTAssert("A" == promise3.value, "Returned promise must be resolved with the value of intermediate promise")
    }

    /**
     doc/Promise.md - 3.2.3.3
     */
    func testImmediateTypedAsyncRescueChainedResolution() {
        let promise1 = Promise<Any>()
        promise1.reject("Error")
        
        let promise2 = Promise<String>()
        let promise3 = promise1.rescue {
            (error: String) -> Promise<String> in
            return promise2
        }
        
        XCTAssert(.pending == promise3.state, "Returned promise must not be resolved prematurely")
        
        promise2.resolve("A")
        XCTAssert(.fulfilled == promise3.state, "Returned promise must have been resolved")
        XCTAssert("A" == promise3.value, "Returned promise must be resolved with the value of intermediate promise")
    }
    
    /**
     doc/Promise.md - 3.2.3.3
     */
    func testTypedAsyncRescueChainedRejection() {
        let promise1 = Promise<Any>()
        let promise2 = Promise<String>()
        let promise3 = promise1.rescue {
            (error: String) -> Promise<String> in
            return promise2
        }
        
        XCTAssert(.pending == promise3.state, "Returned promise must not be resolved prematurely")
        
        promise1.reject("Error1")
        XCTAssert(.pending == promise3.state, "Returned promise must not be resolved prematurely")
        
        promise2.reject("Error2")
        XCTAssert(.rejected == promise3.state, "Returned promise must have been rejected")
        guard let error = promise3.rejectReason as? String else {
            XCTFail("Returned promise must have a rejection reason")
            return
        }
        
        XCTAssert("Error2" == error, "Returned promise must be rejected with the rejection reason of intermediate promise")
    }
    
    /**
     doc/Promise.md - 3.2.3.3
     */
    func testImmediateTypedAsyncRescueChainedRejection() {
        let promise1 = Promise<Any>()
        promise1.reject("Error1")
        
        let promise2 = Promise<String>()
        let promise3 = promise1.rescue {
            (error: String) -> Promise<String> in
            return promise2
        }
        
        XCTAssert(.pending == promise3.state, "Returned promise must not be resolved prematurely")
        
        promise2.reject("Error2")
        XCTAssert(.rejected == promise3.state, "Returned promise must have been rejected")
        guard let error = promise3.rejectReason as? String else {
            XCTFail("Returned promise must have a rejection reason")
            return
        }
        
        XCTAssert("Error2" == error, "Returned promise must be rejected with the rejection reason of intermediate promise")
    }
}
