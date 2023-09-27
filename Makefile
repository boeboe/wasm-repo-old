# Copyright (c) Tetrate, Inc 2022 All Rights Reserved.

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

.PHONY: lint compile run release docker-build docker-run

# Variables
BINARY_NAME        := wasm-repo
GO_FILES           := $(wildcard *.go)
RELEASE_VERSION    ?= v0.1.0

DOCKER_IMAGE_NAME  := wasm-repo
DOCKER_HUB_REPO    := boeboe/${DOCKER_IMAGE_NAME}
GIT_REPO           := boeboe/${DOCKER_IMAGE_NAME}

UPLOAD_DIR         := /tmp/uploads

LINTER             := github.com/golangci/golangci-lint/cmd/golangci-lint@v1.54.2


lint: ## Lint the project using golangci-lint (ensure it's installed)
	@echo "Linting..."
	go run $(LINTER) run --verbose

$(BINARY_NAME): $(GO_FILES)
	@echo "Compiling..."
	go build -o $(BINARY_NAME) $(GO_FILES)
	GOOS=linux GOARCH=amd64 go build -o $(BINARY_NAME)-x86_64 $(GO_FILES)
	GOOS=linux GOARCH=arm64 go build -o $(BINARY_NAME)-arm64 $(GO_FILES)

compile: lint $(BINARY_NAME) ## Compile the project

run: $(BINARY_NAME) ## Run the binary
	@echo "Running..."
	@[ -d $(UPLOAD_DIR) ] || mkdir -p $(UPLOAD_DIR)
	UPLOAD_DIR=$(UPLOAD_DIR) ./$(BINARY_NAME)

release: compile ## Create a GitHub release and upload the binary
	@which gh >/dev/null || (echo "gh is not installed" && exit 1)
	@echo "Checking if release $(RELEASE_VERSION) already exists..."
	@if gh release view $(RELEASE_VERSION) -R $(GIT_REPO) > /dev/null 2>&1; then \
		echo "Release $(RELEASE_VERSION) exists. Deleting it..."; \
		gh release delete $(RELEASE_VERSION) -R $(GIT_REPO) --yes; \
	fi
	@echo "Creating a new release on GitHub..."
	gh release create $(RELEASE_VERSION) $(BINARY_NAME)-x86_64 $(BINARY_NAME)-arm64 --title "Release $(RELEASE_VERSION)" --notes "Release notes for $(RELEASE_VERSION)" --repo $(GIT_REPO)

docker-build: ## Build multi-platform Docker image using buildx
	@echo "Building multi-platform Docker image..."
	docker buildx build --platform linux/amd64,linux/arm64 -t $(DOCKER_HUB_REPO):$(RELEASE_VERSION) . --push

docker-run: ## Run the Docker container
	@echo "Running Docker container..."
	if [ "$$(uname -m)" = "arm64" ]; then docker pull --platform linux/arm64 boeboe/wasm-repo:$(RELEASE_VERSION); fi
	if [ "$$(uname -m)" = "x86_64" ]; then docker pull --platform linux/amd64 boeboe/wasm-repo:$(RELEASE_VERSION); fi
	docker run -p 8080:8080 -e UPLOAD_DIR=/root/uploads $(DOCKER_HUB_REPO):$(RELEASE_VERSION)