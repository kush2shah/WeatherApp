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
