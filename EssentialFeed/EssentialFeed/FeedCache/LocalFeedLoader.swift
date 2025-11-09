//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 22/10/25.
//

import Foundation


public final class LocalFeedLoader {

    public typealias SaveResult = Error?
    public typealias LoadResult = LoadFeedResult?

    private let store: FeedStore
    private let currentDate: () -> Date

    public init(store: FeedStore, currentDate: @autoclosure @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    public func save(_ feedItems: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed{ [weak self] error in
            guard let self else {
                return
            }
            if let error {
                completion(error)
            } else {
                insert(feedItems, completion: completion)
            }
        }
    }

    private func insert(_ feedImage: [FeedImage], completion: @escaping (Error?) -> Void) {
        store.insert(feedImage.toLocalFeedItems(), timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return}
            completion(error)
        }
    }

    public func load(completion: @escaping (LoadResult?) -> Void) {
        store.retrive { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case .empty:
                completion(.success([]))
            case let .found(feed, _):
                completion(.success(feed.toFeedItems()))
            }
        }
    }
}

private extension Array where Element == FeedImage {
    func toLocalFeedItems() -> [LocalFeedImage] {
        return map{ LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    }
}

private extension Array where Element == LocalFeedImage {
    func toFeedItems() -> [FeedImage] {
        return map{ FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    }
}
