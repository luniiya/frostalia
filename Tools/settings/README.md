# Frostalia settings helper

Build with `cargo build --release --locked`. The executable is
`target/release/frostalia-settings`.

```
frostalia-settings load CONFIG.toml [SEED.toml|SEED.json ...]
frostalia-settings save CONFIG.toml
```

Each invocation reads one JSON line from stdin:

```json
{"settings":{"bar":{"position":"top"}},"baseline":{"bar":{"position":"bottom"}}}
```

Both commands emit one JSON line containing `settings` and `fresh`. Errors go to
stderr and produce a nonzero exit status. `baseline` is optional for loading;
provide the previous loaded settings when saving. JSON is only the internal
transport between QML and this helper; the user configuration is TOML.

Loading overlays the file on the supplied defaults. If it does not exist, the
first existing seed is migrated without modifying the seed. The caller orders
seeds with host-specific JSON before generic legacy JSON. With no seed, loading
creates the defaults and returns `fresh: true`. Subsequent loads return false.

Saving rereads the file and applies only values changed since `baseline`, keeping
unrelated external edits, unknown keys, comments, and unchanged array formatting.
With no baseline, all supplied keys are saved. Invalid existing TOML is never
replaced. Changed arrays are replaced as a unit; arrays of objects use TOML table
arrays. Null values are rejected because TOML cannot represent them.

Writes use an atomic replacement in the target directory. New files have mode
0600; existing permissions are retained. Existing symlinks are followed and the
canonical target is replaced, preserving the symlink. Dangling symlinks fail
without replacing the link. No-op saves leave the file and its timestamp intact.

Run `cargo test --locked` and `cargo clippy --all-targets -- -D warnings` to check
the helper.
