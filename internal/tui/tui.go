// Package tui 用 Bubble Tea 实现 usinit 的交互界面。
package tui

import (
	"bufio"
	"embed"
	"os"
	"os/exec"
	"strings"

	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/QuietSugar/ubuntu-server-init/internal/extract"
	"github.com/QuietSugar/ubuntu-server-init/internal/steps"
)

type phase int

const (
	phaseSelect phase = iota
	phaseRun
	phaseDone
)

const markerPrefix = "@@USINIT@@ "

type lineMsg string
type doneMsg struct{ err error }

type model struct {
	fs  embed.FS
	dir string

	list    []steps.Step
	checked []bool
	cursor  int

	ph     phase
	status []string
	log    []string
	vp     viewport.Model
	ch     chan tea.Msg
	cmd    *exec.Cmd
	err    error

	width  int
	height int
	ready  bool
}

// Run 启动交互界面。
func Run(fsys embed.FS, dir string) error {
	list, err := steps.List(fsys)
	if err != nil {
		return err
	}
	m := model{fs: fsys, dir: dir, list: list}
	m.checked = make([]bool, len(list))
	m.status = make([]string, len(list))
	for i := range list {
		m.checked[i] = true
		m.status[i] = "pending"
	}
	p := tea.NewProgram(m, tea.WithAltScreen())
	_, err = p.Run()
	return err
}

func (m model) Init() tea.Cmd { return nil }

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
		h := msg.Height - 8
		if h < 3 {
			h = 3
		}
		if !m.ready {
			m.vp = viewport.New(msg.Width, h)
			m.ready = true
		} else {
			m.vp.Width, m.vp.Height = msg.Width, h
		}
		return m, nil
	case lineMsg:
		m.appendLine(string(msg))
		return m, waitLine(m.ch)
	case doneMsg:
		m.err = msg.err
		m.ph = phaseDone
		return m, nil
	case tea.KeyMsg:
		return m.handleKey(msg)
	}
	return m, nil
}

func (m model) handleKey(k tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch k.String() {
	case "ctrl+c":
		m.stop()
		return m, tea.Quit
	case "q":
		if m.ph != phaseRun {
			m.stop()
			return m, tea.Quit
		}
	}
	switch m.ph {
	case phaseSelect:
		switch k.String() {
		case "up", "k":
			if m.cursor > 0 {
				m.cursor--
			}
		case "down", "j":
			if m.cursor < len(m.list)-1 {
				m.cursor++
			}
		case " ":
			m.checked[m.cursor] = !m.checked[m.cursor]
		case "a":
			for i := range m.checked {
				m.checked[i] = true
			}
		case "n":
			for i := range m.checked {
				m.checked[i] = false
			}
		case "enter":
			return m, m.start()
		}
	case phaseDone:
		if k.String() == "enter" {
			return m, tea.Quit
		}
	}
	return m, nil
}

func (m *model) stop() {
	if m.cmd != nil && m.cmd.Process != nil {
		_ = m.cmd.Process.Kill()
	}
}

func (m *model) start() tea.Cmd {
	if err := extract.To(m.fs, m.dir); err != nil {
		m.err = err
		m.ph = phaseDone
		return nil
	}
	skip := composeSkip(m.list, m.checked)
	cmd := exec.Command("bash", "main.sh")
	cmd.Dir = m.dir
	env := append([]string{}, os.Environ()...)
	env = append(env, "USINIT_PROGRESS=1")
	if len(skip) > 0 {
		env = append(env, "SKIP_STEPS="+strings.Join(skip, " "))
	}
	cmd.Env = env
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		m.err = err
		m.ph = phaseDone
		return nil
	}
	cmd.Stderr = cmd.Stdout
	if err := cmd.Start(); err != nil {
		m.err = err
		m.ph = phaseDone
		return nil
	}
	m.cmd = cmd
	m.ch = make(chan tea.Msg, 256)
	ch := m.ch
	go func() {
		sc := bufio.NewScanner(stdout)
		sc.Buffer(make([]byte, 1<<20), 1<<20)
		for sc.Scan() {
			ch <- lineMsg(sc.Text())
		}
		ch <- doneMsg{cmd.Wait()}
	}()
	m.ph = phaseRun
	return waitLine(ch)
}

// composeSkip 把未勾选的步骤合成为 SKIP_STEPS。
func composeSkip(list []steps.Step, checked []bool) []string {
	var skip []string
	for i, s := range list {
		if i >= len(checked) || !checked[i] {
			skip = append(skip, s.File)
		}
	}
	return skip
}

func waitLine(ch chan tea.Msg) tea.Cmd {
	return func() tea.Msg { return <-ch }
}

func (m *model) appendLine(line string) {
	if name, state, ok := parseMarker(line); ok {
		for i, s := range m.list {
			if s.File == name {
				m.status[i] = state
				break
			}
		}
		return
	}
	m.log = append(m.log, line)
	if m.ready {
		m.vp.SetContent(strings.Join(m.log, "\n"))
		m.vp.GotoBottom()
	}
}

func parseMarker(line string) (string, string, bool) {
	if !strings.HasPrefix(line, markerPrefix) || !strings.HasSuffix(line, "@@") {
		return "", "", false
	}
	body := strings.TrimSuffix(strings.TrimPrefix(line, markerPrefix), "@@")
	parts := strings.Fields(body)
	if len(parts) != 4 || parts[0] != "step" {
		return "", "", false
	}
	return parts[2], parts[3], true
}

var (
	titleStyle  = lipgloss.NewStyle().Bold(true)
	cursorStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("205"))
	okStyle     = lipgloss.NewStyle().Foreground(lipgloss.Color("42"))
	skipStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("244"))
	failStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("196"))
	runStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("214"))
)

func (m model) View() string {
	switch m.ph {
	case phaseSelect:
		return m.viewSelect()
	case phaseRun:
		return m.viewRun()
	default:
		return m.viewDone()
	}
}

func (m model) viewSelect() string {
	var b strings.Builder
	b.WriteString(titleStyle.Render("ubuntu-server-init") + "  —— 选择要执行的步骤")
	b.WriteString("\n\n")
	for i, s := range m.list {
		mark := "[ ]"
		if m.checked[i] {
			mark = "[x]"
		}
		line := mark + " " + s.File
		if s.Desc != "" {
			line += "  " + s.Desc
		}
		if i == m.cursor {
			b.WriteString(cursorStyle.Render("> "+line) + "\n")
		} else {
			b.WriteString("  " + line + "\n")
		}
	}
	b.WriteString("\n空格 勾选 / a 全选 / n 全不选 / ↑↓ 移动 / 回车 执行 / q 退出")
	return b.String()
}

func (m model) viewRun() string {
	var b strings.Builder
	b.WriteString(titleStyle.Render("执行中") + "   （q 中止）")
	b.WriteString("\n")
	for i, s := range m.list {
		label := m.status[i]
		style := lipgloss.NewStyle()
		switch label {
		case "ok":
			style = okStyle
		case "skip":
			style = skipStyle
		case "fail":
			style = failStyle
		case "start":
			label = "running"
			style = runStyle
		}
		b.WriteString("  " + style.Render(label) + "  " + s.File + "\n")
	}
	b.WriteString("\n")
	b.WriteString(m.vp.View())
	return b.String()
}

func (m model) viewDone() string {
	var b strings.Builder
	if m.err != nil {
		b.WriteString(failStyle.Render("失败: " + m.err.Error()))
	} else {
		b.WriteString(okStyle.Render("完成"))
	}
	b.WriteString("\n\n")
	for i, s := range m.list {
		b.WriteString("  " + m.status[i] + "  " + s.File + "\n")
	}
	b.WriteString("\n按 q 退出")
	return b.String()
}
