//! Wallpaper sampling with ImageMagick-compatible resizing and a native PNG fallback.
use std::path::Path;
use std::process::Command;

pub type Rgb = [u8; 3];
type Result<T> = std::result::Result<T, String>;

pub fn parse_ppm(data: &[u8]) -> Result<Vec<Rgb>> {
    let mut pos = 0;
    let mut tokens = Vec::new();
    while tokens.len() < 4 {
        while pos < data.len() && data[pos].is_ascii_whitespace() {
            pos += 1;
        }
        if pos < data.len() && data[pos] == b'#' {
            while pos < data.len() && data[pos] != b'\n' {
                pos += 1;
            }
            continue;
        }
        let start = pos;
        while pos < data.len() && !data[pos].is_ascii_whitespace() && data[pos] != b'#' {
            pos += 1;
        }
        if start == pos {
            return Err("incomplete PPM header".into());
        }
        tokens.push(std::str::from_utf8(&data[start..pos]).map_err(|e| e.to_string())?);
    }
    if tokens[0] != "P6" {
        return Err("expected a binary P6 image".into());
    }
    let width: usize = tokens[1].parse().map_err(|_| "invalid PPM width")?;
    let height: usize = tokens[2].parse().map_err(|_| "invalid PPM height")?;
    let max: usize = tokens[3].parse().map_err(|_| "invalid PPM maximum")?;
    if width == 0 || height == 0 || !(1..=255).contains(&max) {
        return Err("unsupported PPM dimensions or sample depth".into());
    }
    if pos >= data.len() || !data[pos].is_ascii_whitespace() {
        return Err("missing PPM raster separator".into());
    }
    // Exactly one separator: the first pixel may itself contain whitespace bytes.
    if data[pos] == b'\r' && data.get(pos + 1) == Some(&b'\n') {
        pos += 2;
    } else {
        pos += 1;
    }
    let length = width
        .checked_mul(height)
        .and_then(|n| n.checked_mul(3))
        .ok_or("PPM dimensions overflow")?;
    let raster = data
        .get(pos..pos.checked_add(length).ok_or("PPM length overflow")?)
        .ok_or("truncated PPM raster")?;
    Ok(raster
        .as_chunks::<3>()
        .0
        .iter()
        .map(|p| p.map(|sample| (f64::from(sample) * (255.0 / max as f64)) as u8))
        .collect())
}

pub fn read_image(path: &Path, filter: &str) -> Result<Vec<Rgb>> {
    if !path.is_file() {
        return Err(format!("image not found: {}", path.display()));
    }
    if !["Triangle", "Box"].contains(&filter) {
        return Err(format!("unsupported resize filter: {filter}"));
    }
    let args = [
        "-filter",
        filter,
        "-resize",
        "112x112!",
        "-depth",
        "8",
        "-colorspace",
        "sRGB",
        "-strip",
        "ppm:-",
    ];
    let result = Command::new("magick")
        .arg(path)
        .args(args)
        .output()
        .or_else(|e| {
            if e.kind() == std::io::ErrorKind::NotFound {
                Command::new("convert").arg(path).args(args).output()
            } else {
                Err(e)
            }
        });
    let error = match result {
        Ok(output) if output.status.success() => match parse_ppm(&output.stdout) {
            Ok(pixels) => return Ok(pixels),
            Err(error) => error,
        },
        Ok(output) => format!(
            "ImageMagick failed: {}",
            String::from_utf8_lossy(&output.stderr).trim()
        ),
        Err(error) => format!("could not run ImageMagick: {error}"),
    };
    if path
        .extension()
        .is_some_and(|ext| ext.eq_ignore_ascii_case("png"))
    {
        return read_png(path);
    }
    Err(error)
}

pub fn read_png(path: &Path) -> Result<Vec<Rgb>> {
    let image = ::image::ImageReader::open(path)
        .map_err(|e| e.to_string())?
        .decode()
        .map_err(|e| format!("could not decode PNG: {e}"))?
        .into_rgb8();
    if image.width() == 0 || image.height() == 0 {
        return Err("empty PNG image".into());
    }
    Ok(image.pixels().map(|p| p.0).collect())
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn raster_whitespace_is_not_discarded() {
        let mut data = b"P6\n# test\n1 1\n255\n".to_vec();
        data.extend_from_slice(&[10, 32, 9]);
        assert_eq!(parse_ppm(&data).unwrap(), vec![[10, 32, 9]]);
    }
    #[test]
    fn crlf_and_scaled_samples() {
        assert_eq!(
            parse_ppm(b"P6\r\n1 1\r\n15\r\n\x0f\x00\x05").unwrap(),
            vec![[255, 0, 85]]
        );
    }
    #[test]
    fn malformed_rasters_are_errors() {
        for data in [
            b"P6\n1 1\n255\n\x00".as_slice(),
            b"P6\n0 1\n255\n",
            b"P6\n1 1\n0\n",
            b"P3\n1 1\n255\n",
        ] {
            assert!(parse_ppm(data).is_err());
        }
    }
    #[test]
    fn native_png_decodes_real_pixels() {
        let directory = tempfile::tempdir().unwrap();
        let path = directory.path().join("wallpaper.png");
        let image = ::image::RgbImage::from_fn(2, 1, |x, _| {
            ::image::Rgb(if x == 0 { [255, 0, 0] } else { [0, 128, 255] })
        });
        image.save(&path).unwrap();
        assert_eq!(read_png(&path).unwrap(), vec![[255, 0, 0], [0, 128, 255]]);
    }
}
