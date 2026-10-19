//! Bridge between kdeconnectd (session D-Bus) and the Frostalia shell.
//!
//! `frostalia-kdeconnect` prints JSON lines on stdout (see [`model::Output`]) and
//! reads commands from stdin (see [`commands::Command`]).

pub mod bus;
pub mod commands;
pub mod contacts;
pub mod model;
pub mod runcommand;
pub mod sms;

/// What a D-Bus signal from kdeconnectd means for the shell.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SignalKind {
    /// A conversation message was created or updated (`v`).
    Message,
    /// A whole thread was removed (`x`).
    ConversationRemoved,
    /// A requested thread finished loading (`xt`).
    ConversationLoaded,
    /// Incoming call (`sss`: event, number, contact name).
    Call,
    /// A file shared by the phone was received (`s`).
    ShareReceived,
    /// Pairing failed (`s`).
    PairingFailed,
    /// Synced contacts changed on disk.
    ContactsSynced,
    /// Anything else that may change the device state.
    Refresh,
    /// Noise that never changes the state (e.g. remote key presses).
    Ignore,
}

pub fn classify(interface: &str, member: &str) -> SignalKind {
    match (interface, member) {
        ("org.kde.kdeconnect.device.conversations", "conversationCreated" | "conversationUpdated") => SignalKind::Message,
        ("org.kde.kdeconnect.device.conversations", "conversationRemoved") => SignalKind::ConversationRemoved,
        ("org.kde.kdeconnect.device.conversations", "conversationLoaded") => SignalKind::ConversationLoaded,
        ("org.kde.kdeconnect.device.conversations", _) => SignalKind::Ignore,
        ("org.kde.kdeconnect.device.telephony", "callReceived") => SignalKind::Call,
        ("org.kde.kdeconnect.device.share", "shareReceived") => SignalKind::ShareReceived,
        ("org.kde.kdeconnect.device", "pairingFailed") => SignalKind::PairingFailed,
        ("org.kde.kdeconnect.device.contacts", "localCacheSynchronized") => SignalKind::ContactsSynced,
        ("org.kde.kdeconnect.device.remotekeyboard", "keyPressReceived") => SignalKind::Ignore,
        _ => SignalKind::Refresh,
    }
}
