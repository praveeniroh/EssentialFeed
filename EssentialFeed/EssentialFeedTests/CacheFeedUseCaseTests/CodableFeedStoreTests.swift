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
        let cache = try! JSONDecoder().decode(Cache.self, from: data)

        completion(.found(feed: cache.localFeed, timeStamp: cache.timeStamp))
    }

    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let cache = Cache(feed: feed.map({CodableFeedImage($0)}), timeStamp: timestamp)
        let encoded = try! JSONEncoder().encode(cache)
        try! encoded.write(to: storeURL)
        completion(nil)
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

    func test_retriveAfterInsertingToEmptyCache_deliversInsertedValues()  {
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

    //MARK: - Helpers
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: testSpecificStoreURL())
        trackForMemoryLead(sut, file: file, line: line)
        return sut
    }

    private func testSpecificStoreURL() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
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

    private func insert(_ cache: (feed: [LocalFeedImage], timeStamp: Date), to sut: CodableFeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let expectation = expectation(description: "Wait for Insertion to complete")
        sut.insert(cache.feed, timestamp: cache.timeStamp){ error in
            XCTAssertNil(error, "Expected feed to be inserted successfully")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    private func expect(_ sut: CodableFeedStore, toRetriveTwice expectedResult: RetrieveCachedFeedResult, file: StaticString = #filePath, line: UInt = #line ) {
        expect(sut, toRetrive: expectedResult)
        expect(sut, toRetrive: expectedResult)
    }

    private func expect(_ sut: CodableFeedStore, toRetrive expectedResult: RetrieveCachedFeedResult, file: StaticString = #filePath, line: UInt = #line ) {
        let expectation = expectation(description: "Wait for retrival to complete")
        sut.retrive { retrivedResult in
            switch (expectedResult, retrivedResult) {
            case (.empty, .empty):
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
}
