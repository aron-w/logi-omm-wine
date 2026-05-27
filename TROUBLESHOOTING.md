# Troubleshooting

## Prefix Needs Initialization

`omme` does not initialize or repair the Wine prefix automatically. Run:

```sh
just init
```

If the prefix was created by an older OMME release or the window flickers, run:

```sh
just repair
```

## Window Flicker Or Translucency

The current initialization contract selects Wine's GDI renderer because OMM's WPF
interface can flicker or become translucent with accelerated renderers on some
GPU/compositor combinations.

Run `just repair` once after upgrading so the renderer setting is applied to an
existing prefix.

Do not disable `dwmapi.dll`: OMM uses MahApps/ControlzEx and requires that DLL
during startup.

## Mouse Not Detected

Install the udev rule, reload rules, and reconnect the mouse:

```sh
just reload-udev
```

For NixOS, enable `programs.omme.enable = true` and keep
`programs.omme.installUdevRules = true`.

## udev Scope

The included rule grants active local sessions access to Logitech hidraw devices
using the vendor ID `046d`. This is intentionally broad because Logitech mice and
receivers expose different product IDs and OMM needs hidraw access through Wine.

Distribution maintainers may choose to narrow this rule to a tested device list
if their policy requires product-specific hidraw permissions.

## Wayland And X11

Wine still depends on the host desktop stack. If OMM behaves differently across
sessions, compare an X11 session and a Wayland session before filing an issue.
Include the Wine version, compositor, GPU driver, and whether `just repair` was
run after installing the current package.

## Icons

This repository does not ship a Logitech icon or logo. Distributions should not
extract or redistribute vendor artwork unless their packaging policy permits it.
Until a project-owned icon exists, desktop entries may appear with the generic
application icon.
