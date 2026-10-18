# ubuntu-server-init

> Ubuntu / Debian Server 一键初始化：软件源、基础工具、Docker、vfox、zsh、dotfiles

## 安装

**推荐（自动识别架构 + sha256 校验 + 加速站回退）：**

```bash
curl -fsSL https://raw.githubusercontent.com/QuietSugar/ubuntu-server-init/master/install.sh | sh
```

访问不了 GitHub 时，用加速前缀拉这个脚本即可：

```bash
curl -fsSL https://gh-proxy.com/https://raw.githubusercontent.com/QuietSugar/ubuntu-server-init/master/install.sh | sh
```

> - 安装到 `~/.local/bin/usinit`（`USINIT_INSTALL_DIR` 可改）；`USINIT_VERSION` 可指定 tag。
> - 脚本会**校验 sha256**；直连失败自动回退加速站；`GH_PROXY` 可显式指定前缀，`https_proxy` 同样生效。

**手动下载（不想跑脚本时）：**

```bash
ARCH=$(uname -m); case "$ARCH" in x86_64) ARCH=amd64;; aarch64|arm64) ARCH=arm64;; esac
curl -fsSL -o /tmp/usinit "https://github.com/QuietSugar/ubuntu-server-init/releases/latest/download/usinit_linux_${ARCH}" \
  && chmod +x /tmp/usinit && /tmp/usinit
```

> - 二进制**内部**的下载会自动探测 `GH_PROXY`（直连优先 → 加速站），可用 `GH_PROXY` 显式覆盖、`GH_PROXY_AUTO=0` 关闭探测。
> - 自更新：`/tmp/usinit self-update`（`--check` 只检查）；网络体检：`/tmp/usinit net-check`。
> - 交互界面：`--tui`；只解出脚本：`extract --dir DIR`。
> - 卸载 / 回滚：见 [UNINSTALL.md](UNINSTALL.md)。

## 可选扩展

```bash
bash dev-env.sh    # 用 vfox 装 golang / java / maven / nodejs（下载量大）
bash hall-kit.sh   # 安装 hall-kit 工具箱（需要 go；HALL_KIT_VERSION 可指定版本）
bash proxy.sh      # 交互式代理配置（写 ~/.proxy_config）
```

## 与 hall-kit 的关系

本项目是**机器引导层**（Layer 0）：Ubuntu / Debian 首次配置，需要 sudo，一次性。
[hall-kit](https://github.com/QuietSugar/hall-kit) 是**日常工具箱层**（Layer 1）：跨平台、用户级、持续更新。

两者是**单向依赖**：引导层可选地安装工具箱，工具箱不依赖引导层。

边界：本项目管理 `~/.zshrc`、`~/.zsh/source/` 等引导期配置；hall-kit 只使用 `~/.hall/`，不会改动本项目的文件。

## 致谢

部分代码来源于 https://github.com/zgs225/debian-init