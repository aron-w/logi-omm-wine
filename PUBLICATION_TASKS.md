# Public Readiness Tasks

## Before First Public Release

- [x] Confirm the wrapper license choice in `LICENSE`.
- [x] Review `NOTICE.md` language for the Logitech Onboard Memory Manager vendor binary.
- [x] Version the Wine prefix initialization contract so upgrades can migrate existing prefixes.
- [x] Keep the runtime dependency contract small and documented.
- [x] Add a distro-oriented install target with `DESTDIR`, `PREFIX`, `bindir`, `datadir`, udev, and desktop paths.
- [x] Add AppStream/metainfo metadata for software centers.
- [x] Add a GUI-friendly uninitialized-prefix path for desktop launches.
- [x] Decide whether the Logitech hidraw udev rule should remain vendor-wide or be narrowed to known supported product IDs.
- [x] Add an icon policy.
- [x] Add CI for shell tests, formatting, `nix flake check`, and `nix build .#`.

## Nice To Have

- [x] Add `CHANGELOG.md`.
- [x] Add `CONTRIBUTING.md`.
- [x] Add `SECURITY.md`.
- [x] Document known compositor, Wayland, X11, Wine, and GPU-driver workarounds.
