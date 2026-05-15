from __future__ import annotations

import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
BIN_WRAPPER = ROOT / "bin" / "pg"
SCRIPT_WRAPPER = ROOT / "scripts" / "pg.py"


class WrapperCommandTests(unittest.TestCase):
    def test_bin_wrapper_runs_outside_repo_root(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            completed = subprocess.run(
                [str(BIN_WRAPPER), "--show", "--no-clipboard", "--length", "12"],
                cwd=temp_dir,
                text=True,
                capture_output=True,
                check=True,
            )

        self.assertEqual(len(completed.stdout.strip()), 12)
        self.assertEqual(completed.stderr, "")

    def test_legacy_script_wrapper_runs_outside_repo_root(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            completed = subprocess.run(
                [
                    "python3",
                    str(SCRIPT_WRAPPER),
                    "--show",
                    "--no-clipboard",
                    "--length",
                    "12",
                ],
                cwd=temp_dir,
                text=True,
                capture_output=True,
                check=True,
            )

        self.assertEqual(len(completed.stdout.strip()), 12)
        self.assertEqual(completed.stderr, "")


if __name__ == "__main__":
    unittest.main()
