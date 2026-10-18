package main

import (
	"embed"

	"github.com/QuietSugar/ubuntu-server-init/internal/config"
	"github.com/QuietSugar/ubuntu-server-init/internal/tui"
)

// runTUI 进入 Bubble Tea 交互界面。
func runTUI(fsys embed.FS, dir string, cfg config.Config) error {
	_ = cfg
	return tui.Run(fsys, dir)
}
