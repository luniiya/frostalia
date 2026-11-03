//! Wallpaper index for the shell's wallpaper picker: lists the images under some
//! folders and, for each, caches a small JPEG thumbnail and a dominant color.
//!
//! The cache lives in `<cache_dir>/index.json` (keyed by path, invalidated by mtime
//! and size) with thumbnails in `<cache_dir>/thumbs/`. `run()` writes newline
//! separated JSON so the shell can show the list at once and fill in colors as
//! they are computed:
//!
//!   {"entries": [{"path", "name", "ext", "mtime", "color", "thumb"}, ...]}
//!   {"update": {"path", "color", "thumb"}}       one per newly indexed image
//!   {"done": true, "indexed": n, "failed": m}
use crate::color::Rgb;
use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, HashSet};
use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::mpsc;
use std::time::UNIX_EPOCH;

type Result<T> = std::result::Result<T, String>;

pub const EXTENSIONS: [&str; 6] = ["png", "jpg", "jpeg", "gif", "webp", "bmp"];
const CACHE_VERSION: u32 = 1;
// Chroma (max - min channel, 0..1) below which a pixel counts as gray
const NEUTRAL_CHROMA: f64 = 0.12;
// Share of colorful pixels an image needs before a hue wins over its average
const MIN_CHROMATIC_SHARE: f64 = 0.15;
const HUE_BINS: usize = 24;

#[derive(Deserialize)]
pub struct Request {
    pub directories: Vec<PathBuf>,
    pub cache_dir: PathBuf,
    #[serde(default = "default_true")]
    pub index: bool,
    #[serde(default = "default_thumb_height")]
    pub thumb_height: u32,
    #[serde(default)]
    pub threads: usize,
}
fn default_true() -> bool {
    true
}
fn default_thumb_height() -> u32 {
    360
}

#[derive(Debug, Clone, PartialEq)]
pub struct File {
    pub path: PathBuf,
    pub mtime: u64,
    pub size: u64,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
pub struct Cached {
    pub mtime: u64,
    pub size: u64,
    #[serde(default)]
    pub color: Option<String>,
    #[serde(default)]
    pub thumb: Option<String>,
    // Could not be decoded; not retried until the file changes
    #[serde(default)]
    pub failed: bool,
}

#[derive(Default, Serialize, Deserialize)]
pub struct Cache {
    #[serde(default)]
    pub version: u32,
    #[serde(default)]
    pub entries: BTreeMap<String, Cached>,
}

#[derive(Serialize)]
struct Entry<'a> {
    path: &'a str,
    name: String,
    ext: String,
    mtime: u64,
    color: Option<&'a str>,
    thumb: Option<&'a str>,
}

pub fn is_image(path: &Path) -> bool {
    path.extension()
        .and_then(|e| e.to_str())
        .is_some_and(|e| EXTENSIONS.contains(&e.to_ascii_lowercase().as_str()))
}

/// Images under the directories (recursively, following symlinks), sorted by path.
/// Hidden files and folders are skipped. A file reachable twice (a symlink to an
/// image that is also listed, like a `current_wallpaper.jpg` link) is listed once,
/// under the path that is not itself a symlink.
pub fn scan(directories: &[PathBuf]) -> Vec<File> {
    let mut found: Vec<(PathBuf, bool)> = Vec::new();
    let mut visited = HashSet::new();
    for dir in directories {
        walk(dir, &mut visited, &mut found);
    }
    found.sort_by(|a, b| a.0.cmp(&b.0));
    // Real files first so they claim their canonical path before any link to them
    let mut order: Vec<usize> = (0..found.len()).collect();
    order.sort_by_key(|&i| found[i].1);
    let mut seen = HashSet::new();
    let mut keep = vec![false; found.len()];
    for i in order {
        let canonical = fs::canonicalize(&found[i].0).unwrap_or_else(|_| found[i].0.clone());
        if seen.insert(canonical) {
            keep[i] = true;
        }
    }
    found
        .into_iter()
        .zip(keep)
        .filter(|(_, k)| *k)
        .filter_map(|((path, _), _)| {
            let meta = fs::metadata(&path).ok()?;
            let mtime = meta
                .modified()
                .ok()
                .and_then(|t| t.duration_since(UNIX_EPOCH).ok())
                .map_or(0, |d| d.as_secs());
            Some(File {
                path,
                mtime,
                size: meta.len(),
            })
        })
        .collect()
}

fn walk(dir: &Path, visited: &mut HashSet<PathBuf>, found: &mut Vec<(PathBuf, bool)>) {
    let Ok(canonical) = fs::canonicalize(dir) else {
        return;
    };
    if !visited.insert(canonical) {
        return;
    }
    let Ok(read) = fs::read_dir(dir) else {
        return;
    };
    for entry in read.flatten() {
        let path = entry.path();
        if entry.file_name().to_string_lossy().starts_with('.') {
            continue;
        }
        let is_link = entry.file_type().is_ok_and(|t| t.is_symlink());
        // Follows symlinks
        let Ok(meta) = fs::metadata(&path) else {
            continue;
        };
        if meta.is_dir() {
            walk(&path, visited, found);
        } else if meta.is_file() && is_image(&path) {
            found.push((path, is_link));
        }
    }
}

/// The color an image is mostly about: the mean of its most common hue family,
/// weighted by how colorful the pixels are, or its average color when it is
/// mostly gray. Black-and-white images stay neutral instead of picking up a hue.
pub fn dominant_color(pixels: &[Rgb]) -> Rgb {
    if pixels.is_empty() {
        return [0, 0, 0];
    }
    let mut weights = [0.0f64; HUE_BINS];
    let mut bins = vec![usize::MAX; pixels.len()];
    let mut chromatic = 0usize;
    for (i, &[r, g, b]) in pixels.iter().enumerate() {
        let (r, g, b) = (r as f64 / 255.0, g as f64 / 255.0, b as f64 / 255.0);
        let max = r.max(g).max(b);
        let min = r.min(g).min(b);
        let chroma = max - min;
        if chroma < NEUTRAL_CHROMA {
            continue;
        }
        let hue = if max == r {
            60.0 * ((g - b) / chroma).rem_euclid(6.0)
        } else if max == g {
            60.0 * ((b - r) / chroma + 2.0)
        } else {
            60.0 * ((r - g) / chroma + 4.0)
        };
        let bin = ((hue / 360.0 * HUE_BINS as f64) as usize).min(HUE_BINS - 1);
        weights[bin] += chroma;
        bins[i] = bin;
        chromatic += 1;
    }
    if (chromatic as f64) < pixels.len() as f64 * MIN_CHROMATIC_SHARE {
        return mean(pixels.iter());
    }
    let score = |b: usize| {
        weights[(b + HUE_BINS - 1) % HUE_BINS] * 0.5 + weights[b] + weights[(b + 1) % HUE_BINS] * 0.5
    };
    let best = (0..HUE_BINS)
        .max_by(|&a, &b| score(a).total_cmp(&score(b)).then(b.cmp(&a)))
        .unwrap_or(0);
    // The winning bin and its two neighbours
    let near = |bin: usize| {
        bin != usize::MAX && {
            let distance = (bin + HUE_BINS - best) % HUE_BINS;
            distance <= 1 || distance == HUE_BINS - 1
        }
    };
    mean(pixels.iter().zip(&bins).filter(|(_, b)| near(**b)).map(|(p, _)| p))
}

fn mean<'a>(pixels: impl Iterator<Item = &'a Rgb>) -> Rgb {
    let (mut sum, mut n) = ([0u64; 3], 0u64);
    for p in pixels {
        for c in 0..3 {
            sum[c] += p[c] as u64;
        }
        n += 1;
    }
    if n == 0 {
        return [0, 0, 0];
    }
    sum.map(|s| ((s + n / 2) / n) as u8)
}

pub fn hex(color: Rgb) -> String {
    format!("#{:02x}{:02x}{:02x}", color[0], color[1], color[2])
}

/// Stable file name for a thumbnail: FNV-1a of the path, mtime and size.
pub fn thumb_name(file: &File) -> String {
    let mut hash: u64 = 0xcbf29ce484222325;
    let key = format!("{}\0{}\0{}", file.path.display(), file.mtime, file.size);
    for byte in key.bytes() {
        hash ^= byte as u64;
        hash = hash.wrapping_mul(0x100000001b3);
    }
    format!("{hash:016x}.jpg")
}

/// Decodes the image, writes its thumbnail (at most `height` tall) and returns
/// the thumbnail path and dominant color.
pub fn index_file(file: &File, thumbs: &Path, height: u32) -> Result<(String, String)> {
    let image = ::image::ImageReader::open(&file.path)
        .map_err(|e| e.to_string())?
        .with_guessed_format()
        .map_err(|e| e.to_string())?
        .decode()
        .map_err(|e| format!("{}: {e}", file.path.display()))?;
    let height = height.max(16);
    let thumb = image.thumbnail(height.saturating_mul(3), height).to_rgb8();
    let sample = ::image::imageops::thumbnail(&thumb, 64, 64);
    let pixels: Vec<Rgb> = sample.pixels().map(|p| p.0).collect();
    let color = hex(dominant_color(&pixels));
    let target = thumbs.join(thumb_name(file));
    let partial = target.with_extension("jpg.part");
    {
        let out = fs::File::create(&partial).map_err(|e| e.to_string())?;
        let mut writer = std::io::BufWriter::new(out);
        ::image::codecs::jpeg::JpegEncoder::new_with_quality(&mut writer, 82)
            .encode_image(&thumb)
            .map_err(|e| e.to_string())?;
        writer.flush().map_err(|e| e.to_string())?;
    }
    fs::rename(&partial, &target).map_err(|e| e.to_string())?;
    Ok((target.to_string_lossy().into_owned(), color))
}

pub fn load_cache(path: &Path) -> Cache {
    fs::read_to_string(path)
        .ok()
        .and_then(|text| serde_json::from_str::<Cache>(&text).ok())
        .filter(|cache| cache.version == CACHE_VERSION)
        .unwrap_or(Cache {
            version: CACHE_VERSION,
            entries: BTreeMap::new(),
        })
}

fn save_cache(path: &Path, cache: &Cache) -> Result<()> {
    let partial = path.with_extension("json.part");
    fs::write(&partial, serde_json::to_string(cache).map_err(|e| e.to_string())?)
        .map_err(|e| e.to_string())?;
    fs::rename(&partial, path).map_err(|e| e.to_string())
}

/// Cache entry for a file, if it is still current (same mtime and size, and
/// its thumbnail was not deleted).
pub fn cached<'a>(cache: &'a Cache, file: &File) -> Option<&'a Cached> {
    let entry = cache.entries.get(file.path.to_str()?)?;
    let current = entry.mtime == file.mtime && entry.size == file.size;
    let thumb_ok = entry.failed || entry.thumb.as_ref().is_some_and(|t| Path::new(t).is_file());
    (current && thumb_ok).then_some(entry)
}

pub fn run(request: Request, out: &mut impl Write) -> Result<()> {
    let thumbs = request.cache_dir.join("thumbs");
    fs::create_dir_all(&thumbs).map_err(|e| e.to_string())?;
    let cache_path = request.cache_dir.join("index.json");
    let mut cache = load_cache(&cache_path);
    let files = scan(&request.directories);

    let entries: Vec<Entry> = files
        .iter()
        .filter_map(|file| {
            let path = file.path.to_str()?;
            let hit = cached(&cache, file);
            Some(Entry {
                path,
                name: file
                    .path
                    .file_stem()
                    .map_or(String::new(), |s| s.to_string_lossy().into_owned()),
                ext: file
                    .path
                    .extension()
                    .map_or(String::new(), |s| s.to_string_lossy().to_ascii_lowercase()),
                mtime: file.mtime,
                color: hit.and_then(|c| c.color.as_deref()),
                thumb: hit.and_then(|c| c.thumb.as_deref()),
            })
        })
        .collect();
    writeln!(out, "{}", serde_json::json!({ "entries": entries })).map_err(|e| e.to_string())?;
    out.flush().map_err(|e| e.to_string())?;

    let pending: Vec<&File> = if request.index {
        files
            .iter()
            .filter(|f| f.path.to_str().is_some() && cached(&cache, f).is_none())
            .collect()
    } else {
        Vec::new()
    };
    let (mut indexed, mut failed) = (0usize, 0usize);
    if !pending.is_empty() {
        let threads = if request.threads > 0 {
            request.threads
        } else {
            std::thread::available_parallelism().map_or(2, |n| (n.get() / 2).clamp(1, 8))
        };
        let next = AtomicUsize::new(0);
        let (tx, rx) = mpsc::channel();
        std::thread::scope(|scope| -> Result<()> {
            for _ in 0..threads.min(pending.len()) {
                let tx = tx.clone();
                let (next, pending, thumbs) = (&next, &pending, &thumbs);
                scope.spawn(move || {
                    loop {
                        let i = next.fetch_add(1, Ordering::Relaxed);
                        let Some(file) = pending.get(i) else { break };
                        if tx.send((*file, index_file(file, thumbs, request.thumb_height))).is_err() {
                            break;
                        }
                    }
                });
            }
            drop(tx);
            for (file, result) in rx {
                let path = file.path.to_string_lossy().into_owned();
                let mut entry = Cached {
                    mtime: file.mtime,
                    size: file.size,
                    ..Default::default()
                };
                match result {
                    Ok((thumb, color)) => {
                        indexed += 1;
                        let _ = writeln!(
                            out,
                            "{}",
                            serde_json::json!({ "update": { "path": path, "color": color, "thumb": thumb } })
                        );
                        let _ = out.flush();
                        entry.color = Some(color);
                        entry.thumb = Some(thumb);
                    }
                    Err(error) => {
                        failed += 1;
                        eprintln!("frostalia-theming: {error}");
                        entry.failed = true;
                    }
                }
                cache.entries.insert(path, entry);
                // Keep progress if the shell stops us halfway through
                if (indexed + failed) % 200 == 0 {
                    save_cache(&cache_path, &cache)?;
                }
            }
            Ok(())
        })?;
    }
    // Forget files that are gone
    let listed: HashSet<String> = files.iter().map(|f| f.path.to_string_lossy().into_owned()).collect();
    let before = cache.entries.len();
    if request.index {
        cache.entries.retain(|path, _| listed.contains(path));
    }
    if indexed + failed > 0 || cache.entries.len() != before {
        save_cache(&cache_path, &cache)?;
    }
    writeln!(
        out,
        "{}",
        serde_json::json!({ "done": true, "indexed": indexed, "failed": failed })
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn solid(color: Rgb, n: usize) -> Vec<Rgb> {
        vec![color; n]
    }

    #[test]
    fn grayscale_images_stay_neutral() {
        let mut pixels = solid([20, 20, 20], 50);
        pixels.extend(solid([230, 230, 230], 50));
        assert_eq!(dominant_color(&pixels), [125, 125, 125]);
        // A few colorful pixels don't make a gray image colorful
        pixels.extend(solid([255, 0, 0], 5));
        let [r, g, b] = dominant_color(&pixels);
        assert!(r.abs_diff(g) < 30 && g.abs_diff(b) < 5, "{r} {g} {b}");
    }

    #[test]
    fn the_most_colorful_hue_family_wins() {
        let mut pixels = solid([10, 10, 10], 40);
        pixels.extend(solid([30, 60, 200], 35));
        pixels.extend(solid([200, 40, 40], 25));
        assert_eq!(dominant_color(&pixels), [30, 60, 200]);
    }

    #[test]
    fn neighbouring_hues_are_averaged_together() {
        let mut pixels = solid([255, 0, 0], 10);
        pixels.extend(solid([255, 40, 0], 10));
        pixels.extend(solid([0, 0, 255], 12));
        // Two reds next to each other outweigh a slightly bigger blue
        let [r, g, b] = dominant_color(&pixels);
        assert_eq!((r, b), (255, 0));
        assert_eq!(g, 20);
    }

    #[test]
    fn red_wraps_around_the_hue_circle() {
        let mut pixels = solid([255, 0, 10], 10); // hue ~358
        pixels.extend(solid([255, 10, 0], 10)); // hue ~2
        pixels.extend(solid([0, 255, 0], 12));
        let [r, g, _] = dominant_color(&pixels);
        assert!(r > 200 && g < 20);
    }

    #[test]
    fn empty_input_is_black() {
        assert_eq!(dominant_color(&[]), [0, 0, 0]);
        assert_eq!(hex([255, 16, 0]), "#ff1000");
    }

    #[test]
    fn thumb_names_change_with_the_file() {
        let file = File {
            path: "/a/b.png".into(),
            mtime: 1,
            size: 2,
        };
        let name = thumb_name(&file);
        assert!(name.ends_with(".jpg") && name.len() == 20);
        assert_eq!(name, thumb_name(&file.clone()));
        assert_ne!(name, thumb_name(&File { mtime: 3, ..file.clone() }));
        assert_ne!(name, thumb_name(&File { path: "/a/c.png".into(), ..file }));
    }

    fn write_png(path: &Path, color: Rgb, w: u32, h: u32) {
        ::image::RgbImage::from_pixel(w, h, ::image::Rgb(color)).save(path).unwrap();
    }

    #[test]
    fn scan_follows_links_skips_hidden_and_lists_each_file_once() {
        let dir = tempfile::tempdir().unwrap();
        let root = dir.path();
        let real = tempfile::tempdir().unwrap();
        fs::create_dir(root.join("sub")).unwrap();
        fs::create_dir(root.join(".hidden")).unwrap();
        write_png(&root.join("b.png"), [1, 2, 3], 2, 2);
        write_png(&root.join("sub/a.PNG"), [1, 2, 3], 2, 2);
        write_png(&root.join(".hidden/c.png"), [1, 2, 3], 2, 2);
        write_png(&real.path().join("d.png"), [1, 2, 3], 2, 2);
        fs::write(root.join("notes.txt"), "x").unwrap();
        std::os::unix::fs::symlink(real.path(), root.join("linked")).unwrap();
        // Points at a file that is listed anyway
        std::os::unix::fs::symlink(root.join("b.png"), root.join("current.png")).unwrap();
        // A loop must not hang the walk
        std::os::unix::fs::symlink(root, root.join("sub/loop")).unwrap();
        let names: Vec<String> = scan(&[root.to_path_buf()])
            .iter()
            .map(|f| f.path.strip_prefix(root).unwrap().display().to_string())
            .collect();
        assert_eq!(names, ["b.png", "linked/d.png", "sub/a.PNG"]);
        assert!(scan(&[root.join("missing")]).is_empty());
    }

    fn lines(out: &[u8]) -> Vec<serde_json::Value> {
        String::from_utf8_lossy(out)
            .lines()
            .map(|l| serde_json::from_str(l).unwrap())
            .collect()
    }

    #[test]
    fn run_indexes_new_files_and_reuses_the_cache() {
        let walls = tempfile::tempdir().unwrap();
        let cache = tempfile::tempdir().unwrap();
        write_png(&walls.path().join("blue.png"), [20, 40, 220], 64, 40);
        write_png(&walls.path().join("gray.png"), [90, 90, 90], 40, 64);
        fs::write(walls.path().join("broken.jpg"), "not an image").unwrap();
        let request = || Request {
            directories: vec![walls.path().to_path_buf()],
            cache_dir: cache.path().to_path_buf(),
            index: true,
            thumb_height: 32,
            threads: 2,
        };

        let mut out = Vec::new();
        run(request(), &mut out).unwrap();
        let first = lines(&out);
        let entries = first[0]["entries"].as_array().unwrap();
        assert_eq!(entries.len(), 3);
        assert_eq!(entries[1]["name"], "broken");
        assert_eq!(entries[1]["ext"], "jpg");
        assert!(entries.iter().all(|e| e["color"].is_null()));
        let updates: BTreeMap<String, String> = first[1..first.len() - 1]
            .iter()
            .map(|l| (l["update"]["path"].as_str().unwrap().rsplit('/').next().unwrap().to_string(), l["update"]["color"].as_str().unwrap().to_string()))
            .collect();
        assert_eq!(updates["blue.png"], "#1428dc");
        assert_eq!(updates["gray.png"], "#5a5a5a");
        assert_eq!(first.last().unwrap()["indexed"], 2);
        assert_eq!(first.last().unwrap()["failed"], 1);
        let thumb = ::image::open(first[1]["update"]["thumb"].as_str().unwrap()).unwrap();
        assert_eq!(thumb.height(), 32);

        // Second run: everything comes from the cache, broken files are not retried
        let mut out = Vec::new();
        run(request(), &mut out).unwrap();
        let second = lines(&out);
        assert_eq!(second.len(), 2);
        let entries = second[0]["entries"].as_array().unwrap();
        assert_eq!(entries[0]["color"], "#1428dc");
        assert!(entries[0]["thumb"].as_str().unwrap().ends_with(".jpg"));
        assert!(entries[1]["color"].is_null());
        assert_eq!(second[1]["indexed"], 0);

        // A changed file is indexed again; a deleted one leaves the cache
        write_png(&walls.path().join("blue.png"), [220, 30, 30], 64, 41);
        fs::remove_file(walls.path().join("gray.png")).unwrap();
        let mut out = Vec::new();
        run(request(), &mut out).unwrap();
        let third = lines(&out);
        assert_eq!(third[1]["update"]["color"], "#dc1e1e");
        let saved = load_cache(&cache.path().join("index.json"));
        assert_eq!(saved.entries.len(), 2);
    }

    #[test]
    fn listing_only_does_not_index() {
        let walls = tempfile::tempdir().unwrap();
        let cache = tempfile::tempdir().unwrap();
        write_png(&walls.path().join("a.png"), [1, 2, 3], 4, 4);
        let mut out = Vec::new();
        run(
            Request {
                directories: vec![walls.path().to_path_buf()],
                cache_dir: cache.path().to_path_buf(),
                index: false,
                thumb_height: 32,
                threads: 1,
            },
            &mut out,
        )
        .unwrap();
        let result = lines(&out);
        assert_eq!(result.len(), 2);
        assert_eq!(result[1]["indexed"], 0);
        assert!(!cache.path().join("index.json").exists());
    }
}
