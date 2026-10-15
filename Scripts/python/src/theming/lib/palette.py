"""Native palette extraction and small theme utilities."""
from .color import Color
from .native import request

RGB = tuple[int, int, int]


def extract_palette(pixels: list[RGB], k: int = 5, scoring: str = "population") -> list[Color]:
    return [Color.from_rgb(tuple(rgb)) for rgb in request("palette", pixels=pixels, k=k, scoring=scoring)]


def is_grayscale_image(pixels: list[RGB], threshold: float = 0.95, tolerance: int = 10) -> bool:
    if not pixels:
        return False
    return sum(max(pixel) - min(pixel) <= tolerance for pixel in pixels) / len(pixels) >= threshold


def find_error_color(palette: list[Color]) -> Color:
    for color in palette:
        hue, saturation, lightness = color.to_hsl()
        if (hue <= 30 or hue >= 330) and saturation > 0.4 and 0.3 < lightness < 0.7:
            return color
    return Color.from_hex("#FD4663")
