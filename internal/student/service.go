package student

import (
	"context"
	"errors"
	"fmt"
	"regexp"
	"strings"
	"unicode/utf8"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"study-tracker/internal/apperr"
	"study-tracker/internal/db"
)

var (
	educationLevels = []string{"SSC", "HSC"}
	groupTypes      = []string{"SCIENCE", "ARTS", "COMMERCE"}
	boards          = []string{"DHAKA", "RAJSHAHI", "CUMILLA", "JASHORE", "CHATTOGRAM", "BARISHAL", "SYLHET", "DINAJPUR", "MYMENSINGH", "MADRASAH", "TECHNICAL"}
)

var bdPhonePattern = regexp.MustCompile(`^01[3-9]\d{8}$`)

var errNoTrack = apperr.NotFound("No track is available yet for this level and group. Please contact support.")

type OnboardingInput struct {
	UserID          string  `json:"userId"`
	Level           string  `json:"level"`
	Group           string  `json:"group"`
	Board           *string `json:"board"`
	InstitutionName string  `json:"institutionName"`
	PhoneNumber     string  `json:"phoneNumber"`
}

type OnboardingResult struct {
	AlreadyOnboarded bool   `json:"alreadyOnboarded"`
	StudentID        string `json:"studentId"`
	TrackID          string `json:"trackId"`
}

type Service struct {
	pool *pgxpool.Pool
}

func NewService(pool *pgxpool.Pool) *Service { return &Service{pool: pool} }

func (in *OnboardingInput) Validate() error {
	in.UserID = strings.TrimSpace(in.UserID)
	in.InstitutionName = strings.TrimSpace(in.InstitutionName)
	in.PhoneNumber = strings.TrimSpace(in.PhoneNumber)
	if in.Board != nil && *in.Board == "" {
		in.Board = nil
	}

	switch {
	case in.UserID == "":
		return apperr.BadRequest("Missing user id.")
	case !contains(educationLevels, in.Level):
		return apperr.BadRequest("Select a level.")
	case !contains(groupTypes, in.Group):
		return apperr.BadRequest("Select a group.")
	case in.Board != nil && !contains(boards, *in.Board):
		return apperr.BadRequest("Select a valid board.")
	case in.InstitutionName == "":
		return apperr.BadRequest("Institution name is required.")
	case utf8.RuneCountInString(in.InstitutionName) > 160:
		return apperr.BadRequest("Institution name must be at most 160 characters.")
	case !bdPhonePattern.MatchString(in.PhoneNumber):
		return apperr.BadRequest("Enter a valid 11-digit Bangladeshi mobile number, e.g. 01712345678.")
	}
	return nil
}

func (s *Service) CompleteOnboarding(ctx context.Context, in OnboardingInput) (OnboardingResult, error) {
	if strings.TrimSpace(in.UserID) == "" {
		return OnboardingResult{}, apperr.BadRequest("Missing user id.")
	}

	if existing, err := s.findProfile(ctx, strings.TrimSpace(in.UserID)); err != nil {
		return OnboardingResult{}, apperr.FromDB(err, "student profile")
	} else if existing != nil {
		existing.AlreadyOnboarded = true
		return *existing, nil
	}

	if err := in.Validate(); err != nil {
		return OnboardingResult{}, err
	}

	trackID, err := MatchTrackForLevelGroup(ctx, s.pool, in.Level, in.Group)
	if err != nil {
		return OnboardingResult{}, err
	}

	result := OnboardingResult{StudentID: db.NewID(), TrackID: trackID}
	_, err = s.pool.Exec(ctx, `
		INSERT INTO "StudentProfile" ("id", "userId", "trackId", "board", "institutionName", "phoneNumber", "createdAt")
		VALUES ($1, $2, $3, $4::"Board", $5, $6, `+db.NowUTC+`)`,
		result.StudentID, in.UserID, trackID, in.Board, in.InstitutionName, in.PhoneNumber)
	if err != nil {
		return OnboardingResult{}, apperr.FromDB(err, "student profile")
	}
	return result, nil
}

func (s *Service) findProfile(ctx context.Context, userID string) (*OnboardingResult, error) {
	var r OnboardingResult
	err := s.pool.QueryRow(ctx, `SELECT "id", "trackId" FROM "StudentProfile" WHERE "userId" = $1`, userID).
		Scan(&r.StudentID, &r.TrackID)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &r, nil
}

func MatchTrackForLevelGroup(ctx context.Context, q db.DBTX, level, group string) (string, error) {
	if !contains(educationLevels, level) || !contains(groupTypes, group) {
		return "", apperr.BadRequest("Select a valid level and group.")
	}
	var trackID string
	err := q.QueryRow(ctx, `
		SELECT "id"
		FROM "Track"
		WHERE "level" = $1::"EducationLevel" AND "group" = $2::"GroupType" AND "isArchived" = false
		ORDER BY ("examDate" IS NOT NULL AND "examDate" >= `+db.NowUTC+`) DESC,
		         CASE WHEN "examDate" >= `+db.NowUTC+` THEN "examDate" END ASC,
		         "batchYear" DESC
		LIMIT 1`, level, group).Scan(&trackID)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", errNoTrack
	}
	if err != nil {
		return "", apperr.FromDB(fmt.Errorf("match track: %w", err), "track")
	}
	return trackID, nil
}

func contains(list []string, v string) bool {
	for _, item := range list {
		if item == v {
			return true
		}
	}
	return false
}
