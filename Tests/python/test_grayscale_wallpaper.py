"""Tests for grayscale wallpaper detection used by palette generation."""

import pathlib
import sys
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts" / "python" / "src" / "theming"))

from lib.palette import is_grayscale_image


class GrayscaleWallpaperTests(unittest.TestCase):
    def test_pure_grayscale_is_detected(self):
        self.assertTrue(is_grayscale_image([(0, 0, 0), (127, 127, 127), (255, 255, 255)]))

    def test_compression_noise_and_five_percent_color_are_tolerated(self):
        pixels = [(120, 125, 121)] * 95 + [(255, 0, 0)] * 5
        self.assertTrue(is_grayscale_image(pixels))

    def test_more_than_five_percent_color_is_not_overridden(self):
        pixels = [(120, 120, 120)] * 94 + [(255, 0, 0)] * 6
        self.assertFalse(is_grayscale_image(pixels))

    def test_empty_image_is_not_grayscale(self):
        self.assertFalse(is_grayscale_image([]))
