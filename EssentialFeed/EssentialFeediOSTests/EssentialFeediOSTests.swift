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

        sut.stimulateUserInitiatedPulltoRefresh()
        XCTAssertTrue(sut.isShowingLoadingIndicator)
        loader.completeFeedLoadingWithError(at: 2)
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

    func test_loadFeedCompletion_doesNotAlterLoadedImageOnError() {
        let (sut, loader) = makeSUT()
        let image0 = makeImage(description: "a description", location: "a location")
        sut.simulateAppearence()
        loader.completeFeedLoading(with: [image0], at: 0)
        assertThat(sut, isRendering: [image0])
        
        sut.stimulateUserInitiatedPulltoRefresh()
        loader.completeFeedLoadingWithError(at: 1)
        assertThat(sut, isRendering: [image0])
    }

    func test_feedImageView_loadsFeedImageOnVisible() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: [image0, image1])

        XCTAssertEqual(loader.loadedImageURLs, [], "Expected no image URL requests until views become visible")

        sut.simulateFeedImageViewVisible(at: 0)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url], "Expected first image URL request once first view becomes visible")

        sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url], "Expected second image URL request once second view also becomes visible")
    }

    func test_feedImageView_cancelsImageLoadingWhenNotVisible() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: [image0, image1])

        XCTAssertEqual(loader.loadedImageURLs, [], "Expected no image URL requests until views become visible")

        sut.simulateFeedImageViewNotVisible(at: 0)
        XCTAssertEqual(loader.cancelledImageURLs, [image0.url], "Expected to cancel image URL request when view becomes invisible")

        sut.simulateFeedImageViewNotVisible(at: 1)
        XCTAssertEqual(loader.cancelledImageURLs, [image0.url, image1.url], "Expected second image URL request once second view also becomes visible")
    }

    func test_feedImageViewLoadingIndicator_visibleWhileLoadingImage() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: [image0, image1])

        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)


        XCTAssertEqual(view0?.isShowingImageLoadingIndicator, true, "Expected to show shimmering while loading image data")
        XCTAssertEqual(view1?.isShowingImageLoadingIndicator, true, "Expected to show shimmering while loading image data")

        loader.completeImageLoading(at: 0)
        loader.completeImageLoadingWithError(at: 1)

        XCTAssertEqual(view0?.isShimmering, false, "Expected to not show shimmering while loading image data")
        XCTAssertEqual(view1?.isShimmering, false, "Expected to not show shimmering while loading image data")

        sut.simulateFeedImageViewNotVisible(at: 0)
        XCTAssertEqual(view0?.isShimmering,false, "Expected to cancel image URL request when view becomes invisible")

        sut.simulateFeedImageViewNotVisible(at: 1)
        XCTAssertEqual(view1?.isShimmering, false, "Expected second image URL request once second view also becomes visible")
    }


    func test_feedImageView_loadsImageData() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: [image0, image1])

        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)


        XCTAssertEqual(view0?.imageData, nil, "Image data should be nil before loading image")
        XCTAssertEqual(view1?.imageData, nil, "Image data should be nil before loading image")

        let imageData0 = UIImage.make(withColor: .red).pngData()!
        loader.completeImageLoading(with: imageData0, at: 0)

        XCTAssertEqual(view0?.imageData, imageData0, "Expected to show image data after image loading completion")
        XCTAssertEqual(view1?.imageData, .none, "Expected not to show image data after image loading completion")

        let imageData1 = UIImage.make(withColor: .blue).pngData()!
        loader.completeImageLoading(with: imageData1, at: 1)
        XCTAssertEqual(view0?.imageData, imageData0, "Expected to show image data after image loading completion")
        XCTAssertEqual(view1?.imageData, imageData1, "Expected to show image data after image loading completion")
    }

    func test_feedImageView_showsRetryButtonOnImageDataLoadError() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: [image0, image1])

        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)


        XCTAssertEqual(view0?.showsRetryButton, false, "Expected not to show retry button while loading image")
        XCTAssertEqual(view1?.showsRetryButton, false, "Expected not to show retry button while loading image")

        let imageData0 = UIImage.make(withColor: .red).pngData()!
        loader.completeImageLoading(with: imageData0, at: 0)

        XCTAssertEqual(view0?.showsRetryButton, false, "Expected not to show retry button after image loading succeeds")
        XCTAssertEqual(view1?.showsRetryButton, false, "Expected not to show retry button while image loading")

        loader.completeImageLoadingWithError(at: 1)
        XCTAssertEqual(view0?.showsRetryButton, false, "Expected not to show retry button after image loading succeeds")
        XCTAssertEqual(view1?.showsRetryButton, true, "Expected to show retry button after image loading fails")
    }

    func test_feedImageViewRetryButton_visibleOnInvalidData() {
        let feedImage = makeImage()
        let (sut, loader) = makeSUT()

        sut.simulateAppearence()
        loader.completeFeedLoading(with: [feedImage])

        let view = sut.simulateFeedImageViewVisible(at: 0)

        let invalidImageData = Data("invalid data".utf8)
        loader.completeImageLoading(with: invalidImageData, at: 0)

        XCTAssertEqual(view?.showsRetryButton, true, "Expected to show retry button when image data is invalid")
    }

    func test_feedImageViewRetryButtonAction_retriedImageLoading() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)

        let (sut, loader) = makeSUT()
        sut.simulateAppearence()

        loader.completeFeedLoading(with: [image0, image1])

        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)

        loader.completeImageLoadingWithError(at: 0)
        loader.completeImageLoadingWithError(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url])

        view0?.simulateRetryAction()
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url, image0.url])

        view1?.simulateRetryAction()
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url, image0.url, image1.url])
    }

    func test_feedImageView_prefetchesImageOnNearVisibleRow() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        
        let (sut, loader) = makeSUT()
        sut.simulateAppearence()
        
        loader.completeFeedLoading(with: [image0, image1])

        sut.simulateFeedImageViewNearVisible(at: 0)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url])

        sut.simulateFeedImageViewNearVisible(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url])
    }

    func test_feedImageView_cancelsPrefetchesImageOnNotNearVisibleRow() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)

        let (sut, loader) = makeSUT()
        sut.simulateAppearence()

        loader.completeFeedLoading(with: [image0, image1])

        sut.simulateFeedImageViewNotNearVisible(at: 0)
        XCTAssertEqual(loader.cancelledImageURLs, [image0.url])
        sut.simulateFeedImageViewNotNearVisible(at: 1)
        XCTAssertEqual(loader.cancelledImageURLs, [image0.url, image1.url])

    }

    // MARK: Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedUIComposer.makeFeedViewController(feedLoader: loader, imageLoader: loader)
        trackForMemoryLead(sut, file: file, line: line)
        trackForMemoryLead(loader, file: file, line: line)
        return (sut, loader)
    }

    private func makeImage(description: String? = nil, location: String? = nil, url: URL = URL(string: "https://any-url.com")!) -> FeedImage{
        FeedImage(id: UUID(), description: description, location: location, url: url)
    }

    private func assertThat(_ sut: FeedViewController, isRendering images: [FeedImage], file: StaticString = #file, line: UInt = #line) {
        guard sut.numberOfRenderedFeedImageViews() == images.count else {
            return XCTFail("Expected to render \(images.count) but only \(sut.numberOfRenderedFeedImageViews()) rendered",file: file, line: line )
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

    class LoaderSpy: FeedLoader, FeedImageDataLoader {
        
        private var completions: [(EssentialFeed.LoadFeedResult) -> Void] = []
        var loadCallCount: Int {
            completions.count
        }

        var loadedImageURLs: [URL]{
            imageRequests.map({$0.url})
        }
        private(set) var cancelledImageURLs: [URL] = []
        private(set) var imageRequests = [(url: URL, completion: (Result) -> Void)]()

        func load(completion: @escaping (EssentialFeed.LoadFeedResult) -> Void) {
            completions.append(completion)
        }

        func completeFeedLoading(with feedImages: [FeedImage] = [],at index: Int = 0) {
            completions[index](.success(feedImages))
        }

        func completeFeedLoadingWithError(at index: Int) {
            let error = NSError(domain: "test", code: 0, userInfo: nil)
            completions[index](.failure(error))
        }

        struct LoaderTaskSpy: FeedImageDataLoaderTask {
            let cancelCallback: () -> Void
            func cancel() {
                cancelCallback()
            }
        }

        func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
            imageRequests.append((url, completion))
            return LoaderTaskSpy {[weak self] in
                self?.cancelledImageURLs.append(url)
            }
        }

        func completeImageLoading(with imageData: Data = Data(), at index: Int = 0) {
            imageRequests[index].completion(.success(imageData))
        }

        func completeImageLoadingWithError(at index: Int = 0) {
            imageRequests[index].completion(.failure(anyNSError()))
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

fileprivate extension UIButton {
    func stimulateTouchUpInsideAction() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .touchUpInside)?.forEach { action in
                (target as NSObject).perform(Selector(action))
            }
        }
    }
}

fileprivate extension FeedViewController {
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

    var isShowingImageLoadingIndicator : Bool {
        feedImageContainer.isShimmering
    }

    var imageData: Data? {
        feedImageView.image?.pngData()
    }

    var showsRetryButton: Bool {
        !feedImageRetryButton.isHidden
    }

    func simulateRetryAction() {
        feedImageRetryButton.stimulateTouchUpInsideAction()
    }
}


private extension UIImage {
    static func make(withColor color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: rect.size, format: format).image { rendererContext in
            color.setFill()
            rendererContext.fill(rect)
        }
    }
}
