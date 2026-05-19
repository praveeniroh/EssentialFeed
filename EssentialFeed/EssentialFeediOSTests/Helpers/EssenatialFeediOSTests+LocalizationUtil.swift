//
//  EssenatialFeediOSTests+LocalizationUtil.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 20/05/26.
//

import Foundation
import XCTest

extension FeedViewControllerIntegrationTests {
    func localize(_ localizationKey: String, file: StaticString = #file, line: UInt = #line) -> String {
        let bundle = Bundle(for: FeedViewController.self)
        let localizedString = bundle.localizedString(forKey: localizationKey, value: nil, table: "Feed")

        XCTAssertNotEqual(localizationKey, localizedString, "Missing localization for the key: \(localizationKey).")
        return localizedString
    }
}
