package ratelimit

import (
	"bytes"
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync"
	"time"
)

type Result struct {
	Allowed bool

	RetryAfterSeconds int
}

type Limiter interface {
	Allow(ctx context.Context, identifier string) (Result, error)
}

func retryAfterSeconds(d time.Duration) int {
	if d <= 0 {
		return 0
	}
	return int((d + time.Second - 1) / time.Second)
}

type Memory struct {
	mu      sync.Mutex
	limit   int
	window  time.Duration
	now     func() time.Time
	entries map[string][]time.Time
}

func NewMemory(limit int, window time.Duration) *Memory {
	return &Memory{limit: limit, window: window, now: time.Now, entries: make(map[string][]time.Time)}
}

func (m *Memory) Allow(_ context.Context, identifier string) (Result, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	now := m.now()
	kept := m.entries[identifier][:0]
	for _, ts := range m.entries[identifier] {
		if now.Sub(ts) < m.window {
			kept = append(kept, ts)
		}
	}
	if len(kept) >= m.limit {
		m.entries[identifier] = kept
		return Result{Allowed: false, RetryAfterSeconds: retryAfterSeconds(kept[0].Add(m.window).Sub(now))}, nil
	}
	m.entries[identifier] = append(kept, now)
	return Result{Allowed: true}, nil
}

const slidingWindowScript = `
local key = KEYS[1]
local now = tonumber(ARGV[1])
local window = tonumber(ARGV[2])
local limit = tonumber(ARGV[3])
redis.call('ZREMRANGEBYSCORE', key, '-inf', now - window)
local count = redis.call('ZCARD', key)
if count >= limit then
  local oldest = redis.call('ZRANGE', key, 0, 0, 'WITHSCORES')
  local reset = window
  if oldest[2] then reset = tonumber(oldest[2]) + window - now end
  return {0, reset}
end
redis.call('ZADD', key, now, ARGV[4])
redis.call('PEXPIRE', key, window)
return {1, 0}
`

type Upstash struct {
	url    string
	token  string
	prefix string
	limit  int
	window time.Duration
	client *http.Client
}

func NewUpstash(restURL, token, prefix string, limit int, window time.Duration) *Upstash {
	return &Upstash{
		url:    strings.TrimRight(restURL, "/"),
		token:  token,
		prefix: prefix,
		limit:  limit,
		window: window,
		client: &http.Client{Timeout: 5 * time.Second},
	}
}

func (u *Upstash) Allow(ctx context.Context, identifier string) (Result, error) {
	member, err := randomMember()
	if err != nil {
		return Result{}, err
	}
	nowMs := time.Now().UnixMilli()
	command := []any{
		"EVAL", slidingWindowScript, "1", u.prefix + ":" + identifier,
		fmt.Sprint(nowMs), fmt.Sprint(u.window.Milliseconds()), fmt.Sprint(u.limit), member,
	}
	body, err := json.Marshal(command)
	if err != nil {
		return Result{}, err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, u.url, bytes.NewReader(body))
	if err != nil {
		return Result{}, err
	}
	req.Header.Set("Authorization", "Bearer "+u.token)
	req.Header.Set("Content-Type", "application/json")

	resp, err := u.client.Do(req)
	if err != nil {
		return Result{}, fmt.Errorf("upstash request: %w", err)
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(io.LimitReader(resp.Body, 64*1024))

	var payload struct {
		Result []int64 `json:"result"`
		Error  string  `json:"error"`
	}
	if err := json.Unmarshal(raw, &payload); err != nil {
		return Result{}, fmt.Errorf("upstash response (status %d): %w", resp.StatusCode, err)
	}
	if payload.Error != "" || resp.StatusCode != http.StatusOK {
		return Result{}, fmt.Errorf("upstash error (status %d): %s", resp.StatusCode, payload.Error)
	}
	if len(payload.Result) != 2 {
		return Result{}, errors.New("upstash: unexpected script result")
	}
	if payload.Result[0] == 1 {
		return Result{Allowed: true}, nil
	}
	return Result{Allowed: false, RetryAfterSeconds: retryAfterSeconds(time.Duration(payload.Result[1]) * time.Millisecond)}, nil
}

func randomMember() (string, error) {
	var b [12]byte
	if _, err := rand.Read(b[:]); err != nil {
		return "", err
	}
	return hex.EncodeToString(b[:]), nil
}
