.SILENT:
.SUFFIXES:
SHELL = /bin/sh

MODULES = Futures FuturesIO FuturesSync
FOLDERS = Sources Tests

SWIFTFORMAT := $(shell command -v swiftformat 2>/dev/null)
SWIFTLINT := $(shell command -v swiftlint 2>/dev/null)
JAZZY := $(shell command -v jazzy 2>/dev/null)
DOCKER := $(shell command -v docker 2>/dev/null)

override TOOLCHAIN = swiftlang/swift:nightly-bionic


build:
	swift build --configuration debug

build-release:
	swift build --configuration release

test:
	swift test --enable-test-discovery --configuration debug --sanitize thread $(TESTFLAGS)

test-nosanitize:
	swift test --enable-test-discovery --configuration debug $(TESTFLAGS)

test-release:
	swift test --enable-test-discovery --configuration release $(TESTFLAGS)

repl:
	swift run --repl --configuration debug

clean:
	swift package clean

precommit: gyb format lint
pretest: gyb format pristine lint

.PHONY: build build-release test test-nosanitize test-release repl clean precommit pretest


xcodeproj:
	swift package generate-xcodeproj --enable-code-coverage

gyb:
	for folder in $(FOLDERS); do \
		for file in $$(find ./$${folder} -type f -name '*.gyb'); do \
			echo "Generating '$${file%.*}'"; \
			Scripts/gyb.py --line-directive '' -o "$${file%.*}" "$${file}"; \
		done; \
	done

format:
ifndef SWIFTFORMAT
	$(error "swiftformat not found; install with `brew install swiftformat`")
endif
	$(SWIFTFORMAT) .

lint:
ifndef SWIFTLINT
	$(error "swiftlint not found; install with `brew install swiftlint`")
endif
	$(SWIFTLINT) lint --quiet --strict .

pristine:
	Scripts/ensure-pristine.sh

.PHONY: xcodeproj gyb format lint pristine


docs: xcodeproj
ifndef JAZZY
	$(error "jazzy not found; install with `[sudo] gem install --no-document jazzy`")
endif
	Scripts/make-docs.sh

.PHONY: docs


_docker:
ifndef DOCKER
	$(error "docker not found")
endif

LINUX_IMAGE_NAME := 'swift-futures:latest'

linuximage: _docker
	$(DOCKER) build --tag '$(LINUX_IMAGE_NAME)' --build-arg TOOLCHAIN="$(TOOLCHAIN)" .

linuxshell: _docker
	$(DOCKER) run -it --rm --privileged --volume "$$(pwd):/src" --entrypoint '' '$(LINUX_IMAGE_NAME)' /bin/bash

linuxbuild: _docker
	$(DOCKER) run -it --rm --privileged --volume "$$(pwd):/src" '$(LINUX_IMAGE_NAME)' build --configuration debug

linuxrepl: _docker
	$(DOCKER) run -it --rm --privileged --volume "$$(pwd):/src" '$(LINUX_IMAGE_NAME)' run --repl --configuration debug

linuxtest: _docker
	$(DOCKER) run -it --rm --privileged --volume "$$(pwd):/src" '$(LINUX_IMAGE_NAME)' test --enable-test-discovery --configuration debug --sanitize thread $(TESTFLAGS)

.PHONY: _docker linuximage linuxshell linuxbuild linuxrepl linuxtest


digests: build
	digestpath=.digests/$$(date +%s); \
	mkdir -p $${digestpath}; \
	for module in $(MODULES); do \
		xcrun swift-api-digester -dump-sdk -avoid-location -I .build/debug \
			-module $${module} -o $${digestpath}/$${module}.json ; \
	done

listdigests:
	ls .digests 2>/dev/null | cat # it's okay.

apidiagnose:
	digestpathA=".digests/$A"; \
	digestpathB=".digests/$B"; \
	for module in $(MODULES); do \
		echo "/* == $${module} == */"; \
		xcrun swift-api-digester -diagnose-sdk \
			-input-paths $${digestpathA}/$${module}.json \
			-input-paths $${digestpathB}/$${module}.json \
			2>&1 | sed '/^\s*$$/d' ; \
	done

.PHONY: digests listdigests apidiagnose
