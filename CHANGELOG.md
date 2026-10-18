# Changelog

本项目遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

每次发布时：把 `[Unreleased]` 整理为对应版本号章节（含日期），并在其顶部保留新的空 `[Unreleased]` 章节。

## [Unreleased]

## [0.0.1] - 2026-10-18

### Added

- `usinit`（Go 入口，内嵌全部步骤 + TUI）：
  - `install`（默认；`--tui` / `--only` / `--skip` / `--dry-run`，非 TTY 下 `--tui` 自动回退非交互）
  - `extract --dir` / `doctor` / `show-config` / `net-check` / `self-update [--check]` / `version [--json]`
  - `internal/`：config、net（GH_PROXY 探测 / URL 重写）、update（自更新）、extract、steps、tui
- `install.sh` 引导脚本：架构识别 → 解析 tag → 下载二进制 + `checksums.txt` sha256 校验 → 加速站回退 → 安装到 `~/.local/bin`
- GitHub 加速：`GH_PROXY` 显式优先，否则直连探测 → `GH_PROXY_AUTO_LIST` 加速站回退（`GH_PROXY_AUTO=0` 可关闭）
- 幂等初始化步骤（`init/00–99`）：apt 阿里云源、基础工具、Docker、vfox、zsh/dotfiles/z.sh 等；可选 `dev-env.sh` / `proxy.sh` / `hall-kit.sh`
- 工程化：CI（shellcheck + go vet/test + golangci-lint）、GoReleaser 发布（linux amd64/arm64 裸二进制 + checksums.txt）、`Makefile`、`UNINSTALL.md`、`AGENTS.md`
- 依赖：Go `1.26.9` 工具链；共享网络库 `hall-lib/netx v0.1.1`

