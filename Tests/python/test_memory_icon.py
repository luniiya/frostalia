"""The RAM icon must resolve to the bundled Tabler memory glyph."""
import pathlib
import hashlib
import struct
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


def font_tables():
    font = (ROOT / "Assets/Fonts/tabler/frostalia-tabler-icons.ttf").read_bytes()
    count = struct.unpack_from(">H", font, 4)[0]
    tables = {}
    for index in range(count):
        tag, _, offset, length = struct.unpack_from(">4sIII", font, 12 + index * 16)
        tables[tag] = font[offset:offset + length]
    return tables


class MemoryIconTests(unittest.TestCase):
    def test_original_glyph_bounds_are_preserved(self):
        # This icon font deliberately stores padded bounds. Recalculating them
        # when adding a glyph shifts existing icons inside every button.
        tables = font_tables()
        long_offsets = struct.unpack_from(">h", tables[b"head"], 50)[0] == 1
        offset_format, size, multiplier = (">I", 4, 1) if long_offsets else (">H", 2, 2)
        bounds = []
        for index in range(5929):
            start = struct.unpack_from(offset_format, tables[b"loca"], index * size)[0] * multiplier
            end = struct.unpack_from(offset_format, tables[b"loca"], (index + 1) * size)[0] * multiplier
            bounds.append(tables[b"glyf"][start:start + 10] if end > start else b"")
        self.assertEqual(
            hashlib.sha256(b"".join(bounds)).hexdigest(),
            "debbf6beb3e848477c021ddd7e4429fb58528d820e14c6abf190740c2e8a40b5",
        )

    def test_memory_uses_its_own_glyph(self):
        source = (ROOT / "Commons/IconsTabler.qml").read_text()
        self.assertRegex(source, r'"memory": "\\u\{102b7\}"')
        self.assertNotRegex(source, r'"memory": "device-sd-card"')

    def test_memory_codepoint_is_in_the_bundled_font(self):
        # Supplementary codepoints use the font's format-12 cmap. Checking the
        # actual glyph prevents a valid QML mapping from rendering as a box.
        cmap = font_tables()[b"cmap"]
        subtable_count = struct.unpack_from(">H", cmap, 2)[0]
        codepoint = 0x102B7
        for index in range(subtable_count):
            _, _, offset = struct.unpack_from(">HHI", cmap, 4 + index * 8)
            if struct.unpack_from(">H", cmap, offset)[0] != 12:
                continue
            group_count = struct.unpack_from(">I", cmap, offset + 12)[0]
            for group in range(group_count):
                start, end, glyph = struct.unpack_from(">III", cmap, offset + 16 + group * 12)
                if start <= codepoint <= end:
                    self.assertGreater(glyph + codepoint - start, 0)
                    return
        self.fail("Tabler memory glyph is missing from the bundled font")
