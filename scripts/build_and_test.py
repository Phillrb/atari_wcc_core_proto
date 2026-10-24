#!/usr/bin/env python3
"""Build an isolated WCC snapshot and run checks; never program hardware."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE_SUFFIXES = {'.vhd', '.v', '.sv', '.qsf', '.qpf', '.sdc', '.tcl', '.py', '.sh',
                   '.do', '.mif', '.hex', '.qip', '.md'}
FAILURE = re.compile(r'^\s*(?:Error(?:\s*\(|:)|FATAL:)|\(assertion (?:error|failure)\)', re.M)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def snapshot(root, dest, exclude=None):
    """Use current tracked/untracked sources, excluding ignored build products."""
    names = subprocess.check_output(['git', 'ls-files', '-z', '--cached', '--others',
                                     '--exclude-standard'], cwd=root).decode().split('\0')
    hashes = {}
    for name in sorted(set(names)):
        if not name or Path(name).suffix.lower() not in SOURCE_SUFFIXES:
            continue
        source = root / name
        if exclude is not None and (source == exclude or exclude in source.parents):
            continue
        if not source.is_file():  # Locally deleted tracked source.
            continue
        if source.is_symlink():
            raise RuntimeError(f'Symlink source requires inspection: {source}')
        target = dest / name
        target.parent.mkdir(parents=True, exist_ok=True)
        data = source.read_bytes()
        target.write_bytes(data)
        hashes[name] = hashlib.sha256(data).hexdigest()
    # Detect ordinary edits during the copy; later edits cannot affect this run.
    for name, value in hashes.items():
        if not (root / name).is_file() or digest(root / name) != value:
            raise RuntimeError(f'Source changed while snapshotting: {name}; rerun')
    qsf = dest / 'atari_wcc.qsf'
    if qsf.exists():
        for match in re.finditer(r'^set_global_assignment -name (?:VHDL_FILE|VERILOG_FILE|SYSTEMVERILOG_FILE|SDC_FILE|QIP_FILE) (.+)$', qsf.read_text(), re.M):
            name = match[1].strip().strip('"{}')
            path = Path(name)
            if path.is_absolute() or '..' in path.parts or not (dest / path).is_file():
                raise RuntimeError(f'Quartus input is outside/missing from source snapshot: {name}')
    return hashes


class Pipeline:
    def __init__(self, directory, profile, timeout=1800, heartbeat=30):
        self.directory = directory
        self.timeout = timeout
        self.heartbeat = heartbeat
        self.report = {'status': 'RUNNING', 'profile': profile,
                       'started_utc': datetime.now(timezone.utc).isoformat(),
                       'stages': [], 'artifacts': {},
                       'visual_review': 'NOT_RUN', 'hardware_test': 'NOT_RUN',
                       'timing_scope': 'Targeted ball/score/speed checks only; whole design is not fully constrained.'}
        self.save()

    def save(self):
        data = json.dumps(self.report, indent=2) + '\n'
        temp = self.directory / 'report.json.tmp'
        temp.write_text(data)
        temp.replace(self.directory / 'report.json')
        lines = [f"WCC {self.report['status']} ({self.report['profile']})"]
        for stage in self.report['stages']:
            warnings = f"; {stage['warning_lines']} warning lines" if stage.get('warning_lines') else ''
            lines.append(f"{stage['status']:8} {stage['name']} ({stage.get('seconds', 0):.1f}s{warnings}) {stage['log']}")
        if self.report.get('error'):
            lines.append('ERROR: ' + self.report['error'])
        lines += [f"Visual review: {self.report['visual_review']}",
                  'Hardware test: NOT_RUN', self.report['timing_scope']]
        for name, item in self.report['artifacts'].items():
            lines.append(f"{name}: {item['path']} SHA256={item['sha256']}")
        (self.directory / 'summary.txt').write_text('\n'.join(lines) + '\n')

    def stage(self, name, command, cwd, expected=(), artifacts=(), env=None):
        log = self.directory / f'{len(self.report["stages"])+1:02d}_{name}.log'
        row = {'name': name, 'status': 'RUNNING', 'command': command, 'cwd': str(cwd),
               'log': str(log)}
        self.report['stages'].append(row)
        self.save()
        print(f'START {name}', flush=True)
        start = time.monotonic()
        process = None
        try:
            with log.open('w') as output:
                process = subprocess.Popen(command, cwd=cwd, stdout=output,
                                           stderr=subprocess.STDOUT, env=env, start_new_session=True)
                while True:
                    remaining = self.timeout - (time.monotonic() - start)
                    if remaining <= 0:
                        raise TimeoutError(f'{name} exceeded {self.timeout}s')
                    try:
                        code = process.wait(timeout=min(self.heartbeat, remaining))
                        break
                    except subprocess.TimeoutExpired:
                        print(f'RUNNING {name} ({time.monotonic()-start:.0f}s)', flush=True)
            text = log.read_text(errors='replace')
            row['returncode'] = code
            row['warning_lines'] = sum('warning' in line.lower() for line in text.splitlines())
            if code or FAILURE.search(text):
                raise RuntimeError(f'{name} failed (exit {code}); see {log}')
            for marker in expected:
                if marker not in text:
                    raise RuntimeError(f'{name} missing completion marker {marker!r}; see {log}')
            for path in artifacts:
                if not path.is_file() or path.stat().st_size == 0:
                    raise RuntimeError(f'{name} missing/empty artifact: {path}')
            row['status'] = 'PASS'
        except BaseException:
            if process is not None and process.poll() is None:
                os.killpg(process.pid, signal.SIGTERM)
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait()
            row['status'] = 'FAILED'
            if log.exists():
                print('\n'.join(log.read_text(errors='replace').splitlines()[-20:]), file=sys.stderr)
            raise
        finally:
            row['seconds'] = round(time.monotonic() - start, 2)
            self.save()
        print(f"PASS {name} ({row['seconds']}s)", flush=True)


def make_visual_review(source):
    from PIL import Image, ImageDraw
    sim = source / 'sim'
    with Image.open(sim / 'frame_output.png') as frame:
        frame.verify()
    with Image.open(sim / 'gameplay.gif') as gif:
        if gif.n_frames < 2:
            raise RuntimeError('Gameplay capture has no animation')
        width, height = gif.size
        sheet = Image.new('RGB', (width * 3, (height + 24) * 2), '#161616')
        for i in range(6):
            index = i * (gif.n_frames - 1) // 5
            gif.seek(index)
            x, y = i % 3 * width, i // 3 * (height + 24)
            sheet.paste(gif.convert('RGB'), (x, y + 24))
            ImageDraw.Draw(sheet).text((x + 8, y + 5), f'GIF keyframe {index}', fill='white')
        sheet.save(sim / 'review_keyframes.png')


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--quick', action='store_true', help='omit long full-video and SPI suites; report partial coverage')
    parser.add_argument('--quartus-bin', type=Path, help='directory containing quartus_sh and quartus_sta')
    parser.add_argument('--output-dir', type=Path, default=ROOT / 'output_files/build_runs')
    parser.add_argument('--timeout', type=int, default=1800, help='maximum seconds per stage')
    args = parser.parse_args(argv)
    if args.timeout <= 0:
        parser.error('--timeout must be positive')
    tools = {}
    for name in ('quartus_sh', 'quartus_sta'):
        found = str(args.quartus_bin / name) if args.quartus_bin else shutil.which(name)
        if not found:
            found = str(Path.home() / 'altera/13.0sp1/quartus/bin' / name)
        if not shutil.which(found):
            parser.error(f'{name} not found; provide --quartus-bin')
        tools[name] = str(Path(shutil.which(found)).absolute())
    for name in ('ghdl', 'bash', 'git'):
        if not shutil.which(name):
            parser.error(f'{name} not found')
    try:
        import PIL  # Required by existing renderers, including focused suites.
    except ImportError:
        parser.error('Pillow is required by the simulation renderers')
    args.output_dir = args.output_dir.resolve()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    directory = Path(tempfile.mkdtemp(prefix=datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ-'), dir=args.output_dir))
    pipeline = Pipeline(directory, 'quick' if args.quick else 'full', args.timeout)
    source = directory / 'source'
    print(f'RUN DIRECTORY: {directory}\nSUMMARY: {directory / "summary.txt"}', flush=True)
    try:
        pipeline.report['git_head'] = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
        pipeline.report['git_status'] = subprocess.check_output(['git', 'status', '--porcelain'], cwd=ROOT, text=True)
        pipeline.report['ghdl_version'] = subprocess.check_output(['ghdl', '--version'], text=True).splitlines()[0]
        pipeline.report['quartus_bin'] = tools
        hashes = snapshot(ROOT, source, exclude=args.output_dir)
        (directory / 'source_sha256.json').write_text(json.dumps(hashes, indent=2) + '\n')
        pipeline.report['source_manifest_sha256'] = digest(directory / 'source_sha256.json')
        with zipfile.ZipFile(directory / 'inputs.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
            for name in hashes:
                archive.write(source / name, name)
        pipeline.report['input_archive_sha256'] = digest(directory / 'inputs.zip')
        # Prevent inherited overrides from silently shortening/skipping coverage.
        env = dict(os.environ, STOP_MS='650', ONE_PLAYER='0', SPINNER_TEST='false', SPI_TEST='false')
        stage = lambda name, command, **kw: pipeline.stage(name, command, source, env=env, **kw)
        stage('quartus_build', [tools['quartus_sh'], '--flow', 'compile', 'atari_wcc'],
              expected=['Quartus II Full Compilation was successful'],
              artifacts=[source / 'output_files/atari_wcc.pof', source / 'output_files/atari_wcc.sof',
                         source / 'simulation/modelsim/atari_wcc.vho'])
        for circuit in ('ball', 'score', 'acceleration'):
            stage(f'{circuit}_routing', [sys.executable, f'sim/check_{circuit}_routing.py'], expected=['PASS:'])
            stage(f'{circuit}_timing', [tools['quartus_sta'], '-t', f'sim/check_{circuit}_timing.tcl'], expected=['PASS:'])
        suites = [
            ('control', ['Figure 8 credit/start/latch tests passed', 'Figure 12 serve/catch tests passed',
                         'Two-minute timer model (scaled clock count) tests passed']),
            ('sound', ['SoundCircuit PASS']),
            ('acceleration', ['PASS: hit acceleration']),
            ('catch_timeout', ['PASS: both teams auto-kick', 'PASS: solid rear catch']),
            ('moving_hole', ['Moving-hole reset, width, presets, boundary gating, mode and long-scan tests passed',
                             'Actual vertical raster / boundary capture complete']),
            ('player_mode', ['One-player windows suppress checked team and preserve solid team']),
        ]
        if not args.quick:
            suites.append(('spi', ['SPI timing, full ADC sweep, channels, clamps, reversal, atomic frames, rejection and reset passed',
                                   'All 73 travel positions preserve forward/defense/goalie sizes and attract layout',
                                   'Solid defence N8 rejects between-edge ramp transients']))
        for name, expected in suites:
            stage(name, ['bash', f'sim/run_{name}_tests.sh'], expected=expected)
        if not args.quick:
            pipeline.stage('full_simulation', ['bash', 'run_sim.sh'], source / 'sim', env=env,
                           expected=['Full core attract / coin / start / serve / expiry sequence passed', '=== Done ==='],
                           artifacts=[source / 'sim/frame_output.png', source / 'sim/gameplay.gif'])
            make_visual_review(source)
            pipeline.report['visual_review'] = 'PENDING: inspect frame_output.png and review_keyframes.png; animation is gameplay.gif'
        for name, path in [('pof', source / 'output_files/atari_wcc.pof'), ('sof', source / 'output_files/atari_wcc.sof')]:
            pipeline.report['artifacts'][name] = {'path': str(path), 'sha256': digest(path)}
        if not args.quick:
            for name in ('frame_output.png', 'gameplay.gif', 'review_keyframes.png'):
                path = source / 'sim' / name
                pipeline.report['artifacts'][name] = {'path': str(path), 'sha256': digest(path)}
        pipeline.report['status'] = 'QUICK_PASS' if args.quick else 'AUTOMATED_PASS'
    except (Exception, KeyboardInterrupt) as error:
        pipeline.report['status'] = 'INTERRUPTED' if isinstance(error, KeyboardInterrupt) else 'FAILED'
        pipeline.report['error'] = str(error) or 'Interrupted by operator'
    finally:
        pipeline.report['finished_utc'] = datetime.now(timezone.utc).isoformat()
        pipeline.save()
    print((directory / 'summary.txt').read_text(), flush=True)
    return 0 if pipeline.report['status'] in ('QUICK_PASS', 'AUTOMATED_PASS') else 1


if __name__ == '__main__':
    sys.exit(main())
