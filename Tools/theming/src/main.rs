use frostalia_theming::{image, palette, quantizer};
use serde::Deserialize;
use std::io::{self, Read};
use std::path::PathBuf;

#[derive(Deserialize)]
struct ImageRequest {
    path: PathBuf,
    #[serde(default = "default_filter")]
    resize_filter: String,
}
fn default_filter() -> String {
    "Triangle".into()
}

#[derive(Deserialize)]
struct PaletteRequest {
    pixels: Vec<[u8; 3]>,
    #[serde(default = "default_k")]
    k: usize,
    #[serde(default = "default_scoring")]
    scoring: String,
}
fn default_k() -> usize {
    5
}
fn default_scoring() -> String {
    "population".into()
}

#[derive(Deserialize)]
struct SourceRequest {
    pixels: Vec<[u8; 3]>,
    #[serde(default = "default_fallback")]
    fallback_color: u32,
}
fn default_fallback() -> u32 {
    quantizer::FALLBACK_COLOR
}

fn run() -> Result<(), Box<dyn std::error::Error>> {
    let mut args = std::env::args().skip(1);
    let command = args
        .next()
        .ok_or("expected image, png, palette or source")?;
    if args.next().is_some() {
        return Err("expected one command; pass request JSON on stdin".into());
    }
    let mut input = String::new();
    io::stdin().read_to_string(&mut input)?;
    let output = match command.as_str() {
        "image" | "png" => {
            let request: ImageRequest = serde_json::from_str(&input)?;
            let pixels = if command == "png" {
                image::read_png(&request.path)?
            } else {
                image::read_image(&request.path, &request.resize_filter)?
            };
            serde_json::to_string(&pixels)?
        }
        "palette" => {
            let request: PaletteRequest = serde_json::from_str(&input)?;
            serde_json::to_string(&palette::extract_palette(
                &request.pixels,
                request.k,
                &request.scoring,
            )?)?
        }
        "source" => {
            let request: SourceRequest = serde_json::from_str(&input)?;
            serde_json::to_string(&quantizer::extract_source_color(
                &request.pixels,
                request.fallback_color,
            ))?
        }
        _ => return Err(format!("unknown command: {command}").into()),
    };
    println!("{output}");
    Ok(())
}

fn main() {
    if let Err(error) = run() {
        eprintln!("frostalia-theming: {error}");
        std::process::exit(1);
    }
}
