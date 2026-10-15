"""Exercise installation without touching the user's shell or config."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[2]


class InstallationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.checkout = self.root / "checkout"
        self.checkout.mkdir()
        shutil.copy2(REPO / "install.sh", self.checkout / "install.sh")
        self.crates = {}
        self.helpers = {}
        for name in ("settings", "theming"):
            tools = self.checkout / "Tools" / name
            (tools / "src").mkdir(parents=True)
            (tools / "Cargo.toml").write_text("manifest")
            (tools / "Cargo.lock").write_text("lock")
            (tools / "src/main.rs").write_text("source")
            self.crates[name] = tools
            self.helpers[name] = tools / f"target/release/frostalia-{name}"
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.executable("qs", "#!/bin/sh\nexit 0\n")
        self.executable("cargo", '''#!/bin/sh
printf '%s\\n' "$*" >> "$BUILD_LOG"
[ "${FAIL_BUILD:-0}" = 0 ] || exit 9
name="$(basename "$(dirname "$CARGO_TARGET_DIR")")"
[ "${FAIL_HELPER:-}" != "$name" ] || exit 9
mkdir -p "$CARGO_TARGET_DIR/release"
printf '#!/bin/sh\\nexit 0\\n' > "$CARGO_TARGET_DIR/release/frostalia-$name"
chmod +x "$CARGO_TARGET_DIR/release/frostalia-$name"
''')
        self.config = self.root / "config"
        self.target = self.config / "quickshell/frostalia"
        self.env = dict(os.environ, PATH=f"{self.bin}:{os.environ['PATH']}",
                        XDG_CONFIG_HOME=str(self.config), BUILD_LOG=str(self.root / "build.log"))

    def executable(self, name, contents):
        file = self.bin / name
        file.write_text(contents)
        file.chmod(0o755)

    def run_install(self, *args):
        return subprocess.run(["bash", str(self.checkout / "install.sh"), "--no-restart", *args],
                              env=self.env, capture_output=True, text=True)

    def test_first_install_builds_before_linking(self):
        result = self.run_install()
        self.assertEqual(result.returncode, 0, result.stderr)
        for helper in self.helpers.values():
            self.assertTrue(helper.is_file())
        self.assertEqual(self.target.resolve(), self.checkout)
        log = (self.root / "build.log").read_text()
        for name in self.crates:
            self.assertIn(f"build --release --locked --manifest-path {self.crates[name]}/Cargo.toml", log)

    def test_current_helper_does_not_rebuild(self):
        self.assertEqual(self.run_install().returncode, 0)
        (self.root / "build.log").unlink()
        self.assertEqual(self.run_install().returncode, 0)
        self.assertFalse((self.root / "build.log").exists())

    def test_changed_source_rebuilds_only_changed_helper(self):
        self.assertEqual(self.run_install().returncode, 0)
        for name, helper in self.helpers.items():
            with self.subTest(helper=name):
                (self.root / "build.log").unlink()
                source = self.crates[name] / "src/main.rs"
                newer = helper.stat().st_mtime + 10
                os.utime(source, (newer, newer))
                self.assertEqual(self.run_install().returncode, 0)
                log = (self.root / "build.log").read_text().splitlines()
                self.assertEqual(len(log), 1)
                self.assertIn(str(self.crates[name] / "Cargo.toml"), log[0])
                # The fake build completes immediately, so reset the future timestamp.
                os.utime(source, (0, 0))

    def test_failed_build_preserves_existing_installation(self):
        self.target.mkdir(parents=True)
        marker = self.target / "keep.txt"
        marker.write_text("keep")
        self.env["FAIL_BUILD"] = "1"
        result = self.run_install()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(marker.read_text(), "keep")
        self.assertEqual(list(self.target.parent.glob("frostalia.bak-*")), [])

    def test_failed_theming_build_preserves_existing_installation(self):
        self.target.mkdir(parents=True)
        marker = self.target / "keep.txt"
        marker.write_text("keep")
        self.env["FAIL_HELPER"] = "theming"
        result = self.run_install()
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(self.helpers["settings"].exists())
        self.assertEqual(marker.read_text(), "keep")
        self.assertEqual(list(self.target.parent.glob("frostalia.bak-*")), [])

    def test_copy_includes_helpers_without_git_or_cargo_caches(self):
        self.assertEqual(self.run_install().returncode, 0)
        (self.checkout / ".git").mkdir()
        (self.checkout / ".git/config").write_text("private")
        for tools in self.crates.values():
            (tools / "target/release/cache").write_text("cache")
        result = self.run_install("--copy")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.target.is_symlink())
        for name in self.crates:
            self.assertTrue((self.target / f"Tools/{name}/target/release/frostalia-{name}").is_file())
            self.assertFalse((self.target / f"Tools/{name}/target/release/cache").exists())
        self.assertFalse((self.target / ".git").exists())


if __name__ == "__main__":
    unittest.main()
