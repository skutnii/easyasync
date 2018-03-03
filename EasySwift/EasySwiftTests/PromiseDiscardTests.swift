//
//  PromiseDiscardTests.swift
//  EasySwiftTests
//
//  Created by Serge Kutny on 3/2/18.
//  Copyright © 2018 skutnii. All rights reserved.
//

import XCTest

class PromiseDiscardTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDiscardRejects() {
        let promise = Promise<Int>()
        promise.discard()
        XCTAssert(.rejected == promise.state, "Discard must reject")
        guard let reason = promise.rejectReason as? Promise<Int>.Rejection else {
            XCTFail("promise must have a rejection reason")
            return
        }
        
        XCTAssert(.discarded == reason, "Rejection reason must indicate the promise was discarded")
    }
    
    func testSimpleDiscardBlock() {
        var blockCalled = false
        let promise = Promise<Int>(discard: {
            blockCalled = true
        })
        
        promise.discard()
        XCTAssert(blockCalled, "Discard must call the discard block")
    }
    
    func testCannotDiscardFulfilledPromise() {
        let promise = Promise<Int>(discard:{
            XCTFail("The discard block must not be called")
        })
        
        promise.resolve(1)
        promise.discard()
        
        XCTAssert(.fulfilled == promise.state, "Promise must remain fulfilled")
        XCTAssert(1 == promise.value, "Promise value must not change")
    }
    
    func testCannotDiscardRejectedPromise() {
        let promise = Promise<Int>(discard:{
            XCTFail("The discard block must not be called")
        })
        
        promise.reject("Error")
        promise.discard()
        
        guard let error = promise.rejectReason as? String else {
            XCTFail("Reject reason must be a string here")
            return
        }
        
        XCTAssert("Error" == error, "Error must be the one supplied when rejecting")
    }

}
