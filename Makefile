VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
LDFLAGS := -s -w -X main.version=$(VERSION)

.PHONY: build build-all vet test fmt check clean

build:
	mkdir -p dist
	GOOS=linux GOARCH=amd64 go build -trimpath -ldflags "$(LDFLAGS)" -o dist/usinit_linux_amd64 .

build-all:
	mkdir -p dist
	GOOS=linux GOARCH=amd64 go build -trimpath -ldflags "$(LDFLAGS)" -o dist/usinit_linux_amd64 .
	GOOS=linux GOARCH=arm64 go build -trimpath -ldflags "$(LDFLAGS)" -o dist/usinit_linux_arm64 .

vet:
	go vet ./...

test:
	go test ./...

fmt:
	gofmt -w main.go tui.go internal/config internal/net internal/extract internal/steps internal/tui

check: vet test
	shellcheck *.sh init/*.sh

clean:
	rm -rf dist
