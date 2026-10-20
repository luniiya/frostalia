use frostalia_settings::{Request, UiProfiles, load, save};
use serde_json::{Value, json};
use std::{collections::BTreeMap, fs, path::Path};
use tempfile::tempdir;

fn request(directory: &Path, settings: Value, baseline: Option<Value>) -> Request {
    Request {
        settings,
        baseline,
        ui_profiles: Some(UiProfiles {
            directory: directory.join("UI"),
            default_style: "caelestia".into(),
            defaults: BTreeMap::from([
                (
                    "caelestia".into(),
                    json!({"general":{"radiusRatio":1.0},"ui":{"fontDefault":"", "panelBackgroundOpacity":0.93}}),
                ),
                (
                    "material".into(),
                    json!({"general":{"radiusRatio":1.0},"ui":{"fontDefault":"", "panelBackgroundOpacity":1.0}}),
                ),
                (
                    "square".into(),
                    json!({"general":{"radiusRatio":0.0},"ui":{"fontDefault":"Retro", "panelBackgroundOpacity":1.0}}),
                ),
            ]),
        }),
    }
}

fn defaults() -> Value {
    json!({"settingsVersion":65,"general":{"scaleRatio":1.1,"radiusRatio":1.0},"ui":{"style":"caelestia","fontDefault":"","fontDefaultScale":1.2,"panelBackgroundOpacity":0.93}})
}

fn read(path: &Path) -> Value {
    toml_edit::de::from_str(&fs::read_to_string(path).unwrap()).unwrap()
}

#[test]
fn migrates_only_active_style_and_preserves_host_accessibility_and_comments() {
    let dir = tempdir().unwrap();
    let host = dir.path().join("moon.toml");
    fs::write(&host, "# host\n[general]\nscaleRatio=1.15 # readability\nradiusRatio=0.4\n[ui]\nstyle='material'\nfontDefault='Personal Font'\nfontDefaultScale=1.2\nunknown='keep'\n").unwrap();
    let result = load(&host, &[], request(dir.path(), defaults(), None)).unwrap();
    assert_eq!(result.settings["general"]["radiusRatio"], 0.4);
    assert_eq!(result.settings["ui"]["panelBackgroundOpacity"], 1.0);
    let profile = read(&dir.path().join("UI/material.toml"));
    assert_eq!(profile["ui"]["fontDefault"], "Personal Font");
    assert_eq!(profile["general"]["radiusRatio"], 0.4);
    assert!(!dir.path().join("UI/caelestia.toml").exists());
    let stored = read(&host);
    assert!(stored["general"].get("radiusRatio").is_none());
    assert!(stored["ui"].get("fontDefault").is_none());
    assert_eq!(stored["general"]["scaleRatio"], 1.15);
    assert_eq!(stored["ui"]["fontDefaultScale"], 1.2);
    assert_eq!(stored["ui"]["unknown"], "keep");
    assert!(fs::read_to_string(&host).unwrap().contains("# readability"));
    // A restart must not reimport stale host values into the profile.
    assert_eq!(
        load(&host, &[], request(dir.path(), defaults(), None))
            .unwrap()
            .settings,
        result.settings
    );
}

#[test]
fn switching_saves_pending_edits_to_previous_style_and_restores_each_profile() {
    let dir = tempdir().unwrap();
    let host = dir.path().join("moon.toml");
    let original = load(&host, &[], request(dir.path(), defaults(), None))
        .unwrap()
        .settings;
    let mut changed = original.clone();
    changed["general"]["radiusRatio"] = json!(0.35);
    changed["ui"]["fontDefault"] = json!("My Font");
    changed["ui"]["style"] = json!("square");
    let square = save(&host, request(dir.path(), changed, Some(original)))
        .unwrap()
        .settings;
    assert_eq!(square["general"]["radiusRatio"], 0.0);
    assert_eq!(square["ui"]["fontDefault"], "Retro");
    assert_eq!(square["general"]["scaleRatio"], 1.1);
    let mut changed = square.clone();
    changed["general"]["radiusRatio"] = json!(0.1);
    changed["ui"]["style"] = json!("caelestia");
    let restored = save(&host, request(dir.path(), changed, Some(square)))
        .unwrap()
        .settings;
    assert_eq!(restored["general"]["radiusRatio"], 0.35);
    assert_eq!(restored["ui"]["fontDefault"], "My Font");
    assert_eq!(
        read(&dir.path().join("UI/square.toml"))["general"]["radiusRatio"],
        0.1
    );
    assert!(read(&host)["general"].get("radiusRatio").is_none());
}

#[test]
fn existing_profile_wins_over_legacy_host_values_and_is_shared_between_hosts() {
    let dir = tempdir().unwrap();
    fs::create_dir(dir.path().join("UI")).unwrap();
    fs::write(
        dir.path().join("UI/material.toml"),
        "# personal\n[general]\nradiusRatio=0.25\n",
    )
    .unwrap();
    for name in ["first", "second"] {
        let host = dir.path().join(format!("{name}.toml"));
        fs::write(
            &host,
            "[ui]\nstyle='material'\n[general]\nradiusRatio=0.8\n",
        )
        .unwrap();
        let response = load(&host, &[], request(dir.path(), defaults(), None)).unwrap();
        assert_eq!(response.settings["general"]["radiusRatio"], 0.25);
        assert_eq!(response.settings["ui"]["panelBackgroundOpacity"], 1.0);
    }
    assert!(
        fs::read_to_string(dir.path().join("UI/material.toml"))
            .unwrap()
            .starts_with("# personal")
    );
}

#[test]
fn malformed_profile_never_prunes_host_or_commits_switch() {
    let dir = tempdir().unwrap();
    let host = dir.path().join("moon.toml");
    let baseline = load(&host, &[], request(dir.path(), defaults(), None))
        .unwrap()
        .settings;
    fs::write(dir.path().join("UI/material.toml"), "broken = [").unwrap();
    let before = fs::read_to_string(&host).unwrap();
    let mut settings = baseline.clone();
    settings["ui"]["style"] = json!("material");
    assert!(save(&host, request(dir.path(), settings, Some(baseline))).is_err());
    assert_eq!(fs::read_to_string(&host).unwrap(), before);
    fs::write(
        &host,
        "[ui]\nstyle='material'\n[general]\nradiusRatio=0.4\n",
    )
    .unwrap();
    let before = fs::read_to_string(&host).unwrap();
    assert!(load(&host, &[], request(dir.path(), defaults(), None)).is_err());
    assert_eq!(fs::read_to_string(&host).unwrap(), before);
}

#[test]
fn manual_profile_edits_and_removed_keys_resolve_against_style_defaults() {
    let dir = tempdir().unwrap();
    let host = dir.path().join("moon.toml");
    let baseline = load(&host, &[], request(dir.path(), defaults(), None))
        .unwrap()
        .settings;
    fs::write(
        dir.path().join("UI/caelestia.toml"),
        "# edited\n[general]\nradiusRatio=0.75\n[ui]\nfontDefault='External'\n",
    )
    .unwrap();
    let mut changed = baseline.clone();
    changed["ui"]["panelBackgroundOpacity"] = json!(0.7);
    let response = save(&host, request(dir.path(), changed, Some(baseline))).unwrap();
    assert_eq!(response.settings["ui"]["fontDefault"], "External");
    assert_eq!(response.settings["general"]["radiusRatio"], 0.75);
    fs::write(
        dir.path().join("UI/caelestia.toml"),
        "[ui]\nfontDefault='External'\n",
    )
    .unwrap();
    let response = load(&host, &[], request(dir.path(), defaults(), None)).unwrap();
    assert_eq!(response.settings["general"]["radiusRatio"], 1.0);
}

#[test]
fn toml_seed_is_preserved_and_unknown_style_uses_safe_fallback() {
    let dir = tempdir().unwrap();
    let host = dir.path().join("moon.toml");
    let seed = dir.path().join("seed.toml");
    let data =
        "[ui]\nstyle = '../../escape'\nfontDefault = 'Seed Font'\n[general]\nradiusRatio = 0.2\n";
    fs::write(&seed, data).unwrap();
    let response = load(
        &host,
        &[seed.clone()],
        request(dir.path(), defaults(), None),
    )
    .unwrap();
    assert_eq!(response.settings["ui"]["style"], "../../escape");
    assert_eq!(response.settings["ui"]["fontDefault"], "Seed Font");
    assert!(dir.path().join("UI/caelestia.toml").exists());
    assert_eq!(fs::read_to_string(seed).unwrap(), data.to_string());
}

#[test]
fn profile_cannot_override_host_fields_and_pending_edits_survive_external_style_change() {
    let dir = tempdir().unwrap();
    let host = dir.path().join("moon.toml");
    let baseline = load(&host, &[], request(dir.path(), defaults(), None))
        .unwrap()
        .settings;
    fs::write(
        dir.path().join("UI/caelestia.toml"),
        "[general]\nradiusRatio=0.6\nscaleRatio=99\n[ui]\nstyle='square'\nfontDefaultScale=99\n",
    )
    .unwrap();
    let response = save(
        &host,
        request(dir.path(), baseline.clone(), Some(baseline.clone())),
    )
    .unwrap();
    assert_eq!(response.settings["ui"]["style"], "caelestia");
    assert_eq!(response.settings["general"]["scaleRatio"], 1.1);
    assert_eq!(response.settings["ui"]["fontDefaultScale"], 1.2);
    fs::write(&host, "[ui]\nstyle='material'\n").unwrap();
    let mut changed = baseline.clone();
    changed["general"]["radiusRatio"] = json!(0.3);
    let response = save(&host, request(dir.path(), changed, Some(baseline))).unwrap();
    assert_eq!(response.settings["ui"]["style"], "material");
    assert_eq!(response.settings["general"]["radiusRatio"], 1.0);
    assert_eq!(response.settings["ui"]["panelBackgroundOpacity"], 1.0);
    assert_eq!(
        read(&dir.path().join("UI/caelestia.toml"))["general"]["radiusRatio"],
        0.3
    );
}

#[test]
fn malformed_profile_schema_is_rejected_without_panicking_or_creating_files() {
    let dir = tempdir().unwrap();
    let host = dir.path().join("moon.toml");
    let mut input = request(dir.path(), defaults(), None);
    let profiles = input.ui_profiles.as_mut().unwrap();
    profiles.default_style = "material".into();
    profiles
        .defaults
        .insert("material".into(), json!({"ui": 123}));
    assert!(load(&host, &[], input).is_err());
    assert!(!host.exists());
}

#[test]
fn export_includes_active_style_values_without_creating_profile_files() {
    let dir = tempdir().unwrap();
    let path = dir.path().join("export.toml");
    let mut active = defaults();
    active["ui"]["style"] = json!("material");
    active["ui"]["fontDefault"] = json!("My Font");
    active["general"]["radiusRatio"] = json!(0.4);
    let result =
        frostalia_settings::export(&path, request(dir.path(), active.clone(), None)).unwrap();
    assert_eq!(result.settings, active);
    assert!(fs::read_to_string(&path).unwrap().contains("My Font"));
    assert!(!dir.path().join("UI").exists());
}
