// Package update 实现 usinit 的自更新：下载 release 资产 + sha256 校验 + 原子替换。
package update

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"runtime"
	"strings"
	"time"

	ghnet "github.com/QuietSugar/ubuntu-server-init/internal/net"
)

// Repo 是 GitHub 仓库（owner/name）。
const Repo = "QuietSugar/ubuntu-server-init"

// Asset 返回当前平台对应的资产名；不支持的平台返回错误。
func Asset() (string, error) {
	if runtime.GOOS == "linux" && (runtime.GOARCH == "amd64" || runtime.GOARCH == "arm64") {
		return "usinit_" + runtime.GOOS + "_" + runtime.GOARCH, nil
	}
	return "", fmt.Errorf("不支持的平台: %s/%s（仅 linux/amd64、linux/arm64）", runtime.GOOS, runtime.GOARCH)
}

func client(timeout time.Duration) *http.Client {
	if timeout <= 0 {
		timeout = 60 * time.Second
	}
	return &http.Client{
		Timeout: timeout,
		Transport: &http.Transport{
			Proxy:       http.ProxyFromEnvironment,
			DialContext: (&net.Dialer{Timeout: 5 * time.Second}).DialContext,
		},
	}
}

// LatestURL 返回 releases/latest 下的资产地址（GitHub 会 302 到具体 tag）。
func LatestURL(asset, proxy string) string {
	return ghnet.GHURL("https://github.com/"+Repo+"/releases/latest/download/"+asset, proxy)
}

// Get 取一个小文件的内容（如 checksums.txt）。
func Get(ctx context.Context, url string, timeout time.Duration) ([]byte, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	resp, err := client(timeout).Do(req)
	if err != nil {
		return nil, err
	}
	defer func() { _ = resp.Body.Close() }()
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("HTTP %d: %s", resp.StatusCode, url)
	}
	return io.ReadAll(io.LimitReader(resp.Body, 1<<20))
}

// Expected 从 checksums.txt 内容里取 asset 的 sha256。
func Expected(text, asset string) (string, error) {
	for _, line := range strings.Split(text, "\n") {
		fields := strings.Fields(line)
		if len(fields) == 2 && fields[1] == asset {
			return strings.ToLower(fields[0]), nil
		}
	}
	return "", fmt.Errorf("checksums.txt 里没有 %s", asset)
}

// FileSHA256 计算文件哈希。
func FileSHA256(path string) (string, error) {
	f, err := os.Open(path)
	if err != nil {
		return "", err
	}
	defer func() { _ = f.Close() }()
	h := sha256.New()
	if _, err := io.Copy(h, f); err != nil {
		return "", err
	}
	return hex.EncodeToString(h.Sum(nil)), nil
}

// Download 下载 url 到 dest（0755）。
func Download(ctx context.Context, url, dest string, timeout time.Duration) (int64, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return 0, err
	}
	resp, err := client(timeout).Do(req)
	if err != nil {
		return 0, err
	}
	defer func() { _ = resp.Body.Close() }()
	if resp.StatusCode != http.StatusOK {
		return 0, fmt.Errorf("HTTP %d: %s", resp.StatusCode, url)
	}
	out, err := os.OpenFile(dest, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0o755)
	if err != nil {
		return 0, err
	}
	n, err := io.Copy(out, resp.Body)
	cerr := out.Close()
	if err != nil {
		return n, err
	}
	return n, cerr
}

// LatestTag 尽力解析最新 tag（跟随 releases/latest 的最终 URL）；失败返回空串。
func LatestTag(ctx context.Context, proxy string, timeout time.Duration) string {
	url := ghnet.GHURL("https://github.com/"+Repo+"/releases/latest", proxy)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return ""
	}
	resp, err := client(timeout).Do(req)
	if err != nil {
		return ""
	}
	defer func() { _ = resp.Body.Close() }()
	_, _ = io.Copy(io.Discard, io.LimitReader(resp.Body, 1<<16))
	if resp.Request != nil && resp.Request.URL != nil {
		parts := strings.Split(strings.TrimRight(resp.Request.URL.Path, "/"), "/")
		if len(parts) > 0 && strings.HasPrefix(parts[len(parts)-1], "v") {
			return parts[len(parts)-1]
		}
	}
	return ""
}

// Replace 原子替换可执行文件（src 必须与 exe 同一文件系统）。
func Replace(exe, src string) error {
	if err := os.Chmod(src, 0o755); err != nil {
		return err
	}
	return os.Rename(src, exe)
}
