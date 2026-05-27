# Changelog

## Unreleased

- Split runtime behavior into portable checked-in scripts.
- Added explicit Wine prefix initialization through `logi-omm-wine-init`.
- Added a NixOS module and generic Logitech hidraw udev rule.
- Selected Wine's GDI renderer during prefix initialization for OMM stability.
- Install core fonts during prefix initialization for WPF text layout stability.
- Add a robust prefix-scoped stop helper for input-hook hangs.
- Disable Wine's X11 keyboard scancode auto-detection during prefix initialization.
- Switch to Wine staging full and prefer native Wayland on Wayland sessions.
- Stop stale processes in the dedicated Wine prefix before each normal launch.
- Apply Wine's GDI renderer setting directly instead of through winetricks.
- Skip winetricks during forced repair when the current prefix marker already exists.
- Use stable Wine for prefix initialization so winetricks can create fresh prefixes,
  while keeping Wine staging full for normal runtime.
- Add stable and unstable runtime app variants for Wine keyboard-hook comparison.
- Patch the default Wine runtime to clamp hook counter underflows during OMM key assignment.
