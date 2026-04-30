//
//  FeedViewModel.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 30/04/26.
//

import EssentialFeed


final class FeedViewModel {
    private let feedLoader: FeedLoader
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    private enum State {
        case pending
        case loading
        case loaded([FeedImage])
        case failed
    }
    private var state: State = .pending {
        didSet {
            onChange?(self)
        }
    }
    var onChange: ((FeedViewModel)->Void)?

    var isLoading: Bool {
        switch state {
        case .loading: return true
        case .failed, .loaded, .pending: return false
        }
    }

    var feed: [FeedImage]? {
        switch state {
        case .loaded(let feed): return feed
        case .failed, .loading, .pending: return nil
        }
    }

    func loadFeed() {
        state = .loading
        feedLoader.load{[weak self] result in
            guard let self else {
                return
            }
            if let feed = try? result.get() {
                state = .loaded(feed)
            } else {
                state = .failed
            }
        }
    }
}
