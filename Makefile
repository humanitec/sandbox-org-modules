# Disable all the default make stuff
MAKEFLAGS += --no-builtin-rules
.SUFFIXES:

GOPRIVATE := github.com/humanitec

## Display help menu
.PHONY: help
help:
	@echo Documented Make targets:
	@perl -e 'undef $$/; while (<>) { while ($$_ =~ /## (.*?)(?:\n# .*)*\n.PHONY:\s+(\S+).*/mg) { printf "\033[36m%-30s\033[0m %s\n", $$2, $$1 } }' $(MAKEFILE_LIST) | sort

# ------------------------------------------------------------------------------
# NON-PHONY TARGETS
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# PHONY TARGETS
# ------------------------------------------------------------------------------

.PHONY: .ALWAYS
.ALWAYS:

## Test that all terraform modules are valid
.PHONY: test
test: TF_PLUGIN_CACHE_DIR=$$(mktemp -d)
test:
	for f in $$(find . -name .terraform); do rm -r $${f}; done
	for f in $$(find . -name .terraform.lock.hcl); do rm -r $${f}; done
	for f in `find . -name main.tf`; do (cd $$(dirname $$f) && echo $$f && tofu init -backend=false && tofu test) || exit 1; done

## Format all terraform files
.PHONY: fmt
fmt:
	for f in `find . -name main.tf`; do cd $$(dirname $$f); tofu fmt -write=true; cd -; done
