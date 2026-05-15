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
        let presentationAdapter = FeedLoaderPresentationAdapter(feedLoader: feedLoader)
        let refreshController = FeedRefreshController(delegate: presentationAdapter)
        let feedController = FeedViewController(refreshController: refreshController)
        let presenter = FeedPresenter(feedView: FeedViewAdapter(feedController: feedController, imageLoader: imageLoader), loadingView: WeakRefVirtualProxy(refreshController))
        //Why adapter.presenter property injection?
        //Since MVP create's cyclic dependency, Atleast on the property need to be injected. Presentation adapter belongs to composer layer, we're preferring presenter injection here
        presentationAdapter.presenter = presenter

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

    func display(_ viewModel: FeedViewModel) {
        guard let feedController else {
            return
        }
        feedController.tableModel = viewModel.feed.map({model in FeedImageCellController(viewModel: FeedImageViewModel(model: model, imageLoader: imageLoader, imageTransformer: UIImage.init))})
    }
}

private class WeakRefVirtualProxy<T: AnyObject> {
    private weak var value: T?
    init(_ value: T) {
        self.value = value
    }
}
extension WeakRefVirtualProxy: FeedLoadingView where T: FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel) {
        value?.display(viewModel)
    }
}


private class FeedLoaderPresentationAdapter: FeedRefreshViewControllerDelegate {
    let feedLoader: FeedLoader
    var presenter: FeedPresenter?
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    func didRequestRefresh() {
        presenter?.didStartLoading()
        feedLoader.load{[weak self] result in
            guard let self else {
                return
            }
            switch result {
            case .success(let feed):
                presenter?.didFinishLoading(with: feed)
            case .failure(let error):
                presenter?.didFinishLoading(with: error)
            }
        }
    }
}
