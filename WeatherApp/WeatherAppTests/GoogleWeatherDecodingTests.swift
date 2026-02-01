//
//  GoogleWeatherDecodingTests.swift
//  WeatherAppTests
//
//  Created for debugging Google Weather decoding
//

import XCTest
@testable import WeatherApp

final class GoogleWeatherDecodingTests: XCTestCase {

    func testDecodeCurrentConditions() throws {
        let json = """
        {
          "currentTime": "2026-02-01T04:20:22.355995530Z",
          "timeZone": {
            "id": "America/Los_Angeles"
          },
          "isDaytime": false,
          "weatherCondition": {
            "iconBaseUri": "https://maps.gstatic.com/weather/v1/mostly_cloudy_night",
            "description": {
              "text": "Mostly cloudy",
              "languageCode": "en"
            },
            "type": "MOSTLY_CLOUDY"
          },
          "temperature": {
            "degrees": 14.2,
            "unit": "CELSIUS"
          },
          "feelsLikeTemperature": {
            "degrees": 13.9,
            "unit": "CELSIUS"
          },
          "dewPoint": {
            "degrees": 9.1,
            "unit": "CELSIUS"
          },
          "relativeHumidity": 72,
          "uvIndex": 0,
          "precipitation": {
            "probability": {
              "percent": 10,
              "type": "RAIN"
            },
            "snowQpf": {
              "quantity": 0,
              "unit": "MILLIMETERS"
            },
            "qpf": {
              "quantity": 0,
              "unit": "MILLIMETERS"
            }
          },
          "airPressure": {
            "meanSeaLevelMillibars": 1019.68
          },
          "wind": {
            "direction": {
              "degrees": 20,
              "cardinal": "NORTH_NORTHEAST"
            },
            "speed": {
              "value": 6,
              "unit": "KILOMETERS_PER_HOUR"
            },
            "gust": {
              "value": 10,
              "unit": "KILOMETERS_PER_HOUR"
            }
          },
          "visibility": {
            "distance": 16,
            "unit": "KILOMETERS"
          },
          "cloudCover": 88
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let response = try decoder.decode(GWCurrentConditionsResponse.self, from: data)

        XCTAssertEqual(response.weatherCondition?.type, "MOSTLY_CLOUDY")
        XCTAssertEqual(response.weatherCondition?.description.text, "Mostly cloudy")
        XCTAssertEqual(response.temperature?.degrees, 14.2)
        XCTAssertEqual(response.airPressure?.meanSeaLevelMillibars, 1019.68)
    }

    func testDecodeHourlyForecast() throws {
        let json = """
        {
          "forecastHours": [
            {
              "interval": {
                "startTime": "2026-02-01T04:00:00Z",
                "endTime": "2026-02-01T05:00:00Z"
              },
              "weatherCondition": {
                "iconBaseUri": "https://maps.gstatic.com/weather/v1/cloudy",
                "description": {
                  "text": "Cloudy",
                  "languageCode": "en"
                },
                "type": "CLOUDY"
              },
              "temperature": {
                "unit": "CELSIUS",
                "degrees": 14.3
              },
              "precipitation": {
                "probability": {
                  "type": "RAIN",
                  "percent": 10
                },
                "snowQpf": {
                  "unit": "MILLIMETERS",
                  "quantity": 0
                },
                "qpf": {
                  "unit": "MILLIMETERS",
                  "quantity": 0
                }
              },
              "iceThickness": {
                "unit": "MILLIMETERS",
                "thickness": 0
              }
            }
          ]
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let response = try decoder.decode(GWHourlyForecastResponse.self, from: data)

        XCTAssertEqual(response.forecastHours.count, 1)
        XCTAssertEqual(response.forecastHours[0].weatherCondition?.type, "CLOUDY")
        XCTAssertEqual(response.forecastHours[0].temperature?.degrees, 14.3)
        XCTAssertEqual(response.forecastHours[0].iceThickness?.thickness, 0)
    }
}
