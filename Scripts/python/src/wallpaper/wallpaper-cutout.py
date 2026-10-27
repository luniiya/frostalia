#!/usr/bin/env python3
"""Cut the subject out of a wallpaper, for the wallpaper visualizer's depth effect.

    wallpaper-cutout.py IMAGE CACHE_DIR

Prints one JSON line: {"source", "separable", "model", "image", "coverage"}. When the
wallpaper has a clear subject, "image" is a PNG of the wallpaper with everything but
the subject transparent; the shell draws it over the visualizer. Results are cached
in CACHE_DIR per file version, so only the first run for a wallpaper does any work.

Needs rembg, which the shell provides through `uv run --with rembg[cpu]`. The
decision logic below is plain Python so it can be tested without it.
"""

import hashlib
import json
import os
import pathlib
import sys

# rembg models, tried together; the cleaner mask wins. The anime model is precise
# on drawn characters and blank on everything else, the general one the reverse.
MODELS = ("isnet-anime", "isnet-general-use")

# Masks are measured at this size (calibrated on the maintainer's wallpapers)
STATS_SIZE = (128, 72)
# A subject covers part of the picture, not a speck and not the whole frame
MIN_COVERAGE = 0.02
MAX_COVERAGE = 0.7
# Pixels the model is unsure about, relative to the subject: fuzzy masks of scenes
# and close-ups score well above this, clean subjects below
MAX_UNSURE_RATIO = 0.8
# The cut-out never needs more pixels than a 4K screen
MAX_SIDE = 3840
# Cached results kept; older ones are deleted
KEEP_ENTRIES = 30
CACHE_VERSION = 1

ANIMATED_SUFFIXES = (".gif",)


def mask_stats(pixels):
    """Coverage and unsure share of 8-bit mask pixels."""
    pixels = list(pixels)
    if not pixels:
        return {"coverage": 0.0, "unsure": 0.0}
    subject = sum(1 for v in pixels if v > 127)
    unsure = sum(1 for v in pixels if 32 < v < 224)
    return {"coverage": subject / len(pixels), "unsure": unsure / len(pixels)}


def score(stats):
    """Lower is cleaner; None when the mask does not show a separable subject."""
    coverage = stats["coverage"]
    if coverage < MIN_COVERAGE or coverage > MAX_COVERAGE:
        return None
    ratio = stats["unsure"] / coverage
    return ratio if ratio <= MAX_UNSURE_RATIO else None


def pick(candidates):
    """Model with the cleanest separable mask, or None. candidates: {model: stats}."""
    scored = [(score(stats), model) for model, stats in candidates.items()]
    scored = [entry for entry in scored if entry[0] is not None]
    return min(scored)[1] if scored else None


def is_animated(path, frames=1):
    return pathlib.Path(path).suffix.lower() in ANIMATED_SUFFIXES or frames > 1


def cache_key(path, mtime_ns, size):
    text = f"{CACHE_VERSION}:{os.path.abspath(path)}:{mtime_ns}:{size}"
    return hashlib.sha1(text.encode()).hexdigest()[:24]


def stale_entries(entries, keep=KEEP_ENTRIES):
    """Keys to delete, oldest first. entries: {key: mtime}."""
    ordered = sorted(entries, key=lambda key: entries[key], reverse=True)
    return sorted(ordered[keep:], key=lambda key: entries[key])


def result(source, model=None, image="", coverage=0.0):
    return {"source": source, "separable": bool(image), "model": model, "image": image, "coverage": round(coverage, 4)}


def prune(cache):
    entries = {path.stem: path.stat().st_mtime for path in cache.glob("*.json")}
    for key in stale_entries(entries):
        for suffix in (".json", ".png"):
            (cache / (key + suffix)).unlink(missing_ok=True)


def cut(source, cache, key):
    from PIL import Image
    from rembg import new_session, remove

    with Image.open(source) as opened:
        if is_animated(source, getattr(opened, "n_frames", 1)):
            return result(source)
        image = opened.convert("RGB")
    image.thumbnail((MAX_SIDE, MAX_SIDE))
    # Models work at about 1024 px; a smaller input is as good and much faster
    small = image.copy()
    small.thumbnail((1024, 1024))
    masks, candidates = {}, {}
    for model in MODELS:
        mask = remove(small, session=new_session(model), only_mask=True).convert("L")
        masks[model] = mask
        candidates[model] = mask_stats(mask.resize(STATS_SIZE).getdata())
    model = pick(candidates)
    if model is None:
        return result(source)
    alpha = masks[model].resize(image.size, Image.Resampling.LANCZOS)
    # Black under fully transparent pixels: invisible, and it compresses to almost nothing
    image = Image.composite(image, Image.new("RGB", image.size), alpha.point(lambda v: 255 if v else 0))
    image.putalpha(alpha)
    target = cache / (key + ".png")
    image.save(target, compress_level=6)
    return result(source, model, str(target), candidates[model]["coverage"])


def main(argv):
    if len(argv) != 3:
        print(__doc__.strip().splitlines()[2].strip(), file=sys.stderr)
        return 2
    source, cache = argv[1], pathlib.Path(argv[2])
    cache.mkdir(parents=True, exist_ok=True)
    stat = os.stat(source)
    key = cache_key(source, stat.st_mtime_ns, stat.st_size)
    record = cache / (key + ".json")
    if record.exists():
        print(record.read_text().strip())
        return 0
    output = result(source) if is_animated(source) else cut(source, cache, key)
    record.write_text(json.dumps(output))
    prune(cache)
    print(json.dumps(output))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
