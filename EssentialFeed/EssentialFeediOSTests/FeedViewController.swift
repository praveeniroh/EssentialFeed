//
//  FeedViewController.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 19/03/26.
//


import EssentialFeed
import UIKit

public class FeedViewController: UITableViewController {
    private let loader: FeedLoader
    public init(loader: FeedLoader) {
        self.loader = loader
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
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
        loader.load{[weak self]_ in
            self?.refreshControl?.endRefreshing()
        }
    }
}
