//
//  CodableFeedStore.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 23/11/25.
//

import Foundation

public class CodableFeedStore: FeedStore{
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

    private let queue = DispatchQueue(label: "\(CodableFeedStore.self)Queue", qos: .userInitiated, attributes: .concurrent)
    private let storeURL: URL

    public init(storeURL: URL){
        self.storeURL = storeURL
    }

    public func retrive(completion: @escaping RetrivalCompletion) {
        let storeURL = self.storeURL
        queue.async {
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
    }

    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let storeURL = self.storeURL
        queue.async(flags: .barrier) {
            do{
                let cache = Cache(feed: feed.map({CodableFeedImage($0)}), timeStamp: timestamp)
                let encoded = try JSONEncoder().encode(cache)
                try encoded.write(to: storeURL)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    public func deleteCachedFeed(completion: @escaping DeletionCompletion){
        let storeURL = self.storeURL
        queue.async(flags: .barrier) {
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
}
