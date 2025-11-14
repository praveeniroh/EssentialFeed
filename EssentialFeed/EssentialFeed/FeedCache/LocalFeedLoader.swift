//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 22/10/25.
//

import Foundation

fileprivate final class FeedCachePolicy {
    private let calendar = Calendar(identifier: .gregorian)
    private var maxCacheAgeInDays: Int {
        7
    }

    private let currentDate: () -> Date

    init(currentDate: @escaping () -> Date) {
        self.currentDate = currentDate
    }

    func validate(_ timeStamp: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timeStamp) else {
            return false
        }
        return currentDate() < maxCacheAge
    }
}

public final class LocalFeedLoader {

    private let store: FeedStore
    private let currentDate: () -> Date
    private let cachePolicy: FeedCachePolicy

    public init(store: FeedStore, currentDate: @autoclosure @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
        cachePolicy = FeedCachePolicy(currentDate: currentDate)
    }
}

extension LocalFeedLoader {

    public typealias SaveResult = Error?

    public func save(_ feedItems: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed{ [weak self] error in
            guard let self else {
                return
            }
            if let error {
                completion(error)
            } else {
                cache(feedItems, completion: completion)
            }
        }
    }

    private func cache(_ feedImage: [FeedImage], completion: @escaping (Error?) -> Void) {
        store.insert(feedImage.toLocalFeedItems(), timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return}
            completion(error)
        }
    }
}

extension LocalFeedLoader: FeedLoader {
    public typealias LoadResult = LoadFeedResult

    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrive { [weak self] result in
            guard let self else {return}
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .found(feed, timeStamp) where self.cachePolicy.validate(timeStamp):
                completion(.success(feed.toFeedItems()))
            case .found,.empty:
                completion(.success([]))
            }

        }
    }
}

extension LocalFeedLoader {

    public func validateCache()  {
        store.retrive {[weak self] result in
            guard let self else {return}
            switch result {
            case .failure:
                store.deleteCachedFeed { _ in }
            case let .found(_, timeStamp) where !self.cachePolicy.validate(timeStamp):
                store.deleteCachedFeed { _ in }
            default:
                break
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
