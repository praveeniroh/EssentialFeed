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

    private var imageLoaderTask = [IndexPath: FeedImageDataLoaderTask]()
    public init(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader?) {
        self.feedLoader = feedLoader
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        tableView.prefetchDataSource = self
        load()
    }

    public override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        startRefreshing()
    }

    private func startRefreshing(){
        refreshControl?.beginRefreshing()

    }

    @objc private func load() {
        startRefreshing()
        feedLoader.load{[weak self]result in
            if let feed = try? result.get() {
                self?.tableModel = feed
                self?.tableView.reloadData()
            }
            self?.refreshControl?.endRefreshing()
        }
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableModel.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = FeedImageCell()
        let cellModel = tableModel[indexPath.row]
        cell.locationContainer.isHidden = cellModel.location == nil
        cell.descriptionLabel.text = cellModel.description
        cell.locationLabel.text = cellModel.location
        cell.feedImageContainer.startShimmering()
        cell.feedImageRetryButton.isHidden = true

        let loadImage = {[weak self, weak cell ] in
            guard let cell, let self else {
                return
            }
            imageLoaderTask[indexPath] = imageLoader?.loadImageData(from: cellModel.url) {[weak cell] result in
                switch result {
                case .success(let imageData):
                    if let image = UIImage(data: imageData) {
                        cell?.feedImageView.image = image
                    } else {
                        cell?.feedImageRetryButton.isHidden = false
                    }
                case .failure:
                    cell?.feedImageRetryButton.isHidden = false
                }
                cell?.stopShimmering()
            }
        }
        cell.onImageLoadRetry = loadImage
        loadImage()
        return cell
    }

    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        canceImageLoaderTask(atIndexPath: indexPath)
    }

    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let feedModel = tableModel[indexPath.row]
            imageLoaderTask[indexPath] = self.imageLoader?.loadImageData(from: feedModel.url, completion: {_ in})
        }
    }

    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(canceImageLoaderTask)
    }

    private func canceImageLoaderTask(atIndexPath indexPath: IndexPath) {
        imageLoaderTask[indexPath]?.cancel()
        imageLoaderTask[indexPath] = nil
    }
}
