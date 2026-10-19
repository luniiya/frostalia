use frostalia_kdeconnect::bus::{self, Bus, Dirs};
use frostalia_kdeconnect::commands::Command;
use frostalia_kdeconnect::model::{Output, State};
use frostalia_kdeconnect::{SignalKind, classify, contacts, sms};
use std::io::{self, BufRead, Write};
use std::sync::mpsc;
use std::time::{Duration, Instant};
use zbus::blocking::{Connection, MessageIterator};
use zbus::zvariant::OwnedValue;
use zbus::{MatchRule, message};

/// Signals often arrive in bursts (one per property); coalesce them.
const DEBOUNCE: Duration = Duration::from_millis(150);
/// Safety net for state that changes without a signal (sftp mounts, timeouts).
const POLL: Duration = Duration::from_secs(30);

enum Event {
    Signal(zbus::Message),
    Command(Command),
    InvalidCommand(String),
    StdinClosed,
}

fn emit(output: &Output) {
    let mut out = io::stdout().lock();
    if serde_json::to_writer(&mut out, output).is_ok() {
        let _ = out.write_all(b"\n");
        let _ = out.flush();
    }
}

fn error(message: impl Into<String>) {
    emit(&Output::Error { message: message.into() });
}

fn spawn_signals(conn: &Connection, tx: mpsc::Sender<Event>) -> zbus::Result<()> {
    let rules = [
        MatchRule::builder().msg_type(message::Type::Signal).path_namespace(bus::ROOT)?.build(),
        MatchRule::builder()
            .msg_type(message::Type::Signal)
            .sender("org.freedesktop.DBus")?
            .member("NameOwnerChanged")?
            .arg(0, bus::SERVICE)?
            .build(),
    ];
    for rule in rules {
        let iter = MessageIterator::for_match_rule(rule, conn, Some(512))?;
        let tx = tx.clone();
        std::thread::spawn(move || {
            for message in iter.flatten() {
                if tx.send(Event::Signal(message)).is_err() {
                    break;
                }
            }
        });
    }
    Ok(())
}

fn spawn_stdin(tx: mpsc::Sender<Event>) {
    std::thread::spawn(move || {
        for line in io::stdin().lock().lines() {
            let Ok(line) = line else { break };
            if line.trim().is_empty() {
                continue;
            }
            let event = match Command::parse(&line) {
                Ok(command) => Event::Command(command),
                Err(e) => Event::InvalidCommand(e),
            };
            if tx.send(event).is_err() {
                return;
            }
        }
        let _ = tx.send(Event::StdinClosed);
    });
}

/// Emits events carried by a signal; returns true when the state should be re-read.
fn handle_signal(message: &zbus::Message, dirs: &Dirs) -> bool {
    let header = message.header();
    let (Some(iface), Some(member), Some(path)) = (header.interface(), header.member(), header.path()) else {
        return false;
    };
    if iface.as_str() == "org.freedesktop.DBus" {
        return true;
    }
    let device = bus::device_of(path.as_str()).unwrap_or_default().to_owned();
    let body = message.body();
    match classify(iface.as_str(), member.as_str()) {
        SignalKind::Message => {
            if let Some(m) = body.deserialize::<OwnedValue>().ok().and_then(|v| sms::decode(&v)) {
                emit(&Output::Message { device, message: m });
            }
            false
        }
        SignalKind::ConversationRemoved => {
            if let Ok(thread) = body.deserialize::<i64>() {
                emit(&Output::ConversationRemoved { device, thread });
            }
            false
        }
        SignalKind::ConversationLoaded => {
            if let Ok((thread, count)) = body.deserialize::<(i64, u64)>() {
                emit(&Output::ConversationLoaded { device, thread, count });
            }
            false
        }
        SignalKind::Call => {
            if let Ok((event, number, name)) = body.deserialize::<(String, String, String)>() {
                emit(&Output::Call { device, event, number, name });
            }
            false
        }
        SignalKind::ShareReceived => {
            if let Ok(url) = body.deserialize::<String>() {
                emit(&Output::ShareReceived { device, url });
            }
            false
        }
        SignalKind::PairingFailed => {
            if let Ok(error) = body.deserialize::<String>() {
                emit(&Output::PairingFailed { device, error });
            }
            true
        }
        SignalKind::ContactsSynced => {
            emit(&Output::Contacts { contacts: contacts::load(&dirs.data_home, &device), device });
            false
        }
        SignalKind::Refresh => true,
        SignalKind::Ignore => false,
    }
}

fn main() {
    let conn = match Connection::session() {
        Ok(conn) => conn,
        Err(e) => {
            eprintln!("frostalia-kdeconnect: cannot connect to the session bus: {e}");
            std::process::exit(1);
        }
    };
    let dirs = Dirs::from_env();
    let bus = Bus { conn: &conn, dirs: &dirs };
    let (tx, rx) = mpsc::channel();
    if let Err(e) = spawn_signals(&conn, tx.clone()) {
        eprintln!("frostalia-kdeconnect: cannot watch signals: {e}");
        std::process::exit(1);
    }
    spawn_stdin(tx);

    let mut last = State::default();
    let mut publish = |force: bool| {
        let state = bus.state();
        if force || state != last {
            emit(&Output::State(state.clone()));
            last = state;
        }
    };
    publish(true);

    let mut due: Option<Instant> = None;
    let mut next_poll = Instant::now() + POLL;
    loop {
        let deadline = due.map_or(next_poll, |d| d.min(next_poll));
        match rx.recv_timeout(deadline.saturating_duration_since(Instant::now())) {
            Ok(Event::Signal(message)) => {
                if handle_signal(&message, &dirs) && due.is_none() {
                    due = Some(Instant::now() + DEBOUNCE);
                }
            }
            Ok(Event::Command(command)) => {
                match bus.run(&command) {
                    Ok(outputs) => outputs.iter().for_each(emit),
                    Err(e) => error(format!("{command:?}: {e}")),
                }
                due.get_or_insert(Instant::now() + DEBOUNCE);
            }
            Ok(Event::InvalidCommand(e)) => error(e),
            Ok(Event::StdinClosed) | Err(mpsc::RecvTimeoutError::Disconnected) => break,
            Err(mpsc::RecvTimeoutError::Timeout) => {
                let now = Instant::now();
                if due.is_some_and(|d| d <= now) || next_poll <= now {
                    due = None;
                    next_poll = now + POLL;
                    publish(false);
                }
            }
        }
    }
}
