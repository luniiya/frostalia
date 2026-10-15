"""Regression checks for the timer's compact duration controls."""

from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]


class TimerUiTests(unittest.TestCase):
    def test_duration_controls_have_labels_without_descriptions(self):
        for filename in ("Panel.qml", "Settings.qml"):
            source = (ROOT / "Plugins" / "timer" / filename).read_text()
            controls = re.findall(r"NSpinBox\s*\{([^{}]+)\}", source)
            for phase in ("work", "break"):
                with self.subTest(file=filename, phase=phase):
                    matches = [block for block in controls if f'pomodoro.{phase}-duration-label' in block]
                    self.assertEqual(len(matches), 1)
                    self.assertNotRegex(matches[0], r"\bdescription\s*:")
                    self.assertRegex(matches[0], r"\bdefaultValue\s*:")

    def test_panel_does_not_repeat_phase_under_timer(self):
        source = (ROOT / "Plugins" / "timer" / "Panel.qml").read_text()
        self.assertNotRegex(source, r'text:\s*pluginApi\?\.tr\(mainInstance\?\.pmPhase')
