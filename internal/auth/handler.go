package auth

import (
	"net/http"

	"study-tracker/internal/httpx"
)

type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler { return &Handler{svc: svc} }

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("POST /auth/request-otp", h.requestOTP)
	mux.HandleFunc("POST /auth/verify-otp", h.verifyOTP)
}

type requestOTPInput struct {
	Email string `json:"email"`
}

type verifyOTPInput struct {
	Email string `json:"email"`
	Code  string `json:"code"`
}

type messageResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
}

type verifyResponse struct {
	Success bool  `json:"success"`
	User    *User `json:"user"`
}

func (h *Handler) requestOTP(w http.ResponseWriter, r *http.Request) {
	var in requestOTPInput
	if err := httpx.DecodeJSON(w, r, &in); err != nil {
		httpx.WriteError(w, err)
		return
	}
	msg, err := h.svc.RequestOTP(r.Context(), in.Email)
	if err != nil {
		httpx.WriteError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, messageResponse{Success: true, Message: msg})
}

func (h *Handler) verifyOTP(w http.ResponseWriter, r *http.Request) {
	var in verifyOTPInput
	if err := httpx.DecodeJSON(w, r, &in); err != nil {
		httpx.WriteError(w, err)
		return
	}
	user, err := h.svc.VerifyOTP(r.Context(), in.Email, in.Code)
	if err != nil {
		httpx.WriteError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, verifyResponse{Success: true, User: user})
}
