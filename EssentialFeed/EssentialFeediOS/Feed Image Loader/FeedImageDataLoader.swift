//
//  FeedImageDataLoader.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 18/04/26.
//

import Foundation

public protocol FeedImageDataLoader {
    typealias Result = Swift.Result<Data, Error>
    func loadImageData(from url: URL, completion: @escaping (Result) -> Void) -> FeedImageDataLoaderTask
}
