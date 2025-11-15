//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 15/11/25.
//

import Foundation


enum FeedCachePolicy{

    private static let calendar = Calendar(identifier: .gregorian)
    private static var maxCacheAgeInDays: Int {
        7
    }

    internal static func validate(_ timeStamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timeStamp) else {
            return false
        }
        return date < maxCacheAge
    }
}
