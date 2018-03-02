//
//  PromiseConvenienceMethodsTests.swift
//  EasySwiftTests
//
//  Created by Serge Kutny on 2/22/18.
//  Copyright © 2018 skutnii. All rights reserved.
//

import XCTest

class PromiseConvenienceMethodsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testConvenienceInitializer() {
        let expectation = XCTestExpectation(description: "Initializer block must be called asynchronously")
        let promise = Promise<Bool> {
            resolve, reject in
            expectation.fulfill()
            resolve(true)
        }
        
        XCTAssert(.pending == promise.state, "Promise must be created in pending state")
        wait(for: [expectation], timeout:10.0)
    }
    
    func testResolve() {
        let expectation = XCTestExpectation(description: "Promise must be resolved")
        let promise = Promise<Int>.resolve(1)
        promise.then({
            (value: Int) -> () in
            if (1 == value) {
                expectation.fulfill()
            } else{
                XCTFail("Promise must be resolved with the value passed to resolve")
            }
        }, nil)
        
        wait(for: [expectation], timeout:10.0)
    }
    
    func testReject() {
        let expectation = XCTestExpectation(description: "Promise must be rejected")
        let promise = Promise<Any>.reject("Error")
        promise.rescue {
            (reason: String) -> () in
            if ("Error" == reason) {
                expectation.fulfill()
            } else {
                XCTFail("Rejection reason must be passed to the rescue block")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
}
