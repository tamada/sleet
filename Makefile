PACKAGE_LIST := $(shell go list ./...)
VERSION := 0.1.0
NAME := sleet
DIST := $(NAME)-$(VERSION)

sleet: coverage.out cmd/sleet/main.go *.go
	go build -o sleet cmd/sleet/main.go

coverage.out: cmd/sleet/main_test.go
	go test -covermode=count \
		-coverprofile=coverage.out $(PACKAGE_LIST)

docker: sleet
#	docker build -t ghcr.io/$(REPO_NAME):$(VERSION) -t ghcr.io/$(REPO_NAME):latest .
	docker buildx build -t ghcr.io/$(REPO_NAME):$(VERSION) \
		-t ghcr.io/$(REPO_NAME):latest --platform=linux/arm64/v8,linux/amd64 --push .

# refer from https://pod.hatenablog.com/entry/2017/06/13/150342
define _createDist
	mkdir -p dist/$(1)_$(2)/$(DIST)
	GOOS=$1 GOARCH=$2 go build -o dist/$(1)_$(2)/$(DIST)/$(NAME)$(3) cmd/$(NAME)/main.go
	cp -r README.md LICENSE dist/$(1)_$(2)/$(DIST)
#	cp -r docs/public dist/$(1)_$(2)/$(DIST)/docs
	tar cfz dist/$(DIST)_$(1)_$(2).tar.gz -C dist/$(1)_$(2) $(DIST)
endef

dist: build
	@$(call _createDist,darwin,amd64,)
	@$(call _createDist,darwin,arm64,)
	@$(call _createDist,windows,amd64,.exe)
	@$(call _createDist,windows,386,.exe)
	@$(call _createDist,linux,amd64,)
	@$(call _createDist,linux,386,)

distclean: clean
	rm -f dist coverage.out

clean:
	rm -f sleet
