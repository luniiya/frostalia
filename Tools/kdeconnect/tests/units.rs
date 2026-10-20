use frostalia_kdeconnect::bus::device_of;
use frostalia_kdeconnect::commands::Command;
use frostalia_kdeconnect::runcommand::{self, RunCommand};
use frostalia_kdeconnect::{SignalKind, classify, contacts, sms};
use zbus::zvariant::Value;

fn message_value(body: &str, addresses: &[&str], date: i64, kind: i32, thread: i64, uid: i32) -> Value<'static> {
    let addresses: Vec<(String,)> = addresses.iter().map(|a| (a.to_string(),)).collect();
    let attachments: Vec<(i64, String, String, String)> = vec![(7, "image/png".into(), "QUJD".into(), "att-1".into())];
    Value::from((1i32, body.to_string(), addresses, date, kind, 1i32, thread, uid, 0i64, attachments))
}

#[test]
fn decodes_conversation_message() {
    let value = message_value("hello", &["+33 6 12 34 56 78", "+1555"], 1_700_000_000_000, sms::SENT, 42, 9);
    let m = sms::decode(&value).expect("decoded");
    assert_eq!(m.body, "hello");
    assert_eq!(m.addresses, vec!["+33 6 12 34 56 78", "+1555"]);
    assert_eq!(m.date, 1_700_000_000_000);
    assert!(m.sent);
    assert!(m.read);
    assert_eq!(m.thread, 42);
    assert_eq!(m.uid, 9);
    assert_eq!(m.attachments.len(), 1);
    assert_eq!(m.attachments[0].thumbnail, "data:image/png;base64,QUJD");
    assert_eq!(m.attachments[0].id, "att-1");
}

#[test]
fn decodes_message_wrapped_in_variant() {
    // Elements of `av` arrive wrapped in a variant.
    let value = Value::Value(Box::new(message_value("hi", &["1"], 1, sms::RECEIVED, 1, 1)));
    let m = sms::decode(&value).expect("decoded");
    assert!(!m.sent);
}

#[test]
fn rejects_values_that_are_not_messages() {
    assert_eq!(sms::decode(&Value::from(3i32)), None);
    assert_eq!(sms::decode(&Value::from((1i32, "short".to_string()))), None);
}

#[test]
fn keeps_newest_message_per_thread() {
    let decode = |body: &str, date: i64, thread: i64, uid: i32| {
        sms::decode(&message_value(body, &["1"], date, sms::RECEIVED, thread, uid)).unwrap()
    };
    let latest = sms::latest_per_thread(vec![decode("old", 1, 1, 1), decode("other", 5, 2, 2), decode("new", 9, 1, 3)]);
    let bodies: Vec<&str> = latest.iter().map(|m| m.body.as_str()).collect();
    assert_eq!(bodies, vec!["new", "other"]);
}

#[test]
fn parses_vcards() {
    let text = "BEGIN:VCARD\r\nVERSION:2.1\r\nFN:Alex\\, Jr.\r\nTEL;CELL:+33 6 12 34 56 78\r\nTEL:tel:0612\r\nPHOTO;ENCODING=b;TYPE=PNG:QUJD\r\n REVG\r\nEND:VCARD\r\n\
BEGIN:VCARD\nN:Doe;Jane;;;\nTEL:555\nEND:VCARD\nBEGIN:VCARD\nFN:No number\nEND:VCARD\n";
    let parsed = contacts::parse(text);
    assert_eq!(parsed.len(), 2, "cards without numbers are skipped");
    assert_eq!(parsed[0].name, "Alex, Jr.");
    assert_eq!(parsed[0].numbers, vec!["+33 6 12 34 56 78", "0612"]);
    assert_eq!(parsed[0].photo, "data:image/png;base64,QUJDREVG", "folded lines are joined");
    assert_eq!(parsed[1].name, "Jane Doe");
    assert_eq!(parsed[1].photo, "");
}

#[test]
fn loads_contacts_from_device_directory() {
    let home = tempfile::tempdir().unwrap();
    let dir = contacts::directory(home.path(), "dev1");
    std::fs::create_dir_all(&dir).unwrap();
    std::fs::write(dir.join("b.vcf"), "BEGIN:VCARD\nFN:bob\nTEL:2\nEND:VCARD\n").unwrap();
    std::fs::write(dir.join("a.vcf"), "BEGIN:VCARD\nFN:Alice\nTEL:1\nEND:VCARD\n").unwrap();
    std::fs::write(dir.join("ignored.txt"), "BEGIN:VCARD\nFN:X\nTEL:3\nEND:VCARD\n").unwrap();
    let names: Vec<String> = contacts::load(home.path(), "dev1").into_iter().map(|c| c.name).collect();
    assert_eq!(names, vec!["Alice", "bob"]);
    assert!(contacts::load(home.path(), "missing").is_empty());
}

const RUNCOMMAND_CONFIG: &str = r#"[General]
commands="@ByteArray({\"b1\":{\"command\":\"hyprlock\",\"name\":\"lock\"},\"a2\":{\"command\":\"echo \\\"hi\\\"\\n\",\"name\":\"Echo\"}})"
other=kept
[Other]
x=1
"#;

#[test]
fn parses_run_commands() {
    let commands = runcommand::parse(RUNCOMMAND_CONFIG);
    assert_eq!(
        commands,
        vec![
            RunCommand { id: "a2".into(), name: "Echo".into(), command: "echo \"hi\"\n".into() },
            RunCommand { id: "b1".into(), name: "lock".into(), command: "hyprlock".into() },
        ]
    );
    assert!(runcommand::parse("").is_empty());
    assert!(runcommand::parse("[General]\ncommands=\"@ByteArray(not json)\"\n").is_empty());
}

#[test]
fn run_commands_round_trip_and_keep_other_keys() {
    let commands = runcommand::parse(RUNCOMMAND_CONFIG);
    let rendered = runcommand::render(RUNCOMMAND_CONFIG, &commands[..1]);
    assert!(rendered.contains("other=kept"));
    assert!(rendered.contains("[Other]\nx=1"));
    assert_eq!(runcommand::parse(&rendered), commands[..1].to_vec());
    let fresh = runcommand::render("", &commands);
    assert!(fresh.starts_with("[General]\ncommands="));
    assert_eq!(runcommand::parse(&fresh), commands);
}

#[test]
fn saves_run_commands_to_device_config() {
    let home = tempfile::tempdir().unwrap();
    let list = vec![RunCommand { id: "x".into(), name: "Suspend".into(), command: "systemctl suspend".into() }];
    runcommand::save(home.path(), "dev1", &list).unwrap();
    assert_eq!(runcommand::load(home.path(), "dev1"), list);
}

#[test]
fn normalizes_new_run_commands() {
    let input = vec![
        RunCommand { id: String::new(), name: " Lock ".into(), command: "hyprlock".into() },
        RunCommand { id: "keep".into(), name: "Keep".into(), command: "true".into() },
        RunCommand { id: String::new(), name: "".into(), command: "dropped".into() },
        RunCommand { id: String::new(), name: "Dropped".into(), command: "  ".into() },
    ];
    let out = runcommand::normalize(&input, || 0x0123456789abcdef0123456789abcdef);
    assert_eq!(out.len(), 2);
    assert_eq!(out[0].id, "01234567_89ab_cdef_0123_456789abcdef");
    assert_eq!(out[0].name, "Lock");
    assert_eq!(out[1].id, "keep");
}

#[test]
fn parses_commands() {
    assert_eq!(
        Command::parse(r#"{"cmd":"ring","device":"d"}"#).unwrap(),
        Command::Ring { device: "d".into() }
    );
    assert_eq!(
        Command::parse(r#"{"cmd":"requestThread","device":"d","thread":5}"#).unwrap(),
        Command::RequestThread { device: "d".into(), thread: 5, start: 0, count: 50 }
    );
    assert_eq!(
        Command::parse(r#"{"cmd":"keyPress","device":"d","special":12,"ctrl":true}"#).unwrap(),
        Command::KeyPress { device: "d".into(), key: String::new(), special: 12, shift: false, ctrl: true, alt: false }
    );
    assert_eq!(
        Command::parse(r#"{"cmd":"setPluginEnabled","device":"d","plugin":"kdeconnect_ping","enabled":false}"#).unwrap(),
        Command::SetPluginEnabled { device: "d".into(), plugin: "kdeconnect_ping".into(), enabled: false }
    );
    assert!(Command::parse(r#"{"cmd":"explode"}"#).is_err());
    assert!(Command::parse("not json").is_err());
}

#[test]
fn maps_click_buttons() {
    assert_eq!(Command::click_key("single"), Some("singleclick"));
    assert_eq!(Command::click_key("right"), Some("rightclick"));
    assert_eq!(Command::click_key("release"), Some("singlerelease"));
    assert_eq!(Command::click_key("nope"), None);
}

#[test]
fn classifies_signals() {
    assert_eq!(classify("org.kde.kdeconnect.device.conversations", "conversationUpdated"), SignalKind::Message);
    assert_eq!(classify("org.kde.kdeconnect.device.conversations", "conversationLoaded"), SignalKind::ConversationLoaded);
    assert_eq!(classify("org.kde.kdeconnect.device.conversations", "attachmentReceived"), SignalKind::Ignore);
    assert_eq!(classify("org.kde.kdeconnect.device.telephony", "callReceived"), SignalKind::Call);
    assert_eq!(classify("org.kde.kdeconnect.device", "pairingFailed"), SignalKind::PairingFailed);
    assert_eq!(classify("org.kde.kdeconnect.device.battery", "refreshed"), SignalKind::Refresh);
    assert_eq!(classify("org.freedesktop.DBus.Properties", "PropertiesChanged"), SignalKind::Refresh);
    assert_eq!(classify("org.kde.kdeconnect.device.remotekeyboard", "keyPressReceived"), SignalKind::Ignore);
}

#[test]
fn finds_device_in_object_path() {
    assert_eq!(device_of("/modules/kdeconnect/devices/abc/battery"), Some("abc"));
    assert_eq!(device_of("/modules/kdeconnect/devices/abc"), Some("abc"));
    assert_eq!(device_of("/modules/kdeconnect"), None);
    assert_eq!(device_of("/other/devices/abc"), None);
}
