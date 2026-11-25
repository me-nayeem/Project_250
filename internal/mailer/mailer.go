package mailer

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"time"
)

type Mailer interface {
	SendOTP(ctx context.Context, email, code string) error
}

const resendEndpoint = "https://api.resend.com/emails"

type Resend struct {
	apiKey   string
	from     string
	endpoint string
	client   *http.Client
}

func NewResend(apiKey, from string) *Resend {
	return &Resend{apiKey: apiKey, from: from, endpoint: resendEndpoint, client: &http.Client{Timeout: 10 * time.Second}}
}

type resendEmail struct {
	From    string   `json:"from"`
	To      []string `json:"to"`
	Subject string   `json:"subject"`
	Text    string   `json:"text"`
	HTML    string   `json:"html"`
}

func (r *Resend) SendOTP(ctx context.Context, email, code string) error {
	body, err := json.Marshal(resendEmail{
		From:    r.from,
		To:      []string{email},
		Subject: "Your verification code",
		Text:    fmt.Sprintf("Your verification code is %s. It expires in 10 minutes.", code),
		HTML:    fmt.Sprintf("<p>Your verification code is <strong>%s</strong>.</p><p>It expires in 10 minutes.</p>", code),
	})
	if err != nil {
		return err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, r.endpoint, bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+r.apiKey)
	req.Header.Set("Content-Type", "application/json")

	resp, err := r.client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send OTP email: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		return nil
	}

	raw, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
	var payload struct {
		Message string `json:"message"`
	}
	_ = json.Unmarshal(raw, &payload)
	if payload.Message == "" {
		payload.Message = http.StatusText(resp.StatusCode)
	}
	return fmt.Errorf("failed to send OTP email: %s (status %d)", payload.Message, resp.StatusCode)
}

type DevLog struct{}

func (DevLog) SendOTP(_ context.Context, email, code string) error {
	log.Printf("[mailer:dev] OTP for %s is %s (APP_ENV=development, not emailed)", email, code)
	return nil
}
