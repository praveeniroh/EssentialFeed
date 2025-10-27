//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 22/10/25.
//

import Foundation


public final class LocalFeedLoader {

    public typealias SaveResult = Error?

    private let store: FeedStore
    private let currentDate: () -> Date

    public init(store: FeedStore, currentDate: @autoclosure @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    public func save(_ feedItems: [FeedItem], completion: @escaping (SaveResult) -> Void) {
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

    private func insert(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.insert(items.toLocalFeedItems(), timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return}
            completion(error)
        }
    }
}

private extension Array where Element == FeedItem {
    func toLocalFeedItems() -> [LocalFeedItem] {
        return map{ LocalFeedItem(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.imageURL)}
    }
}
