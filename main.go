// usinit —— ubuntu-server-init 的入口 / 编排器。
//
// 默认（非 TTY）：把内嵌的 shell 步骤解到目标目录并执行 main.sh，
// 行为等价于旧的 install.sh + main.sh。交互界面见 --tui（internal/tui）。
package main

import (
	"context"
	"embed"
	"errors"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"time"

	"github.com/QuietSugar/ubuntu-server-init/internal/config"
	"github.com/QuietSugar/ubuntu-server-init/internal/extract"
	"github.com/QuietSugar/ubuntu-server-init/internal/net"
	"github.com/QuietSugar/ubuntu-server-init/internal/steps"
	"github.com/QuietSugar/ubuntu-server-init/internal/update"
)

//go:embed init dotfiles config.sh utils.sh main.sh INFO
var assets embed.FS

var version = "dev"

func defaultDir() string {
	if v := os.Getenv("UBUNTU_SERVER_INIT_DIR"); v != "" {
		return v
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return ".ubuntu-server-init"
	}
	return home + "/.local/share/ubuntu-server-init"
}

func main() {
	args := os.Args[1:]
	if len(args) > 0 && args[0] == "--check-update" {
		args = []string{"self-update", "--check"}
	}
	cmd := "install"
	if len(args) > 0 && !strings.HasPrefix(args[0], "-") {
		cmd, args = args[0], args[1:]
	}
	switch cmd {
	case "install", "run":
		runInstall(args)
	case "extract":
		runExtract(args)
	case "show-config":
		runShowConfig()
	case "net-check":
		runNetCheck(args)
	case "self-update":
		runSelfUpdate(args)
	case "doctor":
		runDoctor(args)
	case "version":
		if len(args) > 0 && args[0] == "--json" {
			fmt.Printf("{\"version\":%q,\"go\":%q,\"os\":%q,\"arch\":%q}\n", version, runtime.Version(), runtime.GOOS, runtime.GOARCH)
			return
		}
		fmt.Println("usinit " + version)
	case "help":
		usage()
	default:
		fmt.Fprintln(os.Stderr, "未知命令: "+cmd)
		fmt.Fprintln(os.Stderr)
		usage()
		os.Exit(2)
	}
}

func usage() {
	fmt.Print(`usinit —— ubuntu-server-init 入口

用法:
  usinit [install] [--dir DIR] [--tui] [--only A,B] [--skip C] [--dry-run]
                                         解出步骤并执行 main.sh（默认命令）
  usinit extract --dir DIR               只解出内嵌的 shell 步骤
  usinit doctor                          只读体检（发行版/sudo/apt/docker/网络/资产）
  usinit show-config                     打印配置与网络探测结果
  usinit net-check                       探测 GitHub 直连 / 加速站可达性
  usinit self-update [--check]           自更新（--check 只检查）
  usinit version [--json]                版本

环境变量: APT_MIRROR / DOCKER_MIRROR / APT_SOURCES_URL / DOCKER_APT_URL /
          SKIP_STEPS / DO_DIST_UPGRADE / HALL_KIT_VERSION / GH_PROXY /
          GH_PROXY_AUTO / GH_PROXY_AUTO_LIST / https_proxy / http_proxy
`)
}

// resolve 装载配置并解析 GH_PROXY；解析到加速站时写入环境，供 shell 步骤复用。
func resolve() config.Config {
	cfg := config.Load()
	if p := net.DetectGHProxy(cfg); p != "" {
		_ = os.Setenv("GH_PROXY", p)
	}
	return cfg
}

func runInstall(args []string) {
	fs := flag.NewFlagSet("install", flag.ExitOnError)
	dir := fs.String("dir", defaultDir(), "解出并运行的目标目录")
	tuiFlag := fs.Bool("tui", false, "进入交互界面")
	only := fs.String("only", "", "只运行这些步骤（逗号/空格分隔）")
	skip := fs.String("skip", "", "跳过这些步骤（逗号/空格分隔）")
	dryRun := fs.Bool("dry-run", false, "只打印将执行的步骤与配置，不执行")
	_ = fs.Parse(args)

	cfg := resolve()

	list, err := steps.List(assets)
	if err != nil {
		fatal(err)
	}
	skipList := resolveSkip(list, *only, *skip)

	if *dryRun {
		fmt.Println("== dry-run ==")
		fmt.Println("目录: " + *dir)
		proxy := os.Getenv("GH_PROXY")
		if proxy == "" {
			proxy = "(直连)"
		}
		fmt.Println("GH_PROXY: " + proxy)
		fmt.Println("将执行:")
		for _, s := range list {
			mark := "run "
			if containsStr(skipList, s.File) {
				mark = "skip"
			}
			fmt.Printf("  [%s] %s\n", mark, s.File)
		}
		if len(skipList) > 0 {
			fmt.Println("SKIP_STEPS=" + strings.Join(skipList, " "))
		}
		return
	}

	if isTTY(os.Stdin) && isTTY(os.Stdout) {
		if err := runTUI(assets, *dir, cfg); err != nil {
			fatal(err)
		}
		return
	}
	if *tuiFlag {
		fmt.Fprintln(os.Stderr, "usinit: 当前环境没有 TTY，--tui 不可用，回退为非交互模式")
	}
	if len(skipList) > 0 {
		merged := strings.TrimSpace(os.Getenv("SKIP_STEPS") + " " + strings.Join(skipList, " "))
		_ = os.Setenv("SKIP_STEPS", merged)
	}
	if err := extract.To(assets, *dir); err != nil {
		fatal(err)
	}
	runMain(*dir)
}

func runExtract(args []string) {
	fs := flag.NewFlagSet("extract", flag.ExitOnError)
	dir := fs.String("dir", defaultDir(), "解出目标目录")
	_ = fs.Parse(args)
	if err := extract.To(assets, *dir); err != nil {
		fatal(err)
	}
	fmt.Println("已解出到 " + *dir)
}

func runShowConfig() {
	cfg := resolve()
	fmt.Println("== usinit " + version + " ==")
	fmt.Println("发行版: " + readOSRelease())
	fmt.Println("APT_MIRROR=" + cfg.APTMirror)
	fmt.Println("DOCKER_MIRROR=" + cfg.DockerMirror)
	fmt.Println("APT_SOURCES_URL=" + cfg.APTSourcesURL)
	fmt.Println("DOCKER_APT_URL=" + cfg.DockerAPTURL)
	fmt.Printf("GH_PROXY=%s (auto=%v list=%v)", os.Getenv("GH_PROXY"), cfg.GHProxyAuto, cfg.GHProxyAutoList)
	fmt.Println()
	fmt.Println("GOPROXY=" + os.Getenv("GOPROXY"))
	fmt.Println("HALL_KIT_VERSION=" + cfg.HallKitVersion)
	fmt.Println("SKIP_STEPS=" + os.Getenv("SKIP_STEPS"))
	fmt.Println("DO_DIST_UPGRADE=" + os.Getenv("DO_DIST_UPGRADE"))
}

func runMain(dir string) {
	cmd := exec.Command("bash", "main.sh")
	cmd.Dir = dir
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr
	cmd.Env = os.Environ()
	err := cmd.Run()
	var ee *exec.ExitError
	if errors.As(err, &ee) {
		os.Exit(ee.ExitCode())
	}
	if err != nil {
		fatal(err)
	}
}

// runNetCheck 探测 GitHub 直连与各加速站的可达性。
func runNetCheck(args []string) {
	fs := flag.NewFlagSet("net-check", flag.ExitOnError)
	timeout := fs.Duration("timeout", 8*time.Second, "每个目标的超时")
	_ = fs.Parse(args)

	cfg := config.Load()
	type target struct{ label, url string }
	var targets []target
	if cfg.GHProxy != "" {
		p := strings.TrimRight(cfg.GHProxy, "/")
		targets = append(targets, target{"GH_PROXY(显式) " + p, p + "/" + net.Canary})
	}
	targets = append(targets, target{"直连 raw.githubusercontent.com", net.Canary})
	for _, cand := range cfg.GHProxyAutoList {
		p := strings.TrimRight(cand, "/")
		targets = append(targets, target{p, p + "/" + net.Canary})
	}

	ctx := context.Background()
	anyOK := false
	fmt.Printf("%-6s %8s  %s\n", "结果", "耗时", "目标")
	for _, t := range targets {
		r := net.Probe(ctx, t.url, *timeout)
		status := "FAIL"
		if r.OK {
			status = "OK"
			anyOK = true
		}
		detail := r.Err
		if detail == "" {
			detail = fmt.Sprintf("HTTP %d", r.Status)
		}
		fmt.Printf("%-6s %7dms  %-38s %s\n", status, r.Elapsed.Milliseconds(), t.label, detail)
	}
	if !anyOK {
		fmt.Fprintln(os.Stderr, "usinit: 所有目标都不可达")
		os.Exit(1)
	}
}

// runSelfUpdate 检查并（可选）安装最新 release。
func runSelfUpdate(args []string) {
	fs := flag.NewFlagSet("self-update", flag.ExitOnError)
	check := fs.Bool("check", false, "只检查，不下载")
	_ = fs.Parse(args)

	resolve()
	proxy := os.Getenv("GH_PROXY")
	asset, err := update.Asset()
	if err != nil {
		fatal(err)
	}
	ctx := context.Background()

	body, err := update.Get(ctx, update.LatestURL("checksums.txt", proxy), 60*time.Second)
	if err != nil {
		fatal(fmt.Errorf("获取 checksums.txt 失败: %w", err))
	}
	want, err := update.Expected(string(body), asset)
	if err != nil {
		fatal(err)
	}

	exe, err := os.Executable()
	if err != nil {
		fatal(err)
	}
	if resolved, err := filepath.EvalSymlinks(exe); err == nil {
		exe = resolved
	}
	cur, err := update.FileSHA256(exe)
	if err != nil {
		fatal(err)
	}

	tag := update.LatestTag(ctx, proxy, 20*time.Second)
	if tag == "" {
		tag = "latest"
	}
	fmt.Println("当前: " + version + "  (" + exe + ")")
	fmt.Println("最新: " + tag)

	if cur == want {
		fmt.Println("已是最新（sha256 一致）。")
		return
	}
	if *check {
		fmt.Println("有可用更新。")
		return
	}

	tmp := exe + ".download"
	n, err := update.Download(ctx, update.LatestURL(asset, proxy), tmp, 300*time.Second)
	if err != nil {
		fatal(fmt.Errorf("下载失败: %w", err))
	}
	got, err := update.FileSHA256(tmp)
	if err != nil {
		_ = os.Remove(tmp)
		fatal(err)
	}
	if got != want {
		_ = os.Remove(tmp)
		fatal(fmt.Errorf("sha256 不匹配: 期望 %s, 实际 %s", want, got))
	}
	if err := update.Replace(exe, tmp); err != nil {
		_ = os.Remove(tmp)
		fatal(fmt.Errorf("替换失败（需要写权限?）: %w", err))
	}
	fmt.Printf("已更新: %s (%d 字节, sha256 校验通过)\n", exe, n)
}

// resolveSkip 根据 --only / --skip 计算要跳过的步骤。
func resolveSkip(list []steps.Step, only, skip string) []string {
	split := func(s string) []string {
		return strings.FieldsFunc(s, func(r rune) bool { return r == ',' || r == ' ' || r == '\t' })
	}
	sel := map[string]bool{}
	for _, f := range split(only) {
		sel[f] = true
	}
	sk := map[string]bool{}
	for _, f := range split(skip) {
		sk[f] = true
	}
	var out []string
	for _, s := range list {
		if len(sel) > 0 {
			if !sel[s.File] {
				out = append(out, s.File)
			}
			continue
		}
		if sk[s.File] {
			out = append(out, s.File)
		}
	}
	return out
}

func containsStr(list []string, s string) bool {
	for _, v := range list {
		if v == s {
			return true
		}
	}
	return false
}

// runDoctor 只读体检：发行版 / sudo / apt 源 / docker / 网络 / 内嵌资产。
func runDoctor(args []string) {
	fs := flag.NewFlagSet("doctor", flag.ExitOnError)
	timeout := fs.Duration("timeout", 6*time.Second, "网络探测超时")
	_ = fs.Parse(args)

	cfg := resolve()
	line := func(ok bool, name, detail string) {
		mark := "OK  "
		if !ok {
			mark = "WARN"
		}
		fmt.Printf("  %-4s %-12s %s\n", mark, name, detail)
	}

	fmt.Println("== usinit doctor ==")
	line(true, "发行版", readOSRelease())
	line(true, "架构", runtime.GOOS+"/"+runtime.GOARCH)

	list, err := steps.List(assets)
	line(err == nil, "内嵌步骤", fmt.Sprintf("%d 个", len(list)))

	if _, err := exec.LookPath("sudo"); err != nil {
		line(false, "sudo", "未安装")
	} else if exec.Command("sudo", "-n", "true").Run() == nil {
		line(true, "sudo", "免密可用")
	} else {
		line(true, "sudo", "需要密码（执行步骤时会提示）")
	}

	if b, err := os.ReadFile("/etc/apt/sources.list"); err == nil {
		first := strings.SplitN(strings.TrimSpace(string(b)), "\n", 2)[0]
		line(true, "apt 源", first)
	} else {
		line(false, "apt 源", "读不到 /etc/apt/sources.list")
	}

	if p, err := exec.LookPath("docker"); err != nil {
		line(false, "docker", "未安装（03-docker.sh 会装）")
	} else if out, err := exec.Command(p, "--version").Output(); err == nil {
		line(true, "docker", strings.TrimSpace(string(out)))
	} else {
		line(false, "docker", "存在但无法执行")
	}

	ctx := context.Background()
	direct := net.Probe(ctx, net.Canary, *timeout)
	line(direct.OK, "GitHub 直连", fmt.Sprintf("HTTP %d (%dms)", direct.Status, direct.Elapsed.Milliseconds()))
	for _, cand := range cfg.GHProxyAutoList {
		c := strings.TrimRight(cand, "/")
		r := net.Probe(ctx, c+"/"+net.Canary, *timeout)
		line(r.OK, "加速站", c)
	}
	proxy := os.Getenv("GH_PROXY")
	if proxy == "" {
		proxy = "(直连)"
	}
	line(true, "GH_PROXY", proxy)
}

func isTTY(f *os.File) bool {
	fi, err := f.Stat()
	if err != nil {
		return false
	}
	return fi.Mode()&os.ModeCharDevice != 0
}

func readOSRelease() string {
	b, err := os.ReadFile("/etc/os-release")
	if err != nil {
		return "unknown"
	}
	for _, line := range strings.Split(string(b), "\n") {
		if strings.HasPrefix(line, "PRETTY_NAME=") {
			return strings.Trim(strings.TrimPrefix(line, "PRETTY_NAME="), `"`)
		}
	}
	return "unknown"
}

func fatal(err error) {
	fmt.Fprintln(os.Stderr, "usinit: "+err.Error())
	os.Exit(1)
}
