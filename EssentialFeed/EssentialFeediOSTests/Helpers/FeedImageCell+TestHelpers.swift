//
//  FeedImageCell+TestHelpers.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 20/05/26.
//

import Foundation
internal import UIKit

extension FeedImageCell {
    var isLocationShown: Bool {
        !locationContainer.isHidden
    }

    var locationText: String? {
        locationLabel.text
    }

    var descriptionText: String? {
        descriptionLabel.text
    }

    var isShowingImageLoadingIndicator : Bool {
        feedImageContainer.isShimmering
    }

    var imageData: Data? {
        feedImageView.image?.pngData()
    }

    var showsRetryButton: Bool {
        !feedImageRetryButton.isHidden
    }

    func simulateRetryAction() {
        feedImageRetryButton.stimulateTouchUpInsideAction()
    }
}
