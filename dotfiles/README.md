# dotfiles

采用rcm管理

- 将一个文件加入dotfile的管理

> 实际上的操作是将该文件移动到了rcm的文件夹中,在原位置建立了一个软链接
> 这个逻辑可以改变,比如把 COPY_ALWAYS="*" 那就变成复制了

```shell
mkrc your_file_name

```

- 如何取消一个文件的管理,将软链接还原成文件

```shell
cd $HOME
# Erase link
rcdn your_file_name
# Create the copy
rcup -C your_file_name
# 此时文件还在rcm中,若不想再管理,在rcm中删除即可
```



