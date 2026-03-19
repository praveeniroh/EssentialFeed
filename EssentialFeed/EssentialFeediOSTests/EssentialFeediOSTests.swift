//
//  EssentialFeediOSTests.swift
//  EssentialFeediOSTests
//
//  Created by Praveenraj T on 16/03/26.
//

import XCTest
import EssentialFeed

final class EssentialFeediOSTests: XCTestCase {

    func test_loadFeedActions_requestFeedFromLoader() {
        let (sut,loader) = makeSUT()
        XCTAssertEqual(loader.loadCallCount, 0, "Should not load while initializing")

        sut.loadViewIfNeeded()
        XCTAssertEqual(loader.loadCallCount, 1,"Expected a loading request once view is loaded")


        sut.stimulateUserInitiatedPulltoRefresh()
        XCTAssertEqual(loader.loadCallCount, 2, "Expected another loading request once user initiates a reload")

        sut.stimulateUserInitiatedPulltoRefresh()
        XCTAssertEqual(loader.loadCallCount, 3, "Expected another loading request once user initiates a reload")
    }

    func test_loadingFeedIndicator_isVisibleWhileLoadingFeed() {
        let (sut, loader) = makeSUT()

        sut.simulateAppearence()
        XCTAssertTrue(sut.isShowingLoadingIndicator)

        loader.completeFeedLoading(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator)

        sut.stimulateUserInitiatedPulltoRefresh()
        XCTAssertTrue(sut.isShowingLoadingIndicator)

        loader.completeFeedLoading(at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator)
    }


    // MARK: Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        trackForMemoryLead(sut, file: file, line: line)
        trackForMemoryLead(loader, file: file, line: line)
        return (sut, loader)
    }

    class LoaderSpy: FeedLoader {
        private var completions: [(EssentialFeed.LoadFeedResult) -> Void] = []
        var loadCallCount: Int {
            completions.count
        }

        func load(completion: @escaping (EssentialFeed.LoadFeedResult) -> Void) {
            completions.append(completion)
        }

        func completeFeedLoading(at index: Int = 0) {
            completions[index](.success([]))
        }
    }
}

fileprivate extension UIRefreshControl {
    func stimulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach { action in
                (target as NSObject).perform(Selector(action))
            }
        }
    }

}
fileprivate extension FeedViewController {
    var isShowingLoadingIndicator: Bool {
        refreshControl?.isRefreshing == true
    }

    func stimulateUserInitiatedPulltoRefresh() {
        refreshControl?.stimulatePullToRefresh()
    }

    func simulateAppearence() {
        if !isViewLoaded {
            loadViewIfNeeded()
            replaceRefreshControlWithFake()
        }
        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
    }

    func replaceRefreshControlWithFake() {
        let fake = FakeRefreshControl()
        refreshControl?.allTargets.forEach { target in
            refreshControl?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach { action in
                fake.addTarget(target, action: Selector(action), for: .valueChanged)
            }
        }
        refreshControl = fake

    }
}

private class FakeRefreshControl: UIRefreshControl {

    private var _isRefreshing: Bool = false

    override var isRefreshing: Bool {
        return _isRefreshing
    }

    override func beginRefreshing() {
        _isRefreshing = true
    }

    override func endRefreshing() {
        _isRefreshing = false
    }
}
