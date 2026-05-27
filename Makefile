PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
DATADIR ?= $(PREFIX)/share
UDEVDIR ?= /usr/lib/udev/rules.d
APPLICATIONSDIR ?= $(DATADIR)/applications
METAINFO_DIR ?= $(DATADIR)/metainfo
OMME_DATADIR ?= $(DATADIR)/omme
OMME_EXE ?=

.PHONY: install install-exe

install:
	install -Dm755 bin/omme "$(DESTDIR)$(BINDIR)/omme"
	install -Dm755 bin/omme-init "$(DESTDIR)$(BINDIR)/omme-init"
	install -Dm755 bin/omme-init-gui "$(DESTDIR)$(BINDIR)/omme-init-gui"
	install -Dm755 bin/omme-debug "$(DESTDIR)$(BINDIR)/omme-debug"
	install -Dm644 udev/70-logitech-omm.rules "$(DESTDIR)$(UDEVDIR)/70-logitech-omm.rules"
	install -Dm644 share/applications/omme.desktop "$(DESTDIR)$(APPLICATIONSDIR)/omme.desktop"
	install -Dm644 share/applications/omme-init.desktop "$(DESTDIR)$(APPLICATIONSDIR)/omme-init.desktop"
	install -Dm644 share/metainfo/io.github.aron-w.omme.metainfo.xml "$(DESTDIR)$(METAINFO_DIR)/io.github.aron-w.omme.metainfo.xml"
	install -d "$(DESTDIR)$(OMME_DATADIR)"

install-exe:
	@test -n "$(OMME_EXE)" || { printf '%s\n' 'Set OMME_EXE=/path/to/OnboardMemoryManager.exe'; exit 2; }
	install -Dm644 "$(OMME_EXE)" "$(DESTDIR)$(OMME_DATADIR)/OnboardMemoryManager.exe"
