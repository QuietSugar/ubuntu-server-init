// Package extract 把内嵌的 shell 资源解到目标目录（语义与 install.sh 的替换行为一致）。
package extract

import (
	"embed"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
)

// To 先删除 dest 再重建，与旧 install.sh 的 rm -rf + mv 行为一致。
func To(fsys embed.FS, dest string) error {
	if dest == "" {
		return os.ErrInvalid
	}
	if err := os.RemoveAll(dest); err != nil {
		return err
	}
	return fs.WalkDir(fsys, ".", func(p string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if p == "." {
			return os.MkdirAll(dest, 0o755)
		}
		// 防目录穿越（内嵌资源本不含 ..，这里只是兜底）
		if strings.Contains(p, "..") {
			return os.ErrInvalid
		}
		out := filepath.Join(dest, filepath.FromSlash(p))
		if d.IsDir() {
			return os.MkdirAll(out, 0o755)
		}
		data, err := fsys.ReadFile(p)
		if err != nil {
			return err
		}
		if err := os.MkdirAll(filepath.Dir(out), 0o755); err != nil {
			return err
		}
		mode := os.FileMode(0o644)
		if strings.HasSuffix(p, ".sh") {
			mode = 0o755
		}
		return os.WriteFile(out, data, mode)
	})
}
