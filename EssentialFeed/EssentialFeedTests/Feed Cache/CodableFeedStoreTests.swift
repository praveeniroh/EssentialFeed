//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Praveenraj T on 19/11/25.
//

import XCTest
import EssentialFeed
class CodableFeedStoreTests: XCTestCase,FeedStoreFailableSpecs {

    override func setUp() {
        super.setUp()
        setUpEmptyStoreState()
    }

    override func tearDown() {
        undoStoreSideEffects()
        super.tearDown()
    }

    func test_retrive_deliversEmptyOnEmptyCache()  {
        let sut = makeSUT()
        expect(sut, toRetrive: .empty)
    }

    func test_retrive_hasNoSideEffectOnEmptyCache()  {
        let sut = makeSUT()
        expect(sut, toRetrive: .empty)
        expect(sut, toRetrive: .empty)
    }

    func test_retrive_deliversFoundValuesOnNonEmptyCache()  {
        let sut = makeSUT()
        let localFeed = uniqueImageFeed().local
        let timeStamp = Date()

        insert((localFeed, timeStamp), to: sut)
        expect(sut, toRetrive: .found(feed: localFeed, timeStamp: timeStamp))
    }

    func test_retrive_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let localFeed = uniqueImageFeed().local
        let timeStamp = Date()

        insert((localFeed, timeStamp), to: sut)
        expect(sut, toRetriveTwice: .found(feed: localFeed, timeStamp: timeStamp))
    }

    func test_retrive_deliversFailureOnRetivalError() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        try! "Invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        expect(sut, toRetrive: .failure(anyNSError()))
    }

    func test_retrive_hasNoSideEffectOnFailure() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        try! "Invalid data".write(to: storeURL, atomically: false, encoding: .utf8)

        expect(sut, toRetriveTwice: .failure(anyNSError()))
    }

    func test_insert_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()

        let insertionError = insert((uniqueImageFeed().local, Date()), to: sut)

        XCTAssertNil(insertionError, "Expected insertion to be successful")
    }

    func test_insert_deliversNoErrorOnNonEmptyCache(){
        let sut = makeSUT()

        insert((uniqueImageFeed().local, Date()), to: sut)
        let insertionError = insert((uniqueImageFeed().local, Date()), to: sut)

        XCTAssertNil(insertionError, "Expected insertion to be successful")
    }

    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()
        insert((uniqueImageFeed().local, Date()), to: sut)

        let latesFeed = uniqueImageFeed().local
        let latestTimeStamp = Date()
        insert((latesFeed, latestTimeStamp), to: sut)

        expect(sut, toRetrive: .found(feed: latesFeed, timeStamp: latestTimeStamp))
    }

    func test_insert_deliversErrorOnInsertionError() {
        let invalidURL = URL(string: "invalid://somelocation")!
        let sut = makeSUT(storeURL: invalidURL)
        let localFeed = uniqueImageFeed().local
        let timeStamp = Date()

        let insertionError = insert((localFeed, timeStamp), to: sut)

        XCTAssertNotNil(insertionError)
    }

    func test_insert_hasNoSideEffectsOnInsertionError() {
        let invalidURL = URL(string: "invalid://somelocation")!
        let sut = makeSUT(storeURL: invalidURL)
        let localFeed = uniqueImageFeed().local
        let timeStamp = Date()
        
        insert((localFeed, timeStamp), to: sut)
        
        expect(sut, toRetrive: .empty)
    }

    func test_delete_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()

        let deletionError = deleteCache(sut)

        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
    }

    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()

        let deletionError = deleteCache(sut)

        XCTAssertNil(deletionError, "Expected to delete with no error, got \(String(describing: deletionError)) instead.")
    }

    func test_delete_deliversNoErrorOnNonEmptyCache(){
        let sut = makeSUT()

        insert((uniqueImageFeed().local, Date()), to: sut)
        let deletionError = deleteCache(sut)

        XCTAssertNil(deletionError, "Expected to delete with no error, got \(String(describing: deletionError)) instead.")
    }

    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timeStamp = Date()

        insert((feed, timeStamp), to: sut)
        deleteCache(sut)

        expect(sut, toRetrive: .empty)
    }

    func test_delete_deliversErrorOnDeltionError() {
        let storeURL = cachesDirectory()
        let sut = makeSUT(storeURL: storeURL)
        let deletionError = deleteCache(sut)

        XCTAssertNotNil(deletionError)

        expect(sut, toRetrive: .empty)
    }

    func test_delete_hasNoSideEffectsOnDeletionError() {
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletePermissionURL)

        deleteCache(sut)

        expect(sut, toRetrive: .empty)
    }

    func test_storeSideEffects_runSerailly(){
        let sut = makeSUT()
        var completedExpectationOrder = [XCTestExpectation]()
        let op1 = expectation(description: "Operation 1")
        sut.insert(uniqueImageFeed().local, timestamp: Date()) { _ in
            completedExpectationOrder.append(op1)
            op1.fulfill()
        }

        let op2 = expectation(description: "Operation 2")
        sut.deleteCachedFeed { _ in
            completedExpectationOrder.append(op2)
            op2.fulfill()
        }

        let op3 = expectation(description: "Operation 3")
        sut.insert([], timestamp: Date()) { _ in
            completedExpectationOrder.append(op3)
            op3.fulfill()
        }
        waitForExpectations(timeout: 5.0)
        XCTAssertEqual(completedExpectationOrder, [op1,op2,op3], "Expected to run side-effects serially but got a different order.")
    }

    //MARK: - Helpers
    private func makeSUT(storeURL: URL? = nil,file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemoryLead(sut, file: file, line: line)
        return sut
    }

    private func testSpecificStoreURL() -> URL {
        cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }

    private func cachesDirectory() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    private func setUpEmptyStoreState() {
        deletesStoreArtifacts()
    }

    private func undoStoreSideEffects() {
        deletesStoreArtifacts()
    }

    private func deletesStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
}
