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
        let feed: [CodableFeedImage]
        let timeStamp: Date

        var localFeed: [LocalFeedImage] {
            feed.map(\.localFeedImage)
        }
    }

    private struct CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL

        init(_ localFeedImage: LocalFeedImage) {
            id = localFeedImage.id
            description = localFeedImage.description
            location = localFeedImage.location
            url = localFeedImage.url
        }
        var localFeedImage: LocalFeedImage {
            LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }

    private let storeURL: URL

    init(storeURL: URL){
        self.storeURL = storeURL
    }

    func retrive(completion: @escaping FeedStore.RetrivalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        do {
            let cache = try JSONDecoder().decode(Cache.self, from: data)

            completion(.found(feed: cache.localFeed, timeStamp: cache.timeStamp))
        } catch {
            completion(.failure(error))
        }
    }

    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        do{
            let cache = Cache(feed: feed.map({CodableFeedImage($0)}), timeStamp: timestamp)
            let encoded = try JSONEncoder().encode(cache)
            try encoded.write(to: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }

    func deleteCachedFeed(completion: @escaping FeedStore.DeletionCompletion){
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            completion(nil)
            return
        }
        do {
            try FileManager.default.removeItem(at: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
}

class CodableFeedStoreTests: XCTestCase {

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

    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()
        let firstInsertionError = insert((uniqueImageFeed().local, Date()), to: sut)
        XCTAssertNil(firstInsertionError)

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

    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
       let deletionError = deleteCache(sut)
        XCTAssertNil(deletionError, "Expected to delete with no error, got \(String(describing: deletionError)) instead.")

        expect(sut, toRetrive: .empty)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timeStamp = Date()

        insert((feed, timeStamp), to: sut)
        let deletionError = deleteCache(sut)
        XCTAssertNil(deletionError, "Expected to delete with no error, got \(String(describing: deletionError)) instead.")

        expect(sut, toRetrive: .empty)
    }

    func test_delete_deliversErrorOnDeltionError() {
        let storeURL = cachesDirectory()
        let sut = makeSUT(storeURL: storeURL)
        let deletionError = deleteCache(sut)

        XCTAssertNotNil(deletionError)

        expect(sut, toRetrive: .empty)
    }

    //MARK: - Helpers
    private func makeSUT(storeURL: URL? = nil,file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
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

    @discardableResult
    private func insert(_ cache: (feed: [LocalFeedImage], timeStamp: Date), to sut: CodableFeedStore, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        let expectation = expectation(description: "Wait for Insertion to complete")
        var insertionError: Error?
        sut.insert(cache.feed, timestamp: cache.timeStamp){ error in
            insertionError = error
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        return insertionError
    }

    private func expect(_ sut: CodableFeedStore, toRetriveTwice expectedResult: RetrieveCachedFeedResult, file: StaticString = #filePath, line: UInt = #line ) {
        expect(sut, toRetrive: expectedResult)
        expect(sut, toRetrive: expectedResult)
    }

    private func expect(_ sut: CodableFeedStore, toRetrive expectedResult: RetrieveCachedFeedResult, file: StaticString = #filePath, line: UInt = #line ) {
        let expectation = expectation(description: "Wait for retrival to complete")
        sut.retrive { retrivedResult in
            switch (expectedResult, retrivedResult) {
            case (.empty, .empty), (.failure, .failure):
                break //pass
            case let (.found(expectedFeed, expectedTimeStamp), .found(retrivedFeed, retrivedTimeStamp)):
                XCTAssertEqual(expectedFeed, retrivedFeed, file: file, line: line)
                XCTAssertEqual(expectedTimeStamp, retrivedTimeStamp, file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult) but got \(retrivedResult)", file: (file), line: line)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    private func deleteCache(_ sut: CodableFeedStore) -> Error? {
        let expectation = expectation(description: "Wait for cache delete completion")
        var deletionError: Error?
        sut.deleteCachedFeed { error in
            deletionError = error
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        return deletionError
    }
}
