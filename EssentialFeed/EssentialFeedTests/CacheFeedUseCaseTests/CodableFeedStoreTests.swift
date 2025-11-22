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
        let sut = makeSUT()
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
        let sut = makeSUT()
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

    func test_retrive_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let localFeed = uniqueImageFeed().local
        let timeStamp = Date()

        let expectation = expectation(description: "Wait for retrival to complete")
        sut.insert(localFeed, timestamp: timeStamp){ error in
            XCTAssertNil(error, "Expected feed to be inserted successfully")
            sut.retrive { firstResult in
                sut.retrive { secondResult in

                    switch (firstResult, secondResult) {
                    case let (.found(firstFeed,firstTimeStamp),.found(secondFeed, secondTimeStamp)):
                        XCTAssertEqual(localFeed, firstFeed)
                        XCTAssertEqual(timeStamp, firstTimeStamp)

                        XCTAssertEqual(localFeed, secondFeed)
                        XCTAssertEqual(timeStamp, secondTimeStamp)
                    default:
                        XCTFail("Expected retrieving twice from non empty cache to deliver same found result with feed \(localFeed) and timestamp \(timeStamp), got \(firstResult) and \(secondResult) instead")
                    }
                    expectation.fulfill()
                }
            }
        }
        wait(for: [expectation], timeout: 1.0)
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
}
