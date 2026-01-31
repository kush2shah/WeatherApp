package main

import (
	"context"
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"
	"time"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
)

const (
	// Google Weather API base URL
	googleWeatherAPIBase = "https://weather.googleapis.com/v1"

	// Cache TTLs for different endpoint types
	currentWeatherTTL = 15 * time.Minute
	forecastTTL       = 1 * time.Hour
	alertsTTL         = 5 * time.Minute
)

// ProxyHandler handles requests to the Google Weather API
type ProxyHandler struct {
	cache      *Cache
	httpClient *http.Client
}

// NewProxyHandler creates a new proxy handler with Google OAuth credentials
func NewProxyHandler(cache *Cache) (*ProxyHandler, error) {
	ctx := context.Background()

	// Get Application Default Credentials with weather scope
	creds, err := google.FindDefaultCredentials(ctx, "https://www.googleapis.com/auth/cloud-platform")
	if err != nil {
		return nil, fmt.Errorf("failed to find default credentials: %w", err)
	}

	// Create OAuth2 token source
	tokenSource := creds.TokenSource

	// Create HTTP client with OAuth2 transport
	client := &http.Client{
		Transport: &oauth2Transport{
			base:        http.DefaultTransport,
			tokenSource: tokenSource,
		},
		Timeout: 30 * time.Second,
	}

	return &ProxyHandler{
		cache:      cache,
		httpClient: client,
	}, nil
}

// oauth2Transport wraps the base transport and adds OAuth2 authentication
type oauth2Transport struct {
	base        http.RoundTripper
	tokenSource oauth2.TokenSource
}

// RoundTrip implements http.RoundTripper
func (t *oauth2Transport) RoundTrip(req *http.Request) (*http.Response, error) {
	// Get fresh token
	token, err := t.tokenSource.Token()
	if err != nil {
		return nil, fmt.Errorf("failed to get OAuth token: %w", err)
	}

	// Clone request to avoid modifying original
	reqClone := req.Clone(req.Context())

	// Add Authorization header
	reqClone.Header.Set("Authorization", "Bearer "+token.AccessToken)

	// Execute request
	return t.base.RoundTrip(reqClone)
}

// ServeHTTP handles proxy requests
func (p *ProxyHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// Only allow GET requests
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract path (remove leading /api/weather)
	path := strings.TrimPrefix(r.URL.Path, "/api/weather")

	// Build Google Weather API URL
	targetURL := googleWeatherAPIBase + path
	if r.URL.RawQuery != "" {
		targetURL += "?" + r.URL.RawQuery
	}

	// Get endpoint type for cache key and TTL
	endpointType := getEndpointType(path)

	// Build cache key from path and query
	cacheKey := path + "?" + r.URL.RawQuery

	// Check cache
	if cached, found := p.cache.Get(cacheKey); found {
		log.Printf("CACHE HIT: %s", endpointType)
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("X-Cache", "HIT")
		w.Write(cached)
		return
	}

	log.Printf("CACHE MISS: %s - Proxying to Google", endpointType)

	// Create request to Google Weather API
	req, err := http.NewRequestWithContext(r.Context(), http.MethodGet, targetURL, nil)
	if err != nil {
		log.Printf("ERROR: Failed to create request: %v", err)
		http.Error(w, "Failed to create request", http.StatusInternalServerError)
		return
	}

	// Copy relevant headers (excluding auth headers)
	for key, values := range r.Header {
		if key == "X-Api-Key" || key == "Authorization" {
			continue
		}
		for _, value := range values {
			req.Header.Add(key, value)
		}
	}

	// Execute request
	resp, err := p.httpClient.Do(req)
	if err != nil {
		log.Printf("ERROR: Failed to proxy request: %v", err)
		http.Error(w, "Failed to proxy request", http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	// Read response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Printf("ERROR: Failed to read response: %v", err)
		http.Error(w, "Failed to read response", http.StatusInternalServerError)
		return
	}

	// Cache successful responses
	if resp.StatusCode == http.StatusOK {
		ttl := getTTLForEndpoint(endpointType)
		p.cache.Set(cacheKey, body, ttl)
		log.Printf("CACHED: %s (TTL: %v)", endpointType, ttl)
	}

	// Copy response headers
	for key, values := range resp.Header {
		for _, value := range values {
			w.Header().Add(key, value)
		}
	}

	// Add cache status header
	w.Header().Set("X-Cache", "MISS")

	// Write response
	w.WriteHeader(resp.StatusCode)
	w.Write(body)
}

// getEndpointType determines the type of endpoint from the path
func getEndpointType(path string) string {
	if contains(path, "/current") {
		return "current"
	}
	if contains(path, "/forecast") {
		return "forecast"
	}
	if contains(path, "/alerts") {
		return "alerts"
	}
	return "unknown"
}

// getTTLForEndpoint returns the appropriate cache TTL for an endpoint type
func getTTLForEndpoint(endpointType string) time.Duration {
	switch endpointType {
	case "current":
		return currentWeatherTTL
	case "forecast":
		return forecastTTL
	case "alerts":
		return alertsTTL
	default:
		return 5 * time.Minute
	}
}

// contains checks if a string contains a substring
func contains(s, substr string) bool {
	return strings.Contains(s, substr)
}
