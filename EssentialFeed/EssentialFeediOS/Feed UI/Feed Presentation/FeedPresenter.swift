//
//  FeedPresenter.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 13/05/26.
//

import Foundation
import EssentialFeed

protocol FeedLoadingView: AnyObject {
    func display(isLoading: Bool)
}

protocol FeedView {
    func display(feed: [FeedImage])
}

final class FeedPresenter {
    typealias Observer<T> = (T) -> Void
    private let feedLoader: FeedLoader
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    var feedView: FeedView?
    weak var loadingView: FeedLoadingView?
    func loadFeed() {
        loadingView?.display(isLoading: true)
        feedLoader.load{[weak self] result in
            guard let self else {
                return
            }
            if let feed = try? result.get() {
                feedView?.display(feed: feed)
            }
            loadingView?.display(isLoading: false)
        }
    }
}
