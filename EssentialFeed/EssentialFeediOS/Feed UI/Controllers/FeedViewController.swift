//
//  FeedViewController.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 19/03/26.
//


//import EssentialFeed
import UIKit

public final class FeedViewController: UITableViewController, UITableViewDataSourcePrefetching {
    var tableModel = [FeedImageCellController]() {
        didSet {
            tableView.reloadData()
        }
    }

    private(set) var refreshController: FeedRefreshController?

    init(refreshController: FeedRefreshController) {
        super.init(nibName: nil, bundle: nil)
        self.refreshController = refreshController
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Feed"
        refreshControl = refreshController?.view
        tableView.prefetchDataSource = self
        refreshController?.refresh()
    }

    public override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        startRefreshing()
    }

    private func startRefreshing(){
        refreshController?.view.beginRefreshing()
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableModel.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cellController(forIndexAt: indexPath).view()
    }

    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cancelCellControllerLoad(atIndexPath: indexPath)
    }

    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            cellController(forIndexAt: indexPath).preload()
        }
    }

    private func cellController(forIndexAt indexPath: IndexPath) -> FeedImageCellController {
        return tableModel[indexPath.row]
    }

    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(cancelCellControllerLoad)
    }

    private func cancelCellControllerLoad(atIndexPath indexPath: IndexPath) {
        cellController(forIndexAt: indexPath).cancelLoad()
    }
}
