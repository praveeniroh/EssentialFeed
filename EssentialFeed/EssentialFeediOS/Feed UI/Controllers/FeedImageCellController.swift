//
//  FeedImageCellController.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 18/04/26.
//

import EssentialFeed
import Foundation
import UIKit

final class FeedImageCellController {
    private var task: FeedImageDataLoaderTask?
    private let model: FeedImage
    private let imageLoader: FeedImageDataLoader?

    init(model: FeedImage, imageLoader: FeedImageDataLoader?) {
        self.model = model
        self.imageLoader = imageLoader
    }

    func cancelLoad() {
        task?.cancel()
        task = nil
    }

    func view() -> UITableViewCell {
        let cell = FeedImageCell()
        cell.locationContainer.isHidden = model.location == nil
        cell.descriptionLabel.text = model.description
        cell.locationLabel.text = model.location
        cell.feedImageContainer.startShimmering()
        cell.feedImageRetryButton.isHidden = true

        let loadImage = {[weak self, weak cell ] in
            guard let cell, let self else {
                return
            }
            task = imageLoader?.loadImageData(from: model.url) {[weak cell] result in
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

    func preload() {
        task = imageLoader?.loadImageData(from: model.url, completion: {_ in})
    }
}
