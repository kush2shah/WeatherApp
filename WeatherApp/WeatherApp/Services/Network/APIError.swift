//
//  APIError.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation

/// Comprehensive API error types
enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case httpError(statusCode: Int, data: Data?)
    case decodingError(Error)
    case encodingError(Error)
    case rateLimitExceeded
    case unauthorized
    case serviceUnavailable
    case timeout
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let statusCode, _):
            return "HTTP error \(statusCode): \(httpStatusMessage(statusCode))"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .unauthorized:
            return "Unauthorized. Please check your API key."
        case .serviceUnavailable:
            return "Service temporarily unavailable"
        case .timeout:
            return "Request timed out"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }

    private func httpStatusMessage(_ code: Int) -> String {
        switch code {
        case 400: return "Bad Request"
        case 401: return "Unauthorized"
        case 403: return "Forbidden"
        case 404: return "Not Found"
        case 429: return "Too Many Requests"
        case 500: return "Internal Server Error"
        case 502: return "Bad Gateway"
        case 503: return "Service Unavailable"
        case 504: return "Gateway Timeout"
        default: return "Error"
        }
    }

    /// Create APIError from HTTP status code
    static func from(statusCode: Int, data: Data? = nil) -> APIError {
        switch statusCode {
        case 401:
            return .unauthorized
        case 429:
            return .rateLimitExceeded
        case 503:
            return .serviceUnavailable
        default:
            return .httpError(statusCode: statusCode, data: data)
        }
    }
}
