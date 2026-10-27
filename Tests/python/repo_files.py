"""Files of the checkout itself, for tests that scan the whole tree."""
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]


def tracked(pattern):
    """Paths under the repo matching `pattern`, skipping hidden folders (.git, and
    .claude, where agents keep whole worktrees of the repo)."""
    for path in ROOT.rglob(pattern):
        if not any(part.startswith(".") for part in path.relative_to(ROOT).parts):
            yield path
