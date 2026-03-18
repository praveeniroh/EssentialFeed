//
//  EssentialFeediOSTests.swift
//  EssentialFeediOSTests
//
//  Created by Praveenraj T on 16/03/26.
//

import XCTest
import EssentialFeed

class FeedViewController: UITableViewController {
    private let loader: FeedLoader
    init(loader: FeedLoader) {
        self.loader = loader
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        load()
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        startRefreshing()
    }

    private func startRefreshing(){
        refreshControl?.beginRefreshing()

    }

    @objc private func load() {
        loader.load{[weak self]_ in
            self?.refreshControl?.endRefreshing()
        }
    }
}

final class EssentialFeediOSTests: XCTestCase {

    func test_init_doesNotLoadFeed() {
        let (_,loader) = makeSUT()
        XCTAssertEqual(loader.loadCallCount, 0)
    }

    func test_viewDidLoad_loadsFeed() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        XCTAssertEqual(loader.loadCallCount, 1)
    }

    func test_pullToRefresh_loadFeed() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()

        stimulatePullToRefresh(sut: sut)
        XCTAssertEqual(loader.loadCallCount, 2)

        stimulatePullToRefresh(sut: sut)
        XCTAssertEqual(loader.loadCallCount, 3)
    }

    func test_viewDidLoad_showsLoadingIndicator() {
        let (sut, _) = makeSUT()

        sut.simulateAppearence()
        XCTAssertEqual(sut.refreshControl?.isRefreshing, true)
    }

    func test_viewDidLoad_HideLoadingIndicator() {
        let (sut, loader) = makeSUT()

        sut.simulateAppearence()
        loader.completeFeedLoading()

        XCTAssertEqual(sut.refreshControl?.isRefreshing, false)
    }

    // MARK: Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        trackForMemoryLead(sut, file: file, line: line)
        trackForMemoryLead(loader, file: file, line: line)
        return (sut, loader)
    }

    private func stimulatePullToRefresh(sut: FeedViewController) {
        sut.refreshControl?.allTargets.forEach { target in
            sut.refreshControl?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach { action in
                (target as NSObject).perform(Selector(action))
            }
        }
    }

    class LoaderSpy: FeedLoader {
        private var completions: [(EssentialFeed.LoadFeedResult) -> Void] = []
        var loadCallCount: Int {
            completions.count
        }

        func load(completion: @escaping (EssentialFeed.LoadFeedResult) -> Void) {
            completions.append(completion)
        }

        func completeFeedLoading() {
            completions[0](.success([]))
        }
    }
}

fileprivate extension FeedViewController {
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
