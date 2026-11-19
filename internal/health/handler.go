package health

import (
	"context"
	"net/http"
	"time"

	"study-tracker/internal/httpx"
)

type Pinger interface {
	Ping(ctx context.Context) error
}

type Handler struct {
	db Pinger
}

func NewHandler(db Pinger) *Handler { return &Handler{db: db} }

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.get)
}

type response struct {
	Status   string `json:"status"`
	Service  string `json:"service"`
	Database string `json:"database"`
}

func (h *Handler) get(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 3*time.Second)
	defer cancel()

	if h.db == nil || h.db.Ping(ctx) != nil {
		httpx.WriteJSON(w, http.StatusServiceUnavailable, response{Status: "degraded", Service: "study-tracker", Database: "unreachable"})
		return
	}
	httpx.WriteJSON(w, http.StatusOK, response{Status: "ok", Service: "study-tracker", Database: "ok"})
}
