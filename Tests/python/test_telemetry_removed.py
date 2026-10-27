"""Telemetry has no runtime service, setting, state or user interface."""
import pathlib
import re
import unittest

import settings_defaults

ROOT = pathlib.Path(__file__).resolve().parents[2]


class TelemetryRemovalTests(unittest.TestCase):
    def test_no_runtime_telemetry_references(self):
        for path in ROOT.rglob("*.qml"):
            if "Tests" in path.relative_to(ROOT).parts or path.name == "Migration70.qml":
                continue
            with self.subTest(path=str(path.relative_to(ROOT))):
                self.assertNotRegex(path.read_text(), r"(?i)telemetry")
        defaults = settings_defaults.defaults()
        self.assertNotIn("telemetryEnabled", defaults["general"])
        self.assertFalse((ROOT / "Services/Frostalia/TelemetryService.qml").exists())

    def test_setup_retains_four_normal_steps(self):
        wizard = (ROOT / "Modules/Panels/SetupWizard/SetupWizard.qml").read_text()
        self.assertIn("totalSteps: 4", wizard)
        self.assertIn("Settings.data.general.scaleRatio = selectedScaleRatio", wizard)
        self.assertIn("Settings.data.bar.position = selectedBarPosition", wizard)
        self.assertIn("Settings.saveImmediate()", wizard)

    def test_removal_migration_is_registered(self):
        settings = (ROOT / "Commons/Settings.qml").read_text()
        version = int(re.search(r"readonly property int settingsVersion: (\d+)", settings).group(1))
        self.assertGreaterEqual(version, 70)
        registry = (ROOT / "Commons/Migrations/MigrationRegistry.qml").read_text()
        self.assertIn("70: migration70Component", registry)
        self.assertIn("migration70Component: Migration70", registry)
