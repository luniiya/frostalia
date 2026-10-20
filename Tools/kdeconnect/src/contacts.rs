//! Contacts synced by KDE Connect's contacts plugin, stored as vCards in
//! `$XDG_DATA_HOME/kpeoplevcard/kdeconnect-<device>/`.

use serde::Serialize;
use std::path::{Path, PathBuf};

#[derive(Serialize, Debug, Default, Clone, PartialEq)]
#[serde(rename_all = "camelCase")]
pub struct Contact {
    pub name: String,
    pub numbers: Vec<String>,
    /// `data:` URL, empty when the contact has no photo.
    pub photo: String,
}

pub fn directory(data_home: &Path, device: &str) -> PathBuf {
    data_home.join("kpeoplevcard").join(format!("kdeconnect-{device}"))
}

/// Joins folded lines (continuations start with a space or tab).
fn unfold(text: &str) -> Vec<String> {
    let mut lines: Vec<String> = Vec::new();
    for raw in text.lines() {
        let line = raw.trim_end_matches('\r');
        if let Some(rest) = line.strip_prefix([' ', '\t']) {
            if let Some(last) = lines.last_mut() {
                last.push_str(rest);
                continue;
            }
        }
        lines.push(line.to_owned());
    }
    lines
}

fn unescape(value: &str) -> String {
    value.replace("\\,", ",").replace("\\;", ";").replace("\\n", " ").replace("\\\\", "\\")
}

fn photo_mime(params: &str) -> &'static str {
    let upper = params.to_ascii_uppercase();
    if upper.contains("PNG") {
        "image/png"
    } else if upper.contains("GIF") {
        "image/gif"
    } else {
        "image/jpeg"
    }
}

/// Parses every vCard in `text`. Cards without a name or number are skipped.
pub fn parse(text: &str) -> Vec<Contact> {
    let mut contacts = Vec::new();
    let mut current: Option<Contact> = None;
    let mut structured_name = String::new();
    for line in unfold(text) {
        let Some((key, value)) = line.split_once(':') else {
            continue;
        };
        let (name, params) = key.split_once(';').unwrap_or((key, ""));
        match name.to_ascii_uppercase().as_str() {
            "BEGIN" if value.eq_ignore_ascii_case("VCARD") => {
                current = Some(Contact::default());
                structured_name.clear();
            }
            "END" if value.eq_ignore_ascii_case("VCARD") => {
                if let Some(mut contact) = current.take() {
                    if contact.name.is_empty() {
                        contact.name = structured_name.clone();
                    }
                    if contact.name.is_empty() {
                        contact.name = contact.numbers.first().cloned().unwrap_or_default();
                    }
                    if !contact.numbers.is_empty() {
                        contacts.push(contact);
                    }
                }
            }
            _ if current.is_none() => {}
            "FN" => current.as_mut().unwrap().name = unescape(value).trim().to_owned(),
            "N" => {
                // Family;Given;Additional;Prefix;Suffix
                let parts: Vec<&str> = value.split(';').collect();
                let given = parts.get(1).copied().unwrap_or("");
                let family = parts.first().copied().unwrap_or("");
                structured_name = unescape(&format!("{given} {family}")).trim().to_owned();
            }
            "TEL" => {
                let number = value.trim().trim_start_matches("tel:").to_owned();
                if !number.is_empty() {
                    current.as_mut().unwrap().numbers.push(number);
                }
            }
            "PHOTO" => {
                let data = value.trim();
                current.as_mut().unwrap().photo = if let Some(rest) = data.strip_prefix("data:") {
                    format!("data:{rest}")
                } else if data.is_empty() || data.contains("://") {
                    String::new()
                } else {
                    format!("data:{};base64,{data}", photo_mime(params))
                };
            }
            _ => {}
        }
    }
    contacts
}

/// All contacts cached for `device`, sorted by name.
pub fn load(data_home: &Path, device: &str) -> Vec<Contact> {
    let Ok(entries) = std::fs::read_dir(directory(data_home, device)) else {
        return Vec::new();
    };
    let mut contacts: Vec<Contact> = entries
        .filter_map(|e| e.ok())
        .filter(|e| e.path().extension().is_some_and(|x| x.eq_ignore_ascii_case("vcf")))
        .filter_map(|e| std::fs::read_to_string(e.path()).ok())
        .flat_map(|text| parse(&text))
        .collect();
    contacts.sort_by_key(|c| c.name.to_lowercase());
    contacts
}
