"""Transport to the native wallpaper and palette helper."""
import json
import os
from pathlib import Path
import subprocess


def request(command: str, **payload):
    helper = os.environ.get("FROSTALIA_THEMING_HELPER") or str(
        Path(__file__).resolve().parents[5] / "Tools/theming/target/release/frostalia-theming"
    )
    try:
        result = subprocess.run(
            [helper, command], input=json.dumps(payload), text=True, capture_output=True
        )
    except OSError as error:
        raise RuntimeError(
            "Cannot start frostalia-theming. Run ./install.sh --no-restart "
            "to build the Rust helper."
        ) from error
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "frostalia-theming failed")
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise RuntimeError("Invalid response from frostalia-theming") from error
