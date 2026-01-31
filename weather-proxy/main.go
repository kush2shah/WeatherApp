package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
)

// HealthResponse represents the health check response
type HealthResponse struct {
	Status string `json:"status"`
}

func main() {
	// Read PORT from environment, default to 8080
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Initialize cache
	cache := NewCache()
	log.Println("Cache initialized")

	// Initialize proxy handler
	proxyHandler, err := NewProxyHandler(cache)
	if err != nil {
		log.Printf("WARNING: Failed to initialize proxy handler: %v", err)
		log.Println("Server will start but proxy endpoints will not work")
		log.Println("Health check endpoint will still be available")
		proxyHandler = nil
	} else {
		log.Println("Proxy handler initialized")
	}

	// Set up routes
	mux := http.NewServeMux()

	// Health check endpoint (no auth required)
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(HealthResponse{Status: "ok"})
	})

	// Proxy endpoints with authentication (only if handler initialized)
	if proxyHandler != nil {
		mux.Handle("/v1/currentConditions:lookup", AuthMiddleware(proxyHandler))
		mux.Handle("/v1/forecast/hours:lookup", AuthMiddleware(proxyHandler))
		mux.Handle("/v1/forecast/days:lookup", AuthMiddleware(proxyHandler))
	} else {
		// Return 503 Service Unavailable if proxy not initialized
		notAvailableHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusServiceUnavailable)
			json.NewEncoder(w).Encode(ErrorResponse{Error: "Proxy service not available - credentials not configured"})
		})
		mux.Handle("/v1/currentConditions:lookup", notAvailableHandler)
		mux.Handle("/v1/forecast/hours:lookup", notAvailableHandler)
		mux.Handle("/v1/forecast/days:lookup", notAvailableHandler)
	}

	// Start server
	addr := ":" + port
	log.Printf("Starting server on %s", addr)
	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
