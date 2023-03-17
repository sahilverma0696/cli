all: lint test build

ci: test build

.PHONY: all ci

#################################################
# Determine the type of `push` and `version`
#################################################

ifdef GITHUB_REF
VERSION ?= $(shell echo $(GITHUB_REF) | sed 's/^refs\/tags\///')
NOT_RC  := $(shell echo $(VERSION) | grep -v -e -rc)
	ifeq ($(NOT_RC),)
PUSHTYPE := release-candidate
	else
PUSHTYPE := release
	endif
else
VERSION ?= $(shell [ -d .git ] && git describe --tags --always --dirty="-dev")
# If we are not in an active git dir then try reading the version from .VERSION.
# .VERSION contains a slug populated by `git archive`.
VERSION := $(or $(VERSION),$(shell make/version.sh .VERSION))
PUSHTYPE := branch
endif

VERSION := $(shell echo $(VERSION) | sed 's/^v//')

ifdef V
$(info    GITHUB_REF is $(GITHUB_REF))
$(info    VERSION is $(VERSION))
$(info    PUSHTYPE is $(PUSHTYPE))
endif

include make/common.mk

#################################################
# Build statically compiled step binary for various operating systems
#################################################

BINARY_OUTPUT=$(OUTPUT_ROOT)binary/

define BUNDLE_MAKE
	# $(1) -- Go Operating System (e.g. linux, darwin, windows, etc.)
	# $(2) -- Go Architecture (e.g. amd64, arm, arm64, etc.)
	# $(3) -- Go ARM architectural family (e.g. 7, 8, etc.)
	# $(4) -- Parent directory for executables generated by 'make'.
	$(q) GOOS_OVERRIDE='GOOS=$(1) GOARCH=$(2) GOARM=$(3)' PREFIX=$(4) make $(4)bin/step
endef

binary-linux-amd64:
	$(call BUNDLE_MAKE,linux,amd64,,$(BINARY_OUTPUT)linux-amd64/)

binary-linux-arm64:
	$(call BUNDLE_MAKE,linux,arm64,,$(BINARY_OUTPUT)linux-arm64/)

binary-linux-armv7:
	$(call BUNDLE_MAKE,linux,arm,7,$(BINARY_OUTPUT)linux-armv7/)

binary-linux-mips:
	$(call BUNDLE_MAKE,linux,mips,,$(BINARY_OUTPUT)linux-mips/)

binary-darwin-amd64:
	$(call BUNDLE_MAKE,darwin,amd64,,$(BINARY_OUTPUT)darwin-amd64/)

binary-darwin-arm64:
	$(call BUNDLE_MAKE,darwin,amd64,,$(BINARY_OUTPUT)darwin-arm64/)

binary-windows-amd64:
	$(call BUNDLE_MAKE,windows,amd64,,$(BINARY_OUTPUT)windows-amd64/)

.PHONY: binary-linux-amd64 binary-linux-arm64 binary-linux-armv7 binary-linux-mips binary-darwin-amd64 binary-darwin-arm64 binary-windows-amd64
