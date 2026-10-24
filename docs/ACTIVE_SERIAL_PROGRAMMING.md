# Program the EPCS4 flash over Active Serial

Connect the USB-Blaster to the board's **AS** header and power the board. Close
other programmer operations using the same cable.

Check the programmer and board without programming:

```bash
python3 scripts/program_as.py --check-only
```

Program and verify a POF:

```bash
python3 scripts/program_as.py output_files/atari_wcc_catch_debug.pof
```

This writes configuration flash, replacing the image loaded at power-on. Use a
POF generated for the board's flash device; SOF files are for volatile FPGA
configuration over JTAG and are rejected by this script.

The script first lists cables, then uses Quartus's AS **Examine** operation to
read the expected flash into a backup POF. Successful cable enumeration alone
does not count as board detection. A failed read, missing backup, ambiguous
cable, or timeout blocks programming. No JTAG chain scan is used as an AS test.
After a successful read, Quartus performs **Program + Verify**. An operation
failure exits nonzero, retains its log, and never prints success.

Each invocation creates a unique directory under `output_files/as_program/`
containing logs and, when the read succeeds, `flash_before.pof`. A flash read can
temporarily interrupt gameplay. A failed or interrupted programming operation
may leave flash incomplete; do not assume the previous image remains intact.

Useful options:

- `--cable 1` or `--cable 'USB-Blaster(Altera) [1-2]'`: select a detected cable.
  Required when multiple cables are present.
- `--device EPCS4`: expected flash device, default EPCS4. This is supplied to the
  read operation, not inferred from the filename and not a POF conversion.
- `--quartus-pgm /path/to/quartus_pgm`: choose Quartus. Otherwise the script uses
  `QUARTUS_PGM`, PATH, then `~/altera/13.0sp1/quartus/bin/quartus_pgm`.
- `--timeout 300`: seconds allowed per operation (default 180).
- `--log-dir /path/to/logs`: choose where logs and backups are retained.

On this setup Quartus has reported `Can't access JTAG chain` even with `-m AS`
explicitly selected. The script reports this as a failed AS board-access check;
it does not switch modes or attempt programming anyway. Check board power,
the AS connection/orientation and cable ownership before retrying.

Tests use a fake Quartus executable and do not access hardware:

```bash
python3 -m unittest discover -s testbench -p 'test_program_as.py' -v
```

Verified on 24 October 2026: all six automated tests passed. A live
`--check-only` invocation detected `USB-Blaster(Altera) [1-2]`, successfully read
the EPCS4, and saved its backup and logs under
`output_files/as_program/20261024-141354-ygemnn1n/`. It did not program flash.
