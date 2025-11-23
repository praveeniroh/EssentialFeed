//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 22/10/25.
//

import Foundation
public enum RetrieveCachedFeedResult {
    case failure(Error)
    case empty
    case found(feed: [LocalFeedImage], timeStamp: Date)
}

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    typealias RetrivalCompletion = (RetrieveCachedFeedResult) -> Void

    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func deleteCachedFeed(completion: @escaping DeletionCompletion)

    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)

    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func retrive(completion: @escaping RetrivalCompletion)
}
