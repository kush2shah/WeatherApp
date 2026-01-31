# Google Weather API Proxy Service Design

**Date:** 2026-01-31
**Status:** Approved
**Estimated Implementation Time:** 4-6 hours

## Overview

A Go-based Cloud Run proxy service that handles OAuth authentication for Google Weather API calls from the iOS WeatherApp. The proxy provides secure credential management, intelligent caching, and cost optimization.

## Problem Statement

The iOS app currently needs to authenticate directly with Google Weather API. The service account (`weather-app@project-85dca6cf-ba5d-4efd-9df.iam.gserviceaccount.com`) uses OAuth 2.0, which is complex to implement in iOS and requires keeping credentials on the client side.

## Solution Architecture

### Components

1. **iOS App (WeatherApp)**
   - Changes base URL from `weather.googleapis.com` to Cloud Run proxy
   - Adds simple API key authentication via `X-API-Key` header
   - Minimal code changes to existing `GoogleWeatherService.swift`

2. **Cloud Run Proxy (Go)**
   - Validates incoming requests with API key
   - Provides in-memory caching with TTL
   - Authenticates to Google Weather API using service account (ADC)
   - Proxies three endpoints matching Google's API structure

3. **Google Weather API**
   - Receives authenticated requests from proxy
   - Returns weather data

### Data Flow

```
iOS App → Cloud Run Proxy → Google Weather API
         (API Key)         (OAuth Token)
            ↓
         Cache
      (10/30/60min)
```

## Authentication Strategy

### iOS → Cloud Run Proxy

**Simple API Key Authentication:**
- Generated key: `12e41cad6b1132308c75673905f0f17220623e481366f584f1f1d730ae1c6f78`
- Transmitted via `X-API-Key` header
- Validated by middleware in proxy
- Returns 401 if invalid/missing

**Why this approach:**
- Simple to implement (no JWT signing, no OAuth flow)
- Matches existing pattern (API keys in Config)
- Adequate security for personal weather app
- Can upgrade later if needed

### Cloud Run → Google Weather API

**Service Account OAuth (Application Default Credentials):**
- Service account: `weather-app@project-85dca6cf-ba5d-4efd-9df.iam.gserviceaccount.com`
- Cloud Run provides credentials automatically via ADC
- Google's Go SDK handles token fetching/refresh
- No service account key files needed (compliant with org policy)

## Caching Strategy

### Cache Configuration

| Endpoint | TTL | Rationale |
|----------|-----|-----------|
| `/v1/currentConditions:lookup` | 10 min | Current conditions change frequently |
| `/v1/forecast/hours:lookup` | 30 min | Hourly forecasts update less often |
| `/v1/forecast/days:lookup` | 60 min | Daily forecasts rarely change |

### Cache Implementation

- **Storage:** In-memory `map[string]CacheEntry` with `sync.RWMutex`
- **Key:** `endpoint + lat + lon` (e.g., `current:37.7749:-122.4194`)
- **Eviction:** Background goroutine cleans expired entries every 5 minutes
- **Benefits:** Reduces API costs, improves response times, provides resilience during API outages

## API Endpoints

The proxy mirrors Google Weather API endpoints exactly:

1. **Current Conditions**
   - Path: `/v1/currentConditions:lookup`
   - Query params: `location.latitude`, `location.longitude`
   - Cache: 10 minutes

2. **Hourly Forecast**
   - Path: `/v1/forecast/hours:lookup`
   - Query params: `location.latitude`, `location.longitude`, `hours`
   - Cache: 30 minutes

3. **Daily Forecast**
   - Path: `/v1/forecast/days:lookup`
   - Query params: `location.latitude`, `location.longitude`, `days`
   - Cache: 60 minutes

## Implementation Details

### Go Project Structure

```
weather-proxy/
├── main.go           # HTTP server, routing, middleware
├── auth.go           # API key validation middleware
├── cache.go          # In-memory cache with TTL
├── proxy.go          # Google Weather API client
├── Dockerfile        # Container configuration
├── go.mod            # Dependencies
└── .env.example      # Config template
```

### Core Components

**1. HTTP Server (main.go)**
```go
- Listen on port 8080 (Cloud Run default)
- Route requests to appropriate handlers
- Middleware chain: API key validation → cache check → proxy handler
```

**2. Authentication Middleware (auth.go)**
```go
- Extract X-API-Key header
- Compare against PROXY_API_KEY environment variable
- Return 401 if invalid
- Use Google ADC for outbound OAuth tokens
```

**3. Cache Manager (cache.go)**
```go
- Thread-safe map with RWMutex
- Cache entries include: data, timestamp, TTL
- Background cleanup goroutine
- TTL varies by endpoint type
```

**4. Proxy Handler (proxy.go)**
```go
- Extract location parameters
- Check cache for fresh data
- On miss: call Google Weather API with OAuth
- Store response in cache
- Return to client
```

### iOS App Changes

**File: WeatherApp/WeatherApp/Info.plist**
```xml
<key>CLOUD_RUN_PROXY_API_KEY</key>
<string>12e41cad6b1132308c75673905f0f17220623e481366f584f1f1d730ae1c6f78</string>
<key>CLOUD_RUN_PROXY_URL</key>
<string>https://weather-proxy-xxxxx-uc.a.run.app</string>
```

**File: WeatherApp/WeatherApp/Utilities/Configuration/Config.swift**
```swift
static let cloudRunProxyAPIKey = infoDict["CLOUD_RUN_PROXY_API_KEY"] as? String ?? ""
static let cloudRunProxyURL = infoDict["CLOUD_RUN_PROXY_URL"] as? String ?? ""
```

**File: WeatherApp/WeatherApp/Services/Weather/GoogleWeatherService.swift**
- Change `baseURL` from `https://weather.googleapis.com/v1` to `Config.cloudRunProxyURL`
- Remove `key=\(apiKey)` parameter from URL construction (lines 40, 42-44)
- Add `X-API-Key: Config.cloudRunProxyAPIKey` header to network requests

**File: WeatherApp/WeatherApp/Services/Network/NetworkClient.swift** (if needed)
- Add support for custom headers in `fetch()` method

## Deployment

### Prerequisites

1. Enable Google Weather API in GCP project
2. Verify service account has API access
3. Install Google Cloud SDK

### Deployment Command

```bash
cd weather-proxy/

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

### Post-Deployment

1. Copy the Cloud Run URL from deployment output
2. Update iOS app's `Info.plist` with the URL
3. Build and test iOS app

## Error Handling

### Error Scenarios

| Scenario | Proxy Behavior | iOS Impact |
|----------|----------------|------------|
| Invalid API key from iOS | Return 401 with JSON error | Treat as auth failure |
| Google API rate limit (429) | Pass through 429 with retry headers | iOS retries or shows error |
| Google API server error (5xx) | Return cached data if available, else pass error | Graceful degradation |
| Cache miss during Google outage | Return stale cache with warning header | Shows slightly old data |
| Service account auth failure | Log alert, return 500 | Shows error to user |

### Logging & Monitoring

**Logging:**
- Cloud Run automatically logs to Google Cloud Logging
- Log format: Structured JSON
- Log events: Cache hits/misses, API calls, errors, response times

**Monitoring:**
- Cloud Run automatic metrics: Request count, latency, error rate
- Set up alerts for error rate > 5%
- Monitor cache hit ratio to optimize TTL values

## Benefits

1. **Security**
   - OAuth credentials stay server-side
   - No service account keys in iOS app
   - API key can be rotated without app release

2. **Cost Optimization**
   - Intelligent caching reduces Google API calls by 60-80%
   - Pay only for actual proxy usage (Cloud Run scales to zero)

3. **Performance**
   - Cached responses return instantly
   - Parallel requests benefit from shared cache

4. **Scalability**
   - Cloud Run auto-scales based on traffic
   - No infrastructure management

5. **Maintainability**
   - Simple codebase (~300 lines of Go)
   - Standard Cloud Run deployment
   - Easy to extend to other weather APIs later

## Future Considerations

### Potential Enhancements (YAGNI for v1)

- **Extend to other APIs:** Could proxy OpenWeatherMap, Tomorrow.io later
- **Redis caching:** For multi-instance shared cache (current in-memory is fine)
- **API key rotation:** Automated key rotation system
- **Analytics:** Track most requested locations
- **Compression:** Gzip responses for bandwidth savings

### Migration Path

This design starts with Google Weather only. Other weather services (WeatherKit, NOAA, OpenWeatherMap, Tomorrow.io) continue calling directly. Can extend proxy later if needed.

## Implementation Checklist

### Phase 1: Build Proxy (2-3 hours)

- [ ] Create `weather-proxy/` directory
- [ ] Implement `main.go` (HTTP server, routing)
- [ ] Implement `auth.go` (API key middleware)
- [ ] Implement `cache.go` (in-memory cache with TTL)
- [ ] Implement `proxy.go` (Google API client)
- [ ] Create `Dockerfile`
- [ ] Test locally with `go run main.go`

### Phase 2: Deploy (1 hour)

- [ ] Enable Google Weather API in GCP project
- [ ] Deploy to Cloud Run
- [ ] Verify service account permissions
- [ ] Test proxy endpoints with curl/Postman

### Phase 3: iOS Integration (30 min)

- [ ] Add proxy config to `Info.plist`
- [ ] Update `Config.swift` with new properties
- [ ] Modify `GoogleWeatherService.swift` (base URL, remove key param)
- [ ] Add header support to `NetworkClient` if needed
- [ ] Build and test iOS app

### Phase 4: Testing & Validation (1 hour)

- [ ] Test all three endpoints (current, hourly, daily)
- [ ] Verify caching behavior (check logs)
- [ ] Test error scenarios (invalid API key, network errors)
- [ ] Monitor Cloud Run metrics
- [ ] Validate cost savings (check API call counts)

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| API key extracted from iOS app | Unauthorized proxy usage | Monitor usage, implement rate limiting, rotate key if needed |
| Cache causes stale data | Users see outdated weather | Conservative TTL values (10/30/60 min) |
| Cold start latency | First request slow | Cloud Run min instances (can set to 1 if needed) |
| Service account permissions | Proxy can't call Google API | Verify API enabled and permissions before deployment |

## Success Metrics

- Proxy successfully handles 100% of Google Weather requests
- Cache hit ratio > 60% after initial warmup
- Response time < 200ms for cache hits
- Response time < 1s for cache misses
- Error rate < 1%
- Cost reduction: 60-80% fewer Google API calls

## Conclusion

This design provides a secure, performant, and cost-effective solution for proxying Google Weather API calls. The simple API key authentication is pragmatic for a personal weather app, while the service account OAuth on Cloud Run provides enterprise-grade security for Google API access. The caching strategy significantly reduces costs while maintaining data freshness.

---

**Next Steps:**
1. Create implementation plan with detailed code
2. Set up git worktree for isolated development
3. Implement and test proxy service
4. Deploy to Cloud Run
5. Update iOS app
6. Validate end-to-end functionality
