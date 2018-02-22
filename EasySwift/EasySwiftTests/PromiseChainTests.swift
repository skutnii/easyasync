//
//  PromiseChainTests.swift
//  EasySwiftTests
//
//  Created by Serge Kutny on 2/18/18.
//  Copyright © 2018 skutnii. All rights reserved.
//

import XCTest

/**
 doc/Promise.md
 
 ### 2.2 Promise chaining
 
 Two promises of the same type may be chained after each other.
 Let `promise1, promise2: Promise<T>`. Then, if `promise2` is chained after `promise1`,
 + 2.2.1 after `promise1` is fulfilled with the value `x`, `promise2` is also fulfilled with the same value;
 + 2.2.2 after `promise1` is rejected with some reason, `promise2` is also rejected with the same reason.
*/
class PromiseChainTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testChainedResolve() {
        let promise1 = Promise<Int>()
        let promise2 = Promise<Int>()
        promise2.chain(after: promise1)
        promise1.resolve(1)
        
        XCTAssert(.fulfilled == promise2.state, "Chained promise must be resolved")
        XCTAssert(1 == promise2.value, "Chained promise must have the same value")
    }
    
    func testChainAfterResolved() {
        let promise1 = Promise<String>()
        promise1.resolve("A")
        
        let promise2 = Promise<String>()
        promise2.chain(after: promise1)
        
        XCTAssert(.fulfilled == promise2.state, "Chained promise must be resolved")
        XCTAssert("A" == promise2.value, "Chained promise must have the same value")
    }
    
    func testChainedReject() {
        let promise1 = Promise<Any>()
        let promise2 = Promise<Any>()
        
        promise2.chain(after: promise1)
        promise1.reject("A")
        
        XCTAssert(.rejected == promise2.state, "Chained promise must be rejected")
        guard let reason = promise2.rejectReason as? String else {
            XCTFail("There must be a rejection reason")
            return
        }
        
        XCTAssert("A" == reason, "Chained promise must have the same rejection reason")
    }
    
    func testChainAfterRejected() {
        let promise1 = Promise<Any>()
        promise1.reject("A")
        
        let promise2 = Promise<Any>()
        promise2.chain(after: promise1)
        
        XCTAssert(.rejected == promise2.state, "Chained promise must be rejected")
        guard let reason = promise2.rejectReason as? String else {
            XCTFail("There must be a rejection reason")
            return
        }
        
        XCTAssert("A" == reason, "Chained promise must have the same rejection reason")
    }
        
}
