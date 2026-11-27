package auth

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"log"
	"math/big"
	"net/mail"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"

	"study-tracker/internal/apperr"
	"study-tracker/internal/db"
	"study-tracker/internal/mailer"
	"study-tracker/internal/ratelimit"
)

const (
	OTPTTL          = 10 * time.Minute
	BcryptCost      = 10
	MaxOTPAttempts  = 5
	RequestLimit    = 3
	RequestWindow   = 10 * time.Minute
	VerifyLimit     = 10
	VerifyWindow    = 10 * time.Minute
	otpPurpose      = "EMAIL_VERIFICATION"
	requestOKText   = "Check your email for the code."
	invalidCodeText = "Invalid or expired code."
)

type User struct {
	ID    string  `json:"id"`
	Email *string `json:"email"`
	Name  *string `json:"name"`
	Role  string  `json:"role"`
}

type Service struct {
	pool           *pgxpool.Pool
	mailer         mailer.Mailer
	requestLimiter ratelimit.Limiter
	verifyLimiter  ratelimit.Limiter
}

func NewService(pool *pgxpool.Pool, m mailer.Mailer, requestLimiter, verifyLimiter ratelimit.Limiter) *Service {
	return &Service{pool: pool, mailer: m, requestLimiter: requestLimiter, verifyLimiter: verifyLimiter}
}

func NormalizeEmail(v string) string { return strings.ToLower(strings.TrimSpace(v)) }

func ValidEmail(v string) bool {
	if v == "" || len(v) > 255 || strings.ContainsAny(v, " \t\r\n<>") {
		return false
	}
	addr, err := mail.ParseAddress(v)
	if err != nil || addr.Address != v {
		return false
	}
	at := strings.LastIndexByte(v, '@')
	return at > 0 && strings.Contains(v[at+1:], ".")
}

func ValidCode(v string) bool {
	if len(v) != 6 {
		return false
	}
	for i := 0; i < len(v); i++ {
		if v[i] < '0' || v[i] > '9' {
			return false
		}
	}
	return true
}

func (s *Service) RequestOTP(ctx context.Context, rawEmail string) (string, error) {
	email := NormalizeEmail(rawEmail)
	if !ValidEmail(email) {
		return "", apperr.BadRequest("Enter a valid email address.")
	}

	limit, err := s.requestLimiter.Allow(ctx, email)
	if err != nil {
		return "", apperr.Internal(fmt.Errorf("otp request rate limit: %w", err))
	}
	if !limit.Allowed {
		return "", apperr.TooManyRequests(fmt.Sprintf("Too many requests. Try again in %ds.", limit.RetryAfterSeconds))
	}

	code, err := generateCode()
	if err != nil {
		return "", apperr.Internal(err)
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(code), BcryptCost)
	if err != nil {
		return "", apperr.Internal(err)
	}

	err = db.WithTx(ctx, s.pool, func(tx pgx.Tx) error {
		if _, err := tx.Exec(ctx, `
			UPDATE "EmailOtp" SET "expiresAt" = `+db.NowUTC+`
			WHERE "email" = $1 AND "purpose" = $2::"OtpPurpose"
			  AND "consumedAt" IS NULL AND "expiresAt" > `+db.NowUTC,
			email, otpPurpose); err != nil {
			return fmt.Errorf("expire previous codes: %w", err)
		}
		if _, err := tx.Exec(ctx, `
			INSERT INTO "EmailOtp" ("id", "email", "codeHash", "purpose", "expiresAt", "attempts", "createdAt")
			VALUES ($1, $2, $3, $4::"OtpPurpose", `+db.NowUTC+` + make_interval(secs => $5), 0, `+db.NowUTC+`)`,
			db.NewID(), email, string(hash), otpPurpose, OTPTTL.Seconds()); err != nil {
			return fmt.Errorf("store code: %w", err)
		}
		return nil
	})
	if err != nil {
		return "", apperr.Internal(err)
	}

	if err := s.mailer.SendOTP(ctx, email, code); err != nil {
		log.Printf("[auth] %v", err)
		return "", apperr.New(502, "We couldn't send the code right now. Please try again.")
	}
	return requestOKText, nil
}

func (s *Service) VerifyOTP(ctx context.Context, rawEmail, rawCode string) (*User, error) {
	email := NormalizeEmail(rawEmail)
	code := strings.TrimSpace(rawCode)
	if !ValidEmail(email) || !ValidCode(code) {
		return nil, apperr.BadRequest("Code must be exactly 6 digits.")
	}

	limit, err := s.verifyLimiter.Allow(ctx, email)
	if err != nil {
		return nil, apperr.Internal(fmt.Errorf("otp verify rate limit: %w", err))
	}
	if !limit.Allowed {
		return nil, apperr.TooManyRequests(fmt.Sprintf("Too many attempts. Try again in %ds.", limit.RetryAfterSeconds))
	}

	var user *User
	var failure *apperr.Error
	err = db.WithTx(ctx, s.pool, func(tx pgx.Tx) error {
		var (
			otpID      string
			codeHash   string
			expired    bool
			attempts   int
			isConsumed bool
		)

		err := tx.QueryRow(ctx, `
			SELECT "id", "codeHash", "expiresAt" < `+db.NowUTC+`, "attempts", "consumedAt" IS NOT NULL
			FROM "EmailOtp"
			WHERE "email" = $1 AND "purpose" = $2::"OtpPurpose"
			ORDER BY "createdAt" DESC
			LIMIT 1
			FOR UPDATE`,
			email, otpPurpose).Scan(&otpID, &codeHash, &expired, &attempts, &isConsumed)
		if errors.Is(err, pgx.ErrNoRows) {
			failure = apperr.Unauthorized(invalidCodeText)
			return nil
		}
		if err != nil {
			return fmt.Errorf("load code: %w", err)
		}
		if isConsumed || expired || attempts >= MaxOTPAttempts {
			failure = apperr.Unauthorized(invalidCodeText)
			return nil
		}

		if bcrypt.CompareHashAndPassword([]byte(codeHash), []byte(code)) != nil {
			if _, err := tx.Exec(ctx, `UPDATE "EmailOtp" SET "attempts" = "attempts" + 1 WHERE "id" = $1`, otpID); err != nil {
				return fmt.Errorf("count failed attempt: %w", err)
			}
			failure = apperr.Unauthorized(invalidCodeText)
			return nil
		}

		if _, err := tx.Exec(ctx, `UPDATE "EmailOtp" SET "consumedAt" = `+db.NowUTC+` WHERE "id" = $1`, otpID); err != nil {
			return fmt.Errorf("consume code: %w", err)
		}

		var isActive bool
		u := &User{}
		err = tx.QueryRow(ctx, `
			INSERT INTO "User" ("id", "email", "emailVerified", "role", "isActive", "createdAt", "updatedAt")
			VALUES ($1, $2, `+db.NowUTC+`, 'STUDENT', true, `+db.NowUTC+`, `+db.NowUTC+`)
			ON CONFLICT ("email") DO UPDATE
			   SET "emailVerified" = EXCLUDED."emailVerified", "updatedAt" = EXCLUDED."updatedAt"
			RETURNING "id", "email", "name", "role"::text, "isActive"`,
			db.NewID(), email).Scan(&u.ID, &u.Email, &u.Name, &u.Role, &isActive)
		if err != nil {
			return fmt.Errorf("upsert user: %w", err)
		}
		if !isActive {
			failure = apperr.Forbidden("This account has been deactivated.")
			return nil
		}
		user = u
		return nil
	})
	if err != nil {
		return nil, apperr.Internal(err)
	}
	if failure != nil {
		return nil, failure
	}
	return user, nil
}

func generateCode() (string, error) {
	n, err := rand.Int(rand.Reader, big.NewInt(1_000_000))
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}
