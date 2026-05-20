//
//  FeedLocalizationTests.swift
//  EssentialFeediOSTests
//
//  Created by Praveenraj T on 20/05/26.
//

import XCTest

final class FeedLocalizationTests: XCTestCase {
    func test_localization_hasValueForAllKeysInAllSupportedLocalization() {
        let table = "Feed"
        let bundle = Bundle(for: FeedViewController.self)
        
        let localizationBundles = allLocalizationBundles(bundle: bundle)
        let localizationKeys = allLocalizedKeys(in: localizationBundles, table: table)
        localizationBundles.forEach { (bundle, localization) in
            localizationKeys.forEach { key in
                let localizedString = bundle.localizedString(forKey: key, value: nil, table: table)
                if key == localizedString {
                    XCTFail("Missing translation for \(key) in \(localization)")
                }
            }
        }

    }

    typealias LocalizedBundle = (bundle: Bundle, localization: String)

    private func allLocalizationBundles(bundle: Bundle, file: StaticString = #file, line: UInt = #line) -> [LocalizedBundle] {
        return bundle.localizations.compactMap { localization in
            guard let path = bundle.path(forResource: localization, ofType: "lproj"), let bundle = Bundle(path: path) else {
                XCTFail("Couldn't find path for \(localization)", file: file, line: line)
                return nil
            }
            print(">>>> \(localization)")
            return (bundle, localization)
        }
    }

    private func allLocalizedKeys(in bundles: [LocalizedBundle], table: String, file: StaticString = #file, line: UInt = #line) -> Set<String> {
        return bundles.reduce([]) {(result, current) in
            guard let path = current.bundle.path(forResource: table, ofType: "strings"),
                  let strings = NSDictionary(contentsOfFile: path),
                    let keys = strings.allKeys as? [String]
            else {
                XCTFail("Couldn't load localized strings for localization: \(current.localization)", file: file, line: line)
                                return result
            }
            return result.union(Set(keys))
        }
    }
}
