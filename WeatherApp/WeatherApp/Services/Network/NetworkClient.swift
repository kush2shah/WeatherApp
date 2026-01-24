//
//  NetworkClient.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation

/// HTTP network client with retry logic
actor NetworkClient {
    private let session: URLSession
    private let maxRetries: Int
    private let retryDelay: TimeInterval

    init(
        session: URLSession = .shared,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1.0
    ) {
        self.session = session
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
    }

    /// Fetch and decode JSON from URL
    /// - Parameters:
    ///   - url: URL string
    ///   - headers: Optional HTTP headers
    /// - Returns: Decoded object
    /// - Throws: APIError if request fails
    func fetch<T: Decodable>(
        url: String,
        headers: [String: String] = [:]
    ) async throws -> T {
        guard let requestURL = URL(string: url) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: requestURL)
        request.timeoutInterval = 30

        // Add headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Add User-Agent for NOAA compliance
        request.setValue("WeatherApp/1.0 (iOS)", forHTTPHeaderField: "User-Agent")

        return try await performRequest(request)
    }

    /// Perform request with retry logic
    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        var lastError: APIError?

        for attempt in 0..<maxRetries {
            do {
                let (data, response) = try await session.data(for: request)

                // Check HTTP response
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.unknown(NSError(domain: "Invalid response", code: 0))
                }

                // Handle HTTP errors
                guard (200...299).contains(httpResponse.statusCode) else {
                    let error = APIError.from(statusCode: httpResponse.statusCode, data: data)

                    // Don't retry client errors (4xx)
                    if (400...499).contains(httpResponse.statusCode) {
                        throw error
                    }

                    lastError = error
                    continue
                }

                // Decode response
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let decoded = try decoder.decode(T.self, from: data)
                    return decoded
                } catch {
                    throw APIError.decodingError(error)
                }

            } catch let error as APIError {
                lastError = error
                // Don't retry authorization or rate limit errors
                if case .unauthorized = error { throw error }
                if case .rateLimitExceeded = error { throw error }
            } catch {
                lastError = .networkError(error)
            }

            // Wait before retry (exponential backoff)
            if attempt < maxRetries - 1 {
                try await Task.sleep(nanoseconds: UInt64(retryDelay * pow(2.0, Double(attempt)) * 1_000_000_000))
            }
        }

        throw lastError ?? .unknown(NSError(domain: "Unknown error", code: 0))
    }
}
