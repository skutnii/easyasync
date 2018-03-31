//
//  WrapperTests.swift
//  EasySwiftTests
//
//  Created by Serge Kutny on 3/31/18.
//  Copyright © 2018 skutnii. All rights reserved.
//

import XCTest

class WrapperTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInit() {
        let value = NSObject()
        let wrapper = Wrapper(value)
        XCTAssert(value === wrapper.value, "Value must be set in init")
    }
    
    func testExtractor() {
        let value = NSObject()
        let wrapper = Wrapper(value)
        XCTAssert(**wrapper === value, "** operator must extract the value")
    }
    
    func testSendLeftValueToWrapper() {
        let wrapper = Wrapper(NSObject())
        let value2 = NSObject()
        
        wrapper <<< value2
        
        XCTAssert(wrapper.value === value2, "<<< operator with a wrapper on the left must send the right hand side to the wrapper")
    }
    
    func testSendLeftWrapperToValue() {
        let value1 = NSObject()
        let wrapper = Wrapper(value1)
        
        var value2 = NSObject()
        value2 <<< wrapper
        
        XCTAssert(value2 === value1, "<<< operator with a wrapper on the right must send wrapper value to the left hand side")
    }
    
    func testSendRightValueToWrapper() {
        let wrapper = Wrapper(NSObject())
        let value = NSObject()
        
        value >>> wrapper
        
        XCTAssert(wrapper.value === value, ">>> operator must send value to its right hand side")
    }
    
    func testSendRightWrapperToValue() {
        let value1 = NSObject()
        let wrapper = Wrapper(value1)
        
        var value2 = NSObject()
        wrapper >>> value2
        
        XCTAssert(value2 === value1, ">>> operator must send wrapper's value to its right hand side")
    }
}
