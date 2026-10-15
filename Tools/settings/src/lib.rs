use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::error::Error;
use std::fs;
use std::io::Write;
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};
use toml_edit::{ArrayOfTables, DocumentMut, Item, Table};

type Result<T> = std::result::Result<T, Box<dyn Error>>;

#[derive(Deserialize)]
pub struct Request {
    #[serde(default)]
    pub ui_profiles: Option<UiProfiles>,
    pub settings: Value,
    pub baseline: Option<Value>,
}

#[derive(Serialize, Debug)]
pub struct Response {
    pub settings: Value,
    pub fresh: bool,
}

fn validate(value: &Value) -> Result<()> {
    match value {
        Value::Null => {
            return Err(
                "TOML cannot represent null settings; remove the key or use an explicit value"
                    .into(),
            );
        }
        Value::Array(values) => values.iter().try_for_each(validate)?,
        Value::Object(values) => values.values().try_for_each(validate)?,
        _ => {}
    }
    Ok(())
}

fn validate_request(request: &Request) -> Result<()> {
    if !request.settings.is_object() || request.baseline.as_ref().is_some_and(|v| !v.is_object()) {
        return Err("settings and baseline must be JSON objects".into());
    }
    validate(&request.settings)?;
    if let Some(baseline) = &request.baseline {
        validate(baseline)?;
    }
    Ok(())
}

fn config_path(path: &Path) -> Result<PathBuf> {
    if path.extension().is_some_and(|ext| ext == "json") {
        return Err("CONFIG must be a .toml file; change FROSTALIA_SETTINGS_FILE to a .toml path and pass the old JSON file as a load seed".into());
    }
    // Follow existing symlinks, including relative links, without replacing the link itself.
    if fs::symlink_metadata(path).is_ok() {
        return Ok(fs::canonicalize(path)?);
    }
    Ok(path.to_path_buf())
}

fn read_document(path: &Path) -> Result<DocumentMut> {
    let text = fs::read_to_string(path)?;
    text.parse()
        .map_err(|error| format!("invalid TOML in {}: {error}", path.display()).into())
}

fn document_value(document: &DocumentMut) -> Result<Value> {
    Ok(toml_edit::de::from_document(document.clone())?)
}

fn item(value: &Value) -> Result<Item> {
    match value {
        Value::Object(values) => {
            let mut table = Table::new();
            for (key, value) in values {
                table.insert(key, item(value)?);
            }
            Ok(Item::Table(table))
        }
        Value::Array(values) if !values.is_empty() && values.iter().all(Value::is_object) => {
            let mut tables = ArrayOfTables::new();
            for value in values {
                tables.push(item(value)?.into_table().map_err(|_| "expected table")?);
            }
            Ok(Item::ArrayOfTables(tables))
        }
        _ => {
            let mut wrapper = serde_json::Map::new();
            wrapper.insert("value".into(), value.clone());
            Ok(toml_edit::ser::to_document(&wrapper)?
                .as_table_mut()
                .remove("value")
                .unwrap())
        }
    }
}

fn document(value: &Value) -> Result<DocumentMut> {
    let mut document = DocumentMut::new();
    *document.as_table_mut() = item(value)?
        .into_table()
        .map_err(|_| "settings must be an object")?;
    Ok(document)
}

fn overlay(base: &mut Value, saved: &Value) {
    if let (Some(base), Some(saved)) = (base.as_object_mut(), saved.as_object()) {
        for (key, value) in saved {
            if let Some(existing) = base.get_mut(key) {
                overlay(existing, value);
            } else {
                base.insert(key.clone(), value.clone());
            }
        }
    } else {
        *base = saved.clone();
    }
}

fn apply_changes(
    table: &mut dyn toml_edit::TableLike,
    baseline: &Value,
    settings: &Value,
) -> Result<()> {
    let before = baseline.as_object().ok_or("baseline must be object")?;
    let after = settings.as_object().ok_or("settings must be object")?;
    for key in before.keys().filter(|key| !after.contains_key(*key)) {
        table.remove(key);
    }
    for (key, value) in after {
        if before.get(key) == Some(value) {
            continue;
        }
        if value.is_object() && before.get(key).is_some_and(Value::is_object) {
            if table.get(key).and_then(Item::as_table_like).is_none() {
                table.insert(key, Item::Table(Table::new()));
            }
            apply_changes(
                table.get_mut(key).unwrap().as_table_like_mut().unwrap(),
                &before[key],
                value,
            )?;
        } else {
            let mut replacement = item(value)?;
            if let (Some(old), Some(new)) = (
                table.get(key).and_then(Item::as_value),
                replacement.as_value_mut(),
            ) {
                *new.decor_mut() = old.decor().clone();
            }
            table.insert(key, replacement);
        }
    }
    Ok(())
}

fn write_document(path: &Path, document: &DocumentMut) -> Result<()> {
    let rendered = document.to_string();
    if fs::read_to_string(path).ok().as_deref() == Some(&rendered) {
        return Ok(());
    }
    let existing = fs::metadata(path).ok();
    if existing
        .as_ref()
        .is_some_and(|meta| meta.permissions().mode() & 0o222 == 0)
    {
        return Err(format!("{} is read-only", path.display()).into());
    }
    let parent = path
        .parent()
        .filter(|p| !p.as_os_str().is_empty())
        .unwrap_or(Path::new("."));
    fs::create_dir_all(parent)?;
    let mut temporary = tempfile::NamedTempFile::new_in(parent)?;
    let mode = existing.map_or(0o600, |meta| meta.permissions().mode());
    temporary
        .as_file()
        .set_permissions(fs::Permissions::from_mode(mode))?;
    temporary.write_all(rendered.as_bytes())?;
    temporary.as_file().sync_all()?;
    temporary.persist(path)?;
    fs::File::open(parent)?.sync_all()?;
    Ok(())
}

fn load_document(path: &Path, seeds: &[PathBuf], request: Request) -> Result<Response> {
    validate_request(&request)?;
    let path = config_path(path)?;
    let mut settings = request.settings;
    let mut fresh = false;
    let document = if path.exists() {
        read_document(&path)?
    } else {
        let mut seeded = None;
        for seed in seeds {
            if !seed.exists() {
                continue;
            }
            let value = if seed.extension().is_some_and(|ext| ext == "json") {
                serde_json::from_str::<Value>(&fs::read_to_string(seed)?)?
            } else {
                document_value(&read_document(seed)?)?
            };
            if !value.is_object() {
                return Err("seed settings must be an object".into());
            }
            validate(&value)?;
            seeded = Some(value);
            break;
        }
        fresh = seeded.is_none();
        if let Some(seed) = seeded {
            overlay(&mut settings, &seed);
        }
        let document = document(&settings)?;
        write_document(&path, &document)?;
        document
    };
    overlay(&mut settings, &document_value(&document)?);
    Ok(Response { settings, fresh })
}

fn save_document(path: &Path, request: Request) -> Result<Response> {
    validate_request(&request)?;
    let path = config_path(path)?;
    let mut document = if path.exists() {
        read_document(&path)?
    } else {
        DocumentMut::new()
    };
    let empty = serde_json::json!({});
    apply_changes(
        document.as_table_mut(),
        request.baseline.as_ref().unwrap_or(&empty),
        &request.settings,
    )?;
    write_document(&path, &document)?;
    let mut settings = request.settings;
    overlay(&mut settings, &document_value(&document)?);
    Ok(Response {
        settings,
        fresh: false,
    })
}

mod ui_profiles;
pub use ui_profiles::{UiProfiles, load, save};
