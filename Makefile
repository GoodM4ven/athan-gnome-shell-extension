#=============================================================================
UUID=$(shell cat src/metadata.json | python3 -c "import json,sys;obj=json.load(sys.stdin);print(obj['uuid']);")
SRCDIR=src
BUILDDIR=build
FILES=metadata.json *.js stylesheet.css schemas
MKFILE_PATH := $(lastword $(MAKEFILE_LIST))
MKFILE_DIR := $(dir $(MKFILE_PATH))
ABS_MKFILE_PATH := $(abspath $(MKFILE_PATH))
ABS_MKFILE_DIR := $(abspath $(MKFILE_DIR))
ABS_BUILDDIR=$(ABS_MKFILE_DIR)/$(BUILDDIR)
INSTALL_PATH=~/.local/share/gnome-shell/extensions
#=============================================================================
default_target: all
.PHONY: clean all zip install reloadGnome check compile-schemas lint

clean:
	rm -rf $(BUILDDIR)

check:
	@echo "Checking prerequisites..."
	@command -v glib-compile-schemas >/dev/null 2>&1 || { echo >&2 "glib-compile-schemas is not installed. Aborting."; exit 1; }
	@command -v eslint >/dev/null 2>&1 || { echo >&2 "ESLint is not installed. Aborting."; exit 1; }

# ? compile the schemas
compile-schemas:
	@if [ -d $(BUILDDIR)/$(UUID)/schemas ]; then \
		glib-compile-schemas $(BUILDDIR)/$(UUID)/schemas; \
	fi

# ? Linting the code
lint: check
	eslint src/**/*.js

# ? Build the extension
all: clean compile-schemas
	mkdir -p $(BUILDDIR)/$(UUID)
	cp -r src/* $(BUILDDIR)/$(UUID)
	@if [ -d $(BUILDDIR)/$(UUID)/schemas ]; then \
		glib-compile-schemas $(BUILDDIR)/$(UUID)/schemas; \
	fi

xz: all
	(cd $(BUILDDIR)/$(UUID); \
         tar -czvf $(ABS_BUILDDIR)/$(UUID).tar.xz $(FILES:%=%); \
        );

zip: all
	(cd $(BUILDDIR)/$(UUID); \
         zip -rq $(ABS_BUILDDIR)/$(UUID).zip $(FILES:%=%); \
        );

install: all
	mkdir -p $(INSTALL_PATH)/$(UUID)
	cp -R -p build/$(UUID)/* $(INSTALL_PATH)/$(UUID)

reloadGnome:
	@dbus-send --type=method_call --print-reply --dest=org.gnome.Shell /org/gnome/Shell org.gnome.Shell.Eval string:'global.reexec_self()' || \
	{ echo "Failed to reload GNOME Shell. Please restart it manually."; exit 1; }
