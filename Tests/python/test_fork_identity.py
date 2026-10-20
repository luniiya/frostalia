"""Protect external dependency identities and resolve renamed shell imports/assets."""
import json
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class ForkIdentityTests(unittest.TestCase):
    def test_quickshell_dependency_still_resolves_upstream(self):
        lock = json.loads((ROOT / "flake.lock").read_text())
        for source in ("locked", "original"):
            self.assertEqual(lock["nodes"]["noctalia-qs"][source]["owner"], "noctalia-dev")
            self.assertEqual(lock["nodes"]["noctalia-qs"][source]["repo"], "noctalia-qs")
        self.assertIn('github:noctalia-dev/noctalia-qs', (ROOT / "flake.nix").read_text())

    def test_shell_module_imports_resolve(self):
        for path in ROOT.rglob("*.qml"):
            for module in re.findall(r"^import qs\.([\w.]+)", path.read_text(), re.MULTILINE):
                self.assertTrue((ROOT / module.replace(".", "/")).is_dir(), f"{path}: {module}")

    def test_branded_assets_exist(self):
        for path in ROOT.rglob("*.qml"):
            for asset in re.findall(r"(/Assets/[\w/.-]*[Ff]rostalia[\w/.-]*)", path.read_text()):
                self.assertTrue((ROOT / asset.lstrip("/")).exists(), f"{path}: {asset}")

    def test_no_upstream_telemetry_or_donation_services(self):
        for service in ("TelemetryService.qml", "SupporterService.qml"):
            self.assertFalse((ROOT / "Services/Frostalia" / service).exists())
        service = (ROOT / "Services/Frostalia/UpdateService.qml").read_text()
        self.assertNotIn("api.noctalia.dev/upgradelog", service)
        self.assertFalse((ROOT / "Modules/Panels/Settings/Tabs/About/SupportersSubTab.qml").exists())


if __name__ == "__main__":
    unittest.main()
