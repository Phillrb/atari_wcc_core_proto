-- Score Circuit (Figure 21) - Goal IV (WCC) TM-035
-- Goal clocking: J3(LS00) gates MISS/H256 -> K3/L3(LS90) decade counters (units digits).
-- Tens carry: N2(LS107) JK FFs clocked by units Q3.
-- BCD mux: M3/N3(LS153) select team and digit position (H256/H16 steering).
-- Decoder: M2(LS48) converts BCD to 7-segment (active-high, common cathode).
-- Pixel decode: F2(LS86), H2(LS10), J2(LS04), N4(LS27), K2(LS10), H5(LS02),
--               F3(LS02), L2(LS10) gate segment signals with H/V counter bits.
-- Video NAND: L1(LS30) 8-input NAND produces SCORE (active-high).
-- Blanking: H3(LS27), E3(LS04), D3(LS08) gate vertical window and SERVE/ATRCn.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ScoreCircuit is
    Port (
        -- Horizontal counter bits
        H2      : in  STD_LOGIC;   -- 2H
        H4      : in  STD_LOGIC;   -- 4H
        H8      : in  STD_LOGIC;   -- 8H
        H16     : in  STD_LOGIC;   -- 16H  (digit select LSB)
        H32     : in  STD_LOGIC;   -- 32H  (narrows score H window to single tens+units pair)
        H64     : in  STD_LOGIC;   -- 64H
        H128    : in  STD_LOGIC;   -- 128H
        H256    : in  STD_LOGIC;   -- 256H (digit select MSB / goal clock source)
        H256n   : in  STD_LOGIC;   -- 256Hn
        -- Vertical counter bits
        V2      : in  STD_LOGIC;   -- 2V
        V4      : in  STD_LOGIC;   -- 4V
        V8      : in  STD_LOGIC;   -- 8V
        V16     : in  STD_LOGIC;   -- 16V  (vertical window)
        V32     : in  STD_LOGIC;   -- 32V
        V64     : in  STD_LOGIC;   -- 64V
        V128    : in  STD_LOGIC;   -- 128V (vertical window)
        -- Game control
        MISS    : in  STD_LOGIC;   -- ball through goal (from WindowMissBounce)
        START   : in  STD_LOGIC;   -- game start (resets score counters, active high)
        STARTn  : in  STD_LOGIC;   -- inverted START
        SERVE   : in  STD_LOGIC;   -- ball in play (from ServeTimingCircuit)
        ATRCn   : in  STD_LOGIC;   -- attract mode, active low = play
        -- Video inputs for compositing
        TIME_LINEn  : in  STD_LOGIC;   -- time line video, active low
        PLAYFIELDn  : in  STD_LOGIC;   -- playfield video, active low
        -- Output
        SCORE   : out STD_LOGIC    -- composite video output (active high)
    );
end ScoreCircuit;

architecture Structural of ScoreCircuit is

    -- J3 (LS00) outputs: goal clock gating
    signal j3_y1  : STD_LOGIC;  -- NAND(H256, MISS)   -> K3 CP0n
    signal j3_y2  : STD_LOGIC;  -- NAND(V32,  V64)    -> H3 gate3 C, vertical window
    signal j3_y3  : STD_LOGIC;  -- NAND(H4,   H2)     -> F3 gate2 A
    signal j3_y4  : STD_LOGIC;  -- NAND(H256n,MISS)   -> L3 CP0n

    -- K3 (LS90) outputs: team-1 units BCD counter (1a=Q0, 1b=Q1, 1c=Q2, 1d=Q3)
    signal k3_q0  : STD_LOGIC;  -- 1a: units bit 0
    signal k3_q1  : STD_LOGIC;  -- 1b: units bit 1
    signal k3_q2  : STD_LOGIC;  -- 1c: units bit 2
    signal k3_q3  : STD_LOGIC;  -- 1d: units bit 3 -> N2 CLK1

    -- L3 (LS90) outputs: team-2 units BCD counter (2a..2d)
    signal l3_q0  : STD_LOGIC;  -- 2a
    signal l3_q1  : STD_LOGIC;  -- 2b
    signal l3_q2  : STD_LOGIC;  -- 2c
    signal l3_q3  : STD_LOGIC;  -- 2d -> N2 CLK2

    -- N2 (LS107) outputs: tens carry flip-flops (1e, 2e)
    signal n2_q1  : STD_LOGIC;  -- 1e: team-1 tens (0 or 1)
    signal n2_q2  : STD_LOGIC;  -- 2e: team-2 tens (0 or 1)

    -- M3 (LS153) outputs: A and B BCD bits routed to M2
    signal m3_y1  : STD_LOGIC;  -- A input to M2
    signal m3_y2  : STD_LOGIC;  -- B input to M2

    -- N3 (LS153) outputs: C and D BCD bits routed to M2
    signal n3_y1  : STD_LOGIC;  -- C input to M2
    signal n3_y2  : STD_LOGIC;  -- D input to M2

    -- M2 (LS48) 7-segment outputs (active high)
    signal m2_a   : STD_LOGIC;
    signal m2_b   : STD_LOGIC;
    signal m2_c   : STD_LOGIC;
    signal m2_d   : STD_LOGIC;
    signal m2_e   : STD_LOGIC;
    signal m2_f   : STD_LOGIC;
    signal m2_g   : STD_LOGIC;

    -- H3 (LS27) outputs: vertical window and blanking
    signal h3_y1  : STD_LOGIC;  -- blanking control -> M2 BIn
    signal h3_y3  : STD_LOGIC;  -- NOR(V128,V16,J3_Y2): vertical score window

    -- E3 (LS04) output: NOT(h3_y3) -> H3 gate1 C
    signal e3_y   : STD_LOGIC;

    -- D3 (LS08) outputs
    signal d3_y1  : STD_LOGIC;  -- AND(TIME_LINEn, PLAYFIELDn) -> L1_F
    signal d3_y3  : STD_LOGIC;  -- AND(SERVE, ATRCn)            -> H3_B1

    -- F2 (LS86) outputs: horizontal XOR decode -> ic_H2 gate1
    signal f2_y1  : STD_LOGIC;  -- H128 XOR H256
    signal f2_y2  : STD_LOGIC;  -- H256n XOR H64

    -- ic_H2 (LS10 at PCB location H2) outputs
    signal ic_h2_y1 : STD_LOGIC; -- NAND(f2_y1, f2_y2, '1')         -> H3 gate1 A (horizontal score window)
    signal ic_h2_y2 : STD_LOGIC; -- NAND(H8, V2, V4)                -> J2_gate3 input
    signal ic_h2_y3 : STD_LOGIC; -- NAND(m2_d, NOT(ic_h2_y2), V8)   -> L1_E (segment d timing)

    -- J2 (LS04 at PCB location J2) outputs
    signal j2_y2  : STD_LOGIC;  -- NOT(V8) = V8n  -> K2_C1, L2_B1, L2_A2, K2_B3
    signal j2_y3  : STD_LOGIC;  -- NOT(ic_h2_y2)  -> K2_A3, ic_H2 gate3 B
    signal j2_y6  : STD_LOGIC;  -- NOT(H8) = H8n  -> H5_B1, F3_B2, N4_B3

    -- N4 (LS27 at PCB location N4) gate3 output
    signal n4_y3  : STD_LOGIC;  -- NOR(H4, H8n, H2) -> K2_B1, K2_A2

    -- K2 (LS10 at PCB location K2) outputs: segment gating
    signal k2_y1  : STD_LOGIC;  -- NAND(m2_f, n4_y3, V8n)               -> L1_C
    signal k2_y2  : STD_LOGIC;  -- NAND(n4_y3, m2_e, V8)                 -> L1_B
    signal k2_y3  : STD_LOGIC;  -- NAND(NOT(ic_h2_y2), V8n, m2_g)        -> L1_D

    -- H5 (LS02 at PCB location H5) outputs
    signal h5_y1  : STD_LOGIC;  -- NOR(V8, H8n) = V8n AND H8 -> L2 gate1 B (segment a H/V composite)
    signal h5_y2  : STD_LOGIC;  -- NOR(V2, V4)  -> L2_C1

    -- F3 (LS02 at PCB location F3) gate2 output
    signal f3_y2  : STD_LOGIC;  -- NOR(j3_y3, H8n) -> L2_B2, L2_C3

    -- L2 (LS10 at PCB location L2) outputs: segment gating
    signal l2_y1  : STD_LOGIC;  -- NAND(m2_a, V8n, NOR(V2,V4))        -> L1_G
    signal l2_y2  : STD_LOGIC;  -- NAND(V8n, f3_y2, m2_b)             -> L1_A
    signal l2_y3  : STD_LOGIC;  -- NAND(m2_c, V8, f3_y2)              -> L1_H

    signal score_i : STD_LOGIC;

begin

    -- =========================================================
    -- J3 (LS00) - Goal clock gating
    -- Gate1: NAND(H256, MISS)  -> K3 CP0n (team-1 goal clock)
    -- Gate2: NAND(V32,  V64)   -> H3 vertical window decode
    -- Gate3: NAND(H4,   H2)    -> F3 horizontal segment decode
    -- Gate4: NAND(H256n,MISS)  -> L3 CP0n (team-2 goal clock)
    -- =========================================================
    ic_J3: entity work.LS00
        port map(
            P1_A1  => H256,     -- gate1 A
            P2_B1  => MISS,     -- gate1 B
            P3_Y1  => j3_y1,    -- -> K3 P14_CP0n
            P4_A2  => V32,      -- gate2 A
            P5_B2  => V64,      -- gate2 B
            P6_Y2  => j3_y2,    -- -> H3 P11_C3
            P9_A3  => H4,       -- gate3 A
            P10_B3 => H2,       -- gate3 B (H2 counter bit)
            P8_Y3  => j3_y3,    -- -> F3 P5_A2
            P12_A4 => H256n,    -- gate4 A
            P13_B4 => MISS,     -- gate4 B
            P11_Y4 => j3_y4     -- -> L3 P14_CP0n
        );

    -- =========================================================
    -- K3 (LS90) - Team-1 units BCD decade counter
    -- CP0n clocked by j3_y1 (MISS on H256 side).
    -- BCD mode: Q0 (P12) fed back to CP1n (P1).
    -- MR1/MR2 = START resets to 0.  MS1/MS2 = 0 (no forced-9).
    -- =========================================================
    ic_K3: entity work.LS90
        port map(
            P14_CP0n => j3_y1,  -- goal clock (team 1)
            P1_CP1n  => k3_q0,  -- BCD feedback Q0 -> CP1n
            P2_MR1   => START,
            P3_MR2   => START,
            P6_MS1   => '0',
            P7_MS2   => '0',
            P12_Q0   => k3_q0,  -- 1a
            P9_Q1    => k3_q1,  -- 1b
            P8_Q2    => k3_q2,  -- 1c
            P11_Q3   => k3_q3   -- 1d -> N2 CLK1
        );

    -- =========================================================
    -- L3 (LS90) - Team-2 units BCD decade counter
    -- CP0n clocked by j3_y4 (MISS on H256n side).
    -- =========================================================
    ic_L3: entity work.LS90
        port map(
            P14_CP0n => j3_y4,  -- goal clock (team 2)
            P1_CP1n  => l3_q0,  -- BCD feedback Q0 -> CP1n
            P2_MR1   => START,
            P3_MR2   => START,
            P6_MS1   => '0',
            P7_MS2   => '0',
            P12_Q0   => l3_q0,  -- 2a
            P9_Q1    => l3_q1,  -- 2b
            P8_Q2    => l3_q2,  -- 2c
            P11_Q3   => l3_q3   -- 2d -> N2 CLK2
        );

    -- =========================================================
    -- N2 (LS107) - Tens-carry JK flip-flops
    -- FF1 toggles on falling edge of k3_q3 (team-1 Q3 = units carrying).
    -- FF2 toggles on falling edge of l3_q3 (team-2 Q3).
    -- CLRn = STARTn resets on game start.
    -- =========================================================
    ic_N2: entity work.LS107
        port map(
            P1_J1     => '1',
            P4_K1     => '1',
            P12_CLK1  => k3_q3,     -- team-1 units Q3 -> tens FF clock
            P13_CLR1n => STARTn,
            P3_Q1     => n2_q1,     -- 1e: team-1 tens
            P2_Q1n    => open,
            P8_J2     => '1',
            P11_K2    => '1',
            P9_CLK2   => l3_q3,     -- team-2 units Q3 -> tens FF clock
            P10_CLR2n => STARTn,
            P5_Q2     => n2_q2,     -- 2e: team-2 tens
            P6_Q2n    => open
        );

    -- =========================================================
    -- M3 (LS153) - Mux for BCD bits A and B to M2
    -- S1=H256, S0=H16 select which team/digit to display:
    --   00 = team-1 tens (1e,  0)
    --   01 = team-1 units (1a, 1b)
    --   10 = team-2 tens (2e,  0)
    --   11 = team-2 units (2a, 2b)
    -- =========================================================
    ic_M3: entity work.LS153
        port map(
            P2_S1    => H256,
            P14_S0   => H16,
            P1_Ea    => '0',        -- always enabled
            P6_1I0   => n2_q1,      -- I0: 1e (team-1 tens)  -> A
            P5_1I1   => k3_q0,      -- I1: 1a (team-1 units Q0) -> A
            P4_1I2   => n2_q2,      -- I2: 2e (team-2 tens)  -> A
            P3_1I3   => l3_q0,      -- I3: 2a (team-2 units Q0) -> A
            P7_1Y    => m3_y1,      -- -> M2 P7_A
            P15_Eb   => '0',        -- always enabled
            P10_2I0  => '0',        -- I0: tens B bit = 0 (tens is 0 or 1, B=0 always)
            P11_2I1  => k3_q1,      -- I1: 1b (team-1 units Q1) -> B
            P12_2I2  => '0',        -- I2: tens B bit = 0
            P13_2I3  => l3_q1,      -- I3: 2b (team-2 units Q1) -> B
            P9_2Y    => m3_y2       -- -> M2 P1_B
        );

    -- =========================================================
    -- N3 (LS153) - Mux for BCD bits C and D to M2
    -- Same select as M3 (S1=H256, S0=H16).
    -- =========================================================
    ic_N3: entity work.LS153
        port map(
            P2_S1    => H256,
            P14_S0   => H16,
            P1_Ea    => '0',
            P6_1I0   => '0',        -- tens C bit = 0
            P5_1I1   => k3_q2,      -- 1c (team-1 units Q2) -> C
            P4_1I2   => '0',        -- tens C bit = 0
            P3_1I3   => l3_q2,      -- 2c (team-2 units Q2) -> C
            P7_1Y    => n3_y1,      -- -> M2 P2_C
            P15_Eb   => '0',
            P10_2I0  => '0',        -- tens D bit = 0
            P11_2I1  => k3_q3,      -- 1d (team-1 units Q3) -> D
            P12_2I2  => '0',        -- tens D bit = 0
            P13_2I3  => l3_q3,      -- 2d (team-2 units Q3) -> D
            P9_2Y    => n3_y2       -- -> M2 P6_D
        );

    -- =========================================================
    -- M2 (LS48) - BCD to 7-segment decoder
    -- BIn (P4) = h3_y1: blanks display outside vertical window
    --            or during SERVE in attract mode.
    -- RBIn (P5) = H16: ripple-blanks leading zero (tens digit when = 0).
    -- =========================================================
    ic_M2: entity work.LS48
        port map(
            P7_A    => m3_y1,       -- A from M3 mux1
            P1_B    => m3_y2,       -- B from M3 mux2
            P2_C    => n3_y1,       -- C from N3 mux1
            P6_D    => n3_y2,       -- D from N3 mux2
            P3_LTn  => '1',         -- no lamp test
            P4_BIn  => h3_y1,       -- blanking: low = blank
            P5_RBIn => H16,         -- ripple blank: H16=0 when tens digit, blanks if 0
            P13_a   => m2_a,
            P12_b   => m2_b,
            P11_c   => m2_c,
            P10_d   => m2_d,
            P9_e    => m2_e,
            P15_f   => m2_f,
            P14_g   => m2_g
        );

    -- =========================================================
    -- D3 (LS08) - AND gates for compositing and blanking
    -- Gate1: AND(TIME_LINEn, PLAYFIELDn) -> L1 (timeline+field into SCORE)
    -- Gate3: AND(SERVE, ATRCn)            -> H3 blanking gate
    -- =========================================================
    ic_D3: entity work.LS08
        port map(
            P1_A1  => TIME_LINEn,   -- timeline active-low
            P2_B1  => PLAYFIELDn,   -- playfield active-low
            P3_Y1  => d3_y1,        -- -> L1 P6_F
            P9_A3  => SERVE,
            P10_B3 => ATRCn,
            P8_Y3  => d3_y3,        -- -> H3 P2_B1
            -- gate2, gate4 unused
            P4_A2  => '0',
            P5_B2  => '0',
            P6_Y2  => open,
            P12_A4 => '0',
            P13_B4 => '0',
            P11_Y4 => open
        );

    -- =========================================================
    -- H3 (LS27) - Vertical window and blanking NOR gates
    -- Gate3: NOR(V128, V16, j3_y2) -> h3_y3 (score visible window)
    -- Gate1: NOR(0, d3_y3, e3_y)   -> h3_y1 -> M2 BIn
    --   h3_y1 HIGH (no blank) when: SERVE_AND_ATRCn=0 AND h3_y3=1
    -- =========================================================
    ic_H3: entity work.LS27
        port map(
            P9_A3  => V128,         -- gate3 A
            P10_B3 => V16,          -- gate3 B
            P11_C3 => j3_y2,        -- gate3 C: NAND(V32,V64)
            P8_Y3  => h3_y3,        -- vertical score window -> E3
            P1_A1  => ic_h2_y1,     -- gate1 A: horizontal score window (NAND of H128/H256/H64 XORs)
            P2_B1  => d3_y3,        -- gate1 B: AND(SERVE,ATRCn)
            P13_C1 => e3_y,         -- gate1 C: NOT(h3_y3)
            P12_Y1 => h3_y1,        -- -> M2 P4_BIn
            -- gate2 unused
            P3_A2  => '0',
            P4_B2  => '0',
            P5_C2  => '0',
            P6_Y2  => open
        );

    -- =========================================================
    -- E3 (LS04) - Inverter: NOT(h3_y3) -> H3 gate1 C
    -- =========================================================
    ic_E3: entity work.LS04
        port map(
            P1_A1  => h3_y3,
            P2_Y1  => e3_y,         -- -> H3 P13_C1
            -- remaining gates unused
            P3_A2  => '0',  P4_Y2  => open,
            P5_A3  => '0',  P6_Y3  => open,
            P9_A4  => '0',  P8_Y4  => open,
            P11_A5 => '0',  P10_Y5 => open,
            P13_A6 => '0',  P12_Y6 => open
        );

    -- =========================================================
    -- F2 (LS86) - Horizontal XOR decode for digit position
    -- Gate1: H128 XOR H256  -> ic_H2 gate1 A
    -- Gate2: H256n XOR H64  -> ic_H2 gate1 B
    -- =========================================================
    ic_F2: entity work.LS86
        port map(
            P1_A1  => H128,
            P2_B1  => H256,
            P3_Y1  => f2_y1,        -- -> ic_H2 P1_A1
            P4_A2  => H256n,
            P5_B2  => H64,
            P6_Y2  => f2_y2,        -- -> ic_H2 P2_B1
            -- gate3, gate4 unused
            P9_A3  => '0',  P10_B3 => '0',  P8_Y3  => open,
            P12_A4 => '0',  P13_B4 => '0',  P11_Y4 => open
        );

    -- =========================================================
    -- ic_H2 (LS10 at PCB location H2) - Horizontal segment timing NAND
    -- Gate1: NAND(f2_y1, f2_y2, '1') - horizontal window (output not traced)
    -- Gate2: NAND(H8, V2, V4)         -> ic_h2_y2 -> J2 gate3
    -- Gate3: NAND('1', NOT(ic_h2_y2), V8) -> ic_h2_y3 -> L1_E
    -- =========================================================
    ic_H2: entity work.LS10
        port map(
            P1_A1  => f2_y1,        -- gate1 A: H128 XOR H256
            P2_B1  => f2_y2,        -- gate1 B: H256n XOR H64
            P13_C1 => H32,          -- gate1 C: H32 (narrows score window to 32 H pixels = single tens+units pair)
            P12_Y1 => ic_h2_y1,     -- -> H3 P1_A1 (horizontal score window)
            P3_A2  => H8,           -- gate2 A
            P4_B2  => V2,           -- gate2 B
            P5_C2  => V4,           -- gate2 C
            P6_Y2  => ic_h2_y2,     -- -> J2 P5_A3 (for inversion)
            P9_A3  => m2_d,         -- gate3 A: segment d (BCD-decoded), gates segment d timing
            P10_B3 => j2_y3,        -- gate3 B: NOT(ic_h2_y2) from J2
            P11_C3 => V8,           -- gate3 C
            P8_Y3  => ic_h2_y3      -- -> L1 P5_E (segment d composite)
        );

    -- =========================================================
    -- J2 (LS04 at PCB location J2) - Inverters
    -- Gate2: NOT(V8)        = V8n  -> K2_C1, L2_B1, L2_A2, K2_B3
    -- Gate3: NOT(ic_h2_y2)        -> K2_A3, ic_H2 gate3 B
    -- Gate6: NOT(H8)        = H8n -> H5_B1, F3_B2, N4_B3
    -- =========================================================
    ic_J2: entity work.LS04
        port map(
            P3_A2  => V8,
            P4_Y2  => j2_y2,        -- V8n
            P5_A3  => ic_h2_y2,
            P6_Y3  => j2_y3,        -- NOT(ic_h2_y2)
            P13_A6 => H8,
            P12_Y6 => j2_y6,        -- H8n
            -- gate1, gate4, gate5 unused
            P1_A1  => '0',  P2_Y1  => open,
            P9_A4  => '0',  P8_Y4  => open,
            P11_A5 => '0',  P10_Y5 => open
        );

    -- =========================================================
    -- N4 (LS27 at PCB location N4) - NOR gate for H segment window
    -- Gate3: NOR(H4, H8n, H2) -> n4_y3 -> K2_B1, K2_A2
    -- =========================================================
    ic_N4: entity work.LS27
        port map(
            P9_A3  => H4,           -- gate3 A
            P10_B3 => j2_y6,        -- gate3 B: H8n
            P11_C3 => H2,           -- gate3 C: H2 counter bit
            P8_Y3  => n4_y3,        -- -> K2 P2_B1, K2 P3_A2
            -- gate1, gate2 unused
            P1_A1  => '0',  P2_B1  => '0',  P13_C1 => '0',  P12_Y1 => open,
            P3_A2  => '0',  P4_B2  => '0',  P5_C2  => '0',  P6_Y2  => open
        );

    -- =========================================================
    -- K2 (LS10 at PCB location K2) - Segment gating NAND
    -- Gate1: NAND(m2_f, n4_y3, V8n) -> k2_y1 -> L1_C
    -- Gate2: NAND(n4_y3, m2_e, V8)  -> k2_y2 -> L1_B
    -- Gate3: NAND(NOT(ic_h2_y2), V8n, m2_g) -> k2_y3 -> L1_D
    -- =========================================================
    ic_K2: entity work.LS10
        port map(
            P1_A1  => m2_f,         -- gate1 A: segment f
            P2_B1  => n4_y3,        -- gate1 B: NOR(H4,H8n,H2)
            P13_C1 => j2_y2,        -- gate1 C: V8n
            P12_Y1 => k2_y1,        -- -> L1 P3_C
            P3_A2  => n4_y3,        -- gate2 A: NOR(H4,H8n,H2)
            P4_B2  => m2_e,         -- gate2 B: segment e
            P5_C2  => V8,           -- gate2 C
            P6_Y2  => k2_y2,        -- -> L1 P2_B
            P9_A3  => j2_y3,        -- gate3 A: NOT(ic_h2_y2)
            P10_B3 => j2_y2,        -- gate3 B: V8n
            P11_C3 => m2_g,         -- gate3 C: segment g
            P8_Y3  => k2_y3         -- -> L1 P4_D
        );

    -- =========================================================
    -- H5 (LS02 at PCB location H5) - NOR gates
    -- Gate2: NOR(V2, V4)   -> h5_y2 -> L2 gate1 C (L2_C1) (top-of-digit V decode)
    -- Gate1: NOR(V8, H8n)  -> h5_y1 -> L2 gate1 B (V8n AND H8: top half of digit, right half of slot)
    -- =========================================================
    ic_H5: entity work.LS02
        port map(
            P5_A2  => V2,           -- gate2 A
            P6_B2  => V4,           -- gate2 B
            P4_Y2  => h5_y2,        -- NOR(V2,V4) -> L2 P13_C1
            P2_A1  => V8,           -- gate1 A: V8
            P3_B1  => j2_y6,        -- gate1 B: H8n
            P1_Y1  => h5_y1,        -- NOR(V8, H8n) -> L2 P2_B1 (segment a H/V composite)
            -- gate3, gate4 unused
            P8_A3  => '0',  P9_B3  => '0',  P10_Y3 => open,
            P11_A4 => '0',  P12_B4 => '0',  P13_Y4 => open
        );

    -- =========================================================
    -- F3 (LS02 at PCB location F3) - NOR gate for segment H decode
    -- Gate2: NOR(j3_y3, H8n) -> f3_y2 -> L2_B2 (L2 gate2 B), L2_C3 (L2 gate3 C)
    -- =========================================================
    ic_F3: entity work.LS02
        port map(
            P5_A2  => j3_y3,        -- gate2 A: NAND(H4,H2)
            P6_B2  => j2_y6,        -- gate2 B: H8n
            P4_Y2  => f3_y2,        -- -> L2 P4_B2, L2 P11_C3
            -- gate1, gate3, gate4 unused
            P2_A1  => '0',  P3_B1  => '0',  P1_Y1  => open,
            P8_A3  => '0',  P9_B3  => '0',  P10_Y3 => open,
            P11_A4 => '0',  P12_B4 => '0',  P13_Y4 => open
        );

    -- =========================================================
    -- L2 (LS10 at PCB location L2) - Segment gating NAND
    -- Gate1: NAND(m2_a, V8n, NOR(V2,V4)) -> l2_y1 -> L1_G
    -- Gate2: NAND(V8n, f3_y2, m2_b)      -> l2_y2 -> L1_A
    -- Gate3: NAND(m2_c, V8,  f3_y2)      -> l2_y3 -> L1_H
    -- =========================================================
    ic_L2: entity work.LS10
        port map(
            P1_A1  => m2_a,         -- gate1 A: segment a
            P2_B1  => h5_y1,        -- gate1 B: NOR(V8,H8n) = V8n AND H8 (top half + right half of slot)
            P13_C1 => h5_y2,        -- gate1 C: NOR(V2,V4)
            P12_Y1 => l2_y1,        -- -> L1 P11_G
            P3_A2  => j2_y2,        -- gate2 A: V8n
            P4_B2  => f3_y2,        -- gate2 B: NOR(NAND(H4,H2), H8n)
            P5_C2  => m2_b,         -- gate2 C: segment b
            P6_Y2  => l2_y2,        -- -> L1 P1_A
            P9_A3  => m2_c,         -- gate3 A: segment c
            P10_B3 => V8,           -- gate3 B
            P11_C3 => f3_y2,        -- gate3 C: NOR(NAND(H4,H2), H8n)
            P8_Y3  => l2_y3         -- -> L1 P12_H
        );

    -- =========================================================
    -- L1 (LS30) - 8-input NAND: final SCORE video output
    -- SCORE goes HIGH when any segment/timeline/playfield pixel is active.
    -- A=L2_Y2, B=K2_Y2, C=K2_Y1, D=K2_Y3, E=ic_H2_Y3, F=D3_Y1, G=L2_Y1, H=L2_Y3
    -- =========================================================
    ic_L1: entity work.LS30
        port map(
            P1_A  => l2_y2,         -- L2_Y2 (segment b timing)
            P2_B  => k2_y2,         -- K2_Y2 (segment e timing)
            P3_C  => k2_y1,         -- K2_Y1 (segment f timing)
            P4_D  => k2_y3,         -- K2_Y3 (segment g timing)
            P5_E  => ic_h2_y3,      -- ic_H2_Y3
            P6_F  => d3_y1,         -- AND(TIME_LINEn, PLAYFIELDn)
            P11_G => l2_y1,         -- L2_Y1 (segment a timing)
            P12_H => l2_y3,         -- L2_Y3 (segment c timing)
            P8_Y  => score_i
        );

    SCORE <= score_i;

end Structural;
