# Notice

OMME is an independent wrapper for running Logitech Onboard Memory Manager
under Wine. It is not affiliated with, endorsed by, or supported by Logitech.

This repository does not include the Logitech Onboard Memory Manager Windows
executable. The Nix package downloads `OnboardMemoryManager_2.6.1749.exe` from
Logitech at build time and verifies it with SHA-256:

```text
aec76587f1d07c51667c140c730a38f82675fbe2d898e79413372146b9632358
```

The wrapper scripts and packaging metadata are covered by this repository's
license. Logitech Onboard Memory Manager remains proprietary vendor software
covered by Logitech's own terms.
