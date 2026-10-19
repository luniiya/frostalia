//! KDE Connect's ConversationMessage, D-Bus signature `(isa(s)xiixixa(xsss))`.

use serde::Serialize;
use zbus::zvariant::Value;

/// `type` values from Android's Telephony.Sms.
pub const RECEIVED: i32 = 1;
pub const SENT: i32 = 2;

#[derive(Serialize, Debug, Default, Clone, PartialEq)]
#[serde(rename_all = "camelCase")]
pub struct Message {
    pub body: String,
    pub addresses: Vec<String>,
    /// Milliseconds since the epoch.
    pub date: i64,
    pub sent: bool,
    pub read: bool,
    pub thread: i64,
    pub uid: i32,
    pub attachments: Vec<Attachment>,
}

#[derive(Serialize, Debug, Default, Clone, PartialEq)]
#[serde(rename_all = "camelCase")]
pub struct Attachment {
    pub part: i64,
    pub mime: String,
    /// `data:` URL of the thumbnail, empty when the phone sent none.
    pub thumbnail: String,
    pub id: String,
}

/// Unwraps variants (`v` inside `av`) down to the contained value.
pub fn inner<'a>(value: &'a Value<'a>) -> &'a Value<'a> {
    match value {
        Value::Value(boxed) => inner(boxed),
        other => other,
    }
}

fn int(value: &Value) -> Option<i64> {
    match inner(value) {
        Value::I32(n) => Some(i64::from(*n)),
        Value::I64(n) => Some(*n),
        Value::U32(n) => Some(i64::from(*n)),
        Value::U64(n) => i64::try_from(*n).ok(),
        Value::I16(n) => Some(i64::from(*n)),
        Value::U8(n) => Some(i64::from(*n)),
        _ => None,
    }
}

fn text(value: &Value) -> Option<String> {
    match inner(value) {
        Value::Str(s) => Some(s.as_str().to_owned()),
        _ => None,
    }
}

fn fields<'a>(value: &'a Value<'a>) -> Option<&'a [Value<'a>]> {
    match inner(value) {
        Value::Structure(s) => Some(s.fields()),
        _ => None,
    }
}

fn items<'a>(value: &'a Value<'a>) -> &'a [Value<'a>] {
    match inner(value) {
        Value::Array(a) => a.inner(),
        _ => &[],
    }
}

fn data_url(mime: &str, base64: &str) -> String {
    if base64.is_empty() {
        return String::new();
    }
    let mime = if mime.starts_with("image/") { mime } else { "image/jpeg" };
    format!("data:{mime};base64,{base64}")
}

fn attachment(value: &Value) -> Option<Attachment> {
    let f = fields(value)?;
    if f.len() < 4 {
        return None;
    }
    let mime = text(&f[1])?;
    Some(Attachment {
        part: int(&f[0])?,
        thumbnail: data_url(&mime, &text(&f[2])?),
        mime,
        id: text(&f[3])?,
    })
}

/// Decodes one message; None for anything that isn't a ConversationMessage.
pub fn decode(value: &Value) -> Option<Message> {
    let f = fields(value)?;
    if f.len() < 9 {
        return None;
    }
    let addresses = items(&f[2])
        .iter()
        .filter_map(|a| match fields(a) {
            Some(parts) => parts.first().and_then(text),
            None => text(a),
        })
        .filter(|a| !a.is_empty())
        .collect();
    Some(Message {
        body: text(&f[1])?,
        addresses,
        date: int(&f[3])?,
        sent: int(&f[4])? == i64::from(SENT),
        read: int(&f[5])? != 0,
        thread: int(&f[6])?,
        uid: i32::try_from(int(&f[7])?).ok()?,
        attachments: f.get(9).map(|a| items(a).iter().filter_map(attachment).collect()).unwrap_or_default(),
    })
}

/// Newest message first, one per thread.
pub fn latest_per_thread(mut messages: Vec<Message>) -> Vec<Message> {
    messages.sort_by(|a, b| b.date.cmp(&a.date).then(b.uid.cmp(&a.uid)));
    let mut seen = std::collections::HashSet::new();
    messages.retain(|m| seen.insert(m.thread));
    messages
}
