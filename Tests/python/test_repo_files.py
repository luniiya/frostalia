import unittest

import repo_files


class TrackedTests(unittest.TestCase):
    # Regression: agent worktrees under .claude/ made every whole-tree scan fail on
    # someone else's work in progress
    def test_skips_hidden_folders(self):
        paths = [p.relative_to(repo_files.ROOT).parts for p in repo_files.tracked("*.qml")]
        self.assertTrue(paths)
        self.assertFalse([p for p in paths if any(part.startswith(".") for part in p)])
        self.assertIn(("shell.qml",), paths)


if __name__ == "__main__":
    unittest.main()
