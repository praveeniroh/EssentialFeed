//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Praveenraj T on 19/11/25.
//

import XCTest
import EssentialFeed

class CodableFeedStore{
    private struct Cache: Codable {
        let feed: [LocalFeedImage]
        let timeStamp: Date
    }
    private let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")

    func retrive(completion: @escaping FeedStore.RetrivalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        let cache = try! JSONDecoder().decode(Cache.self, from: data)

        completion(.found(feed: cache.feed, timeStamp: cache.timeStamp))
    }

    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoded = try! JSONEncoder().encode(Cache(feed: feed, timeStamp: timestamp))
        try! encoded.write(to: storeURL)
        completion(nil)
    }
}

class CodableFeedStoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

    override func tearDown() {
        super.tearDown()
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

    func test_retrive_deliversEmptyOnEmptyCache()  {
        let sut = CodableFeedStore()
        let expectation = expectation(description: "Wait for retrival to complete")
        sut.retrive { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("Expected empty but got \(result)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_retrive_hasNoSideEffectOnEmptyCache()  {
        let sut = CodableFeedStore()
        let expectation = expectation(description: "Wait for retrival to complete")
        sut.retrive { firstResult in
            sut.retrive { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default:
                    XCTFail("Expected Retriving twice empty cache would result empty but got \(firstResult) and \(secondResult)")
                }
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_retriveAfterInsertingToEmptyCache_deliversInsertedValues()  {
        let sut = CodableFeedStore()
        let localFeed = uniqueImageFeed().local
        let timeStamp = Date()

        let expectation = expectation(description: "Wait for retrival to complete")
        sut.insert(localFeed, timestamp: timeStamp){ error in
            XCTAssertNil(error, "Expected feed to be inserted successfully")
            sut.retrive { retriveResult in
                switch retriveResult {
                case .found(feed: let retrivedFeed, timeStamp: let retrivedTimeStamp):
                    XCTAssertEqual(localFeed, retrivedFeed)
                    XCTAssertEqual(timeStamp, retrivedTimeStamp)
                default:
                    XCTFail("Expected Found result with \(localFeed) but got \(retriveResult)")
                }
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

}
