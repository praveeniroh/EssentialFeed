//
//  XCTestCase+MemoryLeakTracking.swift
//  EssentialFeedTests
//
//  Created by Praveenraj T on 21/09/25.
//

import Foundation
import XCTest

extension XCTestCase {
    func trackForMemoryLead(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock {[weak instance] in
            XCTAssertNil(instance, "It should have been deallocated. Potential memory leak", file: file, line: line)
        }
    }
}
