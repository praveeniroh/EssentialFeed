//
//  FeedStoreSpy.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 31/10/25.
//

import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void

    var deletionCompletion = [DeletionCompletion]()
    var insertionCompletion = [InsertionCompletion]()
    var retrivalCompltion = [RetrivalCompletion]()

    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert(feedItems: [LocalFeedImage], timestamp: Date)
        case retrive
    }

    private(set) var receivedMessages: [ReceivedMessage] = []
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        receivedMessages.append(.deleteCachedFeed)
        deletionCompletion.append(completion)
    }

    func completeDeletion(with error: Error?, at index: Int = 0) {
        deletionCompletion[index](error)
    }

    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletion[index](nil)
    }

    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        insertionCompletion.append(completion)
        receivedMessages.append(.insert(feedItems: feed, timestamp: timestamp))
    }

    func retrive(completion: @escaping RetrivalCompletion) {
        retrivalCompltion.append(completion)
        receivedMessages.append(.retrive)
    }

    func completeInsertion(with error: Error?, at index: Int = 0) {
        insertionCompletion[index](error)
    }
    func completeRetrival(with error: Error?, at index: Int = 0) {
        retrivalCompltion[index](error)
    }
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletion[index](nil)
    }

    func completeWithEmptyCache(at index: Int = 0) {
        retrivalCompltion[0](nil)
    }
}
