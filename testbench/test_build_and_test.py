"""Failure-path tests for build automation; no Quartus or FPGA required."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('build_and_test', Path(__file__).resolve().parents[1] / 'scripts/build_and_test.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class PipelineTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.pipeline = module.Pipeline(self.root, 'test', timeout=2, heartbeat=1)

    def tearDown(self):
        self.temp.cleanup()

    def run_stage(self, code, **kw):
        self.pipeline.stage('fixture', [sys.executable, '-c', code], self.root, **kw)

    def test_completion_and_artifact_required(self):
        artifact = self.root / 'image.pof'
        self.run_stage("from pathlib import Path; Path('image.pof').write_text('image'); print('COMPLETE')",
                       expected=['COMPLETE'], artifacts=[artifact])
        report = json.loads((self.root / 'report.json').read_text())
        self.assertEqual(report['stages'][0]['status'], 'PASS')
        self.assertEqual(report['visual_review'], 'NOT_RUN')

    def test_nonzero_exit_fails(self):
        with self.assertRaises(RuntimeError):
            self.run_stage("print('COMPLETE'); raise SystemExit(2)", expected=['COMPLETE'])
        self.assertEqual(self.pipeline.report['stages'][0]['status'], 'FAILED')

    def test_error_text_fails_even_with_zero_exit(self):
        with self.assertRaises(RuntimeError):
            self.run_stage("print('Error (123): synthetic failure')")

    def test_warnings_are_reported_without_claiming_failure(self):
        self.run_stage("print('Warning (123): example')")
        self.assertEqual(self.pipeline.report['stages'][0]['status'], 'PASS')
        self.assertIn('1 warning lines', (self.root / 'summary.txt').read_text())

    def test_missing_completion_fails(self):
        with self.assertRaises(RuntimeError):
            self.run_stage("print('simulation stopped by stop-time')", expected=['TEST PASSED'])

    def test_missing_or_empty_artifact_fails(self):
        path = self.root / 'image.pof'
        for code in ("print('ok')", "from pathlib import Path; Path('image.pof').touch()"):
            with self.assertRaises(RuntimeError):
                self.run_stage(code, artifacts=[path])

    def test_timeout_records_failure(self):
        self.pipeline.timeout = 0.1
        self.pipeline.heartbeat = 0.1
        with self.assertRaises(TimeoutError):
            self.run_stage('import time; time.sleep(60)')
        self.assertEqual(self.pipeline.report['stages'][0]['status'], 'FAILED')

    def test_snapshot_includes_dirty_and_new_sources_but_not_ignored_products(self):
        repo = self.root / 'repo'
        repo.mkdir()
        subprocess.run(['git', 'init', '-q', str(repo)], check=True)
        (repo / 'circuit.vhd').write_text('old')
        subprocess.run(['git', 'add', 'circuit.vhd'], cwd=repo, check=True)
        (repo / 'circuit.vhd').write_text('new')
        (repo / 'new.vhd').write_text('new circuit')
        (repo / '.gitignore').write_text('output_files/\n')
        (repo / 'output_files').mkdir()
        (repo / 'output_files/stale.vhd').write_text('stale')
        dest = self.root / 'snapshot'
        hashes = module.snapshot(repo, dest)
        self.assertEqual((dest / 'circuit.vhd').read_text(), 'new')
        self.assertIn('new.vhd', hashes)
        self.assertNotIn('output_files/stale.vhd', hashes)
        (repo / 'circuit.vhd').write_text('later edit')
        self.assertEqual((dest / 'circuit.vhd').read_text(), 'new')

    def test_snapshot_rejects_missing_quartus_input(self):
        repo = self.root / 'repo'
        repo.mkdir()
        subprocess.run(['git', 'init', '-q', str(repo)], check=True)
        (repo / 'atari_wcc.qsf').write_text('set_global_assignment -name VHDL_FILE missing.vhd\n')
        with self.assertRaises(RuntimeError):
            module.snapshot(repo, self.root / 'snapshot')


if __name__ == '__main__':
    unittest.main()
