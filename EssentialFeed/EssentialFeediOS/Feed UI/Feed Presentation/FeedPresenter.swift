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

    private let feedView: FeedView
    private let loadingView: FeedLoadingView

    init(feedView: FeedView, loadingView: FeedLoadingView) {
        self.feedView = feedView
        self.loadingView = loadingView
    }

    func didStartLoading() {
        loadingView.display(FeedLoadingViewModel(isLoading: true))
    }

    func didFinishLoading(with feed: [FeedImage]) {
        feedView.display(FeedViewModel(feed:feed))
        loadingView.display(FeedLoadingViewModel(isLoading: false))
    }

    func didFinishLoading(with error: Error) {
        loadingView.display(FeedLoadingViewModel(isLoading: false))
    }
}
