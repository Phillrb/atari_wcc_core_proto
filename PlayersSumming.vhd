-- Players Summing + Hit Circuit - Goal IV (WCC) TM-035 Figures 11 & 17
-- Check pattern (E6-6, F6-6), one-player defensemen defeat (J2-2, J1-6), M1-6, K6-6 -> PADDLES.
-- E6 pin 4=H1, 5=V1, 6->F6 pin 5; F6 pin 4=TEAM, 6->K6 pin 5.
-- J2 pin 1=DEFENSEMENn, 2->J1 pin 4; ONE_PLAYER->J1 pin 5; J1 pin 6->M1 pin 4.
-- SYMBOL (H7 pin 9)->M1 pin 5; M1 pin 6->K6 pin 4. K6 pin 6=PADDLES.
-- Hit Circuit (Fig 17): K6 gate 4: BALL(pin 13) AND PADDLES(pin 12) -> HIT(pin 11).

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PlayersSumming is
    Port (
        H1             : in  STD_LOGIC;   -- 1H for check pattern
        V1             : in  STD_LOGIC;   -- 1V for check pattern
        TEAM           : in  STD_LOGIC;
        DEFENSEMENn    : in  STD_LOGIC;
        ONE_PLAYER     : in  STD_LOGIC;
        SYMBOL         : in  STD_LOGIC;   -- from H7 pin 9 (player symbol from mux)
        BALL           : in  STD_LOGIC;   -- ball video signal -> K6 pin 13
        PADDLES        : out STD_LOGIC;
        HIT            : out STD_LOGIC    -- K6 pin 11: BALL AND PADDLES
    );
end PlayersSumming;

architecture Schematic of PlayersSumming is
    signal E6_Y2       : STD_LOGIC;  -- XOR(H1, V1) -> F6 pin 5
    signal F6_Y2       : STD_LOGIC;  -- NAND(TEAM, E6_Y2) -> K6 pin 5 (check pattern)
    signal J2_Y1       : STD_LOGIC;  -- not DEFENSEMENn -> J1 pin 4
    signal J1_Y2    : STD_LOGIC;  -- NAND(J2_Y1, ONE_PLAYER) -> M1 pin 4
    signal M1_Y2    : STD_LOGIC;  -- AND(J1_Y2, SYMBOL) -> K6 pin 4
    signal paddles_i : STD_LOGIC; -- K6 gate 2 output, read back for HIT
begin
    PADDLES <= paddles_i;
    -- E6 gate 2: XOR(H1, V1). Pin 4=A2, 5=B2, 6=Y2 -> F6 pin 5
    IC_E6: entity work.LS86
        port map(
            P4_A2   => H1,
            P5_B2   => V1,
            P6_Y2   => E6_Y2,
            P1_A1   => '0', P2_B1 => '0', P3_Y1 => open,
            P9_A3   => '0', P10_B3 => '0', P8_Y3 => open,
            P12_A4  => '0', P13_B4 => '0', P11_Y4 => open
        );

    -- F6 gate 2: NAND(TEAM, E6_Y2). Pin 4=A2, 5=B2, 6=Y2 -> K6 pin 5 (check pattern)
    IC_F6: entity work.LS00
        port map(
            P4_A2   => TEAM,
            P5_B2   => E6_Y2,
            P6_Y2   => F6_Y2,
            P1_A1   => '1', P2_B1 => '1', P3_Y1 => open,
            P9_A3   => '1', P10_B3 => '1', P11_Y4 => open, P12_A4 => '1', P13_B4 => '1',
            P8_Y3   => open
        );

    -- J2 gate: inverter. Pin 1=A1, 2=Y1 -> J1 pin 4 (DEFENSEMENn in, inverted out)
    IC_J2: entity work.LS04
        port map(
            P1_A1   => DEFENSEMENn,
            P2_Y1   => J2_Y1,
            P3_A2   => '0', P4_Y2 => open, P5_A3 => '0', P6_Y3 => open,
            P9_A4   => '0', P8_Y4 => open, P11_A5 => '0', P10_Y5 => open,
            P13_A6  => '0', P12_Y6 => open
        );

    -- J1 gate 2: NAND(J2_Y1, ONE_PLAYER). Pin 4=A2, 5=B2, 6=Y2 -> M1 pin 4
    IC_J1: entity work.LS00
        port map(
            P4_A2   => J2_Y1,
            P5_B2   => ONE_PLAYER,
            P6_Y2   => J1_Y2,
            P1_A1   => '1', P2_B1 => '1', P3_Y1 => open,
            P9_A3   => '1', P10_B3 => '1', P11_Y4 => open, P12_A4 => '1', P13_B4 => '1',
            P8_Y3   => open
        );

    -- M1 gate 2: AND(J1_Y2, SYMBOL). Pin 4=A2, 5=B2, 6=Y2 -> K6 pin 4
    IC_M1: entity work.LS08
        port map(
            P4_A2   => J1_Y2,
            P5_B2   => SYMBOL,
            P6_Y2   => M1_Y2,
            P1_A1   => '0', P2_B1 => '0', P3_Y1 => open,
            P9_A3   => '0', P10_B3 => '0', P11_Y4 => open, P12_A4 => '0', P13_B4 => '0',
            P8_Y3   => open
        );

    -- K6 gate 2: AND(M1_Y2, F6_Y2). Pin 4=A2, 5=B2, 6=Y2 = PADDLES
    -- K6 gate 4: AND(PADDLES, BALL). Pin 12=A4, 13=B4, 11=Y4 = HIT (Fig 17)
    IC_K6: entity work.LS08
        port map(
            P4_A2   => M1_Y2,
            P5_B2   => F6_Y2,
            P6_Y2   => paddles_i,
            P1_A1   => '0', P2_B1 => '0', P3_Y1 => open,
            P9_A3   => '0', P10_B3 => '0',
            P12_A4  => paddles_i, P13_B4 => BALL, P11_Y4 => HIT,
            P8_Y3   => open
        );
end Schematic;
