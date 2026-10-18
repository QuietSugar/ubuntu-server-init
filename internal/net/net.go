// Package net 是本项目对 github.com/QuietSugar/hall-lib/netx 的薄封装：
// 保留原有函数签名，内部委托给 netx，避免与 hall-kit 各维护一份镜像逻辑。
package net

import (
	"context"
	"time"

	"github.com/QuietSugar/hall-lib/netx"
	"github.com/QuietSugar/ubuntu-server-init/internal/config"
)

// Canary 与 utils.sh 的 GH_PROXY_CANARY 保持一致。
const Canary = netx.Canary

// ProbeResult 是 netx.ProbeResult 的别名。
type ProbeResult = netx.ProbeResult

// GHURL 只重写 GitHub 域，其它 URL 原样返回（与 gh_url 一致）。
func GHURL(raw, proxy string) string { return netx.GHURL(raw, proxy) }

// Probe 请求 url，返回状态码与耗时（供 net-check 等诊断使用）。
func Probe(ctx context.Context, url string, timeout time.Duration) ProbeResult {
	return netx.Probe(ctx, url, timeout)
}

// DetectGHProxy 解析 GitHub 加速前缀：显式 GH_PROXY 优先；否则直连可用即直连；
// 直连不通再依次探测 GH_PROXY_AUTO_LIST（语义与 utils.sh 的 detect_gh_proxy 一致）。
func DetectGHProxy(cfg config.Config) string {
	return netx.Detect(context.Background(), netx.Config{
		Proxy:    cfg.GHProxy,
		Auto:     cfg.GHProxyAuto,
		AutoList: cfg.GHProxyAutoList,
		Timeout:  6 * time.Second,
	})
}
