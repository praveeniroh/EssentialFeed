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

    func test_loadFeedCompletion_rendersSuccessfullyLoadedFeed() {
        let image0 = makeImage(description: "a description", location: "a location")
        let image1 = makeImage(description: nil, location: "a location")
        let image2 = makeImage(description: "a description", location: nil)
        let image3 = makeImage(description: nil, location: nil)
        let (sut, loader) = makeSUT()
        sut.simulateAppearence()
        
        assertThat(sut, isRendering: [])
        loader.completeFeedLoading(with: [image0], at: 0)
        assertThat(sut, isRendering: [image0])

        sut.stimulateUserInitiatedPulltoRefresh()
        loader.completeFeedLoading(with: [image0,image1, image2, image3], at: 1)
        assertThat(sut, isRendering: [image0,image1, image2, image3])
    }


    // MARK: Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        trackForMemoryLead(sut, file: file, line: line)
        trackForMemoryLead(loader, file: file, line: line)
        return (sut, loader)
    }

    private func makeImage(description: String? = nil, location: String? = nil, url: URL = URL(string: "https://any-url.com")!) -> FeedImage{
        FeedImage(id: UUID(), description: description, location: location, url: url)
    }

    private func assertThat(_ sut: FeedViewController, isRendering images: [FeedImage]) {
        guard sut.numberOfRenderedFeedImageViews() == images.count else {
            return XCTFail("Expected to render \(images.count) but only \(sut.numberOfRenderedFeedImageViews()) rendered")
        }

        images.enumerated().forEach({assertThat(sut, hasViewConfigured: $0.1, at: $0.0)})
    }
    private func assertThat(_ sut: FeedViewController,hasViewConfigured image: FeedImage, at index: Int, file: StaticString = #file, line: UInt = #line) {
        guard let view = sut.feedImageView(at: index) as? FeedImageCell else {
            XCTFail("Cell not found at \(index)", file: file, line: line)
            return
        }
        XCTAssertEqual(view.isLocationShown, image.location != nil, file: file, line: line)
        XCTAssertEqual(view.locationText, image.location, file: file, line: line)
        XCTAssertEqual(view.descriptionText, image.description, file: file, line: line)
    }

    class LoaderSpy: FeedLoader {
        private var completions: [(EssentialFeed.LoadFeedResult) -> Void] = []
        var loadCallCount: Int {
            completions.count
        }

        func load(completion: @escaping (EssentialFeed.LoadFeedResult) -> Void) {
            completions.append(completion)
        }

        func completeFeedLoading(with feedImages: [FeedImage] = [],at index: Int = 0) {
            completions[index](.success(feedImages))
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

fileprivate extension FeedImageCell {
    var isLocationShown: Bool {
        !locationContainer.isHidden
    }

    var locationText: String? {
        locationLabel.text
    }

    var descriptionText: String? {
        descriptionLabel.text
    }
}
