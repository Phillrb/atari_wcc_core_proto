#!/usr/bin/env python3
"""Create an isolated Quartus source tree; never replace the normal bitstream."""
from pathlib import Path
import re
import shutil
import sys

root = Path(__file__).resolve().parent.parent
dest = Path(sys.argv[1]).resolve()
dest.mkdir(parents=True, exist_ok=False)
qsf = (root / "atari_wcc.qsf").read_text()
sources = re.findall(r"^set_global_assignment -name (?:VHDL_FILE|SDC_FILE) (\S+)$", qsf, re.M)
for name in sources + ["atari_wcc.qpf", "sim/CatchStatusLED.vhd"]:
    target = dest / name
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(root / name, target)
core = dest / "atari_wcc.vhd"
text = core.read_text()
old = "LED0      <= not PushBtn;"
assert text.count(old) == 1, "Core LED assignment changed; inspect before preparing diagnostic"
text = text.replace(old, """-- Isolated diagnostic: mode switch selects the LED observation.
U_CATCH_STATUS_LED: entity work.CatchStatusLED
    port map(ONE_PLAYER=>selected_one_player_i,
        SOLID_KICK=>solid_kick_pressed, CHECKED_KICK=>check_kick_pressed,
        STOPn=>stopn_i, LEDn=>LED0);""")
core.write_text(text)
(dest / "atari_wcc.qsf").write_text(qsf + "\nset_global_assignment -name VHDL_FILE sim/CatchStatusLED.vhd\n")
print(dest)
