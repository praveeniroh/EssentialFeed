//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Praveenraj T on 13/11/25.
//

import Foundation

func anyURL() -> URL {
    return URL(string: "https://some-url.com")!
}

func anyNSError() -> NSError {
    NSError(domain: "Any Error", code: 0)
}
