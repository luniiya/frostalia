use frostalia_theming::{
    palette::extract_palette,
    quantizer::{FALLBACK_COLOR, extract_source_color},
};
use serde_json::Value;
#[test]
fn palettes_match_original_python_on_wallpaper_patterns() {
    let fixture: Value =
        serde_json::from_str(include_str!("fixtures/python-palettes.json")).unwrap();
    for case in fixture["cases"].as_array().unwrap() {
        let name = case["name"].as_str().unwrap();
        let pixels: Vec<[u8; 3]> = serde_json::from_value(fixture["images"][name].clone()).unwrap();
        if let Some(source) = case.get("source") {
            assert_eq!(
                extract_source_color(&pixels, FALLBACK_COLOR),
                source.as_u64().unwrap() as u32,
                "source {name}"
            );
        } else {
            let scoring = case["scoring"].as_str().unwrap();
            let expected: Vec<[u8; 3]> = serde_json::from_value(case["palette"].clone()).unwrap();
            assert_eq!(
                extract_palette(&pixels, case["k"].as_u64().unwrap() as usize, scoring).unwrap(),
                expected,
                "palette {name} {scoring}"
            );
        }
    }
}
