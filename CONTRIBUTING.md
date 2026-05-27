# Contributing

Contributions are welcome when they keep logi-omm-wine small, auditable, and packageable.

Before submitting a change, run:

```sh
just test
just check
just build
```

Keep runtime behavior in the checked-in shell scripts. Nix packaging should install
and wrap those scripts rather than becoming the only implementation of runtime
behavior.

Do not commit Logitech Onboard Memory Manager binaries. Package builds should
fetch vendor binaries from Logitech or accept a locally supplied executable and
verify it by hash.
