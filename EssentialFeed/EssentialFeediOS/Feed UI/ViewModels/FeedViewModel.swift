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

    var onChange: ((FeedViewModel)->Void)?
    var onFeedLoad: (([FeedImage])->Void)?
    var isLoading: Bool  = false {
        didSet {
            onChange?(self)
        }
    }

    func loadFeed() {
        isLoading = true
        feedLoader.load{[weak self] result in
            guard let self else {
                return
            }
            if let feed = try? result.get() {
                onFeedLoad?(feed)
            }
            isLoading = false
        }
    }
}
