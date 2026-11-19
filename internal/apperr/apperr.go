package apperr

import (
	"errors"
	"fmt"
	"log"
	"net/http"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

const (
	PgUniqueViolation     = "23505"
	PgForeignKeyViolation = "23503"
)

type Error struct {
	Status  int
	Message string
	cause   error
}

func (e *Error) Error() string {
	if e.cause != nil {
		return e.Message + ": " + e.cause.Error()
	}
	return e.Message
}

func (e *Error) Unwrap() error { return e.cause }

func New(status int, message string) *Error { return &Error{Status: status, Message: message} }

func BadRequest(message string) *Error   { return New(http.StatusBadRequest, message) }
func Unauthorized(message string) *Error { return New(http.StatusUnauthorized, message) }
func Forbidden(message string) *Error    { return New(http.StatusForbidden, message) }
func NotFound(message string) *Error     { return New(http.StatusNotFound, message) }
func Conflict(message string) *Error     { return New(http.StatusConflict, message) }
func TooManyRequests(message string) *Error {
	return New(http.StatusTooManyRequests, message)
}

func Internal(cause error) *Error {
	return &Error{Status: http.StatusInternalServerError, Message: "Something went wrong. Please try again.", cause: cause}
}

var (
	ErrLastAdmin = Conflict("Can't change this — they're the last remaining admin. Promote another admin first.")
)

func FromDB(err error, entityLabel string) *Error {
	var appErr *Error
	if errors.As(err, &appErr) {
		return appErr
	}

	if errors.Is(err, pgx.ErrNoRows) {
		return &Error{
			Status:  http.StatusNotFound,
			Message: fmt.Sprintf("This %s was already changed or deleted elsewhere. Refresh and try again.", entityLabel),
			cause:   err,
		}
	}

	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) {
		switch pgErr.Code {
		case PgUniqueViolation:
			target := TargetFromConstraint(pgErr.ConstraintName, pgErr.TableName)
			if target == "" {
				target = "value"
			}
			return &Error{
				Status:  http.StatusConflict,
				Message: fmt.Sprintf("A %s with this %s already exists.", entityLabel, target),
				cause:   err,
			}
		case PgForeignKeyViolation:
			return &Error{
				Status:  http.StatusConflict,
				Message: fmt.Sprintf("This %s references, or is referenced by, a record that blocks this action.", entityLabel),
				cause:   err,
			}
		}
	}

	log.Printf("[db] unexpected error on %s: %v", entityLabel, err)
	return Internal(err)
}

func TargetFromConstraint(constraint, table string) string {
	name := constraint
	if table != "" && strings.HasPrefix(name, table+"_") {
		name = strings.TrimPrefix(name, table+"_")
	} else if i := strings.IndexByte(name, '_'); i >= 0 {
		name = name[i+1:]
	}
	name = strings.TrimSuffix(name, "_key")
	if name == "" || name == constraint {
		return ""
	}
	return strings.Join(strings.Split(name, "_"), ", ")
}
