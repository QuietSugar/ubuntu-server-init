package tui

import (
	"testing"

	"github.com/QuietSugar/ubuntu-server-init/internal/steps"
)

func TestParseMarker(t *testing.T) {
	name, state, ok := parseMarker("@@USINIT@@ step 3/9 02-base.sh start@@")
	if !ok || name != "02-base.sh" || state != "start" {
		t.Fatalf("got %q %q %v", name, state, ok)
	}
	if _, _, ok := parseMarker("普通日志行"); ok {
		t.Fatal("普通行不应被当成标记")
	}
	if _, _, ok := parseMarker("@@USINIT@@ step 3/9 start@@"); ok {
		t.Fatal("字段数不对不应匹配")
	}
}
func TestComposeSkip(t *testing.T) {
	list := []steps.Step{{File: "01-a.sh"}, {File: "02-b.sh"}, {File: "03-c.sh"}}
	got := composeSkip(list, []bool{true, false, true})
	if len(got) != 1 || got[0] != "02-b.sh" {
		t.Fatalf("composeSkip = %v, want [02-b.sh]", got)
	}
	if len(composeSkip(list, []bool{true, true, true})) != 0 {
		t.Fatal("全选时不应有 skip")
	}
	if len(composeSkip(list, []bool{false, false, false})) != 3 {
		t.Fatal("全不选时应 skip 全部")
	}
}
