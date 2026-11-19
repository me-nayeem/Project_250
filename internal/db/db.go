package db

import (
	"context"
	"errors"
	"fmt"
	"net/url"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

const NowUTC = `(now() AT TIME ZONE 'UTC')`

type DBTX interface {
	Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error)
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

var prismaOnlyParams = []string{
	"pgbouncer",
	"connection_limit",
	"pool_timeout",
	"socket_timeout",
	"statement_cache_size",
	"schema",
}

func Connect(ctx context.Context, rawURL string, maxConns int32) (*pgxpool.Pool, error) {
	cfg, err := PoolConfig(rawURL, maxConns)
	if err != nil {
		return nil, err
	}
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		return nil, fmt.Errorf("open database pool: %w", err)
	}
	return pool, nil
}

func PoolConfig(rawURL string, maxConns int32) (*pgxpool.Config, error) {
	cleaned, schema, err := sanitizeURL(rawURL)
	if err != nil {
		return nil, err
	}
	cfg, err := pgxpool.ParseConfig(cleaned)
	if err != nil {
		return nil, errors.New("DATABASE_URL is not a valid Postgres connection string")
	}
	if schema != "" {
		cfg.ConnConfig.RuntimeParams["search_path"] = schema
	}

	cfg.ConnConfig.DefaultQueryExecMode = pgx.QueryExecModeExec
	if maxConns > 0 {
		cfg.MaxConns = maxConns
	}
	cfg.MaxConnIdleTime = 5 * time.Minute
	cfg.ConnConfig.ConnectTimeout = 10 * time.Second
	return cfg, nil
}

func sanitizeURL(rawURL string) (cleaned string, schema string, err error) {
	rawURL = strings.TrimSpace(rawURL)
	if rawURL == "" {
		return "", "", errors.New("DATABASE_URL is empty")
	}
	u, err := url.Parse(rawURL)
	if err != nil || (u.Scheme != "postgres" && u.Scheme != "postgresql") {
		return "", "", errors.New("DATABASE_URL must be a postgres:// or postgresql:// URL")
	}
	q := u.Query()
	schema = q.Get("schema")
	for _, key := range prismaOnlyParams {
		q.Del(key)
	}
	u.RawQuery = q.Encode()
	return u.String(), schema, nil
}

func WithTx(ctx context.Context, pool *pgxpool.Pool, fn func(tx pgx.Tx) error) error {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin transaction: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	if err := fn(tx); err != nil {
		return err
	}
	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit transaction: %w", err)
	}
	return nil
}
