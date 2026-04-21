//
//  FeedUIComposer.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 21/04/26.
//
import EssentialFeed
import Foundation

public final class FeedUIComposer {
    private init() {}
    
    public static func makeFeedViewController(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader?) -> FeedViewController {
        let refreshController = RefreshController(feedLoader: feedLoader)
        let feedController = FeedViewController(refreshController: refreshController)

        refreshController.onRefresh = {[weak feedController] feed in
            feedController?.tableModel = feed.map({FeedImageCellController(model: $0, imageLoader: imageLoader)})
        }
        return feedController
    }
}
