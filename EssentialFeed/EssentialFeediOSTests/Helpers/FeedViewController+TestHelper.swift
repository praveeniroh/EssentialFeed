//
//  FeedViewController+TestHelper.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 20/05/26.
//

internal import UIKit

extension FeedViewController {
    var isShowingLoadingIndicator: Bool {
        refreshController?.view.isRefreshing == true
    }

    func stimulateUserInitiatedPulltoRefresh() {
        refreshController?.view.stimulatePullToRefresh()
    }

    func simulateAppearence() {
        if !isViewLoaded {
            loadViewIfNeeded()
            replaceRefreshControlWithFake()
        }
        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
    }

    @discardableResult
    func simulateFeedImageViewVisible(at index: Int) -> FeedImageCell? {
            return feedImageView(at: index) as? FeedImageCell
    }

    func simulateFeedImageViewNotVisible(at index: Int) {
        guard let cell = simulateFeedImageViewVisible(at: index) else {
            fatalError()
        }
        let delegate = tableView.delegate
        let indexPath = IndexPath(row: index, section: feedImageSection)
        delegate?.tableView?(tableView, willDisplay: cell, forRowAt: indexPath)
        delegate?.tableView?(tableView, didEndDisplaying: cell, forRowAt: indexPath)
    }

    func replaceRefreshControlWithFake() {
        let fake = FakeRefreshControl()
        refreshControl?.allTargets.forEach { target in
            refreshControl?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach { action in
                fake.addTarget(target, action: Selector(action), for: .valueChanged)
            }
        }
        refreshControl = fake
        self.refreshController?.view = fake
//        _ = self.refreshController?.bind(fake)
    }

    func numberOfRenderedFeedImageViews() -> Int{
        tableView.numberOfRows(inSection: feedImageSection)
    }

    func feedImageView(at row: Int) -> UITableViewCell? {
        let ds = tableView.dataSource
        let indexPath = IndexPath(row: row, section: feedImageSection)
        return ds?.tableView(tableView, cellForRowAt: indexPath)
    }

    private var feedImageSection: Int {
        0
    }

    func simulateFeedImageViewNearVisible(at row: Int) {
        let fetchDS = tableView.prefetchDataSource
        let indexPath = IndexPath(row: row, section: feedImageSection)
        fetchDS?.tableView(tableView, prefetchRowsAt: [indexPath])
    }

    func simulateFeedImageViewNotNearVisible(at row: Int) {
        simulateFeedImageViewNearVisible(at: row)
        let fetchDS = tableView.prefetchDataSource
        let indexPath = IndexPath(row: row, section: feedImageSection)
        fetchDS?.tableView?(tableView, cancelPrefetchingForRowsAt: [indexPath])
    }
}
