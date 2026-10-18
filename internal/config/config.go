// Package config 读取 config.sh 暴露的同名环境变量（Go 侧只读，不写回）。
package config

import (
	"os"
	"strings"
)

// Config 对应 config.sh 的变量，默认值保持一致。
type Config struct {
	APTMirror       string
	DockerMirror    string
	APTSourcesURL   string
	DockerAPTURL    string
	GHProxy         string
	GHProxyAuto     bool
	GHProxyAutoList []string
	HallKitVersion  string
}

func env(key, def string) string {
	if v, ok := os.LookupEnv(key); ok {
		return v
	}
	return def
}

// Load 按 config.sh 的默认值装载配置。
func Load() Config {
	return Config{
		APTMirror:       env("APT_MIRROR", "mirrors.aliyun.com"),
		DockerMirror:    env("DOCKER_MIRROR", "mirrors.aliyun.com"),
		APTSourcesURL:   env("APT_SOURCES_URL", ""),
		DockerAPTURL:    env("DOCKER_APT_URL", ""),
		GHProxy:         env("GH_PROXY", ""),
		GHProxyAuto:     env("GH_PROXY_AUTO", "1") != "0",
		GHProxyAutoList: strings.Fields(env("GH_PROXY_AUTO_LIST", "https://gh-proxy.com/ https://ghfast.top/")),
		HallKitVersion:  env("HALL_KIT_VERSION", "latest"),
	}
}
