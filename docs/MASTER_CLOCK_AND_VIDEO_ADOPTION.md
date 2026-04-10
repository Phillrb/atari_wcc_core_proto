# Adopting MaSTer Clock and NTSC Video Output

This document describes how we adopt the **MaSTer** project's clock generation and composite video output so that atari_wcc can drive a real CRT with a **perfect 14.318180 MHz** pixel clock and standard NTSC-style composite output.

## Reference: MaSTer

- **Location**: `../MaSTer/` (sibling of this repo)
- **README**: MaSTer/README.md — standard pinout, composite video circuit, 50 MHz input
- **Pattern**: Each game uses:
  - **50 MHz** on-board crystal → **Altera PLL** → game pixel clock (e.g. 12.096 MHz for Dominos)
  - **Video**: `Sync_O`, `VideoW_O`, `VideoB_O` (or similar) → resistor ladder → composite out to CRT

## Goal for atari_wcc

1. **Clock**: Generate **exactly 14.318180 MHz** from the board’s **50 MHz** clock using a PLL, then feed that as `CLOCK_14` into the existing `ComputerClock` (which divides by 2 to get 7.159090 MHz). No external 14.31818 MHz crystal required.
2. **Video**: Use the **same composite output circuit and pinout** as MaSTer so one hardware “hat” works across games.

## PLL: 50 MHz → 14.318180 MHz

- **Input**: 50 MHz (period 20,000 ps) — same as MaSTer (`inclk0_input_frequency => 20000`).
- **Output**: 14.318180 MHz.
- **Formula**: `f_out = f_in * multiply_by / divide_by`  
  So: `14.31818 = 50 * M / D` → `M/D = 14.31818/50 = 0.2863636`.
- **Integer ratio**: `756 / 2640 = 0.28636…`  
  Check: `50 * 756 / 2640 = 14.3181818…` MHz ✓

So we use the same Altera ALTPLL pattern as MaSTer, with:

- `inclk0_input_frequency => 20000`  (50 MHz)
- `clk0_multiply_by       => 756`
- `clk0_divide_by         => 2640`
- `clk0_duty_cycle        => 50`
- `intended_device_family => "Cyclone II"`

The PLL is in **Altera/clk_pll.vhd**. The **board top-level** is **atari_wcc_board.vhd**: it takes **Clk_50_I**, instantiates the PLL to get **CLOCK_14**, and instantiates **atari_wcc** with that clock. The rest of the design (ComputerClock → CLOCK_7, sync, playfield, etc.) is unchanged.

## Video output (MaSTer-compatible)

MaSTer uses separate signals that are combined off-chip:

| MaSTer signal | atari_wcc equivalent | Purpose |
|---------------|----------------------|--------|
| Sync_O        | CSYNC                | Composite sync (H + V) |
| VideoW_O      | VIDEO                | Active video (white/bright) |
| VideoB_O      | optional             | Black/dark (we can tie low or use blanking) |

**Standard composite circuit (from MaSTer README):**

```
FPGA Sync (e.g. CSYNC)   ---[470Ω]---+
FPGA Video (e.g. VIDEO)  ---[1kΩ]----+---> Composite Video Out (to CRT)
FPGA VideoB (optional)   ---[1kΩ]----+
                                    [GND]
```

For atari_wcc we can drive **Sync_O = CSYNC** and **VideoW_O = VIDEO**; **VideoB_O** can be `'0'` or a blanking signal. Same resistor values and RCA output as other MaSTer games.

## Pinout alignment (MaSTer standard)

From MaSTer README:

| Function      | Pin  | atari_wcc usage        |
|---------------|------|-------------------------|
| Clock 50 MHz  | 17   | PLL input               |
| Video Sync    | 79   | CSYNC                   |
| Video White  | 75   | VIDEO                   |
| Video Black  | 73   | '0' or blanking         |
| Reset        | 144  | PushBtn (optional)      |

Using this pinout allows the same FPGA “hat” and cable to be used for atari_wcc as for other MaSTer games.

## Simulation vs board

- **Simulation**: No PLL; testbench still drives **CLOCK_14** at exactly 14.318180 MHz (e.g. half-period `34920.639355 ps`). Top-level remains **atari_wcc**.
- **Board**: Use **atari_wcc_board** as the Quartus top-level. It takes **50 MHz** (Clk_50_I), instantiates **clk_pll** to get **CLOCK_14**, instantiates **atari_wcc**, and drives **Sync_O**, **VideoW_O**, **VideoB_O** to the MaSTer pinout and resistor network.

### Quartus for board build

1. Add **Altera/clk_pll.vhd** to the project.
2. Add **atari_wcc_board.vhd** to the project.
3. Set **TOP_LEVEL_ENTITY** to **atari_wcc_board** (or add a board-specific .qsf that does this).
4. Ensure **altera_mf** is available (Quartus provides it for Cyclone II).
5. Assign pins per MaSTer: Clock 17, Sync 79, VideoW 75, VideoB 73, Reset 144, etc.

## Summary

- **Clock**: 50 MHz → PLL (756/2640) → **14.318180 MHz** → existing ComputerClock → 7.159090 MHz. Perfect pixel clock from the same board clock as MaSTer.
- **Video**: Same composite output circuit and pinout as MaSTer (Sync + Video resistors → RCA → CRT).

This gives a single, consistent clock and video stack across MaSTer-style projects and guarantees 14.318180 MHz for atari_wcc on hardware.
