"""Execute the production timer decision; no iOS/process-exit claim."""
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class DisconnectTimerPolicyRuntime(unittest.TestCase):
    def test_stale_timer_cannot_cancel_new_session(self):
        compiler = shutil.which("cc")
        if not compiler:
            self.skipTest("A C compiler is required for the production policy harness")
        source = Path(__file__).with_name("disconnect_timer_policy_runtime.c")
        with tempfile.TemporaryDirectory(prefix="duoface-disconnect-test-") as directory:
            binary = Path(directory) / "disconnect-timer-policy"
            subprocess.run(
                [compiler, "-std=c11", "-Wall", "-Wextra", "-Werror", "-pedantic",
                 str(source), "-o", str(binary)],
                check=True, capture_output=True, text=True,
            )
            result = subprocess.run(
                [str(binary)], check=True, capture_output=True, text=True,
            )
            self.assertIn("DF_DISCONNECT_TIMER_POLICY_RUNTIME_PASS", result.stdout)


if __name__ == "__main__":
    unittest.main(verbosity=2)
