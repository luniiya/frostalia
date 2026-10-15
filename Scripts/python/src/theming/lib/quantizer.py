"""Material source-color extraction through the native quantizer."""
from .native import request

RGB = tuple[int, int, int]


def extract_source_color(pixels: list[RGB], fallback_color: int = 0xFF4285F4) -> int:
    return request("source", pixels=pixels, fallback_color=fallback_color)


def source_color_to_rgb(argb: int) -> RGB:
    return ((argb >> 16) & 255, (argb >> 8) & 255, argb & 255)
