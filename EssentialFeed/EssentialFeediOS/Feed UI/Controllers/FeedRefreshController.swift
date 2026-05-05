//
//  RefreshController.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 18/04/26.
//

import Foundation
import UIKit

public class FeedRefreshController: NSObject {
    //Just for testing purpose making removing private(set)
    internal(set) public lazy var view:UIRefreshControl = {
        return bind(UIRefreshControl())
    }()
    private let feedViewModel: FeedViewModel
    init(feedViewModel: FeedViewModel) {
        self.feedViewModel = feedViewModel
    }

    @objc func refresh() {
        feedViewModel.loadFeed()
    }

     func bind(_ view: UIRefreshControl) -> UIRefreshControl {
        feedViewModel.onLoadingStateChange = {[weak view]isLoading in
            if isLoading {
                view?.beginRefreshing()
            } else {
                view?.endRefreshing()
            }
        }
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }
}
