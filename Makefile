PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
DATADIR ?= $(PREFIX)/share
UDEVDIR ?= /usr/lib/udev/rules.d
APPLICATIONSDIR ?= $(DATADIR)/applications
METAINFO_DIR ?= $(DATADIR)/metainfo
LOGI_OMM_WINE_DATADIR ?= $(DATADIR)/logi-omm-wine
LOGI_OMM_WINE_EXE ?=

.PHONY: install install-exe

install:
	install -Dm755 bin/logi-omm-wine "$(DESTDIR)$(BINDIR)/logi-omm-wine"
	install -Dm755 bin/logi-omm-wine-init "$(DESTDIR)$(BINDIR)/logi-omm-wine-init"
	install -Dm755 bin/logi-omm-wine-init-gui "$(DESTDIR)$(BINDIR)/logi-omm-wine-init-gui"
	install -Dm755 bin/logi-omm-wine-debug "$(DESTDIR)$(BINDIR)/logi-omm-wine-debug"
	install -Dm644 udev/70-logi-omm-wine.rules "$(DESTDIR)$(UDEVDIR)/70-logi-omm-wine.rules"
	install -Dm644 share/applications/logi-omm-wine.desktop "$(DESTDIR)$(APPLICATIONSDIR)/logi-omm-wine.desktop"
	install -Dm644 share/applications/logi-omm-wine-init.desktop "$(DESTDIR)$(APPLICATIONSDIR)/logi-omm-wine-init.desktop"
	install -Dm644 share/metainfo/io.github.aron-w.logi-omm-wine.metainfo.xml "$(DESTDIR)$(METAINFO_DIR)/io.github.aron-w.logi-omm-wine.metainfo.xml"
	install -d "$(DESTDIR)$(LOGI_OMM_WINE_DATADIR)"

install-exe:
	@test -n "$(LOGI_OMM_WINE_EXE)" || { printf '%s\n' 'Set LOGI_OMM_WINE_EXE=/path/to/OnboardMemoryManager.exe'; exit 2; }
	install -Dm644 "$(LOGI_OMM_WINE_EXE)" "$(DESTDIR)$(LOGI_OMM_WINE_DATADIR)/OnboardMemoryManager.exe"
