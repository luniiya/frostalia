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
        self.tools = self.checkout / "Tools/settings"
        (self.tools / "src").mkdir(parents=True)
        (self.tools / "Cargo.toml").write_text("manifest")
        (self.tools / "Cargo.lock").write_text("lock")
        (self.tools / "src/main.rs").write_text("source")
        self.helper = self.tools / "target/release/frostalia-settings"
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.executable("qs", "#!/bin/sh\nexit 0\n")
        self.executable("cargo", '''#!/bin/sh
printf '%s\\n' "$*" >> "$BUILD_LOG"
[ "${FAIL_BUILD:-0}" = 0 ] || exit 9
mkdir -p "$CARGO_TARGET_DIR/release"
printf '#!/bin/sh\\nexit 0\\n' > "$CARGO_TARGET_DIR/release/frostalia-settings"
chmod +x "$CARGO_TARGET_DIR/release/frostalia-settings"
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
        self.assertTrue(self.helper.is_file())
        self.assertEqual(self.target.resolve(), self.checkout)
        self.assertIn("build --release --locked --manifest-path", (self.root / "build.log").read_text())

    def test_current_helper_does_not_rebuild(self):
        self.assertEqual(self.run_install().returncode, 0)
        (self.root / "build.log").unlink()
        self.assertEqual(self.run_install().returncode, 0)
        self.assertFalse((self.root / "build.log").exists())

    def test_changed_source_rebuilds(self):
        self.assertEqual(self.run_install().returncode, 0)
        (self.root / "build.log").unlink()
        newer = self.helper.stat().st_mtime + 10
        os.utime(self.tools / "src/main.rs", (newer, newer))
        self.assertEqual(self.run_install().returncode, 0)
        self.assertTrue((self.root / "build.log").exists())

    def test_failed_build_preserves_existing_installation(self):
        self.target.mkdir(parents=True)
        marker = self.target / "keep.txt"
        marker.write_text("keep")
        self.env["FAIL_BUILD"] = "1"
        result = self.run_install()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(marker.read_text(), "keep")
        self.assertEqual(list(self.target.parent.glob("frostalia.bak-*")), [])

    def test_copy_includes_helper_without_git_or_cargo_cache(self):
        self.assertEqual(self.run_install().returncode, 0)
        (self.checkout / ".git").mkdir()
        (self.checkout / ".git/config").write_text("private")
        (self.tools / "target/release/cache").write_text("cache")
        result = self.run_install("--copy")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.target.is_symlink())
        self.assertTrue((self.target / "Tools/settings/target/release/frostalia-settings").is_file())
        self.assertFalse((self.target / "Tools/settings/target/release/cache").exists())
        self.assertFalse((self.target / ".git").exists())


if __name__ == "__main__":
    unittest.main()
