"""The attached dock's panel closes when the dock is turned off."""
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class StaticDockPanelTest(unittest.TestCase):
    def test_closes_when_dock_is_disabled(self):
        # Regression: `dock toggle` while the attached dock was showing left an empty panel open
        source = (ROOT / "Modules/Panels/Dock/StaticDockPanel.qml").read_text()
        self.assertIn("readonly property bool dockEnabled: Settings.data.dock.enabled", source)
        self.assertRegex(source, re.compile(r"onDockEnabledChanged:\s*\{\s*if \(!dockEnabled && isPanelOpen\)\s*close\(\);", re.S))


if __name__ == "__main__":
    unittest.main()
