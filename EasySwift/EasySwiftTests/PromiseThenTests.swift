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
    
}
