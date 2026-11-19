package db

import (
	"crypto/rand"
	"encoding/binary"
	"math/big"
	"os"
	"strconv"
	"strings"
	"sync/atomic"
	"time"
)

const (
	cuidBase      = 36
	cuidBlockSize = 4
)

var (
	cuidDiscrete    = int64(1679616)
	cuidCounter     atomic.Uint32
	cuidFingerprint = makeFingerprint()
)

func init() {
	var b [4]byte
	_, _ = rand.Read(b[:])
	cuidCounter.Store(binary.BigEndian.Uint32(b[:]))
}

func NewID() string {
	var sb strings.Builder
	sb.Grow(25)
	sb.WriteByte('c')
	sb.WriteString(strconv.FormatInt(time.Now().UnixMilli(), cuidBase))
	sb.WriteString(pad(strconv.FormatInt(int64(cuidCounter.Add(1))%cuidDiscrete, cuidBase), cuidBlockSize))
	sb.WriteString(cuidFingerprint)
	sb.WriteString(randomBlock())
	sb.WriteString(randomBlock())
	return sb.String()
}

func randomBlock() string {
	n, err := rand.Int(rand.Reader, big.NewInt(cuidDiscrete))
	if err != nil {
		return pad(strconv.FormatInt(time.Now().UnixNano()%cuidDiscrete, cuidBase), cuidBlockSize)
	}
	return pad(strconv.FormatInt(n.Int64(), cuidBase), cuidBlockSize)
}

func makeFingerprint() string {
	host, _ := os.Hostname()
	sum := len(host) + cuidBase
	for _, r := range host {
		sum += int(r)
	}
	pid := pad(strconv.FormatInt(int64(os.Getpid()), cuidBase), 2)
	hostID := pad(strconv.FormatInt(int64(sum), cuidBase), 2)
	return pid + hostID
}

func pad(s string, size int) string {
	if len(s) >= size {
		return s[len(s)-size:]
	}
	return strings.Repeat("0", size-len(s)) + s
}
