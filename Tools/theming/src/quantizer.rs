//! Wu quantization followed by deterministic weighted Lab clustering and Material scoring.
use crate::color::{lab_to_rgb, rgb_to_lab};
use crate::hct::{Cam16, Hct};
use std::collections::HashMap;

pub const FALLBACK_COLOR: u32 = 0xff4285f4;
pub fn argb(rgb: [u8; 3]) -> u32 {
    0xff000000 | (rgb[0] as u32) << 16 | (rgb[1] as u32) << 8 | rgb[2] as u32
}
pub fn source_color_to_rgb(c: u32) -> [u8; 3] {
    [(c >> 16) as u8, (c >> 8) as u8, c as u8]
}
pub fn distance(a: [f64; 3], b: [f64; 3]) -> f64 {
    (a[0] - b[0]).powi(2) + (a[1] - b[1]).powi(2) + (a[2] - b[2]).powi(2)
}
#[derive(Clone, Copy, Default)]
struct Cube {
    lo: [usize; 3],
    hi: [usize; 3],
}
fn idx(p: [usize; 3]) -> usize {
    p[0] * 1089 + p[1] * 33 + p[2]
}
fn volume(c: Cube, m: &[f64]) -> f64 {
    let [r, g, b] = c.hi;
    let [x, y, z] = c.lo;
    m[idx([r, g, b])] - m[idx([r, g, z])] - m[idx([r, y, b])] + m[idx([r, y, z])]
        - m[idx([x, g, b])]
        + m[idx([x, g, z])]
        + m[idx([x, y, b])]
        - m[idx([x, y, z])]
}
struct Wu {
    m: [Vec<f64>; 5],
}
impl Wu {
    fn new(pixels: &[[u8; 3]]) -> Self {
        let mut m = std::array::from_fn(|_| vec![0.; 35937]);
        for &[r, g, b] in pixels {
            let i = idx([
                (r as usize >> 3) + 1,
                (g as usize >> 3) + 1,
                (b as usize >> 3) + 1,
            ]);
            let [r, g, b] = [r as f64, g as f64, b as f64];
            m[0][i] += 1.;
            m[1][i] += r;
            m[2][i] += g;
            m[3][i] += b;
            m[4][i] += r * r + g * g + b * b;
        }
        for r in 1..33 {
            let mut area = [[0.; 33]; 5];
            for g in 1..33 {
                let mut line = [0.; 5];
                for (channel, area_channel) in area.iter_mut().enumerate() {
                    for (b, area_cell) in area_channel.iter_mut().enumerate().skip(1) {
                        let i = idx([r, g, b]);
                        let prev = idx([r - 1, g, b]);
                        line[channel] += m[channel][i];
                        *area_cell += line[channel];
                        m[channel][i] = m[channel][prev] + *area_cell;
                    }
                }
            }
        }
        Self { m }
    }
    fn variance(&self, c: Cube) -> f64 {
        let w = volume(c, &self.m[0]);
        if w == 0. {
            return 0.;
        }
        volume(c, &self.m[4]) - (1..4).map(|i| volume(c, &self.m[i]).powi(2)).sum::<f64>() / w
    }
    fn cut(&self, c: Cube) -> Option<(Cube, Cube)> {
        let whole: [f64; 4] = std::array::from_fn(|i| volume(c, &self.m[i]));
        let mut maxima = [(None, 0.); 3];
        for (axis, maximum) in maxima.iter_mut().enumerate() {
            for pos in c.lo[axis] + 1..c.hi[axis] {
                let mut half = c;
                half.hi[axis] = pos;
                let v: [f64; 4] = std::array::from_fn(|i| volume(half, &self.m[i]));
                if v[0] == 0. || whole[0] - v[0] == 0. {
                    continue;
                }
                let score = (1..4).map(|i| v[i] * v[i]).sum::<f64>() / v[0]
                    + (1..4).map(|i| (whole[i] - v[i]).powi(2)).sum::<f64>() / (whole[0] - v[0]);
                if score > maximum.1 {
                    *maximum = (Some(pos), score);
                }
            }
        }
        let axis = if maxima[0].1 >= maxima[1].1 && maxima[0].1 >= maxima[2].1 {
            0
        } else if maxima[1].1 >= maxima[0].1 && maxima[1].1 >= maxima[2].1 {
            1
        } else {
            2
        };
        let pos = maxima[axis].0?;
        let mut a = c;
        let mut b = c;
        a.hi[axis] = pos;
        b.lo[axis] = pos;
        Some((a, b))
    }
}
pub fn quantize_wu(pixels: &[[u8; 3]], max_colors: usize) -> Vec<u32> {
    if pixels.is_empty() || max_colors == 0 {
        return vec![];
    }
    let wu = Wu::new(pixels);
    let mut cubes = vec![Cube::default(); max_colors];
    cubes[0].hi = [32; 3];
    let mut variances = vec![0.; max_colors];
    let mut next = 0;
    let mut count = 1;
    while count < max_colors {
        if let Some((a, b)) = wu.cut(cubes[next]) {
            cubes[next] = a;
            cubes[count] = b;
            variances[next] = wu.variance(a);
            variances[count] = wu.variance(b);
            count += 1;
        } else {
            variances[next] = 0.;
        }
        next = 0;
        for i in 1..count {
            if variances[i] > variances[next] {
                next = i;
            }
        }
        if variances[next] <= 0. {
            break;
        }
    }
    let mut out = Vec::new();
    for c in cubes.into_iter().take(count) {
        let w = volume(c, &wu.m[0]);
        if w > 0. {
            let rgb = std::array::from_fn(|i| (volume(c, &wu.m[i + 1]) / w) as u8);
            let color = argb(rgb);
            if !out.contains(&color) {
                out.push(color);
            }
        }
    }
    out
}
struct Random(u64);
impl Random {
    fn new() -> Self {
        Self((0x42688 ^ 0x5deece66d) & ((1 << 48) - 1))
    }
    fn range(&mut self, n: usize) -> usize {
        self.0 = (self.0.wrapping_mul(0x5deece66d) + 0xb) & ((1 << 48) - 1);
        let bits = self.0 >> 17;
        if n.is_power_of_two() {
            ((n as u64 * bits) >> 31) as usize
        } else {
            bits as usize % n
        }
    }
}
pub fn quantize_wsmeans(
    pixels: &[[u8; 3]],
    max_colors: usize,
    starting: &[u32],
) -> Vec<(u32, usize)> {
    let mut indices = HashMap::new();
    let mut points = Vec::new();
    let mut counts = Vec::new();
    for &p in pixels {
        let color = argb(p);
        if let Some(&i) = indices.get(&color) {
            counts[i] += 1;
        } else {
            indices.insert(color, points.len());
            points.push(rgb_to_lab(p));
            counts.push(1usize);
        }
    }
    let n = max_colors.min(points.len());
    if n == 0 {
        return vec![];
    }
    let mut clusters: Vec<_> = starting
        .iter()
        .take(n)
        .map(|&p| rgb_to_lab(source_color_to_rgb(p)))
        .collect();
    let mut rng = Random::new();
    let mut added = Vec::new();
    while clusters.len() < n {
        let i = rng.range(points.len());
        if !added.contains(&i) {
            added.push(i);
            clusters.push(points[i]);
        }
    }
    let mut assigned: Vec<_> = (0..points.len()).map(|i| i % n).collect();
    let mut matrix: Vec<Vec<_>> = (0..n).map(|_| (0..n).map(|j| (0., j)).collect()).collect();
    let mut populations = vec![0; n];
    for iteration in 0..10 {
        let mut moved = 0;
        // Preserve the original matrix update/sort order, including its assignment shortcut.
        for i in 0..n {
            for j in i + 1..n {
                let d = distance(clusters[i], clusters[j]);
                matrix[j][i] = (d, i);
                matrix[i][j] = (d, j);
            }
            matrix[i].sort_by(|a, b| a.0.total_cmp(&b.0));
        }
        for i in 0..points.len() {
            let previous = assigned[i];
            let previous_distance = distance(points[i], clusters[previous]);
            let mut best = previous_distance;
            let mut new = None;
            for (j, cluster) in clusters.iter().enumerate() {
                if matrix[previous][j].0 >= 4. * previous_distance {
                    continue;
                }
                let d = distance(points[i], *cluster);
                if d < best {
                    best = d;
                    new = Some(j);
                }
            }
            if let Some(j) = new {
                moved += 1;
                assigned[i] = j;
            }
        }
        if moved == 0 && iteration > 0 {
            break;
        }
        let mut sums = vec![[0.; 3]; n];
        populations.fill(0);
        for i in 0..points.len() {
            let c = assigned[i];
            populations[c] += counts[i];
            for axis in 0..3 {
                sums[c][axis] += points[i][axis] * counts[i] as f64;
            }
        }
        for i in 0..n {
            clusters[i] = if populations[i] == 0 {
                [0.; 3]
            } else {
                sums[i].map(|v| v / populations[i] as f64)
            };
        }
    }
    let mut out = Vec::new();
    for i in 0..n {
        if populations[i] > 0 {
            let c = argb(lab_to_rgb(clusters[i]));
            if !out.iter().any(|&(color, _)| color == c) {
                out.push((c, populations[i]));
            }
        }
    }
    out
}
pub fn score_colors(colors: &[(u32, usize)], desired: usize, fallback: u32) -> Vec<u32> {
    let mut histogram = [0usize; 360];
    let mut sum = 0;
    let mut hcts = Vec::new();
    for &(c, count) in colors {
        let h = Hct::from_rgb(source_color_to_rgb(c));
        if !h.hue.is_finite() || !h.chroma.is_finite() {
            continue;
        }
        histogram[h.hue as usize % 360] += count;
        sum += count;
        hcts.push((c, h));
    }
    if sum == 0 {
        return vec![fallback];
    }
    let mut excited = [0.; 360];
    for (h, &count) in histogram.iter().enumerate() {
        for offset in -14..16 {
            excited[(h as i32 + offset).rem_euclid(360) as usize] += count as f64 / sum as f64;
        }
    }
    let mut scored = Vec::new();
    for (c, h) in hcts {
        let proportion = excited[h.hue.round_ties_even() as usize % 360];
        if h.chroma < 5. || proportion <= 0.01 {
            continue;
        }
        let weight = if h.chroma < 48. { 0.1 } else { 0.3 };
        scored.push((c, h, proportion * 100. * 0.7 + (h.chroma - 48.) * weight));
    }
    scored.sort_by(|a, b| b.2.total_cmp(&a.2));
    let mut chosen: Vec<(u32, Hct)> = Vec::new();
    for minimum in (15..=90).rev() {
        chosen.clear();
        for &(c, h, _) in &scored {
            if chosen.iter().all(|&(_, other)| {
                let d = (h.hue - other.hue).abs();
                d.min(360. - d) >= minimum as f64
            }) {
                chosen.push((c, h));
            }
            if chosen.len() >= desired {
                break;
            }
        }
        if chosen.len() >= desired {
            break;
        }
    }
    if chosen.is_empty() {
        vec![fallback]
    } else {
        chosen.into_iter().map(|(c, _)| c).collect()
    }
}
pub fn extract_source_color(pixels: &[[u8; 3]], fallback: u32) -> u32 {
    if pixels.is_empty() {
        return fallback;
    }
    let seeds = quantize_wu(pixels, 128);
    let colors = quantize_wsmeans(pixels, 128, &seeds);
    let filtered: Vec<_> = colors
        .iter()
        .copied()
        .filter(|&(c, _)| Cam16::from_rgb(source_color_to_rgb(c)).chroma >= 5.)
        .collect();
    score_colors(
        if filtered.is_empty() {
            &colors
        } else {
            &filtered
        },
        4,
        fallback,
    )[0]
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn empty_and_gray_fallback() {
        assert_eq!(extract_source_color(&[], FALLBACK_COLOR), FALLBACK_COLOR);
        assert_eq!(
            extract_source_color(&[[128; 3]; 30], FALLBACK_COLOR),
            FALLBACK_COLOR
        );
    }
    #[test]
    fn exact_single_color() {
        let pixels = vec![[200, 20, 70]; 80];
        assert_eq!(quantize_wu(&pixels, 128), vec![argb([200, 20, 70])]);
        assert_eq!(
            quantize_wsmeans(&pixels, 128, &quantize_wu(&pixels, 128)),
            vec![(argb([200, 20, 70]), 80)]
        );
        assert_eq!(
            extract_source_color(&pixels, FALLBACK_COLOR),
            argb([200, 20, 70])
        );
    }
    #[test]
    fn population_preserved() {
        let pixels = vec![[255, 0, 0], [0, 255, 0], [255, 0, 0], [0, 0, 255]];
        let out = quantize_wsmeans(&pixels, 3, &quantize_wu(&pixels, 3));
        assert_eq!(out.iter().map(|c| c.1).sum::<usize>(), 4);
        assert_eq!(out.len(), 3);
    }
}
