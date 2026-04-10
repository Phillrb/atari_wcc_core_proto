# Solid Defense / Goalie – Current State and Known Issue

**Date:** 2026-02-19

## What Is Implemented

### PlayersSolidDefenseGoalie.vhd
- **Comparator:** RAMP_VALUE ≥ POSITION (digital); POSITION=0 in atari_wcc so column active for full ramp span.
- **555 (N8) model:** Behavioural. INITIAL_GAP (85 phases) then 3 blocks of (SEGMENT_GAP + SEGMENT_LEN). SEGMENT_GAP=18, SEGMENT_LEN=16. N8_3 high during initial gap and per-block gaps (load); low during 16-line count windows.
- **M7 (IC9316):** CLK=HSYNC, LDn=J8_2_out, CEP=J8_4_out; loads 0, counts 0..15 per segment. B1,C1,D1 = QB,QC,QD to mux.
- **H8 (LS107):** J1=Q1n, K1=Q2n, J2=Q1, K2=Q2n; CLR1n/CLR2n=VSYNCn; CLK=J8_4_out. Produces (Q1,Q2) = (0,0) top def, (1,0) goalie, (0,1) bottom def.
- **E6 (LS86) gate 1:** Pin 1 = goalie_segment (Q1 and not Q2), pin 2 = Q1 → E6_Y1 = 0 for (0,0),(1,0),(0,1) so E1 is not blanked for any of the three segments.
- **K6, J6, L8, J8:** Per schematic; E1 = NOR(K6_8, E6_Y1, L8_8). E1, B1, C1, D1 drive mux.

### Ramp (for defense column)
- **PlayersRampGenerator.vhd:** Ramp increments when charge_enable OR when V256=0 (extended so column can span full frame). Reset on V256=1. Gives enough scanlines for INITIAL_GAP + 3×(40+16) phases so all three segments are visible and position is adjustable.

### Vertical window and mux
- **PlayersVerticalWindow.vhd:** HRESETn → D6 pin 13 (CLR2n). L6 pin 3 (GOALIE) → L6 pin 4 (A2) so TEAM = GOALIE xor M6_Q3.
- **PlayersMultiplexer.vhd:** H7 selects E1 (2I0) when TEAM=0, Qn=1 (solid defense). SYMBOL = mux output; enabled when PLAYER_WINDOWn is low (4H windows).

### Top-level
- **atari_wcc.vhd:** Solid Defense/Goalie POSITION = 0. E1,B1,C1,D1 from U_SOLID_DEF to mux; SYMBOL and PADDLES fed to video.

---

## Fixed: Double Column (Defensemen + Goalie)

- **Symptom:** Three dashes appear in a “goalie” column and three in a “defensemen” column (same content, two horizontal positions). Middle segment is correct for goalie; top and bottom for defenders.
- **Cause:** The vertical window has **two separate 4H slots** per line: one for goalie (e.g. 152H), one for defensemen (e.g. 200H). When (TEAM=0, Qn=1), the mux outputs E1 in **both** slots, so the same three segments (E1/B1/C1/D1) are drawn in both 4H windows → two columns.
- **Attempted fix (reverted):** Gate SYMBOL in PlayersSumming so that when (TEAM=0, Qn=1) and GOALIE=1 (goalie 4H slot), SYMBOL was forced to 0. That would have drawn the defense column only in the defensemen slot (single column). User asked to undo; reverted so SYMBOL is again passed straight from mux to M1.
- **Fix (in PlayersSolidDefenseGoalie.vhd):** Gate E1 by vertical-window GOALIE: goalie 4H slot (GOALIE=1) shows only when goalie_segment; defensemen 4H slot (GOALIE=0) only when not goalie_segment. E1 = J6_Y3 and (goalie_segment xnor GOALIE) via LS86, LS04, LS08 (U_E6_g2, U_J8_slot, U_K6_g4).

---

## File References

| Item | File |
|------|------|
| Solid Defense/Goalie | PlayersSolidDefenseGoalie.vhd |
| Ramp (extended for full frame) | PlayersRampGenerator.vhd |
| Vertical window, TEAM/GOALIE/Q | PlayersVerticalWindow.vhd |
| Mux (E1 → SYMBOL) | PlayersMultiplexer.vhd |
| Summing (SYMBOL → M1 → K6 → PADDLES) | PlayersSumming.vhd |
| Top-level wiring | atari_wcc.vhd |
