# Frostalia timer

This checkout maintains the installed Timer plugin in `Plugins/timer/`.
Copy its source files to `~/.config/frostalia/plugins/timer/` and reload the shell to apply updates; keep the installed `settings.json`.

Modes are ordered Stopwatch, Pomodoro, Countdown, with Stopwatch selected on startup. Reopening the panel preserves the selected mode. Pomodoro repeats 50 minutes of work and 10 minutes of break by default. Edit either duration in its panel or widget settings; this resets the current session but preserves study history. The bar and desktop widget follow the selected mode. The desktop mode button cycles through all three modes.

Only running Pomodoro work time counts toward study history, including partial sessions. Breaks, pauses, countdowns and stopwatches do not count. Switching tabs leaves timers running. History is split at local midnight and saved every 15 seconds, on phase changes, pauses, resets and normal plugin unload. An abrupt crash can lose up to 15 seconds. Elapsed work time during system suspend counts while the timer is running.

Daily data is stored as `studySecondsByDay` in `~/.config/frostalia/plugins/timer/settings.json`, with `YYYY-MM-DD` keys and durations in seconds. Export current data and computed stats with:

```sh
qs -c frostalia ipc call plugin:timer stats
```

A single stats line shows today's and lifetime focus, streak and XP. Hover it for the full stats, including the best day's duration, days with at least one minute of focus, the current streak, and 10 focus XP per full minute studied. Yesterday's streak remains visible until today gets started. Resetting a timer never deletes history.

Regression tests are in `Tests/tst_pomodoro.qml`; run `Scripts/dev/run-tests.sh -silent` from the repository root.

---

# Timer Plugin

A simple and elegant timer and stopwatch plugin for Frostalia.

## Features

- **Countdown Timer**: Set a duration and get notified when it finishes.
- **Stopwatch**: Measure elapsed time.
- **Bar Widget**: Shows status and remaining/elapsed time.
- **Control Center Widget**: Quick access from the control center.
- **Notifications**: Sound and toast notification when timer finishes.
- **Multi-language**: Support for 14 languages.

## IPC Commands

You can control the timer plugin via the command line using the Frostalia IPC interface.

### General Usage
```bash
qs -c frostalia ipc call plugin:timer <command>
```

### Available Commands

| Command | Arguments | Description | Example |
|---|---|---|---|
| `toggle` | | Opens or closes the timer panel on the current screen | `qs -c frostalia ipc call plugin:timer toggle` |
| `start` | `[duration]` or `stopwatch` (optional) | Starts/resumes timer or switches to stopwatch mode. | `qs -c frostalia ipc call plugin:timer start 10m` |
| `pause` | | Pauses the running timer/stopwatch | `qs -c frostalia ipc call plugin:timer pause` |
| `reset` | | Resets the timer/stopwatch to initial state | `qs -c frostalia ipc call plugin:timer reset` |

### Duration Format

The `start` command accepts duration strings in the following formats:
- `30` (defaults to minutes)
- `10s` (seconds)
- `5m` (minutes)
- `2h` (hours)
- `1h30m` (combined)
- `stopwatch` (keyword to start stopwatch)

### Examples

**Start a 25-minute timer (Pomodoro):**
```bash
qs -c frostalia ipc call plugin:timer start 25m
```

**Start the stopwatch:**
```bash
qs -c frostalia ipc call plugin:timer start stopwatch
```
