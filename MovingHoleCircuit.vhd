-- Moving Hole Circuit - Goal IV (WCC), TM-035 Figure 18
-- ICs: F3(LS02), K1(LS74 FF2), L4/M4(9316), H1(LS107 FF1),
--      M1(LS08 gate 4), J1(LS00 gate 1), E3(LS04 gate 2).
-- HOLE is active HIGH; E3 supplies its complement to F3 internally.
-- K1 retains direction across START; STARTn clears L4, M4 and H1 only.
-- Confirmed 9/11 presets yield 311/309-line periods, not bounded up/down
-- motion on the 313-line raster. See docs/MOVING_HOLE_FIG18.md.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MovingHoleCircuit is
    Port (
        C_PLUS_Dn : in  STD_LOGIC;   -- (C+D)n from playfield: top/bottom boundaries
        HSYNCn    : in  STD_LOGIC;   -- Horizontal sync: counter clock
        STARTn    : in  STD_LOGIC;   -- Active-low reset for L4, M4 and H1
        V128      : in  STD_LOGIC;   -- Vertical position sampled by K1
        HOLE      : out STD_LOGIC    -- Active-high moving opening to Figure 19
    );
end MovingHoleCircuit;

architecture Schematic of MovingHoleCircuit is
    -- F3 pin 1 clocks K1 FF2 when HOLE overlaps a playfield boundary
    signal boundary_clock : STD_LOGIC;
    -- K1 pin 9 selects L4's preset bit B
    signal direction_i    : STD_LOGIC;
    -- L4/M4 terminal-count outputs (pin 15)
    signal l4_tc, m4_tc    : STD_LOGIC;
    -- H1 pin 3 supplies the upper counter stage
    signal h1_q           : STD_LOGIC;
    -- J1 pin 3 drives both counters' active-low load inputs
    signal load_n         : STD_LOGIC;
    -- M1 pin 11 = HOLE; E3 pin 4 = HOLEn for feedback to F3
    signal hole_i, hole_n  : STD_LOGIC;
begin
    HOLE <= hole_i;

    -- ========== F3 (LS02) gate 1: boundary sampling clock
    -- (C+D)n -> pin 2, HOLEn -> pin 3; pin 1 -> K1 pin 11
    IC_F3: entity work.LS02
        port map(
            P2_A1   => C_PLUS_Dn,    -- Playfield boundary to F3 pin 2
            P3_B1   => hole_n,       -- E3 pin 4 to F3 pin 3
            P1_Y1   => boundary_clock, -- F3 pin 1 to K1 pin 11
            P5_A2   => '0', P6_B2 => '0', P4_Y2 => open,
            P8_A3   => '0', P9_B3 => '0', P10_Y3 => open,
            P11_A4  => '0', P12_B4 => '0', P13_Y4 => open
        );

    -- ========== K1 (LS74) FF2: direction latch
    -- V128 -> pin 12 (D2), F3 pin 1 -> pin 11 (CLK2); pin 9 -> L4 pin 4
    -- Preset and clear are tied high: STARTn does not reset direction.
    IC_K1: entity work.LS74
        port map(
            P12_D2    => V128,          -- V128 to K1 pin 12
            P11_CLK2  => boundary_clock, -- F3 pin 1 to K1 pin 11
            P10_SET2n => '1',           -- Preset inactive
            P13_CLR2n => '1',           -- Clear inactive
            P9_Q2     => direction_i,   -- K1 pin 9 to L4 pin 4
            P8_Q2n    => open,
            P1_CLR1n  => '1', P2_D1 => '0', P3_CLK1 => '0', P4_SET1n => '1',
            P5_Q1     => open, P6_Q1n => open
        );

    -- ========== L4 (9316): low counter and variable preset
    -- A=1, B=K1 pin 9, C=0, D=1: confirmed Figure 18 presets 9 or 11.
    -- Pin 15 -> M4 pin 7, H1 pin 12 and J1 pin 1
    IC_L4: entity work.IC9316
        port map(
            P1_CLRn => STARTn,      -- STARTn to L4 pin 1
            P2_CLK  => HSYNCn,      -- HSYNCn to L4 pin 2
            P3_A    => '1',         -- Preset bit A (LSB)
            P4_B    => direction_i, -- K1 pin 9 to L4 pin 4
            P5_C    => '0',         -- Preset bit C
            P6_D    => '1',         -- Preset bit D (MSB)
            P7_CEP  => '1',         -- Parallel count enable
            P10_CET => '1',         -- Trickle count enable
            P9_LDn  => load_n,      -- J1 pin 3 to L4 pin 9
            P15_RC  => l4_tc,       -- L4 pin 15 = terminal count
            P14_QA  => open, P13_QB => open, P12_QC => open, P11_QD => open
        );

    -- ========== M4 (9316): high counter, fixed preset 12 (1100)
    -- L4 pin 15 drives CEP, while CET stays high. M4 terminal count
    -- therefore remains high for all sixteen counts of L4.
    IC_M4: entity work.IC9316
        port map(
            P1_CLRn => STARTn,      -- STARTn to M4 pin 1
            P2_CLK  => HSYNCn,      -- HSYNCn to M4 pin 2
            P3_A    => '0',         -- Preset bit A (LSB)
            P4_B    => '0',         -- Preset bit B
            P5_C    => '1',         -- Preset bit C
            P6_D    => '1',         -- Preset bit D (MSB)
            P7_CEP  => l4_tc,       -- L4 pin 15 to M4 pin 7
            P10_CET => '1',         -- Trickle count enable
            P9_LDn  => load_n,      -- J1 pin 3 to M4 pin 9
            P15_RC  => m4_tc,       -- M4 pin 15 to H1 pins 1/4 and M1 pin 13
            P14_QA  => open, P13_QB => open, P12_QC => open, P11_QD => open
        );

    -- ========== H1 (LS107) FF1: upper counter stage
    -- M4 pin 15 -> J/K pins 1/4, L4 pin 15 -> clock pin 12;
    -- STARTn -> clear pin 13, Q pin 3 -> M1 pin 12
    IC_H1: entity work.LS107
        generic map(
            MASTER_SLAVE => true    -- Original 74107 shown in Figure 18
        )
        port map(
            P1_J1     => m4_tc,     -- M4 pin 15 to H1 pin 1
            P4_K1     => m4_tc,     -- M4 pin 15 to H1 pin 4
            P12_CLK1  => l4_tc,     -- L4 pin 15 to H1 pin 12
            P13_CLR1n => STARTn,    -- STARTn to H1 pin 13
            P3_Q1     => h1_q,      -- H1 pin 3 to M1 pin 12
            P2_Q1n    => open,
            P8_J2     => '0', P11_K2 => '0', P9_CLK2 => '0', P10_CLR2n => '1',
            P5_Q2     => open, P6_Q2n => open
        );

    -- ========== M1 (LS08) gate 4: HOLE output
    -- H1 pin 3 -> pin 12, M4 pin 15 -> pin 13; pin 11 = HOLE
    IC_M1: entity work.LS08
        port map(
            P12_A4  => h1_q,        -- H1 pin 3 to M1 pin 12
            P13_B4  => m4_tc,       -- M4 pin 15 to M1 pin 13
            P11_Y4  => hole_i,      -- M1 pin 11 to J1 pin 2 and E3 pin 3
            P1_A1   => '0', P2_B1 => '0', P3_Y1 => open,
            P4_A2   => '0', P5_B2 => '0', P6_Y2 => open,
            P9_A3   => '0', P10_B3 => '0', P8_Y3 => open
        );

    -- ========== J1 (LS00) gate 1: counter reload
    -- L4 pin 15 -> pin 1, HOLE -> pin 2; pin 3 -> L4/M4 pin 9
    IC_J1: entity work.LS00
        port map(
            P1_A1   => l4_tc,       -- L4 pin 15 to J1 pin 1
            P2_B1   => hole_i,      -- M1 pin 11 to J1 pin 2
            P3_Y1   => load_n,      -- J1 pin 3 to L4/M4 pin 9 (LDn)
            P4_A2   => '1', P5_B2 => '1', P6_Y2 => open,
            P9_A3   => '1', P10_B3 => '1', P8_Y3 => open,
            P12_A4  => '1', P13_B4 => '1', P11_Y4 => open
        );

    -- ========== E3 (LS04) gate 2: HOLEn feedback
    -- HOLE -> pin 3; pin 4 -> F3 pin 3
    IC_E3: entity work.LS04
        port map(
            P3_A2   => hole_i,      -- M1 pin 11 to E3 pin 3
            P4_Y2   => hole_n,      -- E3 pin 4 to F3 pin 3
            P1_A1   => '0', P2_Y1 => open,
            P5_A3   => '0', P6_Y3 => open,
            P9_A4   => '0', P8_Y4 => open,
            P11_A5  => '0', P10_Y5 => open,
            P13_A6  => '0', P12_Y6 => open
        );
end Schematic;
