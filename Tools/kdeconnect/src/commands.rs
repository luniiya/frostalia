//! Commands read from stdin, one JSON object per line: `{"cmd":"ring","device":"…"}`.

use crate::runcommand::RunCommand;
use serde::Deserialize;

#[derive(Deserialize, Debug, Clone, PartialEq)]
#[serde(tag = "cmd", rename_all = "camelCase", rename_all_fields = "camelCase")]
pub enum Command {
    /// Re-read everything and ask the daemon to look for devices.
    Refresh,
    SetAnnouncedName { name: String },
    Ring { device: String },
    Ping { device: String, #[serde(default)] message: String },
    SendClipboard { device: String },
    ShareUrls { device: String, urls: Vec<String> },
    ShareText { device: String, text: String },
    Mount { device: String },
    Unmount { device: String },
    Browse { device: String },
    MediaAction { device: String, action: String },
    MediaSeek { device: String, offset: i32 },
    MediaSetPosition { device: String, position: i32 },
    MediaSetVolume { device: String, volume: i32 },
    MediaSetPlayer { device: String, player: String },
    MoveCursor { device: String, dx: i32, dy: i32 },
    /// `single`, `double`, `middle`, `right`, `hold` or `release`.
    Click { device: String, button: String },
    Scroll { device: String, dx: i32, dy: i32 },
    KeyPress {
        device: String,
        #[serde(default)]
        key: String,
        #[serde(default)]
        special: i32,
        #[serde(default)]
        shift: bool,
        #[serde(default)]
        ctrl: bool,
        #[serde(default)]
        alt: bool,
    },
    NotificationDismiss { device: String, id: String },
    NotificationReply { device: String, id: String, text: String },
    RequestConversations { device: String },
    /// Loads messages `start..start+count` of a thread, newest first.
    RequestThread { device: String, thread: i64, #[serde(default)] start: i32, #[serde(default = "default_page")] count: i32 },
    ReplyThread { device: String, thread: i64, text: String },
    SendSms { device: String, addresses: Vec<String>, text: String },
    SyncContacts { device: String },
    RequestPairing { device: String },
    AcceptPairing { device: String },
    RejectPairing { device: String },
    Unpair { device: String },
    SetPluginEnabled { device: String, plugin: String, enabled: bool },
    SetRunCommands { device: String, commands: Vec<RunCommand> },
}

fn default_page() -> i32 {
    50
}

impl Command {
    pub fn parse(line: &str) -> Result<Command, String> {
        serde_json::from_str(line).map_err(|e| format!("invalid command: {e}"))
    }

    /// `remotecontrol.sendCommand` key for a click button name.
    pub fn click_key(button: &str) -> Option<&'static str> {
        Some(match button {
            "single" => "singleclick",
            "double" => "doubleclick",
            "middle" => "middleclick",
            "right" => "rightclick",
            "hold" => "singlehold",
            "release" => "singlerelease",
            _ => return None,
        })
    }
}
