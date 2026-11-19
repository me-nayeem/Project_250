package httpx

import (
	"crypto/subtle"
	"encoding/json"
	"errors"
	"io"
	"log"
	"net/http"
	"runtime/debug"
	"strconv"
	"strings"
	"time"

	"study-tracker/internal/apperr"
)

const maxBodyBytes = 1 << 20

func WriteJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(payload); err != nil {
		log.Printf("[http] encode response: %v", err)
	}
}

type errorBody struct {
	Success bool   `json:"success"`
	Error   string `json:"error"`
}

func WriteError(w http.ResponseWriter, err error) {
	var appErr *apperr.Error
	if !errors.As(err, &appErr) {
		log.Printf("[http] unexpected error: %v", err)
		appErr = apperr.Internal(err)
	} else if appErr.Status >= 500 {
		log.Printf("[http] %v", appErr)
	}
	WriteJSON(w, appErr.Status, errorBody{Success: false, Error: appErr.Message})
}

func DecodeJSON(w http.ResponseWriter, r *http.Request, v any) error {
	if r.Body == nil {
		return apperr.BadRequest("Request body is required.")
	}
	body := http.MaxBytesReader(w, r.Body, maxBodyBytes)
	defer body.Close()

	dec := json.NewDecoder(body)
	if err := dec.Decode(v); err != nil {
		return apperr.BadRequest("Invalid JSON request.")
	}
	if err := dec.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		return apperr.BadRequest("Request body must contain a single JSON object.")
	}
	return nil
}

func QueryPage(r *http.Request) int {
	page, err := strconv.Atoi(strings.TrimSpace(r.URL.Query().Get("page")))
	if err != nil || page < 1 {
		return 1
	}
	return page
}

func RequireInternalToken(token string, next http.Handler) http.Handler {
	expected := []byte("Bearer " + token)
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		got := []byte(r.Header.Get("Authorization"))
		if subtle.ConstantTimeCompare(got, expected) != 1 {
			WriteJSON(w, http.StatusUnauthorized, map[string]string{"error": "invalid internal token"})
			return
		}
		next.ServeHTTP(w, r)
	})
}

func Recover(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if rec := recover(); rec != nil {
				if rec == http.ErrAbortHandler {
					panic(rec)
				}
				log.Printf("[http] panic on %s %s: %v\n%s", r.Method, r.URL.Path, rec, debug.Stack())
				WriteError(w, apperr.Internal(nil))
			}
		}()
		next.ServeHTTP(w, r)
	})
}

type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (s *statusRecorder) WriteHeader(code int) {
	s.status = code
	s.ResponseWriter.WriteHeader(code)
}

func LogRequests(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rec := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(rec, r)
		log.Printf("[http] %s %s %d %s", r.Method, r.URL.Path, rec.status, time.Since(start).Round(time.Millisecond))
	})
}
