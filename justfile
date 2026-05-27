set dotenv-load := true

# List available commands.
default:
    @just --list --unsorted

# Show what to run at each stage.
workflow:
    @printf '%s\n' \
      'One-time setup:' \
      '  direnv allow' \
      '  just doctor' \
      '  just init' \
      '' \
      'Normal use:' \
      '  just run' \
      '' \
      'If the prefix is broken:' \
      '  just repair' \
      '' \
      'If the mouse is not visible:' \
      '  just reload-udev' \
      '  just debug' \
      '' \
      'Before publishing changes:' \
      '  just test' \
      '  just check' \
      '  just build' \
      '' \
      'NixOS integration:' \
      '  enable logiOmmWine.nixosModules.default with programs.logi-omm-wine.enable = true' \
      '  rebuild NixOS, then reconnect the Logitech mouse'

# Verify the local tools used by this repository.
doctor:
    @command -v nix >/dev/null
    @command -v direnv >/dev/null
    @command -v just >/dev/null
    @printf '%s\n' 'Required local tools are available.'

# Initialize the Wine prefix once. Exits quickly when it is already initialized.
init:
    nix run .#init

# Force Wine prefix initialization again without launching OMM.
repair:
    nix run .#init -- --force

# Start Logitech Onboard Memory Manager. Requires `just init` first.
run:
    nix run .#

# Start OMM with Wine HID, plug-and-play, setupapi, and winebus debug logs.
debug:
    nix run .#debug

# Enter the development shell with Wine, winetricks, just, and udev tools.
develop:
    nix develop

# Run local shell syntax and fake-PATH runtime contract tests.
test:
    bash -n bin/logi-omm-wine bin/logi-omm-wine-init bin/logi-omm-wine-init-gui bin/logi-omm-wine-debug tests/runtime-contract.sh
    tests/runtime-contract.sh

# Evaluate flake outputs, package checks, and the NixOS module.
check:
    nix flake check

# Build the default logi-omm-wine package.
build:
    nix build .#

# Format Nix files in this repo.
fmt:
    nixfmt flake.nix

# Check Nix formatting without changing files.
fmt-check:
    nixfmt --check flake.nix

# Reload local udev rules and retrigger hidraw devices; requires sudo.
reload-udev:
    sudo udevadm control --reload-rules
    sudo udevadm trigger --subsystem-match=hidraw
