"""Release notes belong to Frostalia and are opened only on request."""
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class ChangelogTests(unittest.TestCase):
    def test_manual_changelog_opens_project_releases(self):
        service = (ROOT / "Services/Frostalia/UpdateService.qml").read_text()
        self.assertIn('releasesUrl: "https://github.com/luniiya/frostalia/releases"', service)
        self.assertRegex(service, r'function viewChangelog\(\)\s*\{\s*Quickshell.execDetached\(\["xdg-open", releasesUrl\]\);\s*\}')
        about = (ROOT / "Modules/Panels/Settings/Tabs/About/VersionSubTab.qml").read_text()
        self.assertIn("onClicked: UpdateService.viewChangelog()", about)

    def test_startup_has_no_release_notes_or_upgrade_telemetry_prompt(self):
        shell = (ROOT / "shell.qml").read_text()
        self.assertNotRegex(shell, r'UpdateService\.(?:viewChangelog|showLatestChangelog|checkTelemetryWizardOrChangelog|shouldShowTelemetryWizard)\(')
        self.assertIn("if (!Settings.shouldOpenSetupWizard)", shell)
        self.assertIn("setupPanel.open();", shell)
        service = (ROOT / "Services/Frostalia/UpdateService.qml").read_text()
        for obsolete in ("XMLHttpRequest", "popupScheduled", "changelogLastSeenVersion", "telemetryWizardNeeded"):
            self.assertNotIn(obsolete, service)

    def test_shell_state_no_longer_tracks_release_notifications(self):
        state = (ROOT / "Commons/ShellState.qml").read_text()
        self.assertNotIn("changelogState", state)
        self.assertNotIn("getChangelogState", state)
        self.assertNotIn("setChangelogState", state)

    def test_removed_popup_has_no_remaining_imports_or_calls(self):
        for path in ROOT.rglob("*.qml"):
            self.assertNotRegex(path.read_text(), r'(?:qs.Modules.Panels.Changelog|ChangelogPanel\s*\{|UpdateService\.markChangelogSeen\()', str(path))


if __name__ == "__main__":
    unittest.main()
