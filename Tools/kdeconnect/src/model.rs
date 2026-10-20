//! State reported to the shell. Field names are camelCase in JSON.

use crate::contacts::Contact;
use crate::runcommand::RunCommand;
use crate::sms::Message;
use serde::Serialize;

#[derive(Serialize, Debug, Default, Clone, PartialEq)]
#[serde(rename_all = "camelCase")]
pub struct State {
    /// False while kdeconnectd is not on the session bus.
    pub available: bool,
    pub self_name: String,
    pub devices: Vec<Device>,
    /// Ids of devices asking to pair with this computer.
    pub pairing_requests: Vec<String>,
}

#[derive(Serialize, Debug, Default, Clone, PartialEq)]
#[serde(rename_all = "camelCase")]
pub struct Device {
    pub id: String,
    pub name: String,
    #[serde(rename = "type")]
    pub kind: String,
    pub reachable: bool,
    pub paired: bool,
    pub pair_requested: bool,
    pub pair_requested_by_peer: bool,
    pub verification_key: String,
    pub providers: Vec<String>,
    pub addresses: Vec<String>,
    /// Plugins currently loaded (enabled and supported by both sides).
    pub plugins: Vec<String>,
    pub supported_plugins: Vec<String>,
    pub battery: Option<Battery>,
    pub network: Option<Network>,
    pub media: Option<Media>,
    pub notifications: Vec<PhoneNotification>,
    pub sftp: Option<Sftp>,
    pub remote_keyboard_active: bool,
    pub run_commands: Vec<RunCommand>,
}

#[derive(Serialize, Debug, Default, Clone, PartialEq)]
#[serde(rename_all = "camelCase")]
pub struct Battery {
    pub charge: i32,
    pub charging: bool,
}

#[derive(Serialize, Debug, Default, Clone, PartialEq)]
#[serde(rename_all = "camelCase")]
pub struct Network {
    #[serde(rename = "type")]
    pub kind: String,
    /// 0 to 4 bars; -1 when unknown.
    pub strength: i32,
}

#[derive(Serialize, Debug, Default, Clone, PartialEq)]
#[serde(rename_all = "camelCase")]
pub struct Media {
    pub players: Vec<String>,
    pub player: String,
    pub title: String,
    pub artist: String,
    pub album: String,
    pub playing: bool,
    pub can_seek: bool,
    /// Milliseconds.
    pub length: i32,
    pub position: i32,
    pub volume: i32,
    pub art_url: String,
}

#[derive(Serialize, Debug, Default, Clone, PartialEq)]
#[serde(rename_all = "camelCase")]
pub struct PhoneNotification {
    pub id: String,
    pub app: String,
    pub title: String,
    pub text: String,
    pub icon: String,
    pub dismissable: bool,
    pub repliable: bool,
    pub silent: bool,
}

#[derive(Serialize, Debug, Default, Clone, PartialEq)]
#[serde(rename_all = "camelCase")]
pub struct Sftp {
    pub mounted: bool,
    pub mount_point: String,
    pub error: String,
    pub directories: Vec<Directory>,
}

#[derive(Serialize, Debug, Default, Clone, PartialEq)]
pub struct Directory {
    pub path: String,
    pub name: String,
}

/// One JSON line on stdout.
#[derive(Serialize, Debug, Clone, PartialEq)]
#[serde(tag = "type", rename_all = "camelCase")]
pub enum Output {
    State(State),
    /// Latest message of every thread.
    Conversations { device: String, messages: Vec<Message> },
    /// A message was added or changed; the shell merges it into its threads.
    Message { device: String, message: Message },
    ConversationRemoved { device: String, thread: i64 },
    ConversationLoaded { device: String, thread: i64, count: u64 },
    Contacts { device: String, contacts: Vec<Contact> },
    Call { device: String, event: String, number: String, name: String },
    ShareReceived { device: String, url: String },
    PairingFailed { device: String, error: String },
    Error { message: String },
}
