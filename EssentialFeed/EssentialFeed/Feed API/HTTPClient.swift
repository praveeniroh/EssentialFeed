//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 30/08/25.
//

import Foundation

public protocol HTTPClient {
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func get(from url: URL, onCompletion: @escaping (HTTPClientResult) -> Void)
}

public enum HTTPClientResult{
    case success(Data,HTTPURLResponse)
    case failure(Error)
}
