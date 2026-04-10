-- Horizontal Direction and Speed Circuit - Goal IV (WCC) TM-035 Figure 15
-- ICs: B6(IC9316), A6(LS08), A5(LS86), B5(LS83), F6(LS00), B7(LS02), C6(LS04), F5(LS08)
-- Develops horizontal motion codes (HSPEED) from speed counter + direction signal.
--
-- Signal flow:
--   B6 counter increments on each goalie/forward hit (clock from F6 NAND gate 3)
--   B6 QC/QD form speed code, gated by A6 AND gates (enabled during VRESET only)
--   A5 XOR gates conditionally invert speed code based on horizontal direction
--   B5 adder sums XOR outputs + fixed 1010 + direction -> HSPEED motion code
--   When STOPn low or outside VRESET: A6 outputs all zero -> adder produces stop code (1010)
--
-- Shared ICs (each circuit instantiates its own copy with unused gates tied off):
--   F6 (LS00): gate 3 here, gate 4 in Fig 14
--   B7 (LS02): gate 4 here, gates 1,2 in Fig 14
--   C6 (LS04): gates 2,4 here, gates 3,6 in Fig 14
--   F5 (LS08): gate 4 here, gates 1-3 in Fig 19

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity HorizontalDirectionAndSpeed is
    Port (
        VRESET          : in  STD_LOGIC;   -- start of field pulse
        STOPn           : in  STD_LOGIC;   -- from J5 one-shot (active-low stop)
        HORIZ_DIR       : in  STD_LOGIC;   -- from D8 Q1n (CatchKick circuit)
        GOAL            : in  STD_LOGIC;   -- high when goal scored
        SCORE_SOUNDn    : in  STD_LOGIC;   -- active-low score sound
        ONE_PLAYER      : in  STD_LOGIC;   -- high for 1-player mode
        ATRC            : in  STD_LOGIC;   -- attract mode
        GOALIE_FWD_HIT  : in  STD_LOGIC;   -- active-low pulse on goalie/forward hit
        HSPEED          : out STD_LOGIC_VECTOR(3 downto 0);  -- (Hd,Hc,Hb,Ha)
        SLOW            : out STD_LOGIC    -- low when max speed reached (count=15)
    );
end HorizontalDirectionAndSpeed;

architecture Schematic of HorizontalDirectionAndSpeed is
    -- B6 (IC9316) speed counter outputs
    signal B6_QC, B6_QD, B6_RC : STD_LOGIC;

    -- C6 (LS04) inverter outputs
    signal C6_4  : STD_LOGIC;  -- gate 2 (pin 3->4): NOT(QC)
    signal C6_8  : STD_LOGIC;  -- gate 4 (pin 9->8): NOT(RC) = SLOW, -> B6 CEP

    -- B7 (LS02) NOR output
    signal B7_13 : STD_LOGIC;  -- gate 4: NOR(GOAL, ATRC) -> B6 LDn

    -- F6 (LS00) NAND output
    signal F6_8  : STD_LOGIC;  -- gate 3: NAND(SCORE_SOUNDn, GOALIE_FWD_HIT) -> B6 CLK

    -- F5 (LS08) AND output
    signal F5_11 : STD_LOGIC;  -- gate 4: AND(STOPn, VRESET) -> A6 enable

    -- A6 (LS08) AND gate outputs
    signal A6_3  : STD_LOGIC;  -- gate 1: AND(HORIZ_DIR, F5_11) -> direction
    signal A6_6  : STD_LOGIC;  -- gate 2: AND(B6_QD, F5_11)
    signal A6_8  : STD_LOGIC;  -- gate 3: AND(NOT_QC, F5_11)
    signal A6_11 : STD_LOGIC;  -- gate 4: AND(B6_QC, F5_11)

    -- A5 (LS86) XOR gate outputs
    signal A5_3  : STD_LOGIC;  -- gate 1: XOR(A6_6, A6_3) -> B5 B1
    signal A5_8  : STD_LOGIC;  -- gate 3: XOR(A6_8, A6_3) -> B5 B3
    signal A5_11 : STD_LOGIC;  -- gate 4: XOR(A6_11, A6_3) -> B5 B2

    -- B5 (LS83) adder outputs
    signal B5_S1, B5_S2, B5_S3, B5_S4 : STD_LOGIC;

begin

    -- B6 (IC9316): speed counter - increments on each goalie/forward hit
    -- Preset: 0000 (2-player) or 0100 (1-player via pin 5/C)
    -- Stops counting at 15 via CEP = NOT(RC) feedback
    B6: entity work.IC9316
        port map(
            P1_CLRn  => '1',          -- CLRn tied high (not used)
            P2_CLK   => F6_8,         -- clock from F6 NAND gate 3
            P3_A     => '0',          -- preset A = 0
            P4_B     => '0',          -- preset B = 0
            P5_C     => ONE_PLAYER,   -- preset C = 1PLAYER (0100 for 1P mode)
            P6_D     => '0',          -- preset D = 0
            P7_CEP   => C6_8,         -- count enable = NOT(RC); inhibits at max
            P9_LDn   => B7_13,        -- load enable from NOR(GOAL, ATRC)
            P10_CET  => '1',          -- count enable trickle = VCC
            P11_QD   => B6_QD,        -- QD -> A6 gate 2
            P12_QC   => B6_QC,        -- QC -> A6 gate 4 + C6 gate 2
            P13_QB   => open,          -- QB not used in speed code
            P14_QA   => open,          -- QA not used in speed code
            P15_RC   => B6_RC         -- ripple carry -> C6 gate 4
        );

    -- C6 (LS04): inverters (shared IC; gates 3,6 in Fig 14, separate instance)
    -- Gate 2 (pin 3->4): NOT(QC) -> A6 gate 3
    -- Gate 4 (pin 9->8): NOT(RC) -> SLOW + B6 CEP feedback
    C6: entity work.LS04
        port map(
            P1_A1  => '0',      P2_Y1  => open,    -- gate 1 unused
            P3_A2  => B6_QC,    P4_Y2  => C6_4,    -- gate 2: NOT(QC)
            P5_A3  => '0',      P6_Y3  => open,    -- gate 3: Fig 14 (separate instance)
            P9_A4  => B6_RC,    P8_Y4  => C6_8,    -- gate 4: NOT(RC) = SLOW
            P11_A5 => '0',      P10_Y5 => open,    -- gate 5 unused
            P13_A6 => '0',      P12_Y6 => open     -- gate 6: Fig 14 (separate instance)
        );
    SLOW <= C6_8;

    -- B7 (LS02): NOR gates (shared IC; gates 1,2 in Fig 14, separate instance)
    -- Gate 4 (pins 11,12->13): NOR(GOAL, ATRC) -> B6 LDn
    -- LDn=1 during normal play (GOAL=0,ATRC=0); LDn=0 to preset on goal/attract
    B7: entity work.LS02
        port map(
            P2_A1  => '0',    P3_B1  => '0',    P1_Y1  => open,    -- gate 1: Fig 14
            P5_A2  => '0',    P6_B2  => '0',    P4_Y2  => open,    -- gate 2: Fig 14
            P8_A3  => '0',    P9_B3  => '0',    P10_Y3 => open,    -- gate 3 unused
            P11_A4 => GOAL,   P12_B4 => ATRC,   P13_Y4 => B7_13   -- gate 4
        );

    -- F6 (LS00): NAND gates (shared IC; gate 4 in Fig 14, separate instance)
    -- Gate 3 (pins 9,10->8): NAND(SCORE_SOUNDn, GOALIE_FWD_HIT) -> B6 CLK
    -- Negative-true OR: normally both HIGH -> LOW out; either LOW -> HIGH (rising edge)
    F6: entity work.LS00
        port map(
            P1_A1  => '1',            P2_B1  => '1',             P3_Y1  => open,  -- gate 1 unused
            P4_A2  => '1',            P5_B2  => '1',             P6_Y2  => open,  -- gate 2 unused
            P9_A3  => SCORE_SOUNDn,   P10_B3 => GOALIE_FWD_HIT,  P8_Y3 => F6_8,  -- gate 3
            P12_A4 => '1',            P13_B4 => '1',             P11_Y4 => open   -- gate 4: Fig 14
        );

    -- F5 (LS08): AND gates (shared IC; gates 1-3 in Fig 19, separate instance)
    -- Gate 4 (pins 12,13->11): AND(VRESET, STOPn) -> A6 enable
    -- Passes speed code through A6 only during VRESET when not stopped
    F5: entity work.LS08
        port map(
            P1_A1  => '0',      P2_B1  => '0',     P3_Y1  => open,   -- gate 1: Fig 19
            P4_A2  => '0',      P5_B2  => '0',     P6_Y2  => open,   -- gate 2: Fig 19
            P9_A3  => '0',      P10_B3 => '0',     P8_Y3  => open,   -- gate 3: Fig 19
            P12_A4 => VRESET,   P13_B4 => STOPn,   P11_Y4 => F5_11   -- gate 4
        );

    -- A6 (LS08): AND gates - gate speed code + direction with F5 enable
    -- Gate 1 (pins 1,2->3): AND(HORIZ_DIR, F5_11) -> direction to XORs + B5 B4/CIN
    -- Gate 2 (pins 4,5->6): AND(B6_QD, F5_11) -> speed bit D
    -- Gate 3 (pins 9,10->8): AND(NOT_QC, F5_11) -> speed bit NOT_C
    -- Gate 4 (pins 12,13->11): AND(B6_QC, F5_11) -> speed bit C
    A6: entity work.LS08
        port map(
            P1_A1  => HORIZ_DIR,  P2_B1  => F5_11,   P3_Y1  => A6_3,   -- gate 1: direction
            P4_A2  => B6_QD,      P5_B2  => F5_11,   P6_Y2  => A6_6,   -- gate 2: QD gated
            P9_A3  => C6_4,       P10_B3 => F5_11,   P8_Y3  => A6_8,   -- gate 3: NOT_QC gated
            P12_A4 => B6_QC,      P13_B4 => F5_11,   P11_Y4 => A6_11   -- gate 4: QC gated
        );

    -- A5 (LS86): XOR gates - direction inversion of speed code
    -- If direction=0: speed bits pass through unchanged
    -- If direction=1: speed bits inverted (direction reversal)
    -- Gate 1 (pins 1,2->3): XOR(A6_6, A6_3) -> B5 B1 (pin 11)
    -- Gate 3 (pins 9,10->8): XOR(A6_8, A6_3) -> B5 B3 (pin 4)
    -- Gate 4 (pins 12,13->11): XOR(A6_11, A6_3) -> B5 B2 (pin 7)
    A5: entity work.LS86
        port map(
            P1_A1  => A6_6,   P2_B1  => A6_3,    P3_Y1  => A5_3,   -- gate 1 -> B5 B1
            P4_A2  => '0',    P5_B2  => '0',     P6_Y2  => open,   -- gate 2 unused
            P9_A3  => A6_8,   P10_B3 => A6_3,    P8_Y3  => A5_8,   -- gate 3 -> B5 B3
            P12_A4 => A6_11,  P13_B4 => A6_3,    P11_Y4 => A5_11   -- gate 4 -> B5 B2
        );

    -- B5 (LS83): 4-bit adder - generates HSPEED motion code
    -- A side: fixed 1010 (A1=0, A2=1, A3=0, A4=1)
    -- B side: B1=XOR(QD,dir), B2=XOR(QC,dir), B3=XOR(NOT_QC,dir), B4=dir
    -- CIN = direction (A6_3)
    -- Stop code (all B=0, CIN=0): 0000 + 1010 + 0 = 1010
    B5: entity work.LS83
        port map(
            P1_A4   => '1',       -- A4 = 1 (fixed)
            P2_S3   => B5_S3,     -- S3 = Hc
            P3_A3   => '0',       -- A3 = 0 (fixed)
            P4_B3   => A5_8,      -- B3 from XOR gate 3 (NOT_QC ^ dir)
            P6_S2   => B5_S2,     -- S2 = Hb
            P7_B2   => A5_11,     -- B2 from XOR gate 4 (QC ^ dir)
            P8_A2   => '1',       -- A2 = 1 (fixed)
            P9_S1   => B5_S1,     -- S1 = Ha
            P10_A1  => '0',       -- A1 = 0 (fixed)
            P11_B1  => A5_3,      -- B1 from XOR gate 1 (QD ^ dir)
            P13_CIN => A6_3,      -- CIN = direction
            P14_COUT=> open,      -- carry out not used
            P15_S4  => B5_S4,     -- S4 = Hd
            P16_B4  => A6_3       -- B4 = direction
        );

    -- HSPEED(3:0) = (Hd, Hc, Hb, Ha) = (S4, S3, S2, S1)
    HSPEED <= (B5_S4, B5_S3, B5_S2, B5_S1);

end Schematic;
