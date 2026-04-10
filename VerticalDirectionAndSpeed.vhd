-- Vertical Direction and Speed Circuit - Goal IV (WCC) TM-035 Figure 14
-- ICs: D7(IC9314), D6(LS74), C7(LS86), B7(LS02), F6(LS00), C6(LS04), A7(LS83)
-- Converts player-segment data PP2, PP3, PP4 into vertical-motion code VSPEED(3:0).

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity VerticalDirectionAndSpeed is
    Port (
        V128n   : in  STD_LOGIC;
        VBOUNCE : in  STD_LOGIC;
        HIT     : in  STD_LOGIC;
        PP2     : in  STD_LOGIC;
        PP3     : in  STD_LOGIC;
        PP4     : in  STD_LOGIC;
        SERVEn  : in  STD_LOGIC;
        STOPP   : in  STD_LOGIC;
        STOPn   : in  STD_LOGIC;
        VSPEED  : out STD_LOGIC_VECTOR(3 downto 0);
        HITn    : out STD_LOGIC
    );
end VerticalDirectionAndSpeed;

architecture Schematic of VerticalDirectionAndSpeed is
    signal D7_Q0, D7_Q1, D7_Q2 : STD_LOGIC;
    signal D6_Q1 : STD_LOGIC;
    signal C7_Y1, C7_Y2, C7_Y3, C7_Y4 : STD_LOGIC;
    signal B7_Y1, B7_Y2 : STD_LOGIC;
    signal F6_Y4 : STD_LOGIC;
    signal C6_Y3 : STD_LOGIC;
    signal A7_S1, A7_S2, A7_S3, A7_S4 : STD_LOGIC;
    signal hitn_i : STD_LOGIC;  -- internal HITn (feeds D7 OEn and entity output)
begin
    -- C6 (LS04): inverters for HIT and F6 output
    C6: entity work.LS04
        port map(
            P5_A3  => F6_Y4,
            P6_Y3  => C6_Y3,
            P13_A6 => HIT,
            P12_Y6 => hitn_i
        );
    HITn <= hitn_i;

    -- C7 (LS86): XOR gates per Fig 14
    C7: entity work.LS86
        port map(
            P1_A1  => D6_Q1,
            P2_B1  => D7_Q0,
            P3_Y1  => C7_Y1,
            P4_A2  => D7_Q1,
            P5_B2  => D6_Q1,
            P6_Y2  => C7_Y2,
            P9_A3  => D7_Q2,
            P10_B3 => D6_Q1,
            P8_Y3  => C7_Y3,
            P12_A4 => D7_Q2,
            P13_B4 => V128n,
            P11_Y4 => C7_Y4
        );

    -- D6 (LS74): flip-flop 1 used; flip-flop 2 unused
    D6: entity work.LS74
        port map(
            P1_CLR1n  => hitn_i,
            P2_D1     => C7_Y4,
            P3_CLK1   => VBOUNCE,
            P4_SET1n  => '1',
            P5_Q1     => D6_Q1,
            P6_Q1n    => open,
            P8_Q2n    => open,
            P9_Q2     => open,
            P10_SET2n => '1',
            P11_CLK2  => '0',
            P12_D2    => '0',
            P13_CLR2n => '1'
        );

    -- D7 (IC9314): quad latch - player data PP2,PP3,PP4; Q3 tied via D3='0', S3n='1'
    D7: entity work.IC9314
        port map(
            P1_OEn  => hitn_i,
            P2_S0n  => '0',
            P3_D0   => PP2,
            P4_D1   => PP3,
            P5_S2n  => '0',
            P6_D2   => PP4,
            P7_D3   => '0',
            P9_MRn  => SERVEn,
            P10_Q3  => open,   -- not on schematic (4th latch unused)
            P11_S3n => '1',
            P12_Q2  => D7_Q2,
            P13_Q1  => D7_Q1,
            P14_S1n => '0',
            P15_Q0  => D7_Q0
        );

    -- B7 (LS02): NOR gates
    B7: entity work.LS02
        port map(
            P2_A1  => STOPP,
            P3_B1  => C7_Y1,
            P1_Y1  => B7_Y1,
            P5_A2  => STOPP,
            P6_B2  => C7_Y2,
            P4_Y2  => B7_Y2,
            P8_A3  => '0',
            P9_B3  => '0',
            P10_Y3 => open,
            P11_A4 => '0',
            P12_B4 => '0',
            P13_Y4 => open
        );

    -- F6 (LS00): NAND gate
    F6: entity work.LS00
        port map(
            P12_A4 => C7_Y3,
            P13_B4 => STOPn,
            P11_Y4 => F6_Y4,
            P1_A1  => '1',
            P2_B1  => '1',
            P3_Y1  => open,
            P4_A2  => '1',
            P5_B2  => '1',
            P6_Y2  => open,
            P9_A3  => '1',
            P10_B3 => '1',
            P8_Y3  => open
        );

    -- A7 (LS83): 4-bit adder. A = NOR outputs; B = constants; CIN = inverted F6
    A7: entity work.LS83
        port map(
            P1_A4   => '0',
            P2_S3   => A7_S3,
            P3_A3   => F6_Y4,
            P4_B3   => '1',
            P6_S2   => A7_S2,
            P7_B2   => '1',
            P8_A2   => B7_Y2,
            P9_S1   => A7_S1,
            P10_A1  => B7_Y1,
            P11_B1  => '0',
            P13_CIN => C6_Y3,
            P14_COUT=> open,
            P15_S4  => A7_S4,
            P16_B4  => '0'
        );
    VSPEED <= (A7_S4, A7_S3, A7_S2, A7_S1);
end Schematic;
