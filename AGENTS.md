# 项目：ubuntu-server-init

Ubuntu / Debian Server 一键初始化脚本集。通过 `curl | bash` 拉取后按文件名顺序执行 `init/` 下的步骤，完成软件源、基础工具、Docker、vfox、zsh、dotfiles 等配置。部分代码来自 https://github.com/zgs225/debian-init 。

> **分支体系：`master` + `develop`（单人精简 Git Flow），发布时在 master 打 `v*` 附注 tag。**
>
> **工作范围**：默认只处理本仓库（代码 / 文档 / 测试）；其它目录与仓库暂不触碰，除非明确要求。

## 项目定位

### 一句话

ubuntu-server-init 把「新装 Ubuntu / Debian 服务器后要做的第一堆事」收敛成一条命令，是一个**个人 / 小团队自用的服务器初始化脚本集**。

### 解决什么问题

系统装好后通常要做一堆重复劳动：换国内镜像源、装基础工具、装 Docker、装 zsh 与 dotfiles、装版本管理器（vfox）……本项目把这些步骤写成**可重复执行、尽量幂等**的脚本，一条 `curl | bash` 跑完。

### 适用场景

- VPS / 自建机 / 虚拟机交付后的首次配置。
- 作者在多台机器之间保持一致的操作环境。
- 目标系统：**Ubuntu 与 Debian**（脚本按发行版 ID 区分处理）。

### 定位与边界（它不是）

- 不是通用配置管理工具（不是 Ansible / Puppet / Nix 那类）；
- 不是生产集群编排，也不做持续状态收敛，只做一次性初始化；
- 不覆盖所有发行版，只面向 Ubuntu / Debian；
- 各步骤依赖公网下载，网络不通时部分步骤会跳过或回退。

### 取向

- **面向中国网络**：镜像源默认走阿里云，代理通过标准 `http_proxy` / `https_proxy` 环境变量提供。
- **幂等优先**：已完成的步骤输出 `[SKIP]`，重复执行只补缺、不重复破坏。
- **Go 入口 + shell 步骤**：入口是静态二进制 `usinit`（内嵌全部步骤），系统变更仍是 shell（`main.sh` + `init/*.sh`）。
- **可选扩展**：`dev-env.sh` 手动执行，用 vfox 装 golang / java / maven / nodejs；`proxy.sh` 手动管理代理。

### 使用

```bash
# 引导脚本：自动识别架构 + sha256 校验 + 加速站回退
curl -fsSL https://raw.githubusercontent.com/QuietSugar/ubuntu-server-init/master/install.sh | sh
# 装好后（~/.local/bin/usinit）直接运行：
usinit
```

当前默认分支为 `master`，日常开发分支为 `develop`。

### 致谢

部分代码来自 https://github.com/zgs225/debian-init。

## 与 hall-kit 的关系

本项目是机器引导层（Layer 0），[hall-kit](https://github.com/QuietSugar/hall-kit) 是日常工具箱层（Layer 1）。
依赖单向：本项目通过根目录的 `hall-kit.sh` 可选地安装 hall-kit；hall-kit 不依赖本项目。
边界：本项目负责 `~/.zshrc`、`~/.zsh/source/`、apt 源、默认 shell 等引导期配置；hall-kit 只写 `~/.hall/` 并往 rc 追加自己的 marker 块，两者互不覆盖。

## 网络访问约定

- 标准代理 `https_proxy` / `http_proxy` 优先（curl / git / go 都认）。
- `GH_PROXY`：GitHub 加速前缀（末尾斜杠可省）。**默认自动探测**：先试直连，直连不通再依次试 `GH_PROXY_AUTO_LIST`（默认 `gh-proxy.com`、`ghfast.top`）里的加速站，结果缓存；显式设置 `GH_PROXY` 则覆盖、不再探测，`GH_PROXY_AUTO=0` 可关闭探测强制直连。
- `utils.sh` 的 `fetch()` 经 `gh_url()` 统一套用（只重写 GitHub 域）；`90-dotfiles.sh` 的 `git clone` 也走 `gh_url()`（gh-proxy 支持 git）。
- Go 侧 `internal/net` 做同样的探测与重写；`usinit` 启动时解析一次并把结果写回 `GH_PROXY`，供 shell 步骤复用。
- `GOPROXY`：Go module 专用，国内建议 `https://goproxy.cn,direct`；`hall-kit.sh` 会打印当前值。
- 改动 `gh_url()` 时，请与 hall-kit 的 `shell/lib/hall-net.sh` 保持同一规则。

## 分支模型（单人精简 Git Flow）

- `master` —— 仅发布快照；发布时合并 develop 并打 `v*` 附注 tag。
- `develop` —— 日常开发分支。
- `feature/*` —— 可选，需要实验 / 较大改动时从 develop 切出，完成后合并回 develop 并删除。
- 单人开发，不设 PR / release 分支体系；紧急修复走 develop，随下次发布并入 master。

## 目录结构与入口

| 路径 | 作用 |
| --- | --- |
| `usinit`（Go 入口） | 内嵌全部步骤，解出到 `~/.local/share/ubuntu-server-init` 后执行 `main.sh`；含 TUI |
| `install.sh` | 引导脚本：识别架构 → 解析 tag → 下载二进制 + `checksums.txt` 校验 → 装到 `~/.local/bin`（`USINIT_INSTALL_DIR` / `USINIT_VERSION` 可覆盖）|
| `main.go` / `tui.go` | Go CLI：`install`（默认，`--tui` / `--only` / `--skip` / `--dry-run`）/ `extract` / `doctor` / `show-config` / `net-check` / `self-update` / `version [--json]` |
| `internal/` | Go 纯逻辑：`net`（GH_PROXY 探测 / URL 重写）、`update`（自更新）、`extract`、`steps`、`tui`、`config` |
| `Makefile` | `make build` / `make check`（vet + test + shellcheck）|
| `main.sh` | 先 `. ./config.sh`，再 `. ./utils.sh`，trap `ctrl_c`，最后 `run_scripts_in_dir init` |
| `config.sh` | 全局配置，全部用 `${VAR:-默认值}` 形式，可被环境变量覆盖 |
| `utils.sh` | 公共函数库：日志、安装封装、`fetch`、发行版信息等 |
| `proxy.sh` | 独立的交互式代理管理工具（写 `~/.proxy_config`），**不被 main.sh 调用**，需手动执行 |
| `dev-env.sh` | 手动执行：用 vfox 安装 golang / java / maven / nodejs（版本在文件内固定） |
| `init/*.sh` | 按文件名排序依次执行的初始化步骤 |
| `dotfiles/` | 直接复制到 `$HOME` 的 dotfiles（`zshrc`、`p10k.zsh`、`zsh/source/*`） |
| `INFO` | 目录标记，内容必须为 `UBUNTU-SERVER-INIT` |
| `.github/workflows/ci.yml` | CI：shellcheck + tag 发版 |
| `.shellcheckrc` | shellcheck 配置（已禁用 SC1091 / SC2034） |

`config.sh` 暴露的变量：`APT_MIRROR`、`DOCKER_MIRROR`、`APT_SOURCES_URL`、`DOCKER_APT_URL`、`VFOX_VERSION`、`VFOX_APT_REPO`、`VFOX_GITHUB_REPO`、`P10K_REPO`、`ZSH_AUTOSUGGESTIONS_REPO`、`ZSH_SYNTAX_HIGHLIGHTING_REPO`、`ZSH_COMPLETIONS_REPO`、`Z_SH_URL`、`HALL_KIT_VERSION`。

## 执行模型

- `usinit`（Go）：解析 `GH_PROXY` → 把**内嵌**的步骤解到 `~/.local/share/ubuntu-server-init`（`--dir` 可改）→ `bash main.sh`，透传退出码与环境变量。非 TTY 时与旧的 `install.sh + main.sh` 等价；TTY 下默认进 TUI（`--tui` 可强制）。
- `run_scripts_in_dir`：`find <dir> -name '*.sh' | sort` 收集文件，逐个 `bash` 执行并打印 `[i/total]`；**任一步失败即 `l_error` + `exit 1`，整体终止**。
- 步骤脚本都以 `set -e` 开头，然后 `. ./utils.sh`，因此**依赖当前工作目录是仓库根目录**。
- `proxy.sh`、`dev-env.sh` 不在 `init/` 下，不会被自动执行。
- `usinit net-check`：探测 GitHub 直连与 `GH_PROXY_AUTO_LIST` 各加速站，打印可达性表。
- `usinit self-update [--check]`：以 `releases/latest` 的 `checksums.txt` 比对当前二进制 sha256，必要时下载并原子替换；`--check-update` 是 `--check` 的语法糖。
- `usinit install --only A,B --skip C --dry-run`：非交互选步骤 / 只预览。
- `usinit doctor`：只读体检（发行版 / sudo / apt 源 / docker / 网络 / 内嵌资产）。

## 约定

- 步骤命名 `NN-name.sh`，数字前缀决定顺序（`02-base.sh` / `03-docker.sh` / `05-vfox.sh` …）。
- 输出统一用 `l_info` / `l_warn` / `l_error` / `l_success` / `l_skip`。
- 步骤必须**幂等**：先检测再安装/配置，已完成时 `l_skip` 返回。
- **失败策略分层**：必需步骤失败就直接失败退出；可选/易受网络影响的步骤失败时 `l_warn` 后继续（参考 `01-apt-init.sh` 的 dist-upgrade、`05-vfox.sh` 的回退、`09-z.sh` 的下载失败）。
- 安装软件优先复用封装：`install_via_apt`、`install_remote_deb`、`install_via_flatpak`、`install_via_go`（默认已装则跳过，第二参数 `update` 时总是更新）、`install_via_pip`、`install_prebuilt_bin`、`install_prebuilt_zipbin`。
- 网络请求走 `fetch`（内置 curl/wget 超时与重试），不要直接裸 `curl` 下载；apt 相关用 `sudo -E` 保留代理环境变量。
- 镜像站、仓库地址、插件 URL 一律引用 `config.sh` 的变量，不要硬编码。
- 注释和日志使用中文。
- 新增步骤：`init/NN-name.sh` → `#!/bin/bash` + `set -e` + `. ./utils.sh` → 幂等逻辑 + `l_*` 输出。
- Go 改动：改 `main.go` / `internal/` 后跑 `make check`；**步骤仍是 shell，不要把 `init/*.sh` 搬进 Go**。
- TUI 进度：`run_scripts_in_dir` 在 `USINIT_PROGRESS=1` 时输出 `@@USINIT@@ step i/total name state@@`；默认关闭，输出不变。

## 初始化步骤一览

| 步骤 | 作用 |
| --- | --- |
| `00-sys-init.sh` | 关闭并卸载 multipath-tools；移除 lxd / core20 / snapd |
| `01-apt-init.sh` | 若源中无 aliyun 则写入阿里云源，按 `get_distrib_id` 区分 Ubuntu / Debian；`apt update` + `dist-upgrade`（失败仅告警）；删除 `original.list` |
| `02-base.sh` | 安装 git / curl / jq / tree / htop |
| `03-docker.sh` | 装 gpg key 与 docker 源（`DOCKER_MIRROR` + 发行版 ID），安装 docker 全家桶，把 `SUDO_USER` 加入 docker 组 |
| `05-vfox.sh` | 优先装 vfox apt 源；不可达时回退 GitHub release（含架构映射） |
| `08-zsh.sh` | 安装 zsh 并 `chsh` 为默认 shell |
| `09-z.sh` | 下载 z.sh 到 `~/.zsh/source/z.sh` |
| `90-dotfiles.sh` | 复制 dotfiles 到 `$HOME`，clone zsh 插件；`~/.zsh/enable` 为完成标记 |
| `99-end.sh` | `apt autoremove`，提示重开 shell 与可选执行 `dev-env.sh` |

## 代理

- 运行时通过标准环境变量 `http_proxy` / `https_proxy` 走代理，脚本不再内置交互式询问。
- `proxy.sh` 是手动使用的代理管理菜单，配置存 `~/.proxy_config`。


## 校验与 CI

- 本地校验：`make check`（= `go vet` + `go test` + `shellcheck *.sh init/*.sh`）；至少也要 `bash -n <file>`。
- CI：push / PR 到 `develop` 或 `master` 跑 shellcheck + `go vet/test` + `golangci-lint`；推送 `v*` tag 时用 **GoReleaser**（`.goreleaser.yaml`）构建并发布 `usinit_linux_{amd64,arm64}` 与 **`checksums.txt`**（供 `install.sh` / `self-update` 校验）。
- Go：`gofmt` + `go vet` + `go test ./...`；只支持 **linux/amd64、linux/arm64**。
- Go 有单元测试（`internal/net`、`internal/tui`）；**shell 步骤没有单测**，行为只能在真实 Ubuntu / Debian 上验证，不在此环境实际执行初始化。

## 陷阱

- `usinit` 每次都会删除并重建 `~/.local/share/ubuntu-server-init`（`extract` 同理）。
- `01-apt-init.sh` 会覆盖 `/etc/apt/sources.list`（可用 `APT_SOURCES_URL` 指定完整基址，如内网 Nexus apt proxy）。
- `03-docker.sh` 的 key 与源默认来自 `${DOCKER_MIRROR}`，可用 `DOCKER_APT_URL` 整体覆盖（deb 行与 gpg 都从它取）。
- `08-zsh.sh` 会修改当前用户默认 shell。
- `90-dotfiles.sh` 依赖网络 clone 插件，失败会告警跳过。

## 其他

- 远程仓库：https://github.com/QuietSugar/ubuntu-server-init （默认分支 `master`）。
- 文档与提交信息使用中文。

