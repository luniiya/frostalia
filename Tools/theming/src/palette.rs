//! Perceptual palette extraction and wallpaper scoring modes.
use crate::color::{hue_distance, lab_to_rgb, rgb_to_lab};
use crate::hct::{Cam16, Hct};
use crate::quantizer::distance;
use std::collections::HashSet;
type Rgb = [u8; 3];
type Cluster = (Rgb, Rgb, usize);
type Scored = (Rgb, f64);
type HueFamily = (usize, Vec<(Rgb, Hct, usize)>);
pub fn is_grayscale_image(pixels: &[Rgb], threshold: f64, tolerance: u8) -> bool {
    !pixels.is_empty()
        && pixels
            .iter()
            .filter(|p| p.iter().max().unwrap() - p.iter().min().unwrap() <= tolerance)
            .count() as f64
            / pixels.len() as f64
            >= threshold
}
pub fn kmeans_cluster(colors: &[Rgb], k: usize, iterations: usize) -> Vec<Cluster> {
    if k == 0 || colors.is_empty() {
        return vec![];
    }
    if colors.len() < k {
        let mut seen = HashSet::new();
        return colors
            .iter()
            .filter(|&&c| seen.insert(c))
            .map(|&c| (c, c, colors.iter().filter(|&&p| p == c).count()))
            .take(k)
            .collect();
    }
    let labs: Vec<_> = colors.iter().copied().map(rgb_to_lab).collect();
    let mut sorted: Vec<_> = (0..colors.len()).collect();
    sorted.sort_by(|&a, &b| labs[a][0].total_cmp(&labs[b][0]));
    let step = colors.len() / k;
    let mut centroids: Vec<_> = (0..k).map(|i| labs[sorted[i * step]]).collect();
    let mut assignments = vec![0; colors.len()];
    for _ in 0..iterations {
        for (i, &lab) in labs.iter().enumerate() {
            let mut best = f64::INFINITY;
            for (j, &centroid) in centroids.iter().enumerate() {
                let d = distance(lab, centroid).sqrt();
                if d < best {
                    best = d;
                    assignments[i] = j;
                }
            }
        }
        let mut sums = vec![[0.; 3]; k];
        let mut counts = vec![0; k];
        for (i, lab) in labs.iter().enumerate() {
            let j = assignments[i];
            counts[j] += 1;
            for axis in 0..3 {
                sums[j][axis] += lab[axis];
            }
        }
        for j in 0..k {
            if counts[j] > 0 {
                centroids[j] = sums[j].map(|v| v / counts[j] as f64);
            }
        }
    }
    let mut counts = vec![0; k];
    let mut representatives = vec![(colors[0], f64::INFINITY); k];
    for (i, &lab) in labs.iter().enumerate() {
        let j = assignments[i];
        counts[j] += 1;
        let d = distance(lab, centroids[j]).sqrt();
        if d < representatives[j].1 {
            representatives[j] = (colors[i], d);
        }
    }
    let mut out: Vec<_> = (0..k)
        .filter(|&j| counts[j] > 0)
        .map(|j| (lab_to_rgb(centroids[j]), representatives[j].0, counts[j]))
        .collect();
    out.sort_by_key(|c| std::cmp::Reverse(c.2));
    out
}
fn sort_scores(scores: &mut [Scored]) {
    scores.sort_by(|a, b| b.1.total_cmp(&a.1));
}
fn muted(colors: &[(Rgb, usize)]) -> Vec<Scored> {
    let mut out: Vec<_> = colors.iter().map(|&(c, n)| (c, n as f64)).collect();
    sort_scores(&mut out);
    out
}
fn chroma(colors: &[(Rgb, usize)]) -> Vec<Scored> {
    let mut out = Vec::new();
    for &(c, n) in colors {
        let h = Hct::from_rgb(c);
        let tone = if h.tone < 20. {
            (20. - h.tone) * 2.
        } else if h.tone > 80. {
            (h.tone - 80.) * 1.5
        } else if h.tone < 40. {
            (40. - h.tone) * 0.5
        } else if h.tone > 60. {
            (h.tone - 60.) * 0.3
        } else {
            0.
        };
        let hue = if h.hue > 80. && h.hue < 110. { 5. } else { 0. };
        out.push((c, (h.chroma - tone - hue) * (n as f64).powf(0.3)));
    }
    sort_scores(&mut out);
    out
}
fn family(h: f64) -> usize {
    if !(30. ..330.).contains(&h) {
        0
    } else if h < 60. {
        1
    } else if h < 105. {
        2
    } else if h < 190. {
        3
    } else if h < 270. {
        4
    } else {
        5
    }
}
fn family_scores(colors: &[(Rgb, usize)], dysfunctional: bool) -> Vec<Scored> {
    let mut families: Vec<HueFamily> = Vec::new();
    for &(c, n) in colors {
        let h = Hct::from_rgb(c);
        if h.chroma >= 10. {
            let f = family(h.hue);
            if let Some((_, v)) = families.iter_mut().find(|(id, _)| *id == f) {
                v.push((c, h, n));
            } else {
                families.push((f, vec![(c, h, n)]));
            }
        }
    }
    if families.is_empty() {
        return muted(colors);
    }
    families.sort_by_key(|(_, v)| std::cmp::Reverse(v.iter().map(|c| c.2).sum::<usize>()));
    let mut out = Vec::new();
    if !dysfunctional {
        let len = families.len();
        for (rank, (_, v)) in families.iter_mut().enumerate() {
            v.sort_by(|a, b| {
                b.2.cmp(&a.2)
                    .then_with(|| b.1.chroma.total_cmp(&a.1.chroma))
            });
            for &(c, h, n) in v.iter() {
                out.push((
                    c,
                    (len - rank) as f64 * 1_000_000. + n as f64 * 1000. + h.chroma,
                ));
            }
        }
    } else {
        let centers = [0., 45., 82.5, 147.5, 230., 300.];
        let center = centers[families[0].0];
        let minimum = families
            .iter()
            .flat_map(|(_, v)| v)
            .map(|c| c.2)
            .sum::<usize>() as f64
            * 0.02;
        let mut distant = Vec::new();
        let mut close = vec![0];
        for (i, (f, v)) in families.iter().enumerate().skip(1) {
            let d = hue_distance(center, centers[*f]);
            let n = v.iter().map(|c| c.2).sum::<usize>();
            if d >= 45. && n as f64 >= minimum {
                let max = v.iter().map(|c| c.1.chroma).fold(0., f64::max);
                distant.push((i, d * max));
            } else {
                close.push(i);
            }
        }
        distant.sort_by(|a, b| b.1.total_cmp(&a.1));
        for (rank, &(i, _)) in distant.iter().enumerate() {
            let v = &mut families[i].1;
            v.sort_by(|a, b| {
                b.1.chroma
                    .total_cmp(&a.1.chroma)
                    .then_with(|| b.2.cmp(&a.2))
            });
            for &(c, h, n) in v.iter() {
                out.push((
                    c,
                    (distant.len() - rank) as f64 * 1_000_000. + h.chroma * 1000. + n as f64,
                ));
            }
        }
        for i in close {
            let v = &mut families[i].1;
            v.sort_by(|a, b| {
                b.2.cmp(&a.2)
                    .then_with(|| b.1.chroma.total_cmp(&a.1.chroma))
            });
            for &(c, h, n) in v.iter() {
                out.push((c, n as f64 * 1000. + h.chroma));
            }
        }
    }
    sort_scores(&mut out);
    out
}
fn population(colors: &[(Rgb, usize)]) -> Vec<Scored> {
    let mut histogram = [0usize; 360];
    let mut sum = 0;
    let mut hcts = Vec::new();
    for &(c, n) in colors {
        let h = Hct::from_rgb(c);
        if h.hue.is_finite() && h.chroma.is_finite() {
            histogram[h.hue as usize % 360] += n;
            sum += n;
            hcts.push((c, h));
        }
    }
    if sum == 0 {
        return muted(colors);
    }
    let mut excited = [0.; 360];
    for (h, &n) in histogram.iter().enumerate() {
        for offset in -14..16 {
            excited[(h as i32 + offset).rem_euclid(360) as usize] += n as f64 / sum as f64;
        }
    }
    let mut scored = Vec::new();
    for (c, h) in hcts {
        let p = excited[h.hue as usize % 360];
        if h.chroma < 5. || p <= 0.01 {
            continue;
        }
        let weight = if h.chroma < 48. { 0.1 } else { 0.3 };
        scored.push((c, h, p * 100. * 0.7 + (h.chroma - 48.) * weight));
    }
    if scored.is_empty() {
        return muted(colors);
    }
    scored.sort_by(|a, b| b.2.total_cmp(&a.2));
    let mut chosen: Vec<Scored> = Vec::new();
    for minimum in (15..=90).rev() {
        chosen.clear();
        for &(c, h, s) in &scored {
            if chosen
                .iter()
                .all(|&(other, _)| hue_distance(h.hue, Hct::from_rgb(other).hue) >= minimum as f64)
            {
                chosen.push((c, s));
            }
            if chosen.len() >= 4 {
                break;
            }
        }
        if chosen.len() >= 4 {
            break;
        }
    }
    chosen
}
pub fn extract_palette(pixels: &[Rgb], k: usize, scoring: &str) -> Result<Vec<Rgb>, String> {
    if k > 256 {
        return Err("palette size must be at most 256".into());
    }
    if !matches!(
        scoring,
        "population" | "chroma" | "count" | "dysfunctional" | "muted"
    ) {
        return Err(format!("unknown palette scoring mode: {scoring}"));
    }
    let sampled: Vec<_> = pixels.iter().step_by(16).copied().collect();
    let unique: HashSet<_> = sampled.iter().copied().collect();
    let count = match scoring {
        "population" => 128.min((k * 10).max(unique.len() / 10)),
        "count" | "dysfunctional" => 48,
        "muted" => 24,
        _ => 20,
    };
    let mut filtered = sampled.clone();
    if !matches!(scoring, "population" | "count" | "dysfunctional" | "muted") {
        let colorful: Vec<_> = sampled
            .iter()
            .copied()
            .filter(|&c| Cam16::from_rgb(c).chroma >= 5.)
            .collect();
        if colorful.len() >= count * 2 {
            filtered = colorful;
        }
    }
    let clusters = kmeans_cluster(&filtered, count, 10);
    let colors: Vec<_> = clusters
        .iter()
        .map(|&(centroid, representative, n)| {
            (
                if scoring == "chroma" {
                    centroid
                } else {
                    representative
                },
                n,
            )
        })
        .collect();
    let scored = match scoring {
        "chroma" => chroma(&colors),
        "count" => family_scores(&colors, false),
        "dysfunctional" => family_scores(&colors, true),
        "muted" => muted(&colors),
        _ => population(&colors),
    };
    let mut out: Vec<_> = scored.into_iter().map(|(c, _)| c).collect();
    while out.len() < k {
        if out.is_empty() {
            out.push([103, 80, 164]);
            continue;
        }
        let primary = Hct::from_rgb(out[0]);
        out.push(
            Hct::from_hct(
                (primary.hue + out.len() as f64 * 60.) % 360.,
                primary.chroma,
                primary.tone,
            )
            .to_rgb(),
        );
    }
    out.truncate(k);
    Ok(out)
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn grayscale_threshold() {
        assert!(!is_grayscale_image(&[], 0.95, 10));
        assert!(is_grayscale_image(&[[128, 129, 138]], 1., 10));
        assert!(!is_grayscale_image(&[[128, 129, 139]], 1., 10));
    }
    #[test]
    fn empty_palette_is_safe() {
        assert_eq!(
            extract_palette(&[], 1, "population").unwrap(),
            vec![[103, 80, 164]]
        );
        assert!(extract_palette(&[], 0, "muted").unwrap().is_empty());
    }
    #[test]
    fn tiny_input_ties_follow_first_seen_order() {
        assert_eq!(
            kmeans_cluster(&[[0, 0, 255], [255, 0, 0], [0, 0, 255]], 20, 10),
            vec![([0, 0, 255], [0, 0, 255], 2), ([255, 0, 0], [255, 0, 0], 1)]
        );
    }
    #[test]
    fn dominant_color_and_secondary_family() {
        let colors = [
            ([0, 190, 0], 100),
            ([240, 20, 0], 40),
            ([128, 128, 128], 200),
        ];
        assert_eq!(family_scores(&colors, false)[0].0, [0, 190, 0]);
        assert_eq!(family_scores(&colors, true)[0].0, [240, 20, 0]);
        assert_eq!(muted(&colors)[0].0, [128, 128, 128]);
    }
    #[test]
    fn clusters_cover_input() {
        let pixels: Vec<_> = (0..100).map(|i| [i, i, 0]).collect();
        let clusters = kmeans_cluster(&pixels, 5, 10);
        assert_eq!(clusters.iter().map(|c| c.2).sum::<usize>(), 100);
        for c in clusters {
            assert!(pixels.contains(&c.1));
        }
    }
}
