package update

import (
	"context"
	"crypto/sha256"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestExpected(t *testing.T) {
	text := "abc123  usinit_linux_amd64" + "\n" + "def456  usinit_linux_arm64" + "\n"
	got, err := Expected(text, "usinit_linux_arm64")
	if err != nil || got != "def456" {
		t.Fatalf("Expected = %q, %v", got, err)
	}
	if _, err := Expected(text, "usinit_linux_386"); err == nil {
		t.Fatal("缺失资产应当报错")
	}
}

func TestAsset(t *testing.T) {
	name, err := Asset()
	if err != nil {
		t.Skipf("当前平台不支持: %v", err)
	}
	if name != "usinit_linux_amd64" && name != "usinit_linux_arm64" {
		t.Fatalf("资产名异常: %q", name)
	}
}

func TestDownloadVerifyReplace(t *testing.T) {
	payload := []byte("hello-usinit")
	sum := sha256.Sum256(payload)
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/checksums.txt":
			_, _ = fmt.Fprintf(w, "%x  usinit_linux_amd64\n", sum)
		case "/asset":
			_, _ = w.Write(payload)
		default:
			http.NotFound(w, r)
		}
	}))
	defer srv.Close()

	ctx := context.Background()
	body, err := Get(ctx, srv.URL+"/checksums.txt", 5*time.Second)
	if err != nil {
		t.Fatal(err)
	}
	want, err := Expected(string(body), "usinit_linux_amd64")
	if err != nil {
		t.Fatal(err)
	}
	dir := t.TempDir()
	dest := filepath.Join(dir, "asset")
	if _, err := Download(ctx, srv.URL+"/asset", dest, 5*time.Second); err != nil {
		t.Fatal(err)
	}
	got, err := FileSHA256(dest)
	if err != nil {
		t.Fatal(err)
	}
	if got != want {
		t.Fatalf("sha256 = %s, want %s", got, want)
	}
	exe := filepath.Join(dir, "exe")
	if err := os.WriteFile(exe, []byte("old"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := Replace(exe, dest); err != nil {
		t.Fatal(err)
	}
	b, err := os.ReadFile(exe)
	if err != nil {
		t.Fatal(err)
	}
	if string(b) != string(payload) {
		t.Fatalf("替换后内容 = %q", string(b))
	}
}
