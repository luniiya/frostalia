//! sRGB, HSL and CIELAB conversions used by palette extraction.
//! Constants and operation order follow the existing theme engine.
pub type Rgb = [u8; 3];
pub type Lab = [f64; 3];

pub fn rgb_to_hsl([r, g, b]: Rgb) -> [f64; 3] {
    let (r, g, b) = (r as f64 / 255.0, g as f64 / 255.0, b as f64 / 255.0);
    let max = r.max(g).max(b);
    let min = r.min(g).min(b);
    let delta = max - min;
    let l = (max + min) / 2.0;
    if delta == 0.0 {
        return [0.0, 0.0, l];
    }
    let s = if l != 0.0 && l != 1.0 {
        delta / (1.0 - (2.0 * l - 1.0).abs())
    } else {
        0.0
    };
    let h = if max == r {
        60.0 * ((g - b) / delta).rem_euclid(6.0)
    } else if max == g {
        60.0 * ((b - r) / delta + 2.0)
    } else {
        60.0 * ((r - g) / delta + 4.0)
    };
    [h, s, l]
}

pub fn hsl_to_rgb([h, s, l]: [f64; 3]) -> Rgb {
    if s == 0.0 {
        return [(l * 255.0).round_ties_even() as u8; 3];
    }
    fn component(p: f64, q: f64, mut t: f64) -> u8 {
        if t < 0.0 {
            t += 1.0;
        }
        if t > 1.0 {
            t -= 1.0;
        }
        let value = if t < 1.0 / 6.0 {
            p + (q - p) * 6.0 * t
        } else if t < 0.5 {
            q
        } else if t < 2.0 / 3.0 {
            p + (q - p) * (2.0 / 3.0 - t) * 6.0
        } else {
            p
        };
        (value * 255.0).round_ties_even() as u8
    }
    let q = if l < 0.5 {
        l * (1.0 + s)
    } else {
        l + s - l * s
    };
    let p = 2.0 * l - q;
    let h = h / 360.0;
    [
        component(p, q, h + 1.0 / 3.0),
        component(p, q, h),
        component(p, q, h - 1.0 / 3.0),
    ]
}

pub fn hue_distance(a: f64, b: f64) -> f64 {
    let d = (a - b).abs();
    d.min(360.0 - d)
}

fn linearize(c: u8) -> f64 {
    let c = c as f64 / 255.0;
    if c <= 0.04045 {
        c / 12.92
    } else {
        ((c + 0.055) / 1.055).powf(2.4)
    }
}
fn delinearize(c: f64) -> u8 {
    let c = c.clamp(0.0, 1.0);
    let v = if c <= 0.0031308 {
        c * 12.92
    } else {
        1.055 * c.powf(1.0 / 2.4) - 0.055
    };
    (v * 255.0).round_ties_even().clamp(0.0, 255.0) as u8
}
fn lab_f(t: f64) -> f64 {
    if t > 0.008856 {
        t.powf(1.0 / 3.0)
    } else {
        (903.3 * t + 16.0) / 116.0
    }
}
fn lab_f_inv(t: f64) -> f64 {
    if t > 0.206893 {
        t * t * t
    } else {
        (116.0 * t - 16.0) / 903.3
    }
}
pub fn rgb_to_lab(rgb: Rgb) -> Lab {
    let [r, g, b] = rgb.map(linearize);
    let x = (0.4124564 * r + 0.3575761 * g + 0.1804375 * b) * 100.0;
    let y = (0.2126729 * r + 0.7151522 * g + 0.0721750 * b) * 100.0;
    let z = (0.0193339 * r + 0.1191920 * g + 0.9503041 * b) * 100.0;
    let (fx, fy, fz) = (lab_f(x / 95.047), lab_f(y / 100.0), lab_f(z / 108.883));
    [116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz)]
}
pub fn lab_to_rgb([l, a, b]: Lab) -> Rgb {
    let fy = (l + 16.0) / 116.0;
    let fx = a / 500.0 + fy;
    let fz = fy - b / 200.0;
    let (x, y, z) = (
        95.047 * lab_f_inv(fx) / 100.0,
        100.0 * lab_f_inv(fy) / 100.0,
        108.883 * lab_f_inv(fz) / 100.0,
    );
    [
        delinearize(3.2404542 * x - 1.5371385 * y - 0.4985314 * z),
        delinearize(-0.9692660 * x + 1.8760108 * y + 0.0415560 * z),
        delinearize(0.0556434 * x - 0.2040259 * y + 1.0572252 * z),
    ]
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn python_conversion_vectors() {
        let cases: &[(Rgb, Lab, [f64; 3])] = &[
            ([0, 0, 0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]),
            (
                [255, 255, 255],
                [
                    100.00000386666655,
                    -1.6666666158293708e-05,
                    6.666666463317483e-06,
                ],
                [0.0, 0.0, 1.0],
            ),
            (
                [255, 0, 0],
                [53.24079414130722, 80.09245959641109, 67.20319651585301],
                [0.0, 1.0, 0.5],
            ),
            (
                [0, 255, 0],
                [87.73472235279792, -86.1827164205346, 83.17932050269783],
                [120.0, 1.0, 0.5],
            ),
            (
                [0, 0, 255],
                [32.29701093285073, 79.18751984512221, -107.8601617541481],
                [240.0, 1.0, 0.5],
            ),
            (
                [128, 128, 128],
                [
                    53.585015771669404,
                    -9.997846384113274e-06,
                    3.9991385536453095e-06,
                ],
                [0.0, 0.0, 0.5019607843137255],
            ),
            (
                [10, 11, 12],
                [
                    2.9846422795113057,
                    -0.11700125222524616,
                    -0.5059194158199276,
                ],
                [210.0, 0.09090909090909088, 0.043137254901960784],
            ),
            (
                [1, 2, 3],
                [
                    0.5098307617282813,
                    -0.12244785530925173,
                    -0.4705977183223409,
                ],
                [210.0, 0.5000000000000018, 0.00784313725490196],
            ),
            (
                [251, 127, 64],
                [66.56881840216292, 43.1083587770314, 54.385960718461924],
                [20.21390374331551, 0.958974358974359, 0.6176470588235294],
            ),
            (
                [73, 37, 165],
                [27.995414706175794, 47.960671870524884, -62.57738871297379],
                [256.875, 0.6336633663366336, 0.39607843137254906],
            ),
            (
                [255, 255, 0],
                [97.13926722430631, -21.553748216377123, 94.47797505367028],
                [60.0, 1.0, 0.5],
            ),
            (
                [255, 0, 255],
                [60.32421212836874, 98.23431188800402, -60.82489220885006],
                [300.0, 1.0, 0.5],
            ),
        ];
        for &(rgb, lab, hsl) in cases {
            for (actual, expected) in rgb_to_lab(rgb).into_iter().zip(lab) {
                assert!(
                    (actual - expected).abs() < 1e-10,
                    "{rgb:?}: {actual} != {expected}"
                );
            }
            for (actual, expected) in rgb_to_hsl(rgb).into_iter().zip(hsl) {
                assert!((actual - expected).abs() < 1e-10);
            }
            assert_eq!(lab_to_rgb(lab), rgb);
            assert_eq!(hsl_to_rgb(hsl), rgb);
        }
    }
    #[test]
    fn python_rounding_and_hue_boundaries() {
        assert_eq!(hsl_to_rgb([0.0, 0.0, 0.5 / 255.0]), [0; 3]);
        assert_eq!(hsl_to_rgb([0.0, 0.0, 2.5 / 255.0]), [2; 3]);
        assert_eq!(hsl_to_rgb([0.0, 0.0, 3.5 / 255.0]), [4; 3]);
        assert_eq!(hsl_to_rgb([360.0, 1.0, 0.5]), [255, 0, 0]);
        assert_eq!(hue_distance(359.0, 1.0), 2.0);
        assert_eq!(hue_distance(0.0, 180.0), 180.0);
        assert_eq!(lab_to_rgb([0.0, 0.0, 0.0]), [0; 3]);
        assert_eq!(lab_to_rgb([100.0, 0.0, 0.0]), [255; 3]);
    }
}
