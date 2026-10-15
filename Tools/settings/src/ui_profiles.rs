use super::*;
use std::collections::BTreeMap;

#[derive(Deserialize)]
pub struct UiProfiles {
    pub directory: PathBuf,
    pub default_style: String,
    pub defaults: BTreeMap<String, Value>,
}

impl UiProfiles {
    fn validate(&self) -> Result<()> {
        let schema = self
            .defaults
            .get(&self.default_style)
            .ok_or("missing default UI style")?;
        for (name, defaults) in &self.defaults {
            if name.is_empty()
                || name.starts_with('.')
                || !name
                    .chars()
                    .all(|c| c.is_ascii_alphanumeric() || c == '-' || c == '_')
            {
                return Err("unsafe UI style name".into());
            }
            validate(defaults)?;
            let fields = defaults.as_object().ok_or("UI defaults must be objects")?;
            for (section, values) in fields {
                let keys = values.as_object().ok_or("UI sections must be objects")?;
                if section != "general" && section != "ui" || keys.contains_key("style") {
                    return Err("UI profiles may only contain appearance settings".into());
                }
            }
        }
        for defaults in self.defaults.values() {
            // Every style owns the same fields, with its own values.
            if project(defaults, schema) != *defaults || project(schema, defaults) != *schema {
                return Err("UI styles must declare the same appearance fields".into());
            }
        }
        Ok(())
    }

    fn style<'a>(&'a self, settings: &'a Value) -> &'a str {
        settings["ui"]["style"]
            .as_str()
            .filter(|style| self.defaults.contains_key(*style))
            .unwrap_or(&self.default_style)
    }

    fn path(&self, style: &str) -> Result<PathBuf> {
        config_path(&self.directory.join(format!("{style}.toml")))
    }

    fn profile(&self, style: &str, seed: &Value) -> Result<Value> {
        let defaults = &self.defaults[style];
        let path = self.path(style)?;
        let mut settings = defaults.clone();
        if path.exists() {
            overlay(
                &mut settings,
                &project(&document_value(&read_document(&path)?)?, defaults),
            );
        } else {
            overlay(&mut settings, &project(seed, defaults));
            write_document(&path, &document(&settings)?)?;
        }
        Ok(settings)
    }

    fn host(&self, settings: &Value) -> Value {
        let mut host = settings.clone();
        for (section, fields) in self.defaults[&self.default_style].as_object().unwrap() {
            if let Some(values) = host[section].as_object_mut() {
                for key in fields.as_object().unwrap().keys() {
                    values.remove(key);
                }
            }
        }
        host
    }

    fn prune_host(&self, path: &Path) -> Result<()> {
        let mut doc = read_document(path)?;
        for (section, fields) in self.defaults[&self.default_style].as_object().unwrap() {
            if let Some(table) = doc.get_mut(section).and_then(Item::as_table_like_mut) {
                for key in fields.as_object().unwrap().keys() {
                    table.remove(key);
                }
            }
        }
        write_document(path, &doc)
    }
}

fn project(settings: &Value, schema: &Value) -> Value {
    let mut result = serde_json::Map::new();
    for (section, fields) in schema.as_object().unwrap() {
        let mut values = serde_json::Map::new();
        for key in fields.as_object().unwrap().keys() {
            if let Some(value) = settings.get(section).and_then(|s| s.get(key)) {
                values.insert(key.clone(), value.clone());
            }
        }
        result.insert(section.clone(), Value::Object(values));
    }
    Value::Object(result)
}

pub fn load(path: &Path, seeds: &[PathBuf], mut request: Request) -> Result<Response> {
    let Some(profiles) = request.ui_profiles.take() else {
        return load_document(path, seeds, request);
    };
    validate_request(&request)?;
    profiles.validate()?;
    request.settings = profiles.host(&request.settings);
    let mut response = load_document(path, seeds, request)?;
    let profile = profiles.profile(profiles.style(&response.settings), &response.settings)?;
    // Never remove legacy values until the style file has been safely written.
    profiles.prune_host(&config_path(path)?)?;
    response.settings = profiles.host(&response.settings);
    overlay(&mut response.settings, &profile);
    Ok(response)
}

pub fn save(path: &Path, mut request: Request) -> Result<Response> {
    let Some(profiles) = request.ui_profiles.take() else {
        return save_document(path, request);
    };
    validate_request(&request)?;
    profiles.validate()?;
    let baseline = request
        .baseline
        .as_ref()
        .ok_or("UI profile saves require a baseline")?;
    let previous_style = profiles.style(baseline).to_owned();
    let next_style = profiles.style(&request.settings).to_owned();
    // Validate the destination before committing a style switch to the host.
    let next_profile = profiles.profile(&next_style, &serde_json::json!({}))?;
    let previous_path = profiles.path(&previous_style)?;
    profiles.profile(&previous_style, baseline)?;
    let profile = save_document(
        &previous_path,
        Request {
            settings: project(&request.settings, &profiles.defaults[&previous_style]),
            baseline: Some(project(baseline, &profiles.defaults[&previous_style])),
            ui_profiles: None,
        },
    )?;
    request.settings = profiles.host(&request.settings);
    request.baseline = Some(profiles.host(baseline));
    let mut response = save_document(path, request)?;
    profiles.prune_host(&config_path(path)?)?;
    // A manual host edit may have selected another style while this save was
    // queued. Only the fields owned by the resulting style enter the live model.
    let selected = profiles.style(&response.settings);
    let appearance = if selected == previous_style {
        project(&profile.settings, &profiles.defaults[&previous_style])
    } else if selected == next_style {
        next_profile
    } else {
        profiles.profile(selected, &serde_json::json!({}))?
    };
    response.settings = profiles.host(&response.settings);
    overlay(&mut response.settings, &appearance);
    Ok(response)
}
