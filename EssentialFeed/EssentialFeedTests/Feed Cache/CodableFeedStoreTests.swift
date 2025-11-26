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
        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }

    func test_retrive_hasNoSideEffectOnEmptyCache()  {
        let sut = makeSUT()
        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_retrive_deliversFoundValuesOnNonEmptyCache()  {
        let sut = makeSUT()
        assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }
    
    func test_retrive_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on:sut)
    }

    func test_retrive_deliversFailureOnRetivalError() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        try! "Invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        assertThatRetriveDeliversFailureOnRetivalError(sut)
    }
    
    func test_retrive_hasNoSideEffectOnFailure() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        try! "Invalid data".write(to: storeURL, atomically: false, encoding: .utf8)

        assertThatRetriveHasNoSideEffectOnFailure(sut)
    }
    
    func test_insert_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()

        assertThatInsertDeliversNoErrorOnEmptyCache(on:sut)
    }

    func test_insert_deliversNoErrorOnNonEmptyCache(){
        let sut = makeSUT()

        assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()
        assertThatInsertHasOverridesPreviouslyInsertedCacheValues(sut)
    }
    
    func test_insert_deliversErrorOnInsertionError() {
        let invalidURL = URL(string: "invalid://somelocation")!
        let sut = makeSUT(storeURL: invalidURL)
        let localFeed = uniqueImageFeed().local
        let timeStamp = Date()

    assertThatInsertDeliversErrorOnInsertionError(localFeed, timeStamp, sut)
    }
    
    func test_insert_hasNoSideEffectsOnInsertionError() {
        let invalidURL = URL(string: "invalid://somelocation")!
        let sut = makeSUT(storeURL: invalidURL)
        
        assertInsertHasNoSideEffectsOnInsertionError(sut)
    }
    
    func test_delete_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()

        assertThatDeleteHasDeliversNoErrorOnEmptyCache(sut)
    }

    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()

        assertThatDeletehasNoSideEffectsOnEmptyCache(sut)
    }
    
    func test_delete_deliversNoErrorOnNonEmptyCache(){
        let sut = makeSUT()

        assertThatDeleteDeliversNoErrorOnNonEmptyCache(sut)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        assertThatDeleteEmptiesPreviouslyInsertedCache(sut)
    }
    
    func test_delete_deliversErrorOnDeltionError() {
        let storeURL = cachesDirectory()
        let sut = makeSUT(storeURL: storeURL)
        let deletionError = deleteCache(sut)

        assetThatDeleteDeliversErrorOnDeltionError(deletionError, sut)
    }
    
    func test_delete_hasNoSideEffectsOnDeletionError() {
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletePermissionURL)

        assertDeleteHasNoSideEffectsOnDeletionError(sut)
    }
    
    func test_storeSideEffects_runSerailly(){
        let sut = makeSUT()
        assertThatSideEffectsRunSerially(sut)
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
