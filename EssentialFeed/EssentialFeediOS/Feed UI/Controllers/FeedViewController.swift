//
//  FeedViewController.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 19/03/26.
//


import EssentialFeed
import UIKit

public final class FeedViewController: UITableViewController, UITableViewDataSourcePrefetching {
    private let feedLoader: FeedLoader
    private var imageLoader: FeedImageDataLoader?
    private var tableModel = [FeedImage]()

    private var cellControllers = [IndexPath: FeedImageCellController]()

    private(set) public var refreshController: RefreshController?

    public init(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader?) {
        self.feedLoader = feedLoader
        self.imageLoader = imageLoader
        self.refreshController = RefreshController(feedLoader: feedLoader)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        refreshController?.onRefresh = {[weak self ] feed in
            self?.tableModel = feed
            self?.tableView.reloadData()
        }
        refreshControl = refreshController?.view
        tableView.prefetchDataSource = self
        refreshController?.refresh()
    }

    public override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        startRefreshing()
    }

    private func startRefreshing(){
        refreshControl?.beginRefreshing()

    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableModel.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cellController(forIndexAt: indexPath).view()
    }

    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        removeCellController(atIndexPath: indexPath)
    }

    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            cellController(forIndexAt: indexPath).preload()
        }
    }

    private func cellController(forIndexAt indexPath: IndexPath) -> FeedImageCellController {
        let cellController = FeedImageCellController(model: tableModel[indexPath.row], imageLoader: imageLoader)
        cellControllers[indexPath] = cellController
        return cellController
    }

    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(removeCellController)
    }

    private func removeCellController(atIndexPath indexPath: IndexPath) {
        cellControllers[indexPath] = nil
    }
}
