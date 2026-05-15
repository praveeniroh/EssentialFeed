//
//  RefreshController.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 18/04/26.
//

import Foundation
import UIKit

protocol FeedRefreshViewControllerDelegate {
    func didRequestRefresh()
}
public class FeedRefreshController: NSObject, FeedLoadingView {
    //Just for testing purpose making removing private(set)
    internal(set) public lazy var view = loadView()
    private let delegate: FeedRefreshViewControllerDelegate
    init(delegate: FeedRefreshViewControllerDelegate) {
        self.delegate = delegate
    }

    @objc func refresh() {
        delegate.didRequestRefresh()
    }

    func display(_ viewModel: FeedLoadingViewModel) {
        if viewModel.isLoading {
            view.beginRefreshing()
        } else {
            view.endRefreshing()
        }
    }

    private func loadView() -> UIRefreshControl {
         let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }
}
