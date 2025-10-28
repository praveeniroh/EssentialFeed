//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 28/10/25.
//

import Foundation

internal struct RemoteFeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}
