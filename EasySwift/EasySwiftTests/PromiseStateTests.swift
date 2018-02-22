//
//  PromiseStateTests.swift
//  EasySwiftTests
//
//  Created by Serge Kutny on 2/18/18.
//  Copyright © 2018 skutnii. All rights reserved.
//

import XCTest

class PromiseStateTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    /**
     doc/Promise.md - 3.3.1 Default initializer
    */
    func testDefaultInit() {
        let promise = Promise<Any>()
        XCTAssert(.pending == promise.state, "Promise must be created in pending state")
        XCTAssert(nil == promise.value, "There must be no value")
        XCTAssert(nil == promise.rejectReason, "There must be no rejection reason")
    }
    
    /**
     doc/Promise.md - 2.1.2.2
     doc/Promise.md - 3.4.1.1
    */
    func testResolve() {
        let promise = Promise<Int>()
        promise.resolve(1)
        XCTAssert(.fulfilled == promise.state, "Promise must be in the fulfilled state")
        XCTAssert(1 == promise.value, "Promise value must be 1")
    }
    
    /**
     doc/Promise.md - 2.1.2.2
    */
    func testNoDoubleResolve() {
        let promise = Promise<String>()
        promise.resolve("A")
        promise.resolve("B")
        
        XCTAssert("A" == promise.value, "Promise value must not change after it has been fulfilled")
    }
    
    /**
     doc/Promise.md - 2.1.2.1
     */
    func testNoRejectAfterResolve() {
        let promise = Promise<Int>()
        promise.resolve(1)
        promise.reject("BBBB")
        XCTAssert(.fulfilled == promise.state, "Promise must be in the fulfilled state")
        XCTAssert(1 == promise.value, "Promise value must be 1")
        XCTAssert(nil == promise.rejectReason, "There must be no rejectReason")
    }
    
    /**
     doc/Promise.md - 2.1.3.2
     doc/Promise.md - 3.4.2
    */
    func testReject() {
        let promise = Promise<Bool>()
        promise.reject("A")
        XCTAssert(.rejected == promise.state, "Promise must be in the rejected state")
        guard let reason = promise.rejectReason as? String else {
            XCTFail("There must be a rejection reason")
            return
        }
        
        XCTAssert("A" == reason, "Reason must be passed in reject")
    }
    
    /**
     doc/Promise.md - 2.1.3.2
    */
    func testNoDoubleReject() {
        let promise = Promise<Any>()
        promise.reject("A")
        promise.reject("B")
        guard let reason = promise.rejectReason as? String else {
            XCTFail("There must be a rejection reason")
            return
        }
        
        XCTAssert("A" == reason, "Reason must not change")
    }
    
    /**
    doc/Promise.md - 2.1.3.1
    */
    func testNoResolveAfterReject() {
        let promise = Promise<Any>()
        promise.reject("A")
        promise.resolve(1)
        XCTAssert(.rejected == promise.state, "Promise must be in the rejected state")
        XCTAssert(nil == promise.value, "There must be no value")
        guard let reason = promise.rejectReason as? String else {
            XCTFail("There must be a rejection reason")
            return
        }
        
        XCTAssert("A" == reason, "Reason must not change")
    }
}
