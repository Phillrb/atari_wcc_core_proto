# Atari 'World Cup' (WCC/Goal IV) FPGA Recreation

This project is a VHDL recreation of the classic 1974 discrete logic arcade game known as 'World Cup', 'World Cup Football', 'Coupe du Monde' or 'Goal IV' by Atari. The original PCB is marked 'WCC' and was assigned the working ID 'TM-035'.

> **Status: Simulation only — not yet tested on hardware.**
> The design runs correctly in GHDL simulation and produces video output verifiable via the Python visualizer. It has not been synthesised to an FPGA or driven a real display. Board-level integration (Quartus, PLL, composite video) is planned but incomplete.

## Current Implementation Status

| Phase | What | Status |
|-------|------|--------|
| Phase 0 | Foundation: clock, H/V sync, sync summing | **Done** |
| Phase 1 | Playfield circuit (Fig 9) | **Done** |
| Phase 2 | Game control: electronic latch, credit, start, game select, time line, serve timing | Exists — needs review/verification |
| Phase 3 | Ball system: motion, direction & speed, catch/kick, window/miss/bounce | **Done** |
| Phase 4 | Players: all forwards, defense/goalie (solid + striped), ramp, mux, summing | **Done** |
| Phase 5 | Score circuit, sound circuit, moving hole | Not yet implemented |
| Phase 6 | Video summing (Fig 22), board synthesis | Not yet implemented |

See [AGENTS.md](AGENTS.md) for the full circuit-by-circuit breakdown.

## Project Goals and Methodology
- The VHDL code is designed to closely resemble the original schematics for maximum traceability and historical accuracy.
- All standard TTL logic is implemented as 74 series ICs (e.g., LS02, LS04, etc.) and saved in the `74LS` directory.
- Other ICs are saved in the `IC` directory.
- Each IC is defined as a VHDL component, with ports and instance names matching the real IC pinout and PCB location.
- Pin connections in port maps are labeled to reflect both the pin number and the signal it connects to, aiding cross-referencing with the schematic.
- Individual VHD files will be created to represent each circuit as described by the manual.
- The file [Goal_IV_TM-035.pdf](Goal_IV_TM-035.pdf) is the original manual and schematics.
- [Goal_IV_TM-035_ocr.pdf](Goal_IV_TM-035_ocr.pdf) was created with OCR and adds metadata to the original PDF to make it searchable.
- [Goal_IV_TM-035.md](Goal_IV_TM-035.md) is a markdown file generated from the OCR process and further adjusted.

## Architecture

The design mirrors how the original 1970s hardware would work: discrete 74LS-series TTL ICs wired together at the gate/flip-flop level. No behavioral shortcuts - every signal path goes through an explicit IC instantiation. All files use **direct entity instantiation** (`entity work.LS04` etc.) for GHDL compatibility.

## Tooling
- Quartus II version 13.0.1 Service Pack 1 for synthesis.
- **GHDL** 0.37+ (mcode or LLVM backend) for simulation.
- **Python 3** with optional `pygame` for interactive display.

## Running the Simulation

```bash
cd sim
bash run_sim.sh
```

This compiles all VHDL, runs the simulation, and calls the Python visualizer. Output:

- `frame_data.txt` - Raw samples: `HSYNC VSYNC HBLANK VIDEO` captured at 7.159 MHz
- `frame_output.png` - Rendered still (second-to-last complete frame, 2x scale, green phosphor)
- `gameplay.gif` - Animated GIF of all complete frames (generated when >2 frames captured)
- `frame_output.ppm` - Written only when `--ppm` is passed to `visualize.py`

Requires Python 3 with `Pillow`: `pip3 install Pillow`

For VCD waveform debugging, add `--vcd=atari_wcc.vcd` to the GHDL run command in `run_sim.sh`.

## Documentation

- [AGENTS.md](AGENTS.md) - Agent instructions, circuit implementation plan, style guide, and full project status
- [docs/](docs/) - Build documentation, timing analysis, and implementation notes

## Atari WCC PCB

### IC Layout

Predominantly 74 series ICs.
The UA747 at F9 and N9 are opamps so are not implemented.

|       | A  | B  | C  | D  | E  | F  | H  | J  | K  | L  | M  | N  |
| -----:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| **1** | [04](74LS/LS04.vhd) | [20](74LS/LS20.vhd) | [93](74LS/LS93.vhd) | [93](74LS/LS93.vhd) | [93](74LS/LS93.vhd) | [93](74LS/LS93.vhd) | [107](74LS/LS107.vhd) | [00](74LS/LS00.vhd) | [74](74LS/LS74.vhd) | [30](74LS/LS30.vhd) | [08](74LS/LS08.vhd) |  - |
| **2** | [10](74LS/LS10.vhd) | [107](74LS/LS107.vhd) | [30](74LS/LS30.vhd) | [74](74LS/LS74.vhd) | [74](74LS/LS74.vhd) | [86](74LS/LS86.vhd) | [10](74LS/LS10.vhd) | [04](74LS/LS04.vhd) | [10](74LS/LS10.vhd) | [10](74LS/LS10.vhd) | [48](74LS/LS48.vhd) | [107](74LS/LS107.vhd) |
| **3** | [20](74LS/LS20.vhd) | [107](74LS/LS107.vhd) | [00](74LS/LS00.vhd) | [08](74LS/LS08.vhd) | [04](74LS/LS04.vhd) | [02](74LS/LS02.vhd) | [27](74LS/LS27.vhd) | [00](74LS/LS00.vhd) | [90](74LS/LS90.vhd) | [90](74LS/LS90.vhd) | [153](74LS/LS153.vhd) | [153](74LS/LS153.vhd) |
| **4** |[9316](IC/IC9316.vhd)|[9316](IC/IC9316.vhd)|[9316](IC/IC9316.vhd)|[9316](IC/IC9316.vhd)| [74](74LS/LS74.vhd) | [02](74LS/LS02.vhd) | [02](74LS/LS02.vhd) | [20](74LS/LS20.vhd) | [107](74LS/LS107.vhd) |[9316](IC/IC9316.vhd)|[9316](IC/IC9316.vhd)| [27](74LS/LS27.vhd) |
| **5** | [86](74LS/LS86.vhd) | [83](74LS/LS83.vhd) | [08](74LS/LS08.vhd) | [74](74LS/LS74.vhd) |[9602](IC/IC9602.vhd)| [08](74LS/LS08.vhd) | [02](74LS/LS02.vhd) |[9602](IC/IC9602.vhd)|  - | [74](74LS/LS74.vhd) | [86](74LS/LS86.vhd) | [00](74LS/LS00.vhd) |
| **6** | [08](74LS/LS08.vhd) |[9316](IC/IC9316.vhd)| [04](74LS/LS04.vhd) | [74](74LS/LS74.vhd) | [86](74LS/LS86.vhd) | [00](74LS/LS00.vhd) | [10](74LS/LS10.vhd) | [27](74LS/LS27.vhd) | [08](74LS/LS08.vhd) | [86](74LS/LS86.vhd) | [92](74LS/LS92.vhd) |  - |
| **7** | [83](74LS/LS83.vhd) | [02](74LS/LS02.vhd) | [86](74LS/LS86.vhd) |[9314](IC/IC9314.vhd)| [20](74LS/LS20.vhd) | [107](74LS/LS107.vhd) | [153](74LS/LS153.vhd) |[9316](IC/IC9316.vhd)|[9316](IC/IC9316.vhd)| [153](74LS/LS153.vhd) |[9316](IC/IC9316.vhd)|[9316](IC/IC9316.vhd)|
| **8** | [04](74LS/LS04.vhd) | [74](74LS/LS74.vhd) | [00](74LS/LS00.vhd) | [74](74LS/LS74.vhd) | [00](74LS/LS00.vhd) |  - | [107](74LS/LS107.vhd) | [04](74LS/LS04.vhd) | [02](74LS/LS02.vhd) | [00](74LS/LS00.vhd) |  - | 555 |
| **9** | [74](74LS/LS74.vhd) | [74](74LS/LS74.vhd) | [02](74LS/LS02.vhd) | [04](74LS/LS04.vhd) | 555 | 747 | 555 |[9602](IC/IC9602.vhd)|  - |  - |[9602](IC/IC9602.vhd)| 747|

### PCB Image

![Atari WCC PCB](diagrams/atari_wcc_pcb.jpg)

### Playfield Layout (Reference Coordinates)
```
0, 140 to 144,     404 to 408, 548
 ______________________________   0
|    ______________________    |
|   |  __________________  |   |  80 to 84
|   | |                  | |   |
|   |_|                  |_|   |  128
|                              |
|                              |  162
|    _                    _    |
|   | |                  | |   |  196
|   | |__________________| |   |
|   |______________________|   |  240 to 244
|______________________________|
                                  324
```
