//
//  FeedsLoaderTest.swift
//  EssentialFeedTests
//
//  Created by praveen-12298 on 22/08/25.
//

import XCTest

final class FeedsLoaderTest: XCTestCase {
    override class func setUp() {
        super.setUp()
        print(">>>> setup")
    }

    override class func tearDown() {
        super.tearDown()
        print(">>>> tearDown")
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    override func tearDown() {
        super.tearDown()
        print(">>>> instance tearDown")
    }

    override func setUp() {
        super.setUp()
        print(">>>> instance setup")
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testSample() {
        print(">>>> testSample")
        XCTAssertEqual(0.01, 0.02, accuracy: 0.01)
    }

    func testSample2() {
        print(">>>> testSample2")
        XCTAssertEqual(0.01, 0.02, accuracy: 0.01)
    }

}
