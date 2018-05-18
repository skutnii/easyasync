//
//  PromiseAnywayTests.swift
//  EasySwiftTests
//
//  Created by sergii.kutnii on 18.05.18.
//  Copyright © 2018 skutnii. All rights reserved.
//

import XCTest

class PromiseAnywayTests: XCTestCase {
        
    func testAnywaySyncFiredUponFulfill() {
        var blockCalled = false
        
        let promise = Promise<Int>()
        _ = promise.anyway({
            result -> Void in
            XCTAssert(result == 0, "Must be called with the promise's result")
            blockCalled = true
        })
        
        promise.resolve(0)
        XCTAssert(blockCalled, "Handler must have been called")
    }
    
    func testAnywaySyncFiredUponReject() {
        var blockCalled = false
        
        let promise = Promise<Int>()
        _ = promise.anyway({
            result -> Void in
            XCTAssert(result == nil, "Must be nil if promise is rejected")
            blockCalled = true
        })
        
        promise.reject("")
        XCTAssert(blockCalled, "Handler must have been called")
    }

    func testAnywayAsyncFiredUponFulfill() {
        var blockCalled = false
        
        let promise = Promise<Int>()
        let innerPromise = Promise<Int>()
        let outPromise = promise.anyway(async: {
            result -> Promise<Int> in
            XCTAssert(result == 0, "Must be called with the promise's result")
            blockCalled = true
            return innerPromise
        })
        
        promise.resolve(0)
        XCTAssert(.pending == outPromise.state, "Must be pending at this point")
        
        innerPromise.resolve(42)
        XCTAssert(outPromise.value == 42, "Must be resolved at this point")

        XCTAssert(blockCalled, "Handler must have been called")
    }
    
    func testAnywayAsyncFiredUponReject() {
        var blockCalled = false
        
        let promise = Promise<Int>()
        let innerPromise = Promise<Int>()
        let outPromise = promise.anyway(async: {
            result -> Promise<Int> in
            blockCalled = true
            return innerPromise
        })
        
        promise.reject("")
        XCTAssert(.pending == outPromise.state, "Must be pending at this point")
        
        innerPromise.resolve(42)
        XCTAssert(outPromise.value == 42, "Must be resolved at this point")
        
        XCTAssert(blockCalled, "Handler must have been called")
    }

}
