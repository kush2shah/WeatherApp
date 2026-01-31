# Google Weather API Proxy Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Go-based Cloud Run proxy service that handles OAuth authentication and caching for Google Weather API, and update iOS app to use it.

**Architecture:** Three-layer system: iOS app authenticates to proxy with API key, proxy caches responses in-memory with endpoint-specific TTLs, proxy authenticates to Google Weather API using service account OAuth via ADC.

**Tech Stack:** Go (net/http, Google auth libraries), Cloud Run, iOS Swift (NetworkClient already supports headers)

---

## Task 1: Initialize Go Project

**Files:**
- Create: `weather-proxy/`
- Create: `weather-proxy/go.mod`
- Create: `weather-proxy/.env.example`
- Create: `weather-proxy/README.md`

**Step 1: Create project directory**

```bash
mkdir -p weather-proxy
cd weather-proxy
```

**Step 2: Initialize Go module**

```bash
go mod init github.com/kushs/weather-proxy
```

**Step 3: Add dependencies**

```bash
go get cloud.google.com/go/compute/metadata
go get golang.org/x/oauth2/google
```

**Step 4: Create .env.example**

Create `weather-proxy/.env.example`:

```bash
PROXY_API_KEY=your-api-key-here
PORT=8080
```

**Step 5: Create README**

Create `weather-proxy/README.md`:

```markdown
# Weather Proxy

Cloud Run proxy for Google Weather API with OAuth authentication and caching.

## Local Development

```bash
export PROXY_API_KEY=12e41cad6b1132308c75673905f0f17220623e481366f584f1f1d730ae1c6f78
export PORT=8080
go run .
```

## Deploy

```bash
gcloud run deploy weather-proxy \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --service-account weather-app@project-85dca6cf-ba5d-4efd-9df.iam.gserviceaccount.com \
  --set-env-vars PROXY_API_KEY=12e41cad6b1132308c75673905f0f17220623e481366f584f1f1d730ae1c6f78 \
  --memory 256Mi \
  --max-instances 10
```
```

**Step 6: Commit**

```bash
git add weather-proxy/
git commit -m "chore: initialize Go project for weather proxy

Set up Go module, dependencies, and documentation.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 2: Implement Cache Manager

**Files:**
- Create: `weather-proxy/cache.go`

**Step 1: Create cache.go with types and initialization**

Create `weather-proxy/cache.go`:

```go
package main

import (
	"fmt"
	"sync"
	"time"
)

// CacheEntry represents a cached response with expiration
type CacheEntry struct {
	Data      []byte
	ExpiresAt time.Time
}

// Cache provides thread-safe in-memory caching with TTL
type Cache struct {
	mu      sync.RWMutex
	entries map[string]CacheEntry
}

// NewCache creates a new cache instance
func NewCache() *Cache {
	cache := &Cache{
		entries: make(map[string]CacheEntry),
	}

	// Start cleanup goroutine
	go cache.cleanupExpired()

	return cache
}

// Get retrieves a cached entry if it exists and hasn't expired
func (c *Cache) Get(key string) ([]byte, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()

	entry, exists := c.entries[key]
	if !exists {
		return nil, false
	}

	if time.Now().After(entry.ExpiresAt) {
		return nil, false
	}

	return entry.Data, true
}

// Set stores a value in the cache with the specified TTL
func (c *Cache) Set(key string, data []byte, ttl time.Duration) {
	c.mu.Lock()
	defer c.mu.Unlock()

	c.entries[key] = CacheEntry{
		Data:      data,
		ExpiresAt: time.Now().Add(ttl),
	}
}

// cleanupExpired removes expired entries every 5 minutes
func (c *Cache) cleanupExpired() {
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	for range ticker.C {
		c.mu.Lock()
		now := time.Now()
		for key, entry := range c.entries {
			if now.After(entry.ExpiresAt) {
				delete(c.entries, key)
			}
		}
		c.mu.Unlock()
	}
}

// MakeCacheKey creates a cache key from endpoint and location
func MakeCacheKey(endpoint, lat, lon string) string {
	return fmt.Sprintf("%s:%s:%s", endpoint, lat, lon)
}
```

**Step 2: Commit**

```bash
git add weather-proxy/cache.go
git commit -m "feat: implement in-memory cache with TTL

Thread-safe cache with RWMutex, automatic cleanup goroutine
runs every 5 minutes to remove expired entries.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 3: Implement Authentication Middleware

**Files:**
- Create: `weather-proxy/auth.go`

**Step 1: Create auth.go**

Create `weather-proxy/auth.go`:

```go
package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
)

// ErrorResponse represents JSON error response
type ErrorResponse struct {
	Error string `json:"error"`
}

// AuthMiddleware validates the API key from X-API-Key header
func AuthMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		apiKey := r.Header.Get("X-API-Key")
		expectedKey := os.Getenv("PROXY_API_KEY")

		if expectedKey == "" {
			log.Println("WARN: PROXY_API_KEY not set")
			http.Error(w, "Server misconfigured", http.StatusInternalServerError)
			return
		}

		if apiKey == "" {
			log.Printf("AUTH: Missing API key from %s", r.RemoteAddr)
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusUnauthorized)
			json.NewEncoder(w).Encode(ErrorResponse{Error: "Missing X-API-Key header"})
			return
		}

		if apiKey != expectedKey {
			log.Printf("AUTH: Invalid API key from %s", r.RemoteAddr)
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusUnauthorized)
			json.NewEncoder(w).Encode(ErrorResponse{Error: "Invalid API key"})
			return
		}

		next.ServeHTTP(w, r)
	})
}
```

**Step 2: Commit**

```bash
git add weather-proxy/auth.go
git commit -m "feat: add API key authentication middleware

Validates X-API-Key header against PROXY_API_KEY env var.
Returns 401 with JSON error if missing or invalid.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 4: Implement Google Weather API Client

**Files:**
- Create: `weather-proxy/proxy.go`

**Step 1: Create proxy.go with Google API client**

Create `weather-proxy/proxy.go`:

```go
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"time"

	"golang.org/x/oauth2/google"
)

const googleWeatherBaseURL = "https://weather.googleapis.com"

// ProxyHandler handles proxying requests to Google Weather API
type ProxyHandler struct {
	cache      *Cache
	httpClient *http.Client
}

// NewProxyHandler creates a new proxy handler with authenticated HTTP client
func NewProxyHandler(cache *Cache) (*ProxyHandler, error) {
	ctx := context.Background()

	// Get default credentials (Application Default Credentials)
	// This will use the service account when running on Cloud Run
	creds, err := google.FindDefaultCredentials(ctx, "https://www.googleapis.com/auth/cloud-platform")
	if err != nil {
		log.Printf("WARN: Failed to get default credentials: %v", err)
		// For local dev without ADC, we'll just use an unauthenticated client
		// and rely on API key in the URL (but production should use ADC)
		return &ProxyHandler{
			cache:      cache,
			httpClient: &http.Client{Timeout: 30 * time.Second},
		}, nil
	}

	// Create HTTP client with OAuth2 token source
	client := creds.TokenSource
	httpClient := &http.Client{
		Timeout: 30 * time.Second,
		Transport: &oauth2Transport{
			base:   http.DefaultTransport,
			source: client,
		},
	}

	return &ProxyHandler{
		cache:      cache,
		httpClient: httpClient,
	}, nil
}

// oauth2Transport adds OAuth2 token to requests
type oauth2Transport struct {
	base   http.RoundTripper
	source oauth2.TokenSource
}

func (t *oauth2Transport) RoundTrip(req *http.Request) (*http.Response, error) {
	token, err := t.source.Token()
	if err != nil {
		return nil, fmt.Errorf("failed to get token: %w", err)
	}

	// Clone request and add Authorization header
	req = cloneRequest(req)
	req.Header.Set("Authorization", "Bearer "+token.AccessToken)

	return t.base.RoundTrip(req)
}

func cloneRequest(r *http.Request) *http.Request {
	r2 := new(http.Request)
	*r2 = *r
	r2.Header = make(http.Header, len(r.Header))
	for k, s := range r.Header {
		r2.Header[k] = append([]string(nil), s...)
	}
	return r2
}

// ServeHTTP handles the proxy request
func (h *ProxyHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// Extract location parameters
	lat := r.URL.Query().Get("location.latitude")
	lon := r.URL.Query().Get("location.longitude")

	if lat == "" || lon == "" {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(ErrorResponse{Error: "Missing location parameters"})
		return
	}

	// Determine endpoint type and TTL
	endpoint := getEndpointType(r.URL.Path)
	ttl := getTTLForEndpoint(endpoint)

	// Check cache
	cacheKey := MakeCacheKey(endpoint, lat, lon)
	if cachedData, found := h.cache.Get(cacheKey); found {
		log.Printf("CACHE HIT: %s (%s, %s)", endpoint, lat, lon)
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("X-Cache", "HIT")
		w.Write(cachedData)
		return
	}

	log.Printf("CACHE MISS: %s (%s, %s)", endpoint, lat, lon)

	// Build Google Weather API URL
	googleURL := fmt.Sprintf("%s%s?%s", googleWeatherBaseURL, r.URL.Path, r.URL.RawQuery)

	// Create request to Google Weather API
	req, err := http.NewRequest("GET", googleURL, nil)
	if err != nil {
		log.Printf("ERROR: Failed to create request: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	// Forward request to Google
	resp, err := h.httpClient.Do(req)
	if err != nil {
		log.Printf("ERROR: Failed to fetch from Google API: %v", err)
		http.Error(w, "Failed to fetch weather data", http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	// Read response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Printf("ERROR: Failed to read response: %v", err)
		http.Error(w, "Failed to read weather data", http.StatusInternalServerError)
		return
	}

	// If successful response, cache it
	if resp.StatusCode == http.StatusOK {
		h.cache.Set(cacheKey, body, ttl)
		log.Printf("CACHED: %s (%s, %s) for %v", endpoint, lat, lon, ttl)
	}

	// Forward response to client
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("X-Cache", "MISS")
	w.WriteHeader(resp.StatusCode)
	w.Write(body)

	log.Printf("PROXY: %s -> Status %d, Size %d bytes", endpoint, resp.StatusCode, len(body))
}

// getEndpointType extracts endpoint type from path
func getEndpointType(path string) string {
	switch {
	case contains(path, "currentConditions"):
		return "current"
	case contains(path, "hours"):
		return "hourly"
	case contains(path, "days"):
		return "daily"
	default:
		return "unknown"
	}
}

// getTTLForEndpoint returns appropriate TTL for endpoint type
func getTTLForEndpoint(endpoint string) time.Duration {
	switch endpoint {
	case "current":
		return 10 * time.Minute
	case "hourly":
		return 30 * time.Minute
	case "daily":
		return 60 * time.Minute
	default:
		return 10 * time.Minute
	}
}

func contains(s, substr string) bool {
	return len(s) >= len(substr) && s[len(s)-len(substr):] == substr ||
	       len(s) > len(substr) && s[:len(substr)] == substr ||
	       len(s) > len(substr)*2 && s[len(s)/2-len(substr)/2:len(s)/2+len(substr)/2] == substr
}
```

**Step 2: Fix the contains helper**

Replace the `contains` function with proper implementation:

```go
func contains(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}
```

**Step 3: Update imports in proxy.go**

Add this import at the top:

```go
import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"time"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
)
```

**Step 4: Get the oauth2 dependency**

```bash
go get golang.org/x/oauth2
```

**Step 5: Commit**

```bash
git add weather-proxy/proxy.go weather-proxy/go.mod weather-proxy/go.sum
git commit -m "feat: implement Google Weather API proxy with caching

Authenticates to Google using ADC (service account OAuth).
Caches responses with endpoint-specific TTLs:
- Current: 10min
- Hourly: 30min
- Daily: 60min

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 5: Implement HTTP Server

**Files:**
- Create: `weather-proxy/main.go`

**Step 1: Create main.go**

Create `weather-proxy/main.go`:

```go
package main

import (
	"log"
	"net/http"
	"os"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Initialize cache
	cache := NewCache()

	// Initialize proxy handler
	proxyHandler, err := NewProxyHandler(cache)
	if err != nil {
		log.Fatalf("Failed to create proxy handler: %v", err)
	}

	// Set up routes
	mux := http.NewServeMux()

	// Health check endpoint
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	// Proxy endpoints (all require authentication)
	mux.Handle("/v1/currentConditions:lookup", AuthMiddleware(proxyHandler))
	mux.Handle("/v1/forecast/hours:lookup", AuthMiddleware(proxyHandler))
	mux.Handle("/v1/forecast/days:lookup", AuthMiddleware(proxyHandler))

	// Start server
	log.Printf("Starting server on port %s", port)
	if err := http.ListenAndServe(":"+port, mux); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
```

**Step 2: Test locally (without Google auth)**

```bash
export PROXY_API_KEY=12e41cad6b1132308c75673905f0f17220623e481366f584f1f1d730ae1c6f78
export PORT=8080
go run .
```

Expected output:
```
Starting server on port 8080
```

**Step 3: Test health endpoint in another terminal**

```bash
curl http://localhost:8080/health
```

Expected: `OK`

**Step 4: Test authentication**

```bash
# Should fail with 401
curl -i http://localhost:8080/v1/currentConditions:lookup

# Should work (but may fail on Google API call without proper auth)
curl -i -H "X-API-Key: 12e41cad6b1132308c75673905f0f17220623e481366f584f1f1d730ae1c6f78" \
  "http://localhost:8080/v1/currentConditions:lookup?location.latitude=37.7749&location.longitude=-122.4194"
```

**Step 5: Stop the server (Ctrl+C)**

**Step 6: Commit**

```bash
git add weather-proxy/main.go
git commit -m "feat: add HTTP server with routing and health check

Routes /v1/* endpoints through auth middleware to proxy handler.
Health check at /health for Cloud Run readiness probes.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 6: Create Dockerfile

**Files:**
- Create: `weather-proxy/Dockerfile`
- Create: `weather-proxy/.dockerignore`

**Step 1: Create Dockerfile**

Create `weather-proxy/Dockerfile`:

```dockerfile
# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY *.go ./

# Build binary
RUN CGO_ENABLED=0 GOOS=linux go build -o weather-proxy .

# Runtime stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/weather-proxy .

# Cloud Run uses PORT env var
ENV PORT=8080

EXPOSE 8080

CMD ["./weather-proxy"]
```

**Step 2: Create .dockerignore**

Create `weather-proxy/.dockerignore`:

```
.env
.env.example
README.md
.git
.gitignore
```

**Step 3: Test Docker build locally (optional)**

```bash
cd weather-proxy
docker build -t weather-proxy:test .
```

Expected: Build succeeds

**Step 4: Commit**

```bash
git add weather-proxy/Dockerfile weather-proxy/.dockerignore
git commit -m "feat: add Dockerfile for Cloud Run deployment

Multi-stage build with Go 1.21 and Alpine.
Optimized for small image size and fast builds.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 7: Deploy to Cloud Run

**Files:**
- Modify: `weather-proxy/README.md` (add actual Cloud Run URL after deployment)

**Step 1: Verify Google Cloud setup**

```bash
# Set project
gcloud config set project project-85dca6cf-ba5d-4efd-9df

# Verify service account exists
gcloud iam service-accounts list | grep weather-app
```

Expected: Shows `weather-app@project-85dca6cf-ba5d-4efd-9df.iam.gserviceaccount.com`

**Step 2: Enable required APIs**

```bash
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
```

**Step 3: Deploy to Cloud Run**

```bash
cd weather-proxy

gcloud run deploy weather-proxy \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --service-account weather-app@project-85dca6cf-ba5d-4efd-9df.iam.gserviceaccount.com \
  --set-env-vars PROXY_API_KEY=12e41cad6b1132308c75673905f0f17220623e481366f584f1f1d730ae1c6f78 \
  --memory 256Mi \
  --max-instances 10
```

**Step 4: Save Cloud Run URL**

After deployment completes, copy the service URL (looks like `https://weather-proxy-xxxxx-uc.a.run.app`)

**Step 5: Test deployed service**

```bash
# Test health check
curl https://YOUR-CLOUD-RUN-URL/health

# Test authentication
curl -i -H "X-API-Key: 12e41cad6b1132308c75673905f0f17220623e481366f584f1f1d730ae1c6f78" \
  "https://YOUR-CLOUD-RUN-URL/v1/currentConditions:lookup?location.latitude=37.7749&location.longitude=-122.4194"
```

Expected: Should return weather data JSON

**Step 6: Update README with actual URL**

Edit `weather-proxy/README.md` and add a section:

```markdown
## Production URL

https://YOUR-ACTUAL-CLOUD-RUN-URL
```

**Step 7: Commit**

```bash
git add weather-proxy/README.md
git commit -m "docs: add production Cloud Run URL to README

Service deployed and verified at [URL].

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 8: Update iOS App Configuration

**Files:**
- Modify: `WeatherApp/WeatherApp/Info.plist`
- Modify: `WeatherApp/WeatherApp/Utilities/Configuration/Config.swift`

**Step 1: Add configuration to Info.plist**

Edit `WeatherApp/WeatherApp/Info.plist` and add before the closing `</dict>` tag:

```xml
	<key>CLOUD_RUN_PROXY_API_KEY</key>
	<string>12e41cad6b1132308c75673905f0f17220623e481366f584f1f1d730ae1c6f78</string>
	<key>CLOUD_RUN_PROXY_URL</key>
	<string>YOUR-ACTUAL-CLOUD-RUN-URL</string>
```

Replace `YOUR-ACTUAL-CLOUD-RUN-URL` with the URL from Task 7 (without trailing slash).

**Step 2: Read Config.swift to understand structure**

```bash
cat WeatherApp/WeatherApp/Utilities/Configuration/Config.swift | head -50
```

**Step 3: Add properties to Config.swift**

Find the section with API keys and add:

```swift
    // Cloud Run Proxy Configuration
    static let cloudRunProxyAPIKey = infoDict["CLOUD_RUN_PROXY_API_KEY"] as? String ?? ""
    static let cloudRunProxyURL = infoDict["CLOUD_RUN_PROXY_URL"] as? String ?? ""
```

**Step 4: Commit**

```bash
git add WeatherApp/WeatherApp/Info.plist WeatherApp/WeatherApp/Utilities/Configuration/Config.swift
git commit -m "config: add Cloud Run proxy configuration

Add proxy URL and API key to Info.plist and Config.swift.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 9: Update GoogleWeatherService to Use Proxy

**Files:**
- Modify: `WeatherApp/WeatherApp/Services/Weather/GoogleWeatherService.swift:38-44`

**Step 1: Update baseURL and remove API key parameter**

Edit `WeatherApp/WeatherApp/Services/Weather/GoogleWeatherService.swift`:

Find lines 36-44 (the URL construction section):

```swift
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude

        // Build request URLs
        let baseURL = "https://weather.googleapis.com/v1"
        let locationParam = "location.latitude=\(lat)&location.longitude=\(lon)"
        let keyParam = "key=\(apiKey)"

        let currentURL = "\(baseURL)/currentConditions:lookup?\(locationParam)&\(keyParam)"
        let hourlyURL = "\(baseURL)/forecast/hours:lookup?\(locationParam)&hours=240&\(keyParam)"
        let dailyURL = "\(baseURL)/forecast/days:lookup?\(locationParam)&days=10&\(keyParam)"
```

Replace with:

```swift
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude

        // Build request URLs (using proxy)
        let baseURL = Config.cloudRunProxyURL
        let locationParam = "location.latitude=\(lat)&location.longitude=\(lon)"

        let currentURL = "\(baseURL)/v1/currentConditions:lookup?\(locationParam)"
        let hourlyURL = "\(baseURL)/v1/forecast/hours:lookup?\(locationParam)&hours=240"
        let dailyURL = "\(baseURL)/v1/forecast/days:lookup?\(locationParam)&days=10"
```

**Step 2: Add proxy API key header to network requests**

Find lines 46-49 (the parallel fetch section):

```swift
        // Fetch all endpoints in parallel
        async let currentTask: GWCurrentConditionsResponse = networkClient.fetch(url: currentURL)
        async let hourlyTask: GWHourlyForecastResponse = networkClient.fetch(url: hourlyURL)
        async let dailyTask: GWDailyForecastResponse = networkClient.fetch(url: dailyURL)
```

Replace with:

```swift
        // Prepare headers with proxy API key
        let headers = ["X-API-Key": Config.cloudRunProxyAPIKey]

        // Fetch all endpoints in parallel
        async let currentTask: GWCurrentConditionsResponse = networkClient.fetch(url: currentURL, headers: headers)
        async let hourlyTask: GWHourlyForecastResponse = networkClient.fetch(url: hourlyURL, headers: headers)
        async let dailyTask: GWDailyForecastResponse = networkClient.fetch(url: dailyURL, headers: headers)
```

**Step 3: Update isAvailable check**

Find line 20-22:

```swift
    nonisolated var isAvailable: Bool {
        !Config.googleWeatherAPIKey.isEmpty
    }
```

Replace with:

```swift
    nonisolated var isAvailable: Bool {
        !Config.cloudRunProxyURL.isEmpty && !Config.cloudRunProxyAPIKey.isEmpty
    }
```

**Step 4: Commit**

```bash
git add WeatherApp/WeatherApp/Services/Weather/GoogleWeatherService.swift
git commit -m "feat: update GoogleWeatherService to use Cloud Run proxy

- Change base URL to Cloud Run proxy
- Add X-API-Key header to all requests
- Remove Google API key parameter from URLs
- Update availability check for proxy config

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 10: Build and Test iOS App

**Files:**
- None (testing only)

**Step 1: Build the iOS app**

```bash
cd WeatherApp
xcodebuild -project WeatherApp.xcodeproj -scheme WeatherApp -configuration Debug clean build CODE_SIGNING_ALLOWED=NO
```

Expected: `** BUILD SUCCEEDED **`

**Step 2: Test in iOS Simulator (manual)**

If you have access to Xcode GUI:
1. Open `WeatherApp.xcodeproj` in Xcode
2. Run the app in simulator (Cmd+R)
3. Check that Google Weather source loads successfully
4. Verify weather data displays correctly
5. Check Xcode console for log messages showing proxy usage

**Step 3: Verify proxy logs (in separate terminal)**

```bash
gcloud run logs read weather-proxy \
  --region us-central1 \
  --limit 50
```

Look for:
- `CACHE MISS` messages for initial requests
- `CACHE HIT` messages for subsequent requests
- `PROXY:` messages showing successful responses

**Step 4: Document successful test**

No commit needed - this is validation only.

---

## Task 11: Add iOS Unit Tests (Optional but Recommended)

**Files:**
- Create: `WeatherApp/WeatherAppTests/GoogleWeatherServiceTests.swift`

**Step 1: Create test file**

Create `WeatherApp/WeatherAppTests/GoogleWeatherServiceTests.swift`:

```swift
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
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            timezone: .current
        )

        let weather = try await service.fetchWeather(for: location)

        // Verify we got valid weather data
        XCTAssertEqual(weather.source, .googleWeather)
        XCTAssertNotNil(weather.current)
        XCTAssertFalse(weather.hourly.isEmpty)
        XCTAssertFalse(weather.daily.isEmpty)
    }
}
```

**Step 2: Add test target to Xcode project (if needed)**

If test target doesn't exist, skip this step. Otherwise, add the test file to the test target.

**Step 3: Run tests**

```bash
xcodebuild test \
  -project WeatherApp/WeatherApp.xcodeproj \
  -scheme WeatherApp \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  CODE_SIGNING_ALLOWED=NO
```

Expected: Tests pass

**Step 4: Commit**

```bash
git add WeatherApp/WeatherAppTests/GoogleWeatherServiceTests.swift
git commit -m "test: add unit tests for Google Weather proxy integration

Tests verify proxy configuration and integration with Cloud Run.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 12: Documentation and Cleanup

**Files:**
- Create: `docs/deployment/cloud-run-proxy.md`
- Modify: `docs/plans/2026-01-31-google-weather-proxy-design.md` (mark as implemented)

**Step 1: Create deployment documentation**

Create `docs/deployment/cloud-run-proxy.md`:

```markdown
# Cloud Run Weather Proxy Deployment

## Overview

The weather proxy service handles OAuth authentication and caching for Google Weather API calls from the iOS app.

## Architecture

- **Service:** `weather-proxy` on Cloud Run
- **Region:** us-central1
- **Service Account:** `weather-app@project-85dca6cf-ba5d-4efd-9df.iam.gserviceaccount.com`
- **URL:** [YOUR-CLOUD-RUN-URL]

## Authentication

### iOS App → Proxy
- Header: `X-API-Key`
- Value: Stored in `Info.plist` as `CLOUD_RUN_PROXY_API_KEY`

### Proxy → Google Weather API
- OAuth 2.0 via Application Default Credentials (ADC)
- Service account token automatically managed by Google SDK

## Caching

| Endpoint | TTL | Purpose |
|----------|-----|---------|
| Current conditions | 10 min | Frequently changing |
| Hourly forecast | 30 min | Moderate refresh |
| Daily forecast | 60 min | Slow changing |

## Deployment

### Update Proxy Code

```bash
cd weather-proxy
gcloud run deploy weather-proxy --source .
```

### Update API Key

```bash
gcloud run services update weather-proxy \
  --region us-central1 \
  --update-env-vars PROXY_API_KEY=<new-key>
```

### View Logs

```bash
gcloud run logs read weather-proxy \
  --region us-central1 \
  --limit 100
```

### View Metrics

Visit [Cloud Run Console](https://console.cloud.google.com/run/detail/us-central1/weather-proxy/metrics)

## Monitoring

Key metrics to watch:
- Request count (should scale with app usage)
- Cache hit ratio (target >60%)
- Error rate (target <1%)
- Response latency (target <1s for cache misses)

## Troubleshooting

### iOS app shows "unauthorized" error
- Check proxy API key matches in both Info.plist and Cloud Run env vars
- Verify proxy URL is correct in Info.plist

### Proxy returns 401 when calling Google API
- Check service account has Google Weather API enabled
- Verify service account is attached to Cloud Run service

### High costs
- Check cache hit ratio in logs
- Verify TTL values are appropriate
- Consider increasing TTL for daily forecasts

## Security

- API key is embedded in iOS app binary (acceptable for personal app)
- Service account credentials never leave Cloud Run
- No service account keys stored anywhere
- API key can be rotated by updating both iOS config and Cloud Run env var
```

**Step 2: Update design document status**

Edit `docs/plans/2026-01-31-google-weather-proxy-design.md` and change line 4:

```markdown
**Status:** Implemented
```

**Step 3: Commit**

```bash
git add docs/deployment/cloud-run-proxy.md docs/plans/2026-01-31-google-weather-proxy-design.md
git commit -m "docs: add Cloud Run proxy deployment guide

Comprehensive deployment and troubleshooting documentation.
Mark design document as implemented.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 13: Final Verification and Cleanup

**Files:**
- None (verification only)

**Step 1: Verify end-to-end flow**

Test complete flow:
1. iOS app makes request to proxy
2. Proxy caches response
3. Second request gets cache hit
4. All three endpoints work (current, hourly, daily)

**Step 2: Check logs for cache effectiveness**

```bash
gcloud run logs read weather-proxy --region us-central1 --limit 100 | grep -E "CACHE (HIT|MISS)"
```

Calculate cache hit ratio. Should be >50% after warmup period.

**Step 3: Verify git status is clean**

```bash
git status
```

Expected: No uncommitted changes

**Step 4: Review all commits in branch**

```bash
git log --oneline main..HEAD
```

Expected: Should see all 12 commits from this plan

**Step 5: Success metrics check**

Verify against design document success metrics:
- ✅ Proxy handles Google Weather requests
- ✅ Cache hit ratio tracked (check logs)
- ✅ iOS app successfully fetches weather data
- ✅ Error rate low (<1%)

---

## Completion

**Implementation complete!**

All tasks finished:
1. ✅ Go project initialized
2. ✅ Cache manager implemented
3. ✅ Auth middleware implemented
4. ✅ Google API client implemented
5. ✅ HTTP server implemented
6. ✅ Dockerfile created
7. ✅ Deployed to Cloud Run
8. ✅ iOS config updated
9. ✅ iOS service updated to use proxy
10. ✅ iOS app tested
11. ✅ Unit tests added
12. ✅ Documentation created
13. ✅ Final verification passed

**Next steps:**
- Use @superpowers:finishing-a-development-branch to merge back to main
- Monitor proxy logs and metrics for first few days
- Consider extending proxy to other weather APIs if needed
