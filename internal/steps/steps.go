// Package steps 提供内嵌 init/*.sh 的列表与说明（供 TUI 展示）。
package steps

import (
	"embed"
	"io/fs"
	"sort"
	"strings"
)

// Step 是一个初始化步骤。
type Step struct {
	File string
	Desc string
}

// 说明与 AGENTS.md 的「初始化步骤一览」保持一致。
var descs = map[string]string{
	"00-sys-init.sh": "卸载 multipath-tools；移除 snapd / lxd / core20",
	"01-apt-init.sh": "配置 apt 源（默认阿里云，可 APT_SOURCES_URL 覆盖）+ apt update",
	"02-base.sh":     "安装 git / curl / jq / tree / htop",
	"03-docker.sh":   "配置 docker 源并安装 docker 全家桶",
	"05-vfox.sh":     "安装 vfox（apt 源优先，GitHub release 回退）",
	"08-zsh.sh":      "安装 zsh 并设为默认 shell",
	"09-z.sh":        "下载 z.sh 到 ~/.zsh/source",
	"90-dotfiles.sh": "安装 dotfiles 并 clone zsh 插件",
	"99-end.sh":      "收尾提示",
}

// List 返回按文件名排序的步骤列表。
func List(fsys embed.FS) ([]Step, error) {
	entries, err := fs.ReadDir(fsys, "init")
	if err != nil {
		return nil, err
	}
	var out []Step
	for _, e := range entries {
		if e.IsDir() || !strings.HasSuffix(e.Name(), ".sh") {
			continue
		}
		out = append(out, Step{File: e.Name(), Desc: descs[e.Name()]})
	}
	sort.Slice(out, func(i, j int) bool { return out[i].File < out[j].File })
	return out, nil
}
