-- Ball Motion Circuit for Goal IV (WCC) - TM-035 Figure 16
-- ICs: A4(IC9316), D4(IC9316), B4(IC9316), C4(IC9316),
--      B3(LS107), A3(LS10), A2(LS10), D3(LS08), C3(LS00), E3(LS04)
-- Vertical counters (A4/D4) count HSYNCn pulses; horizontal counters (B4/C4)
-- count CLOCK_7 pulses.  B3 provides phase flip-flops for both axes.
-- Ball video = 8x8 dot at position set by VSPEED/HSPEED preset values.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity BallMotionCircuit is
    Port (
        CLOCK_7  : in  STD_LOGIC;   -- 7.159 MHz pixel clock
        HSYNCn   : in  STD_LOGIC;   -- inverted HSYNC (clocks vertical counters)
        HBLANKn  : in  STD_LOGIC;   -- inverted HBLANK (gates horizontal counter)
        SERVE    : in  STD_LOGIC;   -- active-high: '1'=ball in play, '0'=serve/reset
        HSPEED   : in  STD_LOGIC_VECTOR(3 downto 0); -- horizontal motion code
        VSPEED   : in  STD_LOGIC_VECTOR(3 downto 0); -- vertical motion code
        BALL     : out STD_LOGIC;    -- active-high ball video
        BALLn    : out STD_LOGIC;    -- active-low ball video
        HIT_TONE : out STD_LOGIC     -- A4 pin 12 QC (for sound circuit)
    );
end BallMotionCircuit;

architecture Structural of BallMotionCircuit is

-- Internal signals for out-port readback (VHDL-93)
signal ball_i      : STD_LOGIC;
signal ball_n_i    : STD_LOGIC;
signal hit_tone_i  : STD_LOGIC;

-- A4 (IC9316) outputs: Vertical LSB counter
signal a4_rc       : STD_LOGIC;  -- pin 15: ripple carry
signal a4_qd       : STD_LOGIC;  -- pin 11: QD (bit 3) -> A3 gate 3

-- D4 (IC9316) outputs: Vertical MSB counter
signal d4_rc       : STD_LOGIC;  -- pin 15: ripple carry -> B3 J1/K1, D3

-- B4 (IC9316) outputs: Horizontal LSB counter
signal b4_rc       : STD_LOGIC;  -- pin 15: ripple carry -> C4 CEP, A2 gate 1
signal b4_qc       : STD_LOGIC;  -- pin 12: QC (bit 2) -> A3 gate 1
signal b4_qd       : STD_LOGIC;  -- pin 11: QD (bit 3) -> A3 gates 1,2

-- C4 (IC9316) outputs: Horizontal MSB counter
signal c4_rc       : STD_LOGIC;  -- pin 15: ripple carry -> B3 CLK2, A2, A3

-- B3 (LS107) outputs
signal b3_q1       : STD_LOGIC;  -- FF1 Q  (vertical phase) -> D3
signal b3_q2n      : STD_LOGIC;  -- FF2 Qn (horizontal phase) -> A2, A3

-- Gate outputs
signal d3_11       : STD_LOGIC;  -- D3 gate 4: AND(B3_Q1, D4_RC)
signal c3_11       : STD_LOGIC;  -- C3 gate 4: NAND(D3_11, A4_RC) = vert LDn
signal a2_12       : STD_LOGIC;  -- A2 gate 1: NAND(B3_Q2n, C4_RC, B4_RC) = horiz LDn
signal a3_12       : STD_LOGIC;  -- A3 gate 1: NAND(B4_QC, B4_QD, HIT_TONE)
signal a3_6        : STD_LOGIC;  -- A3 gate 2: NAND(B4_QD, C4_RC, B3_Q2n) = horiz window inv
signal e3_10       : STD_LOGIC;  -- E3 inv 5:  NOT(A3_6) = horiz window active high

begin

-- Output assignments
BALL     <= ball_i;
BALLn    <= ball_n_i;
HIT_TONE <= hit_tone_i;

------------------------------------------------------------------------
-- VERTICAL BALL MOTION (counts HSYNCn pulses)
------------------------------------------------------------------------

-- A4 (IC9316): Vertical LSB counter
-- CLRn=SERVE, CLK=HSYNCn, preset=VSPEED, CEP='1', CET='1'
-- RC -> D4 CEP, B3 CLK1, C3 gate 4 input
-- QC = HIT_TONE -> A3 gate 1;  QD -> A3 gate 3
A4: entity work.IC9316
    port map(
        P1_CLRn => SERVE,
        P2_CLK  => HSYNCn,
        P3_A    => VSPEED(0),
        P4_B    => VSPEED(1),
        P5_C    => VSPEED(2),
        P6_D    => VSPEED(3),
        P7_CEP  => '1',
        P9_LDn  => c3_11,
        P10_CET => '1',
        P11_QD  => a4_qd,
        P12_QC  => hit_tone_i,
        P13_QB  => open,
        P14_QA  => open,
        P15_RC  => a4_rc
    );

-- D4 (IC9316): Vertical MSB counter -- fixed preset = 12 (DCBA=1100)
-- CEP=A4_RC (cascaded), CET='1'
-- RC -> B3 J1/K1, D3 gate 4 input
D4: entity work.IC9316
    port map(
        P1_CLRn => SERVE,
        P2_CLK  => HSYNCn,
        P3_A    => '0',
        P4_B    => '0',
        P5_C    => '1',
        P6_D    => '1',
        P7_CEP  => a4_rc,
        P9_LDn  => c3_11,
        P10_CET => '1',
        P11_QD  => open,
        P12_QC  => open,
        P13_QB  => open,
        P14_QA  => open,
        P15_RC  => d4_rc
    );

-- B3 (LS107): Dual JK flip-flop
-- FF1: vertical phase -- CLK=A4_RC, J=K=D4_RC (toggle when D4 terminal), CLRn=SERVE
-- FF2: horizontal phase -- CLK=C4_RC, J=K='1' (always toggle), CLRn=SERVE
B3: entity work.LS107
    port map(
        P1_J1     => d4_rc,
        P2_Q1n    => open,
        P3_Q1     => b3_q1,
        P4_K1     => d4_rc,
        P5_Q2     => open,
        P6_Q2n    => b3_q2n,
        P8_J2     => '1',
        P9_CLK2   => c4_rc,
        P10_CLR2n => SERVE,
        P11_K2    => '1',
        P12_CLK1  => a4_rc,
        P13_CLR1n => SERVE
    );

-- D3 (LS08): gate 4 -- AND(B3_Q1, D4_RC)
-- Vertical ball detect: correct phase AND MSB counter at terminal
D3: entity work.LS08
    port map(
        P1_A1  => '0',  P2_B1  => '0',  P3_Y1  => open,   -- gate 1 unused
        P4_A2  => '0',  P5_B2  => '0',  P6_Y2  => open,   -- gate 2 unused
        P9_A3  => '0',  P10_B3 => '0',  P8_Y3  => open,   -- gate 3 unused
        P12_A4 => b3_q1,
        P13_B4 => d4_rc,
        P11_Y4 => d3_11
    );

-- C3 (LS00): gate 4 -- NAND(D3_11, A4_RC) = vertical preset trigger
-- LDn for A4/D4: goes LOW when vert phase correct AND both vert counters at terminal
C3: entity work.LS00
    port map(
        P1_A1  => '1',  P2_B1  => '1',  P3_Y1  => open,   -- gate 1 unused
        P4_A2  => '1',  P5_B2  => '1',  P6_Y2  => open,   -- gate 2 unused
        P9_A3  => '1',  P10_B3 => '1',  P8_Y3  => open,   -- gate 3 unused
        P12_A4 => d3_11,
        P13_B4 => a4_rc,
        P11_Y4 => c3_11
    );

------------------------------------------------------------------------
-- HORIZONTAL BALL MOTION (counts CLOCK_7 pulses)
------------------------------------------------------------------------

-- B4 (IC9316): Horizontal LSB counter
-- CLRn=SERVE, CLK=CLOCK_7, preset=HSPEED, CEP='1', CET=HBLANKn
-- QC -> A3 gate 1;  QD -> A3 gates 1,2;  RC -> C4 CEP, A2 gate 1
B4: entity work.IC9316
    port map(
        P1_CLRn => SERVE,
        P2_CLK  => CLOCK_7,
        P3_A    => HSPEED(0),
        P4_B    => HSPEED(1),
        P5_C    => HSPEED(2),
        P6_D    => HSPEED(3),
        P7_CEP  => '1',
        P9_LDn  => a2_12,
        P10_CET => HBLANKn,
        P11_QD  => b4_qd,
        P12_QC  => b4_qc,
        P13_QB  => open,
        P14_QA  => open,
        P15_RC  => b4_rc
    );

-- C4 (IC9316): Horizontal MSB counter -- fixed preset = 8 (DCBA=1000)
-- CEP=B4_RC (cascaded), CET='1'
-- RC -> B3 CLK2, A2 gate 1, A3 gate 2
C4: entity work.IC9316
    port map(
        P1_CLRn => SERVE,
        P2_CLK  => CLOCK_7,
        P3_A    => '0',
        P4_B    => '0',
        P5_C    => '0',
        P6_D    => '1',
        P7_CEP  => b4_rc,
        P9_LDn  => a2_12,
        P10_CET => '1',
        P11_QD  => open,
        P12_QC  => open,
        P13_QB  => open,
        P14_QA  => open,
        P15_RC  => c4_rc
    );

-- A2 (LS10): gate 1 -- NAND(B3_Q2n, C4_RC, B4_RC) = horizontal preset trigger
-- LDn for B4/C4: goes LOW when horiz phase correct AND both horiz counters at terminal
A2: entity work.LS10
    port map(
        P1_A1  => b3_q2n,      -- gate 1: B3 Q2n (horiz phase)
        P2_B1  => c4_rc,       -- gate 1: C4 RC
        P13_C1 => b4_rc,       -- gate 1: B4 RC
        P12_Y1 => a2_12,       -- gate 1 output -> B4/C4 LDn
        P3_A2  => '1',  P4_B2  => '1',  P5_C2  => '1',  P6_Y2  => open,  -- gate 2 unused
        P9_A3  => '1',  P10_B3 => '1',  P11_C3 => '1',  P8_Y3  => open   -- gate 3 unused
    );

------------------------------------------------------------------------
-- BALL SUMMING
------------------------------------------------------------------------

-- A3 (LS10): Triple 3-input NAND
-- Gate 1: NAND(B4_QC, B4_QD, HIT_TONE) -- qualified hit tone (to sound circuit)
-- Gate 2: NAND(B4_QD, C4_RC, B3_Q2n)  -- horizontal window (inverted) -> E3
-- Gate 3: NAND(D3_11, E3_10, A4_QD)   -- BALLn (active-low ball video)
A3: entity work.LS10
    port map(
        P1_A1  => b4_qc,       -- gate 1: B4 QC (horiz bit 2)
        P2_B1  => b4_qd,       -- gate 1: B4 QD (horiz bit 3)
        P13_C1 => hit_tone_i,  -- gate 1: HIT_TONE (A4 QC = vert bit 2)
        P12_Y1 => a3_12,       -- gate 1 output (qualified hit tone)
        P3_A2  => b4_qd,       -- gate 2: B4 QD (horiz bit 3)
        P4_B2  => c4_rc,       -- gate 2: C4 RC (horiz MSB terminal)
        P5_C2  => b3_q2n,      -- gate 2: B3 Q2n (horiz phase)
        P6_Y2  => a3_6,        -- gate 2 output -> E3 inv 5
        P9_A3  => d3_11,       -- gate 3: D3 = AND(B3_Q1, D4_RC) (vert detect)
        P10_B3 => e3_10,       -- gate 3: E3 = horiz window (active high)
        P11_C3 => a4_qd,       -- gate 3: A4 QD (vert bit 3 = ball height)
        P8_Y3  => ball_n_i     -- gate 3 output = BALLn
    );

-- E3 (LS04): Inverters
-- Inv 5: NOT(A3 gate 2) -> horizontal window (active high)
-- Inv 6: NOT(BALLn) -> BALL (active high)
E3: entity work.LS04
    port map(
        P1_A1  => '0',  P2_Y1  => open,   -- inv 1 unused
        P3_A2  => '0',  P4_Y2  => open,   -- inv 2 unused
        P5_A3  => '0',  P6_Y3  => open,   -- inv 3 unused
        P9_A4  => '0',  P8_Y4  => open,   -- inv 4 unused
        P11_A5 => a3_6,                    -- inv 5 input: A3 gate 2 output
        P10_Y5 => e3_10,                   -- inv 5 output: horiz window active high
        P13_A6 => ball_n_i,                -- inv 6 input: BALLn
        P12_Y6 => ball_i                   -- inv 6 output: BALL active high
    );

end Structural;
