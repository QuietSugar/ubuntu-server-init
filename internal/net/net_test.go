package net

import "testing"

func TestGHURL(t *testing.T) {
	cases := []struct{ in, proxy, want string }{
		{"https://raw.githubusercontent.com/a/b", "", "https://raw.githubusercontent.com/a/b"},
		{"https://raw.githubusercontent.com/a/b", "https://gh-proxy.com/", "https://gh-proxy.com/https://raw.githubusercontent.com/a/b"},
		{"https://github.com/a/b", "https://gh-proxy.com", "https://gh-proxy.com/https://github.com/a/b"},
		{"https://codeload.github.com/x", "https://gh-proxy.com/", "https://gh-proxy.com/https://codeload.github.com/x"},
		{"https://mirrors.aliyun.com/x", "https://gh-proxy.com/", "https://mirrors.aliyun.com/x"},
		{"http://example.com/repository/x", "https://gh-proxy.com/", "http://example.com/repository/x"},
	}
	for _, c := range cases {
		if got := GHURL(c.in, c.proxy); got != c.want {
			t.Errorf("GHURL(%q, %q) = %q, want %q", c.in, c.proxy, got, c.want)
		}
	}
}
