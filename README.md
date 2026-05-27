# OMME

OMME is a Nix-first wrapper for Logitech Onboard Memory Manager running under Wine.

The Nix package pins Logitech Onboard Memory Manager `2.6.1749`, installs the vendor EXE under `share/omme`, and PATH-wraps portable runtime scripts. The scripts can also be packaged by other distributions without assuming `/nix/store`.

The dedicated Wine prefix lives at:

```sh
${XDG_DATA_HOME:-$HOME/.local/share}/omme/prefix
```

## Use

```sh
direnv allow
just init
just run
```

`just init` creates the Wine prefix, installs `.NET 4.8` and the Visual C++ runtime with `winetricks`, sets Windows 10 mode, selects Wine's GDI renderer, and configures WineBus to avoid SDL capture while leaving hidraw enabled.

`just run` never initializes or repairs the prefix. If the prefix marker is missing, it exits with a message telling you to run `omme-init`.

## Portable Runtime

The checked-in scripts define the runtime contract:

- `omme` starts Wine only after the prefix marker exists.
- `omme-init` performs the slow, idempotent setup. Use `omme-init --force` to repair an existing prefix.
- `omme-debug` enables Wine HID debug channels and delegates to `omme`.
- `udev/70-logitech-omm.rules` is the generic Logitech hidraw rule.

Executable lookup checks `OMME_EXE`, then `OMME_DATA_DIR/OnboardMemoryManager.exe`, then `../share/omme/OnboardMemoryManager.exe` relative to the installed script, then the user cache. Runtime download is disabled unless `OMME_ALLOW_DOWNLOAD=1` is set, and downloaded files are verified with SHA-256.

## NixOS Module

Add this flake as an input and enable the module:

```nix
{
  inputs.omme.url = "path:/home/aron/projects/logitech/omme";

  outputs = { nixpkgs, omme, ... }: {
    nixosConfigurations.host = nixpkgs.lib.nixosSystem {
      modules = [
        omme.nixosModules.default
        {
          programs.omme.enable = true;
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

This runs OMM with Wine HID and plug-and-play debug channels enabled. Override the prefix with `OMME_WINEPREFIX=/some/path`.
