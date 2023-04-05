# ubuntu-server-init

> ubuntu 的初始化脚本,用于ubuntu-server的初始化

# 如何使用

- 下载

```
curl -o ubuntu-server-init.zip -O https://github.com/QuietSugar/ubuntu-server-init/archive/refs/heads/master.zip
```
> 如果无法访问github,那就使用
```
curl -o ubuntu-server-init.zip -O https://ghproxy.com/https://github.com/QuietSugar/ubuntu-server-init/archive/refs/heads/master.zip
```

- 下载`unzip` 
```
sudo apt install unzip
```


# TODO

- docker的安装可以修改成国内地址安装,应该会更快
- 支持部分安装软件(可选)
- 支持打印软件版本

```
/etc/update-motd.d/11-system-info

#!/bin/sh
#
# 此处输出该系统已安装的信息
#
#

printf "\n"
printf "this path is /etc/update-motd.d/11-system-info\n"
printf " 已安装软件: \n"
printf " docker:        18.06.1-ce\n"
printf " java:          1.8.0_171\n"
printf " golang:        1.10.3\n"
printf " node:          v11.14.0\n"
printf " npm:           6.7.0\n"
printf " python         2.7.12\n"
printf " python3:       3.5.2\n"

printf " TODO: \n"
printf " \n"
```


# 致谢

许多代码来源于 https://github.com/zgs225/debian-init

区别在于,这个项目是为了初始化一个ubuntu-server虚拟机,安装软件尽量使用国内的源(为了在没有代理的情况下能够正常运行)