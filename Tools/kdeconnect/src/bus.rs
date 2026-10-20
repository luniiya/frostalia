//! Reading state from and sending commands to kdeconnectd over D-Bus.

use crate::commands::Command;
use crate::model::*;
use crate::runcommand;
use crate::sms::{self, Message};
use std::collections::HashMap;
use std::path::PathBuf;
use zbus::blocking::Connection;
use zbus::zvariant::{OwnedValue, Value};

pub const SERVICE: &str = "org.kde.kdeconnect";
pub const ROOT: &str = "/modules/kdeconnect";
const DAEMON: &str = "org.kde.kdeconnect.daemon";
const DEVICE: &str = "org.kde.kdeconnect.device";
const PROPERTIES: &str = "org.freedesktop.DBus.Properties";

type Props = HashMap<String, OwnedValue>;
pub type Result<T> = std::result::Result<T, zbus::Error>;

pub struct Dirs {
    pub config_home: PathBuf,
    pub data_home: PathBuf,
}

impl Dirs {
    pub fn from_env() -> Dirs {
        let home = PathBuf::from(std::env::var_os("HOME").unwrap_or_default());
        let env = |name: &str, fallback: &str| {
            std::env::var_os(name).filter(|v| !v.is_empty()).map(PathBuf::from).unwrap_or_else(|| home.join(fallback))
        };
        Dirs { config_home: env("XDG_CONFIG_HOME", ".config"), data_home: env("XDG_DATA_HOME", ".local/share") }
    }
}

pub fn device_path(device: &str) -> String {
    format!("{ROOT}/devices/{device}")
}

fn plugin_path(device: &str, plugin: &str) -> String {
    format!("{ROOT}/devices/{device}/{plugin}")
}

pub struct Bus<'a> {
    pub conn: &'a Connection,
    pub dirs: &'a Dirs,
}

fn boolean(p: &Props, key: &str) -> bool {
    matches!(p.get(key).map(|v| sms::inner(v)), Some(Value::Bool(true)))
}

fn int(p: &Props, key: &str) -> i32 {
    match p.get(key).map(|v| sms::inner(v)) {
        Some(Value::I32(n)) => *n,
        Some(Value::I64(n)) => i32::try_from(*n).unwrap_or_default(),
        Some(Value::U32(n)) => i32::try_from(*n).unwrap_or_default(),
        _ => 0,
    }
}

fn string(p: &Props, key: &str) -> String {
    match p.get(key).map(|v| sms::inner(v)) {
        Some(Value::Str(s)) => s.as_str().to_owned(),
        _ => String::new(),
    }
}

fn strings(p: &Props, key: &str) -> Vec<String> {
    match p.get(key).map(|v| sms::inner(v)) {
        Some(Value::Array(a)) => a
            .inner()
            .iter()
            .filter_map(|v| match sms::inner(v) {
                Value::Str(s) => Some(s.as_str().to_owned()),
                _ => None,
            })
            .collect(),
        _ => Vec::new(),
    }
}

impl Bus<'_> {
    fn call<B, R>(&self, path: &str, iface: &str, method: &str, body: &B) -> Result<R>
    where
        B: serde::Serialize + zbus::zvariant::DynamicType,
        R: for<'d> serde::Deserialize<'d> + zbus::zvariant::Type,
    {
        let reply = self.conn.call_method(Some(SERVICE), path, Some(iface), method, body)?;
        reply.body().deserialize::<R>().map_err(zbus::Error::from)
    }

    fn call_void<B>(&self, path: &str, iface: &str, method: &str, body: &B) -> Result<()>
    where
        B: serde::Serialize + zbus::zvariant::DynamicType,
    {
        self.conn.call_method(Some(SERVICE), path, Some(iface), method, body).map(|_| ())
    }

    fn props(&self, path: &str, iface: &str) -> Result<Props> {
        self.call(path, PROPERTIES, "GetAll", &(iface,))
    }

    fn set_prop<'v>(&self, path: &str, iface: &str, name: &str, value: Value<'v>) -> Result<()> {
        self.call_void(path, PROPERTIES, "Set", &(iface, name, value))
    }

    fn plugin_iface(plugin: &str) -> String {
        format!("{DEVICE}.{plugin}")
    }

    pub fn state(&self) -> State {
        let Ok(ids) = self.call::<_, Vec<String>>(ROOT, DAEMON, "devices", &(false, false)) else {
            return State::default();
        };
        let self_name = self.call::<_, String>(ROOT, DAEMON, "announcedName", &()).unwrap_or_default();
        let pairing_requests = self.props(ROOT, DAEMON).map(|p| strings(&p, "pairingRequests")).unwrap_or_default();
        let mut devices: Vec<Device> = ids.iter().filter_map(|id| self.device(id).ok()).collect();
        // Paired and reachable devices first, then by name.
        devices.sort_by(|a, b| {
            (b.paired, b.reachable).cmp(&(a.paired, a.reachable)).then(a.name.to_lowercase().cmp(&b.name.to_lowercase()))
        });
        State { available: true, self_name, devices, pairing_requests }
    }

    fn device(&self, id: &str) -> Result<Device> {
        let path = device_path(id);
        let p = self.props(&path, DEVICE)?;
        let plugins: Vec<String> = self.call(&path, DEVICE, "loadedPlugins", &()).unwrap_or_default();
        let has = |name: &str| plugins.iter().any(|p| p == &format!("kdeconnect_{name}"));
        let mut device = Device {
            id: id.to_owned(),
            name: string(&p, "name"),
            kind: string(&p, "type"),
            reachable: boolean(&p, "isReachable"),
            paired: boolean(&p, "isPaired"),
            pair_requested: boolean(&p, "isPairRequested"),
            pair_requested_by_peer: boolean(&p, "isPairRequestedByPeer"),
            verification_key: string(&p, "verificationKey"),
            providers: strings(&p, "activeProviderNames"),
            addresses: strings(&p, "reachableAddresses"),
            supported_plugins: strings(&p, "supportedPlugins"),
            run_commands: runcommand::load(&self.dirs.config_home, id),
            ..Device::default()
        };
        if device.reachable && device.paired {
            if has("battery") {
                if let Ok(b) = self.props(&plugin_path(id, "battery"), &Self::plugin_iface("battery")) {
                    if boolean(&b, "hasBattery") || b.get("hasBattery").is_none() {
                        device.battery = Some(Battery { charge: int(&b, "charge"), charging: boolean(&b, "isCharging") });
                    }
                }
            }
            if has("connectivity_report") {
                if let Ok(n) = self.props(&plugin_path(id, "connectivity_report"), &Self::plugin_iface("connectivity_report")) {
                    let kind = string(&n, "cellularNetworkType");
                    if !kind.is_empty() {
                        device.network = Some(Network { kind, strength: int(&n, "cellularNetworkStrength") });
                    }
                }
            }
            if has("mprisremote") {
                device.media = self.media(id).ok();
            }
            if has("notifications") {
                device.notifications = self.notifications(id).unwrap_or_default();
            }
            if has("sftp") {
                device.sftp = self.sftp(id).ok();
            }
            if has("remotekeyboard") {
                if let Ok(k) = self.props(&plugin_path(id, "remotekeyboard"), &Self::plugin_iface("remotekeyboard")) {
                    device.remote_keyboard_active = boolean(&k, "remoteState");
                }
            }
        }
        device.plugins = plugins;
        Ok(device)
    }

    fn media(&self, id: &str) -> Result<Media> {
        let m = self.props(&plugin_path(id, "mprisremote"), &Self::plugin_iface("mprisremote"))?;
        Ok(Media {
            players: strings(&m, "playerList"),
            player: string(&m, "player"),
            title: string(&m, "title"),
            artist: string(&m, "artist"),
            album: string(&m, "album"),
            playing: boolean(&m, "isPlaying"),
            can_seek: boolean(&m, "canSeek"),
            length: int(&m, "length"),
            position: int(&m, "position"),
            volume: int(&m, "volume"),
            art_url: string(&m, "localAlbumArtUrl"),
        })
    }

    fn notifications(&self, id: &str) -> Result<Vec<PhoneNotification>> {
        let base = plugin_path(id, "notifications");
        let ids: Vec<String> = self.call(&base, &Self::plugin_iface("notifications"), "activeNotifications", &())?;
        let iface = format!("{DEVICE}.notifications.notification");
        Ok(ids
            .iter()
            .filter_map(|nid| {
                let n = self.props(&format!("{base}/{nid}"), &iface).ok()?;
                Some(PhoneNotification {
                    id: nid.clone(),
                    app: string(&n, "appName"),
                    title: string(&n, "title"),
                    text: string(&n, "text"),
                    icon: if boolean(&n, "hasIcon") { string(&n, "iconPath") } else { String::new() },
                    dismissable: boolean(&n, "dismissable"),
                    repliable: !string(&n, "replyId").is_empty(),
                    silent: boolean(&n, "silent"),
                })
            })
            .collect())
    }

    fn sftp(&self, id: &str) -> Result<Sftp> {
        let path = plugin_path(id, "sftp");
        let iface = Self::plugin_iface("sftp");
        let mounted: bool = self.call(&path, &iface, "isMounted", &())?;
        let mut sftp = Sftp {
            mounted,
            error: self.call(&path, &iface, "getMountError", &()).unwrap_or_default(),
            ..Sftp::default()
        };
        if mounted {
            sftp.mount_point = self.call(&path, &iface, "mountPoint", &()).unwrap_or_default();
            let dirs: HashMap<String, OwnedValue> = self.call(&path, &iface, "getDirectories", &()).unwrap_or_default();
            let mut list: Vec<Directory> = dirs
                .into_iter()
                .map(|(path, name)| Directory {
                    name: match sms::inner(&name) {
                        Value::Str(s) => s.as_str().to_owned(),
                        _ => String::new(),
                    },
                    path,
                })
                .collect();
            list.sort_by(|a, b| a.path.cmp(&b.path));
            sftp.directories = list;
        }
        Ok(sftp)
    }

    pub fn conversations(&self, device: &str) -> Result<Vec<Message>> {
        let values: Vec<OwnedValue> =
            self.call(&device_path(device), &format!("{DEVICE}.conversations"), "activeConversations", &())?;
        Ok(sms::latest_per_thread(values.iter().filter_map(|v| sms::decode(v)).collect()))
    }

    /// Runs one command. Outputs it produces directly (conversations, contacts) are returned.
    pub fn run(&self, command: &Command) -> Result<Vec<Output>> {
        use Command::*;
        let plugin = |device: &str, name: &str| (plugin_path(device, name), Self::plugin_iface(name));
        match command {
            Refresh => self.call_void(ROOT, DAEMON, "forceOnNetworkChange", &())?,
            SetAnnouncedName { name } => self.call_void(ROOT, DAEMON, "setAnnouncedName", &(name,))?,
            Ring { device } => {
                let (p, i) = plugin(device, "findmyphone");
                self.call_void(&p, &i, "ring", &())?
            }
            Ping { device, message } => {
                let (p, i) = plugin(device, "ping");
                if message.is_empty() {
                    self.call_void(&p, &i, "sendPing", &())?
                } else {
                    self.call_void(&p, &i, "sendPing", &(message,))?
                }
            }
            SendClipboard { device } => {
                let (p, i) = plugin(device, "clipboard");
                self.call_void(&p, &i, "sendClipboard", &())?
            }
            ShareUrls { device, urls } => {
                let (p, i) = plugin(device, "share");
                self.call_void(&p, &i, "shareUrls", &(urls,))?
            }
            ShareText { device, text } => {
                let (p, i) = plugin(device, "share");
                self.call_void(&p, &i, "shareText", &(text,))?
            }
            Mount { device } => {
                let (p, i) = plugin(device, "sftp");
                self.call_void(&p, &i, "mount", &())?
            }
            Unmount { device } => {
                let (p, i) = plugin(device, "sftp");
                self.call_void(&p, &i, "unmount", &())?
            }
            Browse { device } => {
                let (p, i) = plugin(device, "sftp");
                self.call::<_, bool>(&p, &i, "startBrowsing", &())?;
            }
            MediaAction { device, action } => {
                let (p, i) = plugin(device, "mprisremote");
                self.call_void(&p, &i, "sendAction", &(action,))?
            }
            MediaSeek { device, offset } => {
                let (p, i) = plugin(device, "mprisremote");
                self.call_void(&p, &i, "seek", &(offset,))?
            }
            MediaSetPosition { device, position } => {
                let (p, i) = plugin(device, "mprisremote");
                self.set_prop(&p, &i, "position", Value::from(*position))?
            }
            MediaSetVolume { device, volume } => {
                let (p, i) = plugin(device, "mprisremote");
                self.set_prop(&p, &i, "volume", Value::from((*volume).clamp(0, 100)))?
            }
            MediaSetPlayer { device, player } => {
                let (p, i) = plugin(device, "mprisremote");
                self.set_prop(&p, &i, "player", Value::from(player.as_str()))?
            }
            MoveCursor { device, dx, dy } => {
                let (p, i) = plugin(device, "remotecontrol");
                self.call_void(&p, &i, "moveCursor", &((dx, dy),))?
            }
            Click { device, button } => {
                let key = Command::click_key(button).ok_or_else(|| zbus::Error::Failure(format!("unknown button {button}")))?;
                let (p, i) = plugin(device, "remotecontrol");
                let body: HashMap<&str, Value> = HashMap::from([(key, Value::from(true))]);
                self.call_void(&p, &i, "sendCommand", &(body,))?
            }
            Scroll { device, dx, dy } => {
                let (p, i) = plugin(device, "remotecontrol");
                let body: HashMap<&str, Value> =
                    HashMap::from([("scroll", Value::from(true)), ("dx", Value::from(*dx)), ("dy", Value::from(*dy))]);
                self.call_void(&p, &i, "sendCommand", &(body,))?
            }
            KeyPress { device, key, special, shift, ctrl, alt } => {
                let (p, i) = plugin(device, "remotekeyboard");
                self.call_void(&p, &i, "sendKeyPress", &(key, special, shift, ctrl, alt))?
            }
            NotificationDismiss { device, id } => {
                let path = format!("{}/{id}", plugin_path(device, "notifications"));
                self.call_void(&path, &format!("{DEVICE}.notifications.notification"), "dismiss", &())?
            }
            NotificationReply { device, id, text } => {
                let path = format!("{}/{id}", plugin_path(device, "notifications"));
                self.call_void(&path, &format!("{DEVICE}.notifications.notification"), "sendReply", &(text,))?
            }
            RequestConversations { device } => {
                let iface = format!("{DEVICE}.conversations");
                let messages = self.conversations(device)?;
                // The phone answers with conversationCreated/Updated signals.
                self.call_void(&device_path(device), &iface, "requestAllConversationThreads", &())?;
                let contacts = crate::contacts::load(&self.dirs.data_home, device);
                return Ok(vec![
                    Output::Contacts { device: device.clone(), contacts },
                    Output::Conversations { device: device.clone(), messages },
                ]);
            }
            RequestThread { device, thread, start, count } => {
                let iface = format!("{DEVICE}.conversations");
                self.call_void(&device_path(device), &iface, "requestConversation", &(thread, start, start + count))?
            }
            ReplyThread { device, thread, text } => {
                let iface = format!("{DEVICE}.conversations");
                let attachments: Vec<Value> = Vec::new();
                self.call_void(&device_path(device), &iface, "replyToConversation", &(thread, text, attachments))?
            }
            SendSms { device, addresses, text } => {
                let iface = format!("{DEVICE}.conversations");
                // ConversationAddress is a struct holding one string.
                let addresses: Vec<Value> = addresses.iter().map(|a| Value::from((a.as_str(),))).collect();
                let attachments: Vec<Value> = Vec::new();
                self.call_void(&device_path(device), &iface, "sendWithoutConversation", &(addresses, text, attachments))?
            }
            SyncContacts { device } => {
                let (p, i) = plugin(device, "contacts");
                self.call_void(&p, &i, "synchronizeRemoteWithLocal", &())?;
                let contacts = crate::contacts::load(&self.dirs.data_home, device);
                return Ok(vec![Output::Contacts { device: device.clone(), contacts }]);
            }
            RequestPairing { device } => self.call_void(&device_path(device), DEVICE, "requestPairing", &())?,
            AcceptPairing { device } => self.call_void(&device_path(device), DEVICE, "acceptPairing", &())?,
            RejectPairing { device } => self.call_void(&device_path(device), DEVICE, "cancelPairing", &())?,
            Unpair { device } => self.call_void(&device_path(device), DEVICE, "unpair", &())?,
            SetPluginEnabled { device, plugin, enabled } => {
                self.call_void(&device_path(device), DEVICE, "setPluginEnabled", &(plugin, enabled))?
            }
            SetRunCommands { device, commands } => {
                let mut counter = 0u128;
                let base = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).map(|d| d.as_nanos()).unwrap_or(0)
                    ^ (u128::from(std::process::id()) << 64);
                let commands = runcommand::normalize(commands, || {
                    counter += 1;
                    base.wrapping_mul(6364136223846793005).wrapping_add(counter)
                });
                runcommand::save(&self.dirs.config_home, device, &commands)
                    .map_err(|e| zbus::Error::Failure(format!("cannot save run commands: {e}")))?;
                // Reloading plugins makes runcommand send the new list to the phone.
                self.call_void(&device_path(device), DEVICE, "reloadPlugins", &())?
            }
        }
        Ok(Vec::new())
    }
}

/// Device id from an object path below `/modules/kdeconnect/devices/`.
pub fn device_of(path: &str) -> Option<&str> {
    path.strip_prefix(ROOT)?.strip_prefix("/devices/")?.split('/').next().filter(|id| !id.is_empty())
}
