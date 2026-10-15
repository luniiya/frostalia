# Native theming helper

`frostalia-theming` handles image decoding, Wu/WSMeans source-color quantization,
Lab clustering and palette scoring. Python still generates theme tokens and
renders templates. It calls the helper through `lib/native.py`.

Build with `cargo build --release --locked --manifest-path Tools/theming/Cargo.toml`,
or run the repository installer. Set `FROSTALIA_THEMING_HELPER` to override the
binary location. The default is this crate's release executable.

Each invocation accepts one command and a JSON object on stdin, returns JSON on
stdout, and reports errors on stderr with a nonzero exit status:

| Command | Input | Result |
| --- | --- | --- |
| `image` | `path`, optional `resize_filter` (`Triangle` or `Box`) | RGB pixels |
| `png` | `path` | Original PNG RGB pixels |
| `palette` | `pixels`, optional `k` (default 5), `scoring` (default `population`) | Palette RGB colors |
| `source` | `pixels`, optional `fallback_color` (ARGB integer) | Source ARGB integer |

Image loading retains ImageMagick's 112 by 112 resizing, with native PNG decoding
when ImageMagick fails or is unavailable. Native PNG decoding also supports
grayscale and indexed images. Unsupported formats fail instead of sampling
compressed bytes as if they were pixels.

The fixtures preserve outputs from the Python implementation before this port:
four deterministic pixel patterns, all five scoring modes, source colors, and
dark/light theme tokens for all nine schemes. Color math tests include Python
HCT gamut vectors. Tiny palettes with tied colors now follow first-seen order
instead of Python set order. Empty input produces a fallback palette.

Run `Scripts/dev/run-tests.sh -silent` for native tests and Python integration
checks, including the actual helper process, image fallback and generated themes.
