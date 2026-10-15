"""Image loading through Frostalia's Rust helper."""
from pathlib import Path
from .native import request

RGB = tuple[int, int, int]


class ImageReadError(Exception):
    """Raised when an image cannot be decoded."""


def _read(command: str, path: Path, **options) -> list[RGB]:
    try:
        return [tuple(pixel) for pixel in request(command, path=str(path), **options)]
    except RuntimeError as error:
        raise ImageReadError(str(error)) from error


def read_image(path: Path, resize_filter: str = "Triangle") -> list[RGB]:
    return _read("image", path, resize_filter=resize_filter)


def read_png(path: Path) -> list[RGB]:
    return _read("png", path)
