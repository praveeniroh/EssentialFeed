//
//  FeedPresenter.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 13/05/26.
//

import Foundation
import EssentialFeed
struct FeedLoadingViewModel {
    var isLoading: Bool
}
protocol FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel)
}

struct FeedViewModel {
    var feed: [FeedImage]
}

protocol FeedView {
    func display(_ viewModel: FeedViewModel)
}

final class FeedPresenter {
    typealias Observer<T> = (T) -> Void
    private let feedLoader: FeedLoader
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    var feedView: FeedView?
    var loadingView: FeedLoadingView?
    func loadFeed() {
        loadingView?.display(FeedLoadingViewModel(isLoading: true))
        feedLoader.load{[weak self] result in
            guard let self else {
                return
            }
            if let feed = try? result.get() {
                feedView?.display(FeedViewModel(feed:feed))
            }
            loadingView?.display(FeedLoadingViewModel(isLoading: false))
        }
    }
}
