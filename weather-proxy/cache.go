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
