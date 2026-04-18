//
//  RefreshController.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 18/04/26.
//

import Foundation
import UIKit
import EssentialFeed

public class RefreshController: NSObject {
    //Just for testing purpose making removing private(set)
    internal(set) public lazy var view:UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()
    private let feedLoader: FeedLoader
    public var onRefresh: (([FeedImage])->Void)?
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    @objc func refresh() {
        view.beginRefreshing()
        feedLoader.load{[weak self]result in
            if let feed = try? result.get() {
                self?.onRefresh?(feed)
            }
            self?.view.endRefreshing()
        }
    }
}
