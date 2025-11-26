//
//  FeedStoreSpecs.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 25/11/25.
//


protocol FeedStoreSpecs {
    func test_retrive_deliversEmptyOnEmptyCache()
    func test_retrive_hasNoSideEffectOnEmptyCache()
    func test_retrive_deliversFoundValuesOnNonEmptyCache()
    func test_retrive_hasNoSideEffectsOnNonEmptyCache()

    func test_insert_deliversNoErrorOnEmptyCache()
    func test_insert_deliversNoErrorOnNonEmptyCache()
    func test_insert_overridesPreviouslyInsertedCacheValues()

    func test_delete_deliversNoErrorOnEmptyCache()
    func test_delete_hasNoSideEffectsOnEmptyCache()
    func test_delete_deliversNoErrorOnNonEmptyCache()
    func test_delete_emptiesPreviouslyInsertedCache()

    func test_storeSideEffects_runSerailly()
}

protocol FailableRetrieveFeedStoreSpecs: FeedStoreSpecs {
    func test_retrive_deliversFailureOnRetivalError()
    func test_retrive_hasNoSideEffectOnFailure()
}

protocol FailableInsertFeedStoreSpecs: FeedStoreSpecs {
    func test_insert_deliversErrorOnInsertionError()
    func test_insert_hasNoSideEffectsOnInsertionError()
}

protocol FailableDeleteFeedStoreSpecs: FeedStoreSpecs {
    func test_delete_deliversErrorOnDeltionError()
    func test_delete_hasNoSideEffectsOnDeletionError()
}

typealias FeedStoreFailableSpecs = FailableInsertFeedStoreSpecs & FailableDeleteFeedStoreSpecs & FailableRetrieveFeedStoreSpecs
