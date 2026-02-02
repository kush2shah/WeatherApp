//
//  NetworkClientProtocol.swift
//  WeatherApp
//
//  Created by Kush Shah on 2/1/26.
//

import Foundation

/// Protocol for HTTP network clients, enabling dependency injection and testing
protocol NetworkClientProtocol: Sendable {
    /// Fetch and decode JSON from URL
    /// - Parameters:
    ///   - url: URL string
    ///   - headers: Optional HTTP headers
    /// - Returns: Decoded object
    /// - Throws: APIError if request fails
    func fetch<T: Decodable>(
        url: String,
        headers: [String: String]
    ) async throws -> T
}

// Default parameter extension
extension NetworkClientProtocol {
    func fetch<T: Decodable>(url: String) async throws -> T {
        try await fetch(url: url, headers: [:])
    }
}
