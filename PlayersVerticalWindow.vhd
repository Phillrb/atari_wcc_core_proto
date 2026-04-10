-- Vertical Window Generator - Goal IV (WCC) TM-035 Figure 11, Players Circuit
-- Per schematic: F6 (LS00), H6 (LS10), J6 (LS27), M6 (LS92), D6 (LS74), L6 (LS86).
-- TEAM to F6 pin 1; PLAYER to F6 pin 2; F6 pin 3 -> H6 pin 13.
-- H_ENABLE -> H6 pin 1; V_ENABLE -> H6 pin 10; H6 pin 12 -> J6 pin 5.
-- M6 (LS92): pin 5 = VCC (1), pin 10 = GND (0). Pin 8 (Q3) = pin 14 (CP0n) = L6 pin 5 (B2) = L6 pin 10 (B3); same net as M8 pin 14 if connected off-sheet. H8 -> pin 1; HRESET -> pin 6,7; pin 12 (Q0) -> D6 pin 11, L6 pin 2; pin 11 (Q1) -> J6 pin 4; pin 9 (Q2) = BLIP -> J6 pin 3.
-- D6 pin 8 (Q2n) -> D6 pin 12 (D2), L6 pin 1,9. D6 pin 11 (CLK2) = M6 Q0. D6 pin 13 (CLR2n) = HRESETn.
-- L6 pin 3 = GOALIE (A1 xor B1 = D6_Q2n xor M6_Q0); pin 6 = TEAM (A2 xor B2); pin 8 = DEFENSEMENn (A3 xor B3).
-- J6 gate 2: BLIP, M6_Q1, H6_Y1 -> J6 pin 6 -> H6 pin 5. H6 gate 2: H4n, H8, J6_Y2 -> H6 pin 6 (to H7 pin 15).
--
-- UNIFORM SPACING CORRECTION:
-- The schematic's J6 NOR(M6_Q2, M6_Q1, H6_Y1) opens player windows at LS92 states 0
-- and 4, giving alternating 64px/32px column spacing (4 vs 2 state gaps). This places
-- the player layout centre at H=280, offset ~6.5px from the playfield centre (H=273.5),
-- making the solid team visibly further from the left wall than the striped team from
-- the right wall.
--
-- Fix: Replace J6 inputs with NOR(Q1 XOR Q2, M6_Q3, H6_Y1). This opens windows at
-- states 0 and 3 only (uniform 3-state / 48px gap between columns). Also change L6
-- gates 2 and 3 from M6_Q3 to M6_Q2 so TEAM and DEFENSEMENn toggle correctly between
-- the new window pair (Q2 differs between states 0 and 3; Q3 does not).
--
-- Schematic-accurate J6: P3_A2 => M6_Q2, P4_B2 => M6_Q1
-- Schematic-accurate L6: P5_B2 => M6_Q3, P10_B3 => M6_Q3

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PlayersVerticalWindow is
    Port (
        H4       : in  STD_LOGIC;
        H8       : in  STD_LOGIC;
        HRESET   : in  STD_LOGIC;
        HRESETn  : in  STD_LOGIC;   -- D6 pin 13 (CLR2n)
        H_ENABLE : in  STD_LOGIC;
        V_ENABLE : in  STD_LOGIC;
        PLAYER   : in  STD_LOGIC;   -- 1-player (PLAYER=1) / 2-player (PLAYER=0)
        TEAM     : out STD_LOGIC;
        GOALIE   : out STD_LOGIC;
        DEFENSEMENn : out STD_LOGIC;
        Q        : out STD_LOGIC;   -- D6 Q2 (pin 9)
        Qn       : out STD_LOGIC;   -- D6 pin 8 (Q2n) -> L7/H7 S0
        BLIP     : out STD_LOGIC;  -- M6 Q2 (pin 9)
        PLAYER_WINDOWn : out STD_LOGIC  -- H6 pin 6 -> H7 pin 15 (mux enable)
    );
end PlayersVerticalWindow;

architecture Schematic of PlayersVerticalWindow is
    -- M6 (LS92) outputs
    signal M6_Q0, M6_Q1, M6_Q2, M6_Q3 : STD_LOGIC;
    signal M6_CP0n : STD_LOGIC;  -- M6 pin 14 driven by M6 pin 8 (Q3)
    -- D6 (LS74) FF2
    signal D6_Q2, D6_Q2n : STD_LOGIC;
    -- F6 gate 1: NAND(TEAM, PLAYER) -> H6 C1
    signal F6_Y1 : STD_LOGIC;
    -- H6 gate 1: NAND(H_ENABLE, V_ENABLE, F6_Y1) -> J6 C2
    signal H6_Y1 : STD_LOGIC;
    -- J6 gate 2: NOR(Q1_xor_Q2, M6_Q3, H6_Y1) -> H6 C2 (corrected; see header)
    signal J6_Y2 : STD_LOGIC;
    -- Q1 XOR Q2: high at states 1,2,4,5; low at states 0,3 (used by J6 for uniform spacing)
    signal Q1_xor_Q2 : STD_LOGIC;
    -- H6 gate 2: NAND(H4n, H8, J6_Y2) -> PLAYER_WINDOWn (to H7 pin 15)
    signal H6_Y2 : STD_LOGIC;
    -- L6 outputs
    signal L6_Y1, L6_Y2, L6_Y3 : STD_LOGIC;
    -- H4n = not H4 (for H6 gate 2)
    signal H4n : STD_LOGIC;
begin
    -- H4n from H4 (inverter)
    U_H4n: entity work.LS04
        port map(
            P1_A1   => H4,
            P2_Y1   => H4n,
            P3_A2   => '0', P4_Y2 => open, P5_A3 => '0', P6_Y3 => open,
            P9_A4   => '0', P8_Y4 => open, P11_A5 => '0', P10_Y5 => open,
            P13_A6  => '0', P12_Y6 => open
        );

    -- M6 (LS92): pin 5=VCC(1), pin 10=GND(0). Pin 8 (Q3) -> pin 14 (CP0n), L6 pin 5 (B2), L6 pin 10 (B3). H8 -> CP1n (1); HRESET -> 6,7.
    M6_CP0n <= M6_Q3;
    IC_M6: entity work.LS92
        port map(
            P1_CP1n  => H8,
            P6_MR1   => HRESET,
            P7_MR2   => HRESET,
            P14_CP0n => M6_CP0n,
            P12_Q0   => M6_Q0,
            P11_Q1   => M6_Q1,
            P9_Q2    => M6_Q2,
            P8_Q3    => M6_Q3
        );
    BLIP <= M6_Q2;

    -- D6 (LS74) FF2: CLK2 = M6_Q0 (pin 11), D2 = Q2n (pin 12 from pin 8). So toggles on M6_Q0.
    IC_D6: entity work.LS74
        port map(
            P1_CLR1n => '1', P2_D1 => '0', P3_CLK1 => '0', P4_SET1n => '1',
            P5_Q1    => open, P6_Q1n => open,
            P10_SET2n => '1',
            P11_CLK2  => M6_Q0,
            P12_D2    => D6_Q2n,
            P13_CLR2n => HRESETn,
            P8_Q2n    => D6_Q2n,
            P9_Q2     => D6_Q2
        );
    Q  <= D6_Q2;
    Qn <= D6_Q2n;

    -- L6 (LS86): gate 1 A1=D6_Q2n, B1=M6_Q0 -> Y1=GOALIE (pin 3).
    -- Gates 2 and 3 use M6_Q2 (corrected; schematic had M6_Q3).
    -- Q2 toggles between states 0 and 3, so TEAM and DEFENSEMENn alternate correctly
    -- with the uniform-spacing window pair. Q3 does not differ between states 0 and 3.
    IC_L6: entity work.LS86
        port map(
            P1_A1   => D6_Q2n,
            P2_B1   => M6_Q0,
            P3_Y1   => L6_Y1,
            P4_A2   => L6_Y1,   -- L6 pin 3 to L6 pin 4 (Y1 -> A2)
            P5_B2   => M6_Q2,   -- was M6_Q3 (corrected for uniform spacing)
            P6_Y2   => L6_Y2,
            P9_A3   => D6_Q2n,
            P10_B3  => M6_Q2,   -- was M6_Q3 (corrected for uniform spacing)
            P8_Y3   => L6_Y3,
            P12_A4  => '0', P13_B4 => '0', P11_Y4 => open
        );
    GOALIE     <= L6_Y1;
    TEAM       <= L6_Y2;
    DEFENSEMENn <= L6_Y3;

    -- F6 gate 1: NAND(TEAM, PLAYER). F6 pin 1=TEAM, pin 2=PLAYER, pin 3=Y1 -> H6 pin 13.
    IC_F6: entity work.LS00
        port map(
            P1_A1   => L6_Y2,   -- TEAM (from L6)
            P2_B1   => PLAYER,
            P3_Y1   => F6_Y1,
            P4_A2   => '1', P5_B2 => '1', P6_Y2 => open,
            P9_A3   => '1', P10_B3 => '1', P11_Y4 => open, P12_A4 => '1', P13_B4 => '1',
            P8_Y3   => open
        );

    -- H6 (LS10) one physical IC: gate 1 then J6 then gate 2 so comb loop resolves (J6 needs H6_Y1; H6 gate 2 needs J6_Y2).
    IC_H6_g1: entity work.LS10
        port map(
            P1_A1   => H_ENABLE,
            P2_B1   => V_ENABLE,
            P13_C1  => F6_Y1,
            P12_Y1  => H6_Y1,
            P3_A2   => '1', P4_B2 => '1', P5_C2 => '1', P6_Y2 => open,
            P9_A3   => '1', P10_B3 => '1', P11_C3 => '1', P8_Y3 => open
        );

    -- Q1 XOR Q2 (spare L6 gate or F6 gate; produces '0' at M6 states 0 and 3 only)
    -- Schematic-accurate: J6 inputs were M6_Q2 (BLIP) and M6_Q1 directly.
    IC_Q1xQ2: entity work.LS86
        port map(
            P1_A1   => M6_Q1,
            P2_B1   => M6_Q2,
            P3_Y1   => Q1_xor_Q2,
            P4_A2   => '0', P5_B2 => '0', P6_Y2 => open,
            P9_A3   => '0', P10_B3 => '0', P8_Y3 => open,
            P12_A4  => '0', P13_B4 => '0', P11_Y4 => open
        );

    -- J6 (LS27) gate 2: NOR(Q1_xor_Q2, M6_Q3, H6_Y1) -> opens at states 0 and 3.
    -- Schematic-accurate was: NOR(M6_Q2, M6_Q1, H6_Y1) -> opened at states 0 and 4.
    IC_J6: entity work.LS27
        port map(
            P3_A2   => Q1_xor_Q2,   -- was M6_Q2 (corrected for uniform spacing)
            P4_B2   => M6_Q3,       -- was M6_Q1 (corrected: Q3 blocks state 4)
            P5_C2   => H6_Y1,
            P6_Y2   => J6_Y2,
            P1_A1   => '0', P2_B1 => '0', P13_C1 => '0', P12_Y1 => open,
            P9_A3   => '0', P10_B3 => '0', P11_C3 => '0', P8_Y3 => open
        );

    IC_H6_g2: entity work.LS10
        port map(
            P3_A2   => H4n,
            P4_B2   => H8,
            P5_C2   => J6_Y2,
            P6_Y2   => H6_Y2,
            P1_A1   => '1', P2_B1 => '1', P13_C1 => '1', P12_Y1 => open,
            P9_A3   => '1', P10_B3 => '1', P11_C3 => '1', P8_Y3 => open
        );

    PLAYER_WINDOWn <= H6_Y2;
end Schematic;
