//
//  FeedUIComposer.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 21/04/26.
//
import EssentialFeed
import Foundation
import UIKit

public final class FeedUIComposer {
    private init() {}
    
    public static func makeFeedViewController(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
        let presenter = FeedPresenter(feedLoader: feedLoader)
        let refreshController = FeedRefreshController(presenter: presenter)
        let feedController = FeedViewController(refreshController: refreshController)
        presenter.loadingView = refreshController
        presenter.feedView = FeedViewAdapter(feedController: feedController, imageLoader: imageLoader)
        return feedController
    }
}

private class FeedViewAdapter: FeedView {
    private weak var feedController: FeedViewController?
    private var imageLoader: FeedImageDataLoader

    init(feedController: FeedViewController?, imageLoader: FeedImageDataLoader) {
        self.feedController = feedController
        self.imageLoader = imageLoader
    }

    func display(feed: [FeedImage]) {
        guard let feedController else {
            return
        }
        feedController.tableModel = feed.map({model in FeedImageCellController(viewModel: FeedImageViewModel(model: model, imageLoader: imageLoader, imageTransformer: UIImage.init))})
    }
}
