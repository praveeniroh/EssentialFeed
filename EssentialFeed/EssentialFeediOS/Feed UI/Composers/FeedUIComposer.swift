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
        let feedVM = FeedViewModel(feedLoader: feedLoader)
        let refreshController = FeedRefreshController(feedViewModel: feedVM)
        let feedController = FeedViewController(refreshController: refreshController)

        feedVM.onFeedLoad =  adaptFeedToCellControllers(feedController: feedController, imageLoader: imageLoader)
        return feedController
    }

    private static func adaptFeedToCellControllers(feedController: FeedViewController, imageLoader: FeedImageDataLoader) -> ([FeedImage]) -> Void{
        return {[weak feedController] feed in
            guard let feedController else {
                return
            }
            feedController.tableModel = feed.map({model in FeedImageCellController(viewModel: FeedImageViewModel(model: model, imageLoader: imageLoader, imageTransformer: UIImage.init))})
        }
    }

}
