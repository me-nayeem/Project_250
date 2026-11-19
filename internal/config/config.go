package config

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
)

const MinInternalTokenLength = 32

type Config struct {
	Port          string
	DatabaseURL   string
	DBMaxConns    int32
	InternalToken string

	ResendAPIKey string
	EmailFrom    string

	UpstashURL   string
	UpstashToken string

	DevMode bool
}

func Load(envFile string) (Config, error) {
	if envFile != "" {
		if err := loadDotEnv(envFile); err != nil && !errors.Is(err, os.ErrNotExist) {
			return Config{}, fmt.Errorf("read %s: %w", envFile, err)
		}
	}

	cfg := Config{
		Port:          getenv("PORT", "8080"),
		DatabaseURL:   strings.TrimSpace(os.Getenv("DATABASE_URL")),
		InternalToken: strings.TrimSpace(os.Getenv("GO_INTERNAL_TOKEN")),
		ResendAPIKey:  strings.TrimSpace(os.Getenv("RESEND_API_KEY")),
		EmailFrom:     getenv("EMAIL_FROM", "onboarding@resend.dev"),
		UpstashURL:    strings.TrimSpace(os.Getenv("UPSTASH_REDIS_REST_URL")),
		UpstashToken:  strings.TrimSpace(os.Getenv("UPSTASH_REDIS_REST_TOKEN")),
		DevMode:       strings.EqualFold(strings.TrimSpace(os.Getenv("APP_ENV")), "development"),
		DBMaxConns:    5,
	}

	if raw := strings.TrimSpace(os.Getenv("DB_MAX_CONNS")); raw != "" {
		n, err := strconv.Atoi(raw)
		if err != nil || n < 1 {
			return Config{}, fmt.Errorf("DB_MAX_CONNS must be a positive integer, got %q", raw)
		}
		cfg.DBMaxConns = int32(n)
	}

	var missing []string
	if cfg.DatabaseURL == "" {
		missing = append(missing, "DATABASE_URL")
	}
	if cfg.InternalToken == "" {
		missing = append(missing, "GO_INTERNAL_TOKEN")
	}
	if !cfg.DevMode {
		if cfg.ResendAPIKey == "" {
			missing = append(missing, "RESEND_API_KEY")
		}
		if cfg.UpstashURL == "" || cfg.UpstashToken == "" {
			missing = append(missing, "UPSTASH_REDIS_REST_URL/UPSTASH_REDIS_REST_TOKEN")
		}
	}
	if len(missing) > 0 {
		return Config{}, fmt.Errorf("missing required environment variables: %s", strings.Join(missing, ", "))
	}
	if len(cfg.InternalToken) < MinInternalTokenLength {
		return Config{}, fmt.Errorf("GO_INTERNAL_TOKEN must be at least %d characters", MinInternalTokenLength)
	}

	return cfg, nil
}

func getenv(key, fallback string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return fallback
}

func loadDotEnv(path string) error {
	f, err := os.Open(path)
	if err != nil {
		return err
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	scanner.Buffer(make([]byte, 0, 64*1024), 1024*1024)
	for scanner.Scan() {
		key, value, ok := parseDotEnvLine(scanner.Text())
		if !ok {
			continue
		}
		if _, exists := os.LookupEnv(key); exists {
			continue
		}
		_ = os.Setenv(key, value)
	}
	return scanner.Err()
}

func parseDotEnvLine(line string) (key, value string, ok bool) {
	line = strings.TrimSpace(line)
	if line == "" || strings.HasPrefix(line, "#") {
		return "", "", false
	}
	line = strings.TrimPrefix(line, "export ")
	key, value, found := strings.Cut(line, "=")
	if !found {
		return "", "", false
	}
	key = strings.TrimSpace(key)
	value = strings.TrimSpace(value)
	if key == "" {
		return "", "", false
	}

	if len(value) >= 2 && (value[0] == '"' || value[0] == '\'') {
		quote := value[0]
		if end := strings.IndexByte(value[1:], quote); end >= 0 {
			return key, value[1 : end+1], true
		}
	}

	if i := strings.Index(value, " #"); i >= 0 {
		value = strings.TrimSpace(value[:i])
	}
	return key, value, true
}
