# ubuntu-server-init

> ubuntu 的初始化脚本,用于ubuntu-server的初始化

# 安装

如果当前终端可以访问 GitHub，直接执行：

```bash
curl -fsSL https://raw.githubusercontent.com/QuietSugar/ubuntu-server-init/refs/heads/dev/install.sh | bash
```

如果需要代理，先设置环境变量再执行：

```bash
export https_proxy=http://your-proxy:port
export http_proxy=http://your-proxy:port
curl -fsSL https://raw.githubusercontent.com/QuietSugar/ubuntu-server-init/refs/heads/dev/install.sh | bash
```

# 从旧版本迁移（移除 rcm）

新版本已移除对 `rcm` 工具的依赖，dotfiles 改为直接复制到目标位置。

若你之前通过旧版本（使用 rcm）初始化过机器，且需要重新运行脚本或迁移到新逻辑，请按以下步骤操作：

## 1. 检查并清理 rcm 创建的符号链接

rcm 通过 `rcup` 创建的 dotfiles 可能是符号链接，例如：

```bash
ls -la ~ | grep '\->'
```

典型的 rcm 符号链接包括：
- `~/.zshrc` -> `.../ubuntu-server-init/dotfiles/zshrc`
- `~/.p10k.zsh` -> `.../ubuntu-server-init/dotfiles/p10k.zsh`

## 2. 保留双方文件（推荐）

rcm 默认创建的是符号链接，直接删除会导致 home 目录丢失配置。使用 `rcup -C` 可将符号链接"降级"为普通文件，同时保留 dotfiles 目录中的源文件：

```bash
# 进入旧的项目目录
cd ~/git-repo/github.com/QuietSugar/ubuntu-server-init

# 将符号链接复制为实体文件（保留双方）
rcup -C -d dotfiles zshrc p10k.zsh
```

执行后：
- `~/.zshrc` 和 `~/.p10k.zsh` 变为独立的普通文件（内容不变）
- `dotfiles/zshrc` 和 `dotfiles/p10k.zsh` 仍然保留

## 3. 彻底清理 rcm（可选）

如果你不再需要 rcm：

```bash
# 卸载 rcm
sudo apt remove -y rcm
```

## 4. 删除标记文件后重新运行

```bash
rm ~/.zsh/enable
cd ~/.local/share/ubuntu-server-init
bash main.sh
```

脚本会自动复制 dotfiles 到对应位置。

# 致谢
部分代码来源于 https://github.com/zgs225/debian-init
