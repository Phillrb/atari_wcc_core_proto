"""Exercise programming decisions with a fake Quartus executable, never hardware."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "scripts/program_as.py"


class ProgramASTest(unittest.TestCase):
    def exercise(self, scenario, *options):
        with tempfile.TemporaryDirectory(prefix="as test ") as temp:
            root = Path(temp)
            tool = root / "fake_quartus"
            tool.write_text("#!/usr/bin/env python3\n" + f"scenario={scenario!r}\n" + '''
import json, pathlib, sys
root=pathlib.Path(__file__).parent
with (root/'calls').open('a') as f: f.write(json.dumps(sys.argv[1:])+'\\n')
args=sys.argv[1:]
if args == ['-l']:
    if scenario != 'absent': print('1) USB-Blaster(Altera) [1-2]')
    if scenario == 'multiple': print('2) USB-Blaster [1-3]')
else:
    assert args[2:4] == ['-m', 'AS']
    op=args[-1]
    if op.startswith('e;'):
        if scenario == 'unreachable':
            print("Error (209040): Can't access JTAG chain"); sys.exit(3)
        if scenario != 'no_backup': pathlib.Path(op.split(';')[1]).write_bytes(b'flash backup')
    elif op.startswith('pv;'):
        if scenario == 'verify_fail': print('Error: Verification failed'); sys.exit(3)
    else: sys.exit(4)
''')
            tool.chmod(0o755)
            pof = root / "diagnostic image.pof"
            pof.write_bytes(b"test fixture")
            result = subprocess.run([sys.executable, str(SCRIPT), str(pof),
                                     "--quartus-pgm", str(tool), "--log-dir", str(root / "logs"),
                                     *options], capture_output=True, text=True)
            calls = [json.loads(line) for line in (root / "calls").read_text().splitlines()]
            return result, calls

    def test_success_backs_up_before_program_and_verify(self):
        result, calls = self.exercise("success")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(calls[1][-1].startswith("e;"))
        self.assertTrue(calls[2][-1].startswith("pv;"))
        self.assertIn("SUCCESS", result.stdout)

    def test_check_only_never_programs(self):
        result, calls = self.exercise("success", "--check-only")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(calls), 2)

    def test_absent_or_ambiguous_cable_never_reads_or_programs(self):
        for scenario in ("absent", "multiple"):
            with self.subTest(scenario=scenario):
                result, calls = self.exercise(scenario)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(len(calls), 1)

    def test_selected_cable(self):
        result, calls = self.exercise("multiple", "--cable", "2")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls[1][1], "USB-Blaster [1-3]")

    def test_failed_or_empty_read_blocks_programming(self):
        for scenario in ("unreachable", "no_backup"):
            with self.subTest(scenario=scenario):
                result, calls = self.exercise(scenario)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(len(calls), 2)

    def test_verify_failure_is_not_success(self):
        result, calls = self.exercise("verify_fail")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(calls), 3)
        self.assertNotIn("SUCCESS", result.stdout)


if __name__ == "__main__":
    unittest.main()
