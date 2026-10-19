//! Runs the helper against a fake kdeconnectd on a private D-Bus daemon.

use serde_json::Value as Json;
use std::io::{BufRead, BufReader, Write};
use std::process::{Child, ChildStdin, Command, Stdio};
use std::sync::mpsc;
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};
use zbus::blocking::{Connection, connection};
use zbus::zvariant::{OwnedValue, Value};

const DEVICE: &str = "/modules/kdeconnect/devices/phone1";
const TIMEOUT: Duration = Duration::from_secs(10);

type Calls = Arc<Mutex<Vec<String>>>;

struct Daemon;

#[zbus::interface(name = "org.kde.kdeconnect.daemon")]
impl Daemon {
    #[zbus(name = "devices")]
    fn devices(&self, _only_reachable: bool, _only_paired: bool) -> Vec<String> {
        vec!["phone1".into()]
    }
    #[zbus(name = "announcedName")]
    fn announced_name(&self) -> String {
        "testhost".into()
    }
    #[zbus(property, name = "pairingRequests")]
    fn pairing_requests(&self) -> Vec<String> {
        Vec::new()
    }
}

struct Device {
    calls: Calls,
}

#[zbus::interface(name = "org.kde.kdeconnect.device")]
impl Device {
    #[zbus(name = "loadedPlugins")]
    fn loaded_plugins(&self) -> Vec<String> {
        vec!["kdeconnect_battery".into(), "kdeconnect_findmyphone".into(), "kdeconnect_sms".into()]
    }
    #[zbus(name = "unpair")]
    fn unpair(&self) {
        self.calls.lock().unwrap().push("unpair".into());
    }
    #[zbus(property, name = "name")]
    fn name(&self) -> String {
        "Test Phone".into()
    }
    #[zbus(property, name = "type")]
    fn kind(&self) -> String {
        "phone".into()
    }
    #[zbus(property, name = "isReachable")]
    fn is_reachable(&self) -> bool {
        true
    }
    #[zbus(property, name = "isPaired")]
    fn is_paired(&self) -> bool {
        true
    }
    #[zbus(property, name = "activeProviderNames")]
    fn providers(&self) -> Vec<String> {
        vec!["LAN".into()]
    }
}

struct Conversations {
    calls: Calls,
}

fn message() -> Value<'static> {
    let addresses = vec![("+15550100".to_string(),)];
    let attachments: Vec<(i64, String, String, String)> = Vec::new();
    Value::from((1i32, "see you at 7".to_string(), addresses, 1_700_000_000_000i64, 1i32, 0i32, 7i64, 3i32, 0i64, attachments))
}

#[zbus::interface(name = "org.kde.kdeconnect.device.conversations")]
impl Conversations {
    #[zbus(name = "activeConversations")]
    fn active_conversations(&self) -> Vec<OwnedValue> {
        vec![OwnedValue::try_from(Value::Value(Box::new(message()))).unwrap()]
    }
    #[zbus(name = "requestAllConversationThreads")]
    fn request_all(&self) {
        self.calls.lock().unwrap().push("requestAllConversationThreads".into());
    }
    #[zbus(name = "replyToConversation")]
    fn reply(&self, thread: i64, text: String, _attachments: Vec<OwnedValue>) {
        self.calls.lock().unwrap().push(format!("reply {thread} {text}"));
    }
}

struct Battery {
    charge: i32,
}

#[zbus::interface(name = "org.kde.kdeconnect.device.battery")]
impl Battery {
    #[zbus(property, name = "charge")]
    fn charge(&self) -> i32 {
        self.charge
    }
    #[zbus(property, name = "isCharging")]
    fn is_charging(&self) -> bool {
        false
    }
    #[zbus(property, name = "hasBattery")]
    fn has_battery(&self) -> bool {
        true
    }
}

struct FindMyPhone {
    calls: Calls,
}

#[zbus::interface(name = "org.kde.kdeconnect.device.findmyphone")]
impl FindMyPhone {
    #[zbus(name = "ring")]
    fn ring(&self) {
        self.calls.lock().unwrap().push("ring".into());
    }
}

struct Bus {
    process: Child,
    address: String,
    _dir: tempfile::TempDir,
}

impl Bus {
    fn start() -> Bus {
        let dir = tempfile::tempdir().unwrap();
        let config = dir.path().join("bus.conf");
        std::fs::write(
            &config,
            format!(
                r#"<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-Bus Bus Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>
  <type>session</type>
  <listen>unix:dir={}</listen>
  <auth>EXTERNAL</auth>
  <policy context="default">
    <allow send_destination="*" eavesdrop="true"/>
    <allow eavesdrop="true"/>
    <allow own="*"/>
  </policy>
</busconfig>"#,
                dir.path().display()
            ),
        )
        .unwrap();
        let mut process = Command::new("dbus-daemon")
            .arg(format!("--config-file={}", config.display()))
            .arg("--print-address=1")
            .arg("--nofork")
            .stdout(Stdio::piped())
            .spawn()
            .expect("dbus-daemon is required for the integration tests");
        let mut address = String::new();
        BufReader::new(process.stdout.take().unwrap()).read_line(&mut address).unwrap();
        Bus { process, address: address.trim().to_owned(), _dir: dir }
    }

    fn serve(&self, calls: &Calls) -> Connection {
        connection::Builder::address(self.address.as_str())
            .unwrap()
            .name("org.kde.kdeconnect")
            .unwrap()
            .serve_at("/modules/kdeconnect", Daemon)
            .unwrap()
            .serve_at(DEVICE, Device { calls: calls.clone() })
            .unwrap()
            .serve_at(DEVICE, Conversations { calls: calls.clone() })
            .unwrap()
            .serve_at(format!("{DEVICE}/battery"), Battery { charge: 77 })
            .unwrap()
            .serve_at(format!("{DEVICE}/findmyphone"), FindMyPhone { calls: calls.clone() })
            .unwrap()
            .build()
            .unwrap()
    }
}

impl Drop for Bus {
    fn drop(&mut self) {
        let _ = self.process.kill();
        let _ = self.process.wait();
    }
}

struct Helper {
    process: Child,
    stdin: ChildStdin,
    lines: mpsc::Receiver<Json>,
    _home: tempfile::TempDir,
}

impl Helper {
    fn start(bus: &Bus) -> Helper {
        let home = tempfile::tempdir().unwrap();
        let mut process = Command::new(env!("CARGO_BIN_EXE_frostalia-kdeconnect"))
            .env("DBUS_SESSION_BUS_ADDRESS", &bus.address)
            .env("XDG_CONFIG_HOME", home.path().join("config"))
            .env("XDG_DATA_HOME", home.path().join("data"))
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .spawn()
            .unwrap();
        let stdout = process.stdout.take().unwrap();
        let (tx, lines) = mpsc::channel();
        std::thread::spawn(move || {
            for line in BufReader::new(stdout).lines().map_while(Result::ok) {
                if tx.send(serde_json::from_str(&line).expect("helper prints JSON lines")).is_err() {
                    break;
                }
            }
        });
        let stdin = process.stdin.take().unwrap();
        Helper { process, stdin, lines, _home: home }
    }

    fn send(&mut self, command: &str) {
        writeln!(self.stdin, "{command}").unwrap();
        self.stdin.flush().unwrap();
    }

    /// Next output matching `pred`, skipping others.
    fn expect(&self, what: &str, pred: impl Fn(&Json) -> bool) -> Json {
        let end = Instant::now() + TIMEOUT;
        while let Some(left) = end.checked_duration_since(Instant::now()) {
            match self.lines.recv_timeout(left) {
                Ok(line) if pred(&line) => return line,
                Ok(_) => continue,
                Err(_) => break,
            }
        }
        panic!("timed out waiting for {what}");
    }
}

impl Drop for Helper {
    fn drop(&mut self) {
        let _ = self.process.kill();
        let _ = self.process.wait();
    }
}

fn is_type(line: &Json, kind: &str) -> bool {
    line["type"] == kind
}

fn wait_for_call(calls: &Calls, call: &str) {
    let end = Instant::now() + TIMEOUT;
    while Instant::now() < end {
        if calls.lock().unwrap().iter().any(|c| c == call) {
            return;
        }
        std::thread::sleep(Duration::from_millis(20));
    }
    panic!("{call} was not called; calls: {:?}", calls.lock().unwrap());
}

#[test]
fn reports_state_and_runs_commands() {
    let bus = Bus::start();
    let calls = Calls::default();
    let service = bus.serve(&calls);
    let mut helper = Helper::start(&bus);

    let state = helper.expect("initial state", |l| is_type(l, "state"));
    assert_eq!(state["available"], true);
    assert_eq!(state["selfName"], "testhost");
    let device = &state["devices"][0];
    assert_eq!(device["id"], "phone1");
    assert_eq!(device["name"], "Test Phone");
    assert_eq!(device["providers"][0], "LAN");
    assert_eq!(device["battery"]["charge"], 77);

    helper.send(r#"{"cmd":"ring","device":"phone1"}"#);
    wait_for_call(&calls, "ring");

    helper.send(r#"{"cmd":"replyThread","device":"phone1","thread":7,"text":"ok"}"#);
    wait_for_call(&calls, "reply 7 ok");

    // Property changes followed by a signal publish a new state.
    let battery = service.object_server().interface::<_, Battery>(format!("{DEVICE}/battery")).unwrap();
    battery.get_mut().charge = 50;
    service
        .emit_signal(None::<&str>, format!("{DEVICE}/battery"), "org.kde.kdeconnect.device.battery", "refreshed", &(true, 50i32))
        .unwrap();
    helper.expect("updated battery", |l| is_type(l, "state") && l["devices"][0]["battery"]["charge"] == 50);

    helper.send("not json");
    helper.expect("error for invalid command", |l| is_type(l, "error"));
    helper.send(r#"{"cmd":"ring","device":"missing"}"#);
    helper.expect("error for unknown device", |l| is_type(l, "error"));
}

#[test]
fn streams_sms_conversations() {
    let bus = Bus::start();
    let calls = Calls::default();
    let service = bus.serve(&calls);
    let mut helper = Helper::start(&bus);
    helper.expect("initial state", |l| is_type(l, "state"));

    helper.send(r#"{"cmd":"requestConversations","device":"phone1"}"#);
    let contacts = helper.expect("contacts", |l| is_type(l, "contacts"));
    assert_eq!(contacts["device"], "phone1");
    let conversations = helper.expect("conversations", |l| is_type(l, "conversations"));
    assert_eq!(conversations["messages"][0]["body"], "see you at 7");
    assert_eq!(conversations["messages"][0]["thread"], 7);
    assert_eq!(conversations["messages"][0]["addresses"][0], "+15550100");
    wait_for_call(&calls, "requestAllConversationThreads");

    service
        .emit_signal(None::<&str>, DEVICE, "org.kde.kdeconnect.device.conversations", "conversationUpdated", &message())
        .unwrap();
    let update = helper.expect("message update", |l| is_type(l, "message"));
    assert_eq!(update["device"], "phone1");
    assert_eq!(update["message"]["uid"], 3);
    assert_eq!(update["message"]["sent"], false);

    service
        .emit_signal(None::<&str>, DEVICE, "org.kde.kdeconnect.device.conversations", "conversationLoaded", &(7i64, 1u64))
        .unwrap();
    let loaded = helper.expect("thread loaded", |l| is_type(l, "conversationLoaded"));
    assert_eq!(loaded["thread"], 7);
}

#[test]
fn follows_the_daemon_appearing_later() {
    let bus = Bus::start();
    let helper = Helper::start(&bus);
    let state = helper.expect("state without daemon", |l| is_type(l, "state"));
    assert_eq!(state["available"], false);

    let calls = Calls::default();
    let _service = bus.serve(&calls);
    helper.expect("state once the daemon appears", |l| is_type(l, "state") && l["available"] == true);
}
