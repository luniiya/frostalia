# Frostalia KDE Connect helper

Build with `cargo build --release --locked`. The executable is
`target/release/frostalia-kdeconnect`. It needs a running `kdeconnectd` on the
session bus and follows it when it starts or stops.

The helper prints one JSON object per line on stdout, tagged by `type`:

| type | contents |
|---|---|
| `state` | `available`, `selfName`, `pairingRequests` and `devices` (status, battery, network, media, phone notifications, sftp, run commands). Printed at start and whenever it changes. |
| `conversations` | Latest SMS of every thread for `device`. |
| `message` | One SMS created or updated (threads load as a stream of these). |
| `conversationLoaded` / `conversationRemoved` | Thread loading finished / thread removed. |
| `contacts` | Contacts synced from the phone (`name`, `numbers`, `photo` data URL). |
| `call`, `shareReceived`, `pairingFailed` | Events from the phone. |
| `error` | A command failed; `message` explains why. |

Commands are read from stdin, one JSON object per line, for example:

```json
{"cmd":"ring","device":"521e38b25c074fb1884917e1bca07796"}
{"cmd":"replyThread","device":"…","thread":7,"text":"on my way"}
```

See `src/commands.rs` for the full list. `setRunCommands` edits
`~/.config/kdeconnect/<device>/kdeconnect_runcommand/config` and reloads the
device's plugins so the phone receives the new list.

Tests: `cargo test --locked`. The integration tests start a private
`dbus-daemon` with a fake `kdeconnectd`.
