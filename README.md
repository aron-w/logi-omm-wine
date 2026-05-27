# logi-omm-wine

logi-omm-wine is a Nix-first wrapper for Logitech Onboard Memory Manager running under Wine.

The Nix package pins Logitech Onboard Memory Manager `2.6.1749`, installs the vendor EXE under `share/logi-omm-wine`, and PATH-wraps portable runtime scripts. The scripts can also be packaged by other distributions without assuming `/nix/store`.

This project is not affiliated with Logitech. The wrapper code is open source; Logitech Onboard Memory Manager is proprietary vendor software and is downloaded from Logitech during packaging.

The dedicated Wine prefix lives at:

```sh
${XDG_DATA_HOME:-$HOME/.local/share}/logi-omm-wine/prefix
```

## Use

```sh
direnv allow
just init
just run
```

`just init` creates the Wine prefix, installs core fonts, `.NET 4.8`, and the Visual C++ runtime with `winetricks`, sets Windows 10 mode, selects Wine's GDI renderer, and configures WineBus to avoid SDL capture while leaving hidraw enabled. The current prefix contract marker is `.logi-omm-wine-initialized-v3`.

`just run` never initializes or repairs the prefix. If the prefix marker is missing, it exits with a message telling you to run `logi-omm-wine-init`.

## Portable Runtime

The checked-in scripts define the runtime contract:

- `logi-omm-wine` starts Wine only after the prefix marker exists.
- `logi-omm-wine-init` performs the slow, idempotent setup. Use `logi-omm-wine-init --force` to repair an existing prefix.
- `logi-omm-wine-init-gui` opens `logi-omm-wine-init` in a terminal emulator for desktop launchers.
- `logi-omm-wine-debug` enables Wine HID debug channels and delegates to `logi-omm-wine`.
- `udev/70-logi-omm-wine.rules` is the generic Logitech hidraw rule.

Executable lookup checks `LOGI_OMM_WINE_EXE`, then `LOGI_OMM_WINE_DATA_DIR/OnboardMemoryManager.exe`, then `../share/logi-omm-wine/OnboardMemoryManager.exe` relative to the installed script, then the user cache. Runtime download is disabled unless `LOGI_OMM_WINE_ALLOW_DOWNLOAD=1` is set, and downloaded files are verified with SHA-256.

Runtime dependencies are expected from `PATH`: `bash`, `wine`, `wineboot`, `winetricks`, `sha256sum`, and optionally `curl` for the explicit runtime download fallback.

## Distro Packaging

For non-Nix packaging, install the portable scripts and metadata with:

```sh
make install DESTDIR="$pkgdir" PREFIX=/usr UDEVDIR=/usr/lib/udev/rules.d
```

Package recipes should fetch `OnboardMemoryManager_2.6.1749.exe` from Logitech and verify:

```text
aec76587f1d07c51667c140c730a38f82675fbe2d898e79413372146b9632358
```

Then install it as:

```sh
make install-exe DESTDIR="$pkgdir" PREFIX=/usr LOGI_OMM_WINE_EXE=/path/to/OnboardMemoryManager_2.6.1749.exe
```

Do not commit or vendor the Logitech executable into this repository.

## NixOS Module

Add this flake as an input and enable the module:

```nix
{
  inputs.logiOmmWine.url = "github:aron-w/logi-omm-wine";

  outputs = { nixpkgs, logiOmmWine, ... }: {
    nixosConfigurations.host = nixpkgs.lib.nixosSystem {
      modules = [
        logiOmmWine.nixosModules.default
        {
          programs.logi-omm-wine.enable = true;
        }
      ];
    };
  };
}
```

The module installs a udev rules package that grants the active local session access to Logitech hidraw devices:

```udev
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="046d", MODE="0660", TAG+="uaccess"
```

After enabling it, rebuild NixOS and reconnect the Logitech mouse. For a local test without a rebuild, `just reload-udev` reloads and triggers hidraw rules.

## Debugging

```sh
just debug
```

This runs OMM with Wine HID and plug-and-play debug channels enabled. Override the prefix with `LOGI_OMM_WINE_PREFIX=/some/path`.

If the OMM window flickers or becomes translucent, run `just repair` once to make sure the prefix has the current GDI renderer setting.

See `TROUBLESHOOTING.md` for udev, compositor, renderer, and icon policy notes.

## License

The wrapper scripts and packaging files are licensed under the MIT License. See `LICENSE`.

Logitech Onboard Memory Manager is proprietary vendor software. See `NOTICE.md`.
