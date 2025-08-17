# dotfiles

采用 rcm 管理

- 将一个文件加入dotfile的管理

> 实际上的操作是将该文件移动到了rcm的文件夹中,在原位置建立了一个软链接
> 这个逻辑可以改变,比如把 COPY_ALWAYS="*" 那就变成复制了

```shell
mkrc your_file_name

```

- 管理文件

```shell
export dotfiles_dir=${HOME}/git-repo/github.com/QuietSugar/ubuntu-server-init/dotfiles

# rcdn → 清理 dotfiles（移除符号链接，恢复原始状态）
RCRC=${dotfiles_dir}/rcrc rcdn -d ${dotfiles_dir}
# rcup → 部署/更新 dotfiles（将文件链接到正确位置）
RCRC=${dotfiles_dir}/rcrc rcup -d ${dotfiles_dir}
# mkrc → 将文件纳入 rcm 管理
RCRC=${dotfiles_dir}/rcrc mkrc -d ${dotfiles_dir}
# lsrc → 列出受管理的 dotfiles
RCRC=${dotfiles_dir}/rcrc lsrc -d ${dotfiles_dir}
```



