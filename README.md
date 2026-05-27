# OMME

OMME is a Nix flake wrapper for Logitech Onboard Memory Manager running under Wine.

The wrapper pins Logitech Onboard Memory Manager `2.6.1749` and runs it in a dedicated Wine prefix at:

```sh
${XDG_DATA_HOME:-$HOME/.local/share}/omme/prefix
```

## Use

```sh
direnv allow
just init
just run
```

`just init` creates the Wine prefix, installs the Visual C++ runtime with `winetricks`, and configures WineBus to avoid SDL capture while leaving hidraw enabled.

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
