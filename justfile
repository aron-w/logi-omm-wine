set dotenv-load := true

# Show the available repo commands and their descriptions.
default:
    @just --list --unsorted

# Show the recommended workflow for this repo.
workflow:
    @printf '%s\n' \
      'First time:' \
      '  direnv allow' \
      '  just init' \
      '  just run' \
      '' \
      'Normal development:' \
      '  just check' \
      '  just build' \
      '' \
      'NixOS integration:' \
      '  enable omme.nixosModules.default with programs.omme.enable = true' \
      '  rebuild NixOS, then reconnect the Logitech mouse'

# Verify that the common local tools are available.
doctor:
    @command -v nix >/dev/null
    @command -v direnv >/dev/null
    @command -v just >/dev/null
    @printf '%s\n' 'Required local tools are available.'

# Build the default OMME package.
build:
    nix build .#

# Evaluate flake outputs and the NixOS module.
check:
    nix flake check

# Format Nix files in this repo.
fmt:
    nixfmt flake.nix

# Check Nix formatting without changing files.
fmt-check:
    nixfmt --check flake.nix

# Enter the development shell with Wine, winetricks, just, and udev tools.
develop:
    nix develop

# Initialize the dedicated Wine prefix and install OMM runtime dependencies.
init:
    omme-init

# Run Logitech Onboard Memory Manager through Wine.
run:
    omme

# Run OMM with Wine HID, plug-and-play, setupapi, and winebus debug logs.
debug:
    omme-debug

# Reload local udev rules and retrigger hidraw devices; requires sudo.
reload-udev:
    sudo udevadm control --reload-rules
    sudo udevadm trigger --subsystem-match=hidraw
