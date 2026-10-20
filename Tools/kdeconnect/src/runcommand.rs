//! Commands the phone can run on this computer. KDE Connect keeps them in
//! `$XDG_CONFIG_HOME/kdeconnect/<device>/kdeconnect_runcommand/config`, a
//! QSettings file whose `commands` key holds JSON wrapped in `@ByteArray(...)`.

use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};
use std::path::{Path, PathBuf};

#[derive(Serialize, Deserialize, Debug, Default, Clone, PartialEq)]
pub struct RunCommand {
    #[serde(default)]
    pub id: String,
    pub name: String,
    pub command: String,
}

pub fn config_path(config_home: &Path, device: &str) -> PathBuf {
    config_home.join("kdeconnect").join(device).join("kdeconnect_runcommand").join("config")
}

/// QSettings string escaping: backslash and double quote.
fn unquote(value: &str) -> String {
    let inner = value.trim().strip_prefix('"').and_then(|v| v.strip_suffix('"')).unwrap_or(value.trim());
    let mut out = String::with_capacity(inner.len());
    let mut chars = inner.chars();
    while let Some(c) = chars.next() {
        if c == '\\' {
            match chars.next() {
                Some('n') => out.push('\n'),
                Some('t') => out.push('\t'),
                Some(other) => out.push(other),
                None => {}
            }
        } else {
            out.push(c);
        }
    }
    out
}

fn quote(value: &str) -> String {
    format!("\"{}\"", value.replace('\\', "\\\\").replace('"', "\\\""))
}

fn commands_line(text: &str) -> Option<&str> {
    let mut in_general = false;
    for line in text.lines() {
        let trimmed = line.trim();
        if trimmed.starts_with('[') {
            in_general = trimmed == "[General]";
        } else if in_general {
            if let Some(value) = trimmed.strip_prefix("commands=") {
                return Some(value);
            }
        }
    }
    None
}

/// Commands sorted by name. Unreadable or missing config yields an empty list.
pub fn parse(text: &str) -> Vec<RunCommand> {
    let Some(raw) = commands_line(text) else {
        return Vec::new();
    };
    let value = unquote(raw);
    let json = value.strip_prefix("@ByteArray(").and_then(|v| v.strip_suffix(')')).unwrap_or(&value);
    let Ok(Value::Object(map)) = serde_json::from_str::<Value>(json) else {
        return Vec::new();
    };
    let mut commands: Vec<RunCommand> = map
        .into_iter()
        .filter_map(|(id, entry)| {
            Some(RunCommand {
                id,
                name: entry.get("name")?.as_str()?.to_owned(),
                command: entry.get("command")?.as_str()?.to_owned(),
            })
        })
        .collect();
    commands.sort_by(|a, b| a.name.to_lowercase().cmp(&b.name.to_lowercase()).then(a.id.cmp(&b.id)));
    commands
}

/// Replaces the `commands` key in `text`, keeping every other line.
pub fn render(text: &str, commands: &[RunCommand]) -> String {
    let mut map = Map::new();
    for c in commands {
        let mut entry = Map::new();
        entry.insert("command".into(), Value::String(c.command.clone()));
        entry.insert("name".into(), Value::String(c.name.clone()));
        map.insert(c.id.clone(), Value::Object(entry));
    }
    let line = format!("commands={}", quote(&format!("@ByteArray({})", Value::Object(map))));
    let mut out = Vec::new();
    let mut in_general = false;
    let mut written = false;
    for raw in text.lines() {
        let trimmed = raw.trim();
        if trimmed.starts_with('[') {
            if in_general && !written {
                out.push(line.clone());
                written = true;
            }
            in_general = trimmed == "[General]";
        } else if in_general && trimmed.starts_with("commands=") {
            if !written {
                out.push(line.clone());
                written = true;
            }
            continue;
        }
        out.push(raw.to_owned());
    }
    if !written {
        if !in_general {
            out.push("[General]".into());
        }
        out.push(line);
    }
    out.join("\n") + "\n"
}

/// KDE Connect ids look like UUIDs with underscores.
pub fn new_id(seed: u128) -> String {
    let hex = format!("{seed:032x}");
    format!("{}_{}_{}_{}_{}", &hex[0..8], &hex[8..12], &hex[12..16], &hex[16..20], &hex[20..32])
}

/// Fills missing ids and drops entries without a name or command.
pub fn normalize(commands: &[RunCommand], mut seed: impl FnMut() -> u128) -> Vec<RunCommand> {
    commands
        .iter()
        .filter(|c| !c.name.trim().is_empty() && !c.command.trim().is_empty())
        .map(|c| RunCommand {
            id: if c.id.is_empty() { new_id(seed()) } else { c.id.clone() },
            name: c.name.trim().to_owned(),
            command: c.command.clone(),
        })
        .collect()
}

pub fn load(config_home: &Path, device: &str) -> Vec<RunCommand> {
    std::fs::read_to_string(config_path(config_home, device)).map(|t| parse(&t)).unwrap_or_default()
}

pub fn save(config_home: &Path, device: &str, commands: &[RunCommand]) -> std::io::Result<()> {
    let path = config_path(config_home, device);
    let existing = std::fs::read_to_string(&path).unwrap_or_default();
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent)?;
    }
    let tmp = path.with_extension("frostalia-tmp");
    std::fs::write(&tmp, render(&existing, commands))?;
    std::fs::rename(tmp, path)
}
