//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 30/08/25.
//

import Foundation

public protocol HTTPClient {
    func load(from url: URL, onCompletion: @escaping (HTTPClientResult) -> Void)
}

public enum HTTPClientResult{
    case success(Data,HTTPURLResponse)
    case failure(Error)
}
