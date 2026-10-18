# 卸载 / 回滚 ubuntu-server-init

本项目是**一次性初始化**脚本，"卸载"＝按需把下面这些它可能动过的东西删掉。按来源分组，逐段执行；**执行前先读一遍**，尤其第 4 段（zsh）。

> 仓库里**不含**自动化卸载脚本（作者本地有一份 `usinit-uninstall.sh`，按 `.gitignore` 不提交）。本文件就是它的"手动版"。

## 0. 它会动什么

| 步骤 | 动的东西 |
| --- | --- |
| `00-sys-init` | multipath-tools、snapd / lxd / core20 |
| `01-apt-init` | `/etc/apt/sources.list`（默认改阿里云；可用 `APT_SOURCES_URL` 覆盖）|
| `02-base` | git / curl / jq / tree / htop |
| `03-docker` | docker 源、gpg key、docker 全家桶、docker 组 |
| `05-vfox` | vfox 源与包 |
| `08-zsh` | zsh 包、默认 shell |
| `09-z` | `~/.zsh/source/z.sh` |
| `90-dotfiles` | `~/.zshrc`、`~/.p10k.zsh`、`~/.zsh/`、`~/.zsh/enable` |
| `99-end` | 无（只提示）|

## 1. 还原 apt 源

```bash
# 有安装器原件就用它（Ubuntu 安装器会留 /etc/apt/sources.list.curtin.old）
if [ -s /etc/apt/sources.list.curtin.old ]; then
  sudo cp /etc/apt/sources.list.curtin.old /etc/apt/sources.list
  sudo chmod 644 /etc/apt/sources.list
fi
# 否则手写一份官方源（示例：Ubuntu 22.04 jammy）
```

## 2. 移除 docker

```bash
sudo apt purge -y docker-ce docker-ce-cli docker-ce-rootless-extras containerd.io \
  docker-buildx-plugin docker-compose-plugin docker.io docker-compose
sudo rm -f /etc/apt/keyrings/docker.gpg /etc/apt/sources.list.d/docker.list
sudo rm -rf /var/lib/docker /var/lib/containerd /etc/docker /etc/containerd
sudo gpasswd -d "$USER" docker 2>/dev/null || true
```

## 3. 移除 vfox（想保留 SDK 数据就跳过 `~/.version-fox`）

```bash
sudo rm -f /etc/apt/sources.list.d/versionfox.list
sudo apt purge -y vfox
rm -rf ~/.version-fox
```

## 4. zsh / dotfiles（⚠️ 小心）

**默认不要卸 zsh**：若当前登录 shell 是 zsh，卸载后登录会坏。要卸就先切回 bash：

```bash
chsh -s /bin/bash          # 先切回，重登确认没问题再卸
sudo apt purge -y zsh zsh-common
```

dotfiles（项目复制进去的；`~/.zshrc` / `~/.p10k.zsh` 若原本就有，删前自行备份）：

```bash
rm -rf ~/.zsh ~/.zshrc ~/.p10k.zsh
```

## 5. hall-kit（可选，装过才需要）

```bash
hall shell uninstall 2>/dev/null || true
rm -rf ~/.hall
# Go 命令（hall / gitcheck / ...）在 $(go env GOPATH)/bin，或 vfox 的 packages/bin 下
```

## 6. 项目产物

```bash
rm -rf ~/.local/share/ubuntu-server-init
rm -f ~/.proxy_config
```

## 7. 收尾

```bash
sudo apt autoremove        # 不加 -y：先看它要删什么
```

> ⚠️ `apt autoremove` 可能删掉你仍在用的包（例如 `pkg-config`、`python3-distupgrade`）。**先不加 `-y` 看列表**再决定。
