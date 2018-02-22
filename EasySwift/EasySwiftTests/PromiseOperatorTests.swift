//
//  PromiseOperatorTests.swift
//  EasySwiftTests
//
//  Created by Serge Kutny on 2/22/18.
//  Copyright © 2018 skutnii. All rights reserved.
//

import XCTest

class PromiseOperatorTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRightAndResolution() {
        let promise1 = Promise<Int>()
        let promise2 = (promise1 &&& true)
        promise1.resolve(1)
        
        XCTAssert(.fulfilled == promise2.state, "&&& result must be resolved")
        XCTAssertNotNil(promise2.value, "&&& result must have a value")
        let (integer, boolean) = promise2.value!
        XCTAssert((1 == integer) && (true == boolean), "Result of promise &&& value must be (promise.value!, value)")
    }
    
    func testRightAndRejection() {
        let promise1 = Promise<Int>()
        let promise2 = (promise1 &&& true)
        promise1.reject("Error")
        
        XCTAssert(.rejected == promise2.state, "&&& result must be rejected")
        XCTAssertNotNil(promise2.rejectReason, "&&& result must have a rejection reason")
        XCTAssert("Error" == (promise2.rejectReason as! String), "&&& result must be rejected with the same reason")
    }
    
    func testLeftAndResolution() {
        let promise1 = Promise<Int>()
        let promise2 = (true &&& promise1)
        promise1.resolve(1)
        
        XCTAssert(.fulfilled == promise2.state, "&&& result must be resolved")
        XCTAssertNotNil(promise2.value, "&&& result must have a value")
        let (boolean, integer) = promise2.value!
        XCTAssert((1 == integer) && (true == boolean), "Result of promise &&& value must be (promise.value!, value)")
    }
    
    func testLeftAndRejection() {
        let promise1 = Promise<Int>()
        let promise2 = (true &&& promise1)
        promise1.reject("Error")
        
        XCTAssert(.rejected == promise2.state, "&&& result must be rejected")
        XCTAssertNotNil(promise2.rejectReason, "&&& result must have a rejection reason")
        XCTAssert("Error" == (promise2.rejectReason as! String), "&&& result must be rejected with the same reason")
    }
    
    func testPromiseAndResolution() {
        let promise1 = Promise<Int>()
        let promise2 = Promise<String>()
        let promise3 = (promise1 &&& promise2)
        
        promise1.resolve(1)
        XCTAssert(.pending == promise3.state, "&&& result must be fulfilled only when both arguments are resolved")
        
        promise2.resolve("A")
        
        XCTAssert(.fulfilled == promise3.state, "&&& result must be fulfilled at this point")
        XCTAssertNotNil(promise3.value, "&&& result must have a value")
        let (integer, string) = promise3.value!
        XCTAssert((1 == integer) && ("A" == string), "&&& result value must be (left.value!, right.value!)")
    }
    
    func testPromiseAndRejectsWhenFirstRejects() {
        let promise1 = Promise<Int>()
        let promise2 = Promise<String>()
        let promise3 = (promise1 &&& promise2)
        promise1.reject("Error")
        promise2.resolve("A")
        
        XCTAssert(.rejected == promise3.state, "&&& result must be rejected")
        XCTAssertNotNil(promise3.rejectReason, "&&& result must have a rejection reason")
        XCTAssert("Error" == (promise3.rejectReason as! String), "&&& result's rejection reason must be the same as the one of the first rejected promise")
    }

    func testPromiseAndRejectsWhenSecondRejects() {
        let promise1 = Promise<Int>()
        let promise2 = Promise<String>()
        let promise3 = (promise1 &&& promise2)
        promise1.resolve(1)
        promise2.reject("Error")
        
        XCTAssert(.rejected == promise3.state, "&&& result must be rejected")
        XCTAssertNotNil(promise3.rejectReason, "&&& result must have a rejection reason")
        XCTAssert("Error" == (promise3.rejectReason as! String), "&&& result's rejection reason must be the same as the one of the first rejected promise")
    }
    
    func testPromiseAndRejectsWithTheFirstRejectionReason() {
        let promise1 = Promise<Int>()
        let promise2 = Promise<String>()
        let promise3 = (promise1 &&& promise2)
        promise1.reject("Error1")
        promise2.reject("Error2")

        XCTAssert(.rejected == promise3.state, "&&& result must be rejected")
        XCTAssertNotNil(promise3.rejectReason, "&&& result must have a rejection reason")
        XCTAssert("Error1" == (promise3.rejectReason as! String), "&&& result's rejection reason must be the same as the one of the first rejected promise")
        
        let promise4 = Promise<Bool>()
        let promise5 = Promise<Any>()
        let promise6 = (promise4 &&& promise5)
        promise5.reject("Error5")
        promise4.reject("Error4")

        XCTAssert(.rejected == promise6.state, "&&& result must be rejected")
        XCTAssertNotNil(promise6.rejectReason, "&&& result must have a rejection reason")
        XCTAssert("Error5" == (promise6.rejectReason as! String), "&&& result's rejection reason must be the same as the one of the first rejected promise")
    }
    
    func testPromiseOrFulfilsWhenFirstFulfils() {
        let promise1 = Promise<Int>()
        let promise2 = Promise<String>()
        let promise3 = (promise1 ||| promise2)
        promise1.resolve(1)
        promise2.reject("Error")
        
        XCTAssert(.fulfilled == promise3.state, "||| result must be fulfilled")
        XCTAssertNotNil(promise3.value, "||| result must have a value")
        XCTAssert(1 == (promise3.value as! Int), "||| result's value must be the first fulfilled promise[s value")
    }
    
    func testPromiseOrFulfilsWhenSecondFulfils() {
        let promise1 = Promise<Int>()
        let promise2 = Promise<String>()
        let promise3 = (promise1 ||| promise2)
        promise1.reject("Error")
        promise2.resolve("A")
        
        XCTAssert(.fulfilled == promise3.state, "||| result must be fulfilled")
        XCTAssertNotNil(promise3.value, "||| result must have a value")
        XCTAssert("A" == (promise3.value as! String), "||| result's value must be the first fulfilled promise[s value")
    }
    
    func testPromiseOrRejection() {
        let promise1 = Promise<Int>()
        let promise2 = Promise<String>()
        let promise3 = (promise1 ||| promise2)
        
        promise1.reject("Error1")
        XCTAssert(.pending == promise3.state, "||| result must not be rejected prematurely")
        
        promise2.reject("Error2")
        XCTAssert(.rejected == promise3.state, "||| result must be frejected")
        XCTAssertNotNil(promise3.rejectReason as? (Any?, Any?), "||| result must have a rejection reason")
        let (reason1, reason2) = promise3.rejectReason as! (Any?, Any?)
        XCTAssert(("Error1" == (reason1 as! String)) && ("Error2" == (reason2 as! String)), "||| result's rejection reason must be (left.rejectReason, right.rejectReason)")
    }

}
