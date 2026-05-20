//
//  UIButton+TestHelpers.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 20/05/26.
//

internal import UIKit

extension UIButton {
    func stimulateTouchUpInsideAction() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .touchUpInside)?.forEach { action in
                (target as NSObject).perform(Selector(action))
            }
        }
    }
}
