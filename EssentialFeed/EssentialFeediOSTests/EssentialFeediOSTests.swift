//
//  EssentialFeediOSTests.swift
//  EssentialFeediOSTests
//
//  Created by Praveenraj T on 16/03/26.
//

import XCTest
import EssentialFeed

class FeedViewController: UIViewController {
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

        loader.load(completion: {_ in })
    }
}

final class EssentialFeediOSTests: XCTestCase {

    func test_init_doesNotLoadFeed() {
        let loader = LoaderSpy()
        _ = FeedViewController(loader: loader)
        XCTAssertEqual(loader.loadCallCount, 0)
    }

    func test_viewDidLoad_loadsFeed() {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        sut.loadViewIfNeeded()
        XCTAssertEqual(loader.loadCallCount, 1)
    }

    class LoaderSpy: FeedLoader {

        private(set) var loadCallCount: Int = 0

        func load(completion: @escaping (EssentialFeed.LoadFeedResult) -> Void) {
            loadCallCount += 1
        }
    }
}
