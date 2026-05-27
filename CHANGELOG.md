# Changelog

## Unreleased

- Split runtime behavior into portable checked-in scripts.
- Added explicit Wine prefix initialization through `logi-omm-wine-init`.
- Added a NixOS module and generic Logitech hidraw udev rule.
- Selected Wine's GDI renderer during prefix initialization for OMM stability.
- Install core fonts during prefix initialization for WPF text layout stability.
- Add a robust prefix-scoped stop helper for input-hook hangs.
