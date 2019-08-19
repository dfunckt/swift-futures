.SILENT:
.SUFFIXES:
SHELL = /bin/sh

MODULES = Futures FuturesSync
FOLDERS = Sources Tests

LINUX_DEV_TOOLCHAIN_URL = https://swift.org/builds/swift-5.1-branch/ubuntu1804/swift-5.1-DEVELOPMENT-SNAPSHOT-2019-08-17-a/swift-5.1-DEVELOPMENT-SNAPSHOT-2019-08-17-a-ubuntu18.04.tar.gz
LINUX_DEV_IMAGE_NAME = swift-futures
LINUX_DEV_IMAGE_TAG = 5.1-dev

SWIFT := $(shell command -v swift 2>/dev/null)
SWIFTFORMAT := $(shell command -v swiftformat 2>/dev/null)
SWIFTLINT := $(shell command -v swiftlint 2>/dev/null)
JAZZY := $(shell command -v jazzy 2>/dev/null)
DOCKER := $(shell command -v docker 2>/dev/null)


build:
	$(SWIFT) build --configuration debug

build-release:
	$(SWIFT) build --configuration release

test:
	$(SWIFT) test --configuration debug --sanitize thread

test-release:
	$(SWIFT) test --configuration release

repl:
	$(SWIFT) run --repl --configuration debug

clean:
	$(SWIFT) package clean

precommit: gyb tests format lint
pretest: gyb tests format pristine lint

.PHONY: build test build-release test-release repl clean precommit pretest


xcodeproj:
	$(SWIFT) package generate-xcodeproj --enable-code-coverage

tests:
	$(SWIFT) test --generate-linuxmain

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

.PHONY: xcodeproj tests gyb format lint pristine


docs: xcodeproj
ifndef JAZZY
	$(error "jazzy not found; install with `[sudo] gem install --no-document jazzy`")
endif
	Scripts/make-docs.sh

.PHONY: docs


toolchain-bionic:
	Scripts/install-toolchain.sh "$(LINUX_DEV_TOOLCHAIN_URL)"

.PHONY: toolchain-bionic


_docker:
ifndef DOCKER
	$(error "docker not found")
endif

linuximage: _docker
	$(DOCKER) build --tag '$(LINUX_DEV_IMAGE_NAME):$(LINUX_DEV_IMAGE_TAG)' --build-arg TOOLCHAIN_URL="$(LINUX_DEV_TOOLCHAIN_URL)" .

linuxtest: _docker
	cwd=$$(pwd); \
	$(DOCKER) run -it --rm --privileged --volume "$${cwd}:/src" '$(LINUX_DEV_IMAGE_NAME):$(LINUX_DEV_IMAGE_TAG)' test --configuration debug --sanitize thread

linuxrepl: _docker
	cwd=$$(pwd); \
	$(DOCKER) run -it --rm --privileged --volume "$${cwd}:/src" '$(LINUX_DEV_IMAGE_NAME):$(LINUX_DEV_IMAGE_TAG)' run --repl --configuration debug

.PHONY: _docker linuximage linuxtest linuxrepl


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
