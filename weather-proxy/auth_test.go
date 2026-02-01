package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
)

func TestAuthMiddleware(t *testing.T) {
	// Set up test API key
	os.Setenv("PROXY_API_KEY", "test-secret-key")
	defer os.Unsetenv("PROXY_API_KEY")

	// Create a test handler
	testHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	// Wrap with auth middleware
	authHandler := AuthMiddleware(testHandler)

	tests := []struct {
		name           string
		apiKey         string
		expectedStatus int
		expectedBody   string
	}{
		{
			name:           "Valid API key",
			apiKey:         "test-secret-key",
			expectedStatus: http.StatusOK,
			expectedBody:   "OK",
		},
		{
			name:           "Missing API key",
			apiKey:         "",
			expectedStatus: http.StatusUnauthorized,
			expectedBody:   `{"error":"Missing X-API-Key header"}`,
		},
		{
			name:           "Invalid API key",
			apiKey:         "wrong-key",
			expectedStatus: http.StatusUnauthorized,
			expectedBody:   `{"error":"Invalid API key"}`,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, "/test", nil)
			if tt.apiKey != "" {
				req.Header.Set("X-API-Key", tt.apiKey)
			}

			rr := httptest.NewRecorder()
			authHandler.ServeHTTP(rr, req)

			if rr.Code != tt.expectedStatus {
				t.Errorf("Expected status %d, got %d", tt.expectedStatus, rr.Code)
			}

			// For JSON responses, compare parsed JSON
			if tt.expectedStatus == http.StatusUnauthorized {
				var got, expected ErrorResponse
				if err := json.Unmarshal(rr.Body.Bytes(), &got); err != nil {
					t.Fatalf("Failed to parse response: %v", err)
				}
				if err := json.Unmarshal([]byte(tt.expectedBody), &expected); err != nil {
					t.Fatalf("Failed to parse expected body: %v", err)
				}
				if got.Error != expected.Error {
					t.Errorf("Expected error %q, got %q", expected.Error, got.Error)
				}
			} else {
				got := rr.Body.String()
				if got != tt.expectedBody {
					t.Errorf("Expected body %q, got %q", tt.expectedBody, got)
				}
			}
		})
	}
}
