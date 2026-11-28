package student

import (
	"net/http"

	"study-tracker/internal/httpx"
)

type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler { return &Handler{svc: svc} }

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("POST /student/onboarding", h.completeOnboarding)
}

type onboardingResponse struct {
	Success bool `json:"success"`
	OnboardingResult
}

func (h *Handler) completeOnboarding(w http.ResponseWriter, r *http.Request) {
	var in OnboardingInput
	if err := httpx.DecodeJSON(w, r, &in); err != nil {
		httpx.WriteError(w, err)
		return
	}
	result, err := h.svc.CompleteOnboarding(r.Context(), in)
	if err != nil {
		httpx.WriteError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, onboardingResponse{Success: true, OnboardingResult: result})
}
