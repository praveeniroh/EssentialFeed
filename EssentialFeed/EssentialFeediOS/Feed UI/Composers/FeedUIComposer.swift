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
        let refreshController = FeedRefreshController(feedLoader: feedLoader)
        let feedController = FeedViewController(refreshController: refreshController)

        refreshController.onRefresh = adaptFeedToCellControllers(feedController: feedController, imageLoader: imageLoader)
        return feedController
    }

    private static func adaptFeedToCellControllers(feedController: FeedViewController, imageLoader: FeedImageDataLoader?) -> ([FeedImage]) -> Void{
        return {[weak feedController] feed in
            feedController?.tableModel = feed.map({FeedImageCellController(model: $0, imageLoader: imageLoader)})
        }
    }

}
