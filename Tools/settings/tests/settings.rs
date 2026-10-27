use frostalia_settings::{Request, load, save};
use serde_json::{Value, json};
use std::fs;
use std::os::unix::fs::{PermissionsExt, symlink};
use std::path::Path;
use tempfile::tempdir;

fn request(settings: Value, baseline: Option<Value>) -> Request {
    Request {
        settings,
        baseline,
        ui_profiles: None,
    }
}

fn read(path: &Path) -> String {
    fs::read_to_string(path).unwrap()
}

#[test]
fn first_install_creates_private_config_and_loads_it_again() {
    let directory = tempdir().unwrap();
    let path = directory.path().join("settings/host.toml");
    let defaults = json!({"enabled": true, "nested": {"volume": 0.5}, "widgets": [{"id": "clock", "options": {"format": "HH:mm"}}]});
    let result = load(&path, &[], request(defaults.clone(), None)).unwrap();
    assert!(result.fresh);
    assert_eq!(result.settings, defaults);
    assert_eq!(
        fs::metadata(&path).unwrap().permissions().mode() & 0o777,
        0o600
    );
    assert!(read(&path).contains("[[widgets]]"));
    let result = load(&path, &[], request(json!({}), None)).unwrap();
    assert!(!result.fresh);
    assert_eq!(result.settings, defaults);
}

#[test]
fn seeds_precede_defaults_and_hosts_stay_independent() {
    let directory = tempdir().unwrap();
    let first_seed = directory.path().join("first-seed.toml");
    let second_seed = directory.path().join("second-seed.toml");
    fs::write(&first_seed, "value = 2\n").unwrap();
    fs::write(&second_seed, "value = 1\n").unwrap();
    let first = directory.path().join("first.toml");
    let second = directory.path().join("second.toml");
    let result = load(
        &first,
        &[first_seed.clone(), second_seed.clone()],
        request(json!({"value": 0, "new": true}), None),
    )
    .unwrap();
    assert!(!result.fresh);
    assert_eq!(result.settings, json!({"value": 2, "new": true}));
    load(
        &second,
        std::slice::from_ref(&second_seed),
        request(json!({}), None),
    )
    .unwrap();
    assert_eq!(
        load(&second, &[], request(json!({}), None))
            .unwrap()
            .settings["value"],
        1
    );
    assert_eq!(read(&first_seed), "value = 2\n");
    assert_eq!(read(&second_seed), "value = 1\n");
    assert_eq!(
        load(&first, &[second_seed], request(json!({}), None))
            .unwrap()
            .settings["value"],
        2
    );
}

#[test]
fn toml_seed_is_accepted_and_left_untouched() {
    let directory = tempdir().unwrap();
    let seed = directory.path().join("seed.toml");
    fs::write(&seed, "# legacy\nvalue = 7\n").unwrap();
    let config = directory.path().join("host.toml");
    assert_eq!(
        load(
            &config,
            std::slice::from_ref(&seed),
            request(json!({}), None)
        )
        .unwrap()
        .settings["value"],
        7
    );
    assert_eq!(read(&seed), "# legacy\nvalue = 7\n");
}

#[test]
fn save_preserves_comments_unknown_keys_and_nested_arrays() {
    let directory = tempdir().unwrap();
    let path = directory.path().join("host.toml");
    let source = "# My shell\nunknown = 'keep'\n[bar]\nvalue = 1 # inline\nexternal = 9\n# widget comment\n[[bar.widgets]]\nid = 'clock' # my clock\n[bar.widgets.options]\nformat = 'HH:mm' # format\n";
    fs::write(&path, source).unwrap();
    let baseline = json!({"bar": {"value": 1, "widgets": [{"id": "clock", "options": {"format": "HH:mm"}}]}, "defaultOnly": true});
    let mut updated = baseline.clone();
    updated["bar"]["value"] = json!(2);
    save(&path, request(updated, Some(baseline))).unwrap();
    let text = read(&path);
    assert!(text.contains("value = 2 # inline"));
    assert!(text.contains("unknown = 'keep'"));
    assert!(text.contains("external = 9"));
    assert!(text.contains("id = 'clock' # my clock"));
    assert!(text.contains("format = 'HH:mm' # format"));
    assert!(!text.contains("defaultOnly"));
}

#[test]
fn edits_merge_external_changes_and_only_add_changed_defaults() {
    let directory = tempdir().unwrap();
    let path = directory.path().join("host.toml");
    fs::write(&path, "[bar]\nvalue = 8\nother = 12\n").unwrap();
    let baseline = json!({"bar": {"value": 1, "other": 2, "added": 3, "absent": 4}});
    let updated = json!({"bar": {"value": 5, "other": 2, "added": 9, "absent": 4}});
    let result = save(&path, request(updated, Some(baseline))).unwrap();
    assert_eq!(result.settings["bar"]["value"], 5);
    assert_eq!(result.settings["bar"]["other"], 12);
    assert!(read(&path).contains("added = 9"));
    assert!(!read(&path).contains("absent"));
}

#[test]
fn no_op_does_not_replace_file_or_change_modification_time() {
    use std::os::unix::fs::MetadataExt;
    let directory = tempdir().unwrap();
    let path = directory.path().join("host.toml");
    fs::write(&path, "# custom\nvalue=1\n").unwrap();
    let before = fs::metadata(&path).unwrap();
    save(
        &path,
        request(
            json!({"value": 1, "default": true}),
            Some(json!({"value": 1, "default": true})),
        ),
    )
    .unwrap();
    let after = fs::metadata(&path).unwrap();
    assert_eq!(before.ino(), after.ino());
    assert_eq!(before.modified().unwrap(), after.modified().unwrap());
    assert_eq!(read(&path), "# custom\nvalue=1\n");
}

#[test]
fn malformed_toml_is_never_overwritten() {
    let directory = tempdir().unwrap();
    let path = directory.path().join("host.toml");
    fs::write(&path, "broken = [").unwrap();
    assert!(load(&path, &[], request(json!({}), None)).is_err());
    assert!(save(&path, request(json!({"value": 1}), None)).is_err());
    assert_eq!(read(&path), "broken = [");
}

#[test]
fn reject_null_json_config_and_bad_seed_without_creating_file() {
    let directory = tempdir().unwrap();
    let path = directory.path().join("host.toml");
    assert!(load(&path, &[], request(json!({"nested": [null]}), None)).is_err());
    assert!(!path.exists());
    let json_path = directory.path().join("host.json");
    assert!(
        load(&json_path, &[], request(json!({}), None))
            .unwrap_err()
            .to_string()
            .contains("FROSTALIA_SETTINGS_FILE")
    );
    let seed = directory.path().join("seed.json");
    fs::write(&seed, "{broken").unwrap();
    assert!(load(&path, &[seed], request(json!({}), None)).is_err());
    assert!(!path.exists());
}

#[test]
fn symlinks_keep_the_link_and_existing_permissions() {
    let directory = tempdir().unwrap();
    let target = directory.path().join("actual.toml");
    let link = directory.path().join("host.toml");
    fs::write(&target, "value = 1\n").unwrap();
    fs::set_permissions(&target, fs::Permissions::from_mode(0o640)).unwrap();
    symlink("actual.toml", &link).unwrap();
    save(
        &link,
        request(json!({"value": 2}), Some(json!({"value": 1}))),
    )
    .unwrap();
    assert!(
        fs::symlink_metadata(&link)
            .unwrap()
            .file_type()
            .is_symlink()
    );
    assert!(read(&target).contains("value = 2"));
    assert_eq!(
        fs::metadata(&target).unwrap().permissions().mode() & 0o777,
        0o640
    );
}

#[test]
fn dangling_symlinks_and_read_only_files_fail_safely() {
    let directory = tempdir().unwrap();
    let link = directory.path().join("host.toml");
    symlink("missing.toml", &link).unwrap();
    assert!(load(&link, &[], request(json!({}), None)).is_err());
    assert!(
        fs::symlink_metadata(&link)
            .unwrap()
            .file_type()
            .is_symlink()
    );
    let path = directory.path().join("readonly.toml");
    fs::write(&path, "value = 1\n").unwrap();
    fs::set_permissions(&path, fs::Permissions::from_mode(0o400)).unwrap();
    assert!(save(&path, request(json!({"value": 2}), None)).is_err());
    assert_eq!(read(&path), "value = 1\n");
}

#[test]
fn cli_reads_one_json_line_and_reports_errors_on_stderr() {
    use std::io::Write;
    use std::process::{Command, Stdio};
    let directory = tempdir().unwrap();
    let path = directory.path().join("host.toml");
    let mut child = Command::new(env!("CARGO_BIN_EXE_frostalia-settings"))
        .arg("load")
        .arg(&path)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .unwrap();
    child
        .stdin
        .take()
        .unwrap()
        .write_all(b"{\"settings\":{\"value\":1}}\n")
        .unwrap();
    let output = child.wait_with_output().unwrap();
    assert!(output.status.success());
    assert_eq!(
        serde_json::from_slice::<Value>(&output.stdout).unwrap(),
        json!({"settings":{"value":1},"fresh":true})
    );
    let output = Command::new(env!("CARGO_BIN_EXE_frostalia-settings"))
        .arg("unknown")
        .output()
        .unwrap();
    assert!(!output.status.success());
    assert!(output.stdout.is_empty());
    assert!(!output.stderr.is_empty());
}

#[test]
fn json_settings_and_seeds_are_rejected_even_when_valid() {
    let dir = tempdir().unwrap();
    let seed = dir.path().join("settings.json");
    fs::write(&seed, r#"{"value":1}"#).unwrap();
    let host = dir.path().join("host.toml");
    assert!(load(&host, std::slice::from_ref(&seed), request(json!({}), None)).is_err());
    assert!(!host.exists());
    assert!(load(&seed, &[], request(json!({}), None)).is_err());
    assert!(save(&seed, request(json!({}), None)).is_err());
    assert_eq!(read(&seed), r#"{"value":1}"#);
}

#[test]
fn export_is_a_complete_private_toml_snapshot_without_stale_keys() {
    let dir = tempdir().unwrap();
    let path = dir.path().join("export.toml");
    fs::write(&path, "stale = true\n").unwrap();
    let settings = json!({"settingsVersion":71,"general":{"lockCommand":"hyprlock","scaleRatio":1.1},"ui":{"style":"material","fontDefault":"Roboto"},"desktopWidgets":{"monitorWidgets":[{"name":"DP-1","widgets":[{"id":"Weather","view":"detail","detail":"moon"}]}]}});
    let result = frostalia_settings::export(&path, request(settings.clone(), None)).unwrap();
    assert_eq!(result.settings, settings);
    assert_eq!(
        load(&path, &[], request(json!({}), None)).unwrap().settings,
        settings
    );
    assert!(!read(&path).contains("stale"));
    let new_path = dir.path().join("new-export.toml");
    frostalia_settings::export(&new_path, request(settings, None)).unwrap();
    assert_eq!(
        fs::metadata(&new_path).unwrap().permissions().mode() & 0o777,
        0o600
    );
    let bad_path = dir.path().join("export.json");
    assert!(frostalia_settings::export(&bad_path, request(json!({}), None)).is_err());
    assert!(!bad_path.exists());
}

#[test]
fn export_command_writes_toml_to_selected_file() {
    use std::process::{Command, Stdio};
    let dir = tempdir().unwrap();
    let path = dir.path().join("my settings.toml");
    let settings = json!({"ui":{"style":"material","fontDefault":"Roboto"},"general":{"lockCommand":"hyprlock"}});
    let mut child = Command::new(env!("CARGO_BIN_EXE_frostalia-settings"))
        .arg("export")
        .arg(&path)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .unwrap();
    serde_json::to_writer(child.stdin.take().unwrap(), &json!({"settings": settings})).unwrap();
    let output = child.wait_with_output().unwrap();
    assert!(output.status.success());
    assert_eq!(
        load(&path, &[], request(json!({}), None)).unwrap().settings,
        settings
    );
    assert!(read(&path).contains("[general]"));
}
