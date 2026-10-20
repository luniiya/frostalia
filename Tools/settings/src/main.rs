use std::io::{self, BufRead};
use std::path::PathBuf;

fn main() {
    if let Err(error) = run() {
        eprintln!("frostalia-settings: {error}");
        std::process::exit(1);
    }
}

fn run() -> Result<(), Box<dyn std::error::Error>> {
    let mut args = std::env::args_os().skip(1);
    let command = args
        .next()
        .ok_or("usage: frostalia-settings load CONFIG [SEED...] | save CONFIG | export CONFIG")?;
    let path = PathBuf::from(args.next().ok_or("missing CONFIG path")?);
    let seeds: Vec<PathBuf> = args.map(PathBuf::from).collect();
    let line = io::stdin()
        .lock()
        .lines()
        .next()
        .ok_or("missing JSON input")??;
    let input: frostalia_settings::Request = serde_json::from_str(&line)?;
    let response = match command.to_str() {
        Some("load") => frostalia_settings::load(&path, &seeds, input)?,
        Some("save") if seeds.is_empty() => frostalia_settings::save(&path, input)?,
        Some("export") if seeds.is_empty() => frostalia_settings::export(&path, input)?,
        _ => {
            return Err(
                "usage: frostalia-settings load CONFIG [SEED...] | save CONFIG | export CONFIG"
                    .into(),
            );
        }
    };
    println!("{}", serde_json::to_string(&response)?);
    Ok(())
}
