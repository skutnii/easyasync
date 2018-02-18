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

}
