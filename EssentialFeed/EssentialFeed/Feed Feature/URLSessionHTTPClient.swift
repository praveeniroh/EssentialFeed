//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 23/09/25.
//

import Foundation


public class URLSessionHTTPClient: HTTPClient{
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    private struct UnexpectedValuesRepresentaionError: Error {}

    public func get(from url: URL, onCompletion: @escaping (HTTPClientResult) -> Void) {
//        let url = URL(string: "https://somewrong-url.com")! //URL Mismatch Failing case
        session.dataTask(with: url) { data, response, error in
            if let error {
                onCompletion(.failure(error))
            } else if let data, let httpURLResponse = response as? HTTPURLResponse {
                onCompletion(.success(data, httpURLResponse))
            } else {
                onCompletion(.failure(UnexpectedValuesRepresentaionError())) // Error supplied is nil
            }
        }.resume()
    }
}
