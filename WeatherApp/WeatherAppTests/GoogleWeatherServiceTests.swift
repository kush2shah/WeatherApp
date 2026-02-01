//
//  GoogleWeatherServiceTests.swift
//  WeatherAppTests
//
//  Created by Implementation Plan
//

import XCTest
@testable import WeatherApp
import CoreLocation

final class GoogleWeatherServiceProxyTests: XCTestCase {

    func testProxyConfigurationPresent() {
        // Verify proxy configuration is set
        XCTAssertFalse(Config.cloudRunProxyURL.isEmpty, "Cloud Run proxy URL should be configured")
        XCTAssertFalse(Config.cloudRunProxyAPIKey.isEmpty, "Cloud Run proxy API key should be configured")
    }

    func testServiceAvailability() {
        // Service should be available when proxy is configured
        let service = GoogleWeatherService()
        XCTAssertTrue(service.isAvailable, "GoogleWeatherService should be available with proxy config")
    }

    func testFetchWeatherWithProxy() async throws {
        // Integration test - requires proxy to be deployed
        let service = GoogleWeatherService()
        let location = Location(
            name: "San Francisco",
            clCoordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            timezone: .current
        )

        let weather = try await service.fetchWeather(for: location)

        // Verify we got valid weather data
        XCTAssertEqual(weather.source, WeatherSource.googleWeather)
        XCTAssertNotNil(weather.current)
        XCTAssertFalse(weather.hourly.isEmpty)
        XCTAssertFalse(weather.daily.isEmpty)
    }
}
