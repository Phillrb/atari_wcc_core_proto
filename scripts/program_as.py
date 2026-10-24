#!/usr/bin/env python3
"""Check an Active Serial connection, back up flash, then program/verify a POF."""
import argparse
from datetime import datetime
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pof", nargs="?", type=Path, help="POF to program (required unless --check-only)")
    parser.add_argument("--check-only", action="store_true", help="detect cable and read flash without programming")
    parser.add_argument("--cable", help="exact cable name from Quartus, or its list number")
    parser.add_argument("--device", default="EPCS4", help="expected AS flash device (default: EPCS4)")
    parser.add_argument("--quartus-pgm", default=os.environ.get("QUARTUS_PGM"), help="path to quartus_pgm")
    parser.add_argument("--log-dir", type=Path, default=Path(__file__).resolve().parents[1] / "output_files/as_program")
    parser.add_argument("--timeout", type=int, default=180, help="maximum seconds per Quartus operation (default: 180)")
    args = parser.parse_args(argv)
    if not args.check_only and args.pof is None:
        parser.error("provide a .pof file or use --check-only")
    if args.timeout <= 0:
        parser.error("--timeout must be positive")
    if not re.fullmatch(r"[A-Za-z0-9_]+", args.device):
        parser.error("invalid flash device name")
    if args.pof is not None:
        args.pof = args.pof.resolve()
        if args.pof.suffix.lower() != ".pof" or not args.pof.is_file() or not os.access(args.pof, os.R_OK):
            parser.error("POF must be an existing readable .pof file")
        if args.pof.stat().st_size == 0:
            parser.error("POF is empty")
        if any(c in str(args.pof) for c in ";@\r\n"):
            parser.error("POF path cannot contain Quartus operation delimiters ; @ or newlines")
    tool = args.quartus_pgm or shutil.which("quartus_pgm")
    if not tool:
        candidate = Path.home() / "altera/13.0sp1/quartus/bin/quartus_pgm"
        if candidate.is_file():
            tool = str(candidate)
    if not tool or not shutil.which(str(tool)):
        parser.error("quartus_pgm not found; use --quartus-pgm or QUARTUS_PGM")
    args.log_dir = args.log_dir.resolve()
    if any(c in str(args.log_dir) for c in ";@\r\n"):
        parser.error("log directory cannot contain Quartus operation delimiters ; @ or newlines")
    args.log_dir.mkdir(parents=True, exist_ok=True)
    run_dir = Path(tempfile.mkdtemp(prefix=datetime.now().strftime("%Y%m%d-%H%M%S-"), dir=args.log_dir))
    print(f"Logs and flash backup: {run_dir}", flush=True)

    def run(label, options):
        log = run_dir / f"{label}.log"
        print(f"{label}…", flush=True)
        try:
            with log.open("w") as output:
                result = subprocess.run([str(tool), *options], stdout=output, stderr=subprocess.STDOUT,
                                        timeout=args.timeout, check=False)
        except subprocess.TimeoutExpired:
            raise RuntimeError(f"{label} timed out after {args.timeout}s. See {log}") from None
        text = log.read_text(errors="replace")
        if result.returncode != 0 or re.search(r"^\s*Error(?:\s*\(|:)", text, re.M):
            print(text[-6000:], file=sys.stderr)
            raise RuntimeError(f"{label} failed. See {log}")
        return text

    try:
        listing = run("detect_programmer", ["-l"])
        cables = re.findall(r"^\s*(\d+)\)\s+(.+?)\s*$", listing, re.M)
        if not cables:
            raise RuntimeError("No programmer detected. Check USB connection and USB permissions.")
        if args.cable:
            matches = [name for number, name in cables if args.cable in (number, name)]
            if len(matches) != 1:
                raise RuntimeError(f"Cable {args.cable!r} not uniquely detected. Available: {cables}")
            cable = matches[0]
        else:
            if len(cables) != 1:
                raise RuntimeError(f"Multiple programmers detected; select one with --cable. Available: {cables}")
            cable = cables[0][1]
        print(f"Programmer detected: {cable}", flush=True)
        # -a/JTAG scans do not establish AS connectivity. Read the expected flash
        # instead. Fail closed: never program if this non-writing probe fails.
        backup = run_dir / "flash_before.pof"
        run("read_flash", ["-c", cable, "-m", "AS", "-o", f"e;{backup};{args.device}"])
        if not backup.is_file() or backup.stat().st_size == 0:
            raise RuntimeError("Flash read produced no backup; board access is unconfirmed. Programming blocked.")
        print(f"Board flash reachable: {args.device}. Backup saved: {backup}", flush=True)
        if args.check_only:
            print("Connection check passed. Flash was not programmed.")
            return 0
        print(f"Programming power-on configuration from {args.pof}", flush=True)
        run("program_verify", ["-c", cable, "-m", "AS", "-o", f"pv;{args.pof}"])
        print("SUCCESS: Active Serial programming and verification completed.")
        return 0
    except (RuntimeError, OSError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        print("Check board power, AS header/cable orientation, and whether another programmer owns the cable.\n"
              "Quartus may report 'Can't access JTAG chain' even when -m AS was selected.\n"
              "A programming timeout/failure can leave flash incomplete; use the logs before retrying.", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
