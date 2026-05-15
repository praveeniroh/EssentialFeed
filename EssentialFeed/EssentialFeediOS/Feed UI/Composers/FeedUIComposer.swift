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
        let presenter = FeedPresenter()
        let presentationAdapter = FeedLoaderPresentationAdapter(feedLoader: feedLoader, presenter: presenter)
        let refreshController = FeedRefreshController(delegate: presentationAdapter)
        let feedController = FeedViewController(refreshController: refreshController)
        presenter.loadingView = WeakRefVirtualProxy(refreshController)
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
    let presenter: FeedPresenter
    init(feedLoader: FeedLoader, presenter: FeedPresenter) {
        self.feedLoader = feedLoader
        self.presenter = presenter
    }

    func didRequestRefresh() {
        presenter.didStartLoading()
        feedLoader.load{[weak self] result in
            guard let self else {
                return
            }
            switch result {
            case .success(let feed):
                presenter.didFinishLoading(with: feed)
            case .failure(let error):
                presenter.didFinishLoading(with: error)
            }
        }
    }
}
