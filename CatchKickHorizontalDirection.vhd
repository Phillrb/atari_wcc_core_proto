-- Catch/Kick/Horizontal Direction Circuit for Goal IV (WCC) - TM-035 Figure 13
-- ICs: E8(LS00), C8(LS00), D8(LS74), D5(LS74), C5(LS08), C9(LS02), K8(LS02), A8(LS04), D9(LS04)
-- Controls ball catching by goalies/forwards, kicking via pushbuttons,
-- and horizontal ball direction after bounces.
--
-- D8 FF2 (catch): SET by HIT EXTENDER (E8 NAND BALL,BLIP), CLR by HIT+DEFENSEMENn
-- D8 FF1 (horiz dir): D=HORIZ_DIR, CLK=H_BOUNCE, SET/CLR by kick logic
-- D5 FF1 (ball-off-paddle): D='1', CLK=HIT, SET=STOP, CLR=VSYNCn
-- D5 FF2 (VRESET sampler): D=D5_Q1, CLK=VRESET
-- C5 gate 1: AND(K8-4, D5-9 Q2) -> CATCH_CLRn (J5 ch1 CLR1n)
-- Kick logic: C9 NORs combine team-gated kicks, K8 NOR merges them

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CatchKickHorizontalDirection is
    Port (
        BALL          : in  STD_LOGIC;  -- E8 pin 9 (gate 3 input)
        BLIP          : in  STD_LOGIC;  -- E8 pin 10 (gate 3 input)
        HIT           : in  STD_LOGIC;  -- C8 gates, D5 pin 3 (CLK1)
        DEFENSEMENn   : in  STD_LOGIC;  -- C8 pin 5 (gate 2 input)
        TEAM          : in  STD_LOGIC;  -- C8 pin 1 (gate 1), A8 pin 5
        ONE_PLAYER    : in  STD_LOGIC;  -- E8 pin 1 (gate 1 input)
        WINDOWS       : in  STD_LOGIC;  -- E8 pin 2 (gate 1 input)
        H256n         : in  STD_LOGIC;  -- E8 pin 13 (gate 4 input)
        H_BOUNCE      : in  STD_LOGIC;  -- D8 pin 3 (CLK1)
        VSYNCn        : in  STD_LOGIC;  -- D5 pin 1 (CLR1n)
        VRESET        : in  STD_LOGIC;  -- D5 pin 11 (CLK2)
        STOP          : in  STD_LOGIC;  -- D5 pin 4 (SET1n); from J5 ch1 Q1
        SOLID_KICK    : in  STD_LOGIC;  -- D9 pin 13 (gate 6 input); HIGH when pressed
        CHECKED_KICK  : in  STD_LOGIC;  -- D9 pin 11 (gate 5 input); HIGH when pressed
        CATCH_TRIGGER : out STD_LOGIC;  -- D8 pin 9 (Q2) -> J5 ch1 A1
        CATCH_CLRn    : out STD_LOGIC;  -- C5 pin 3 (Y1) -> J5 ch1 CLR1n
        HORIZ_DIR_Qn  : out STD_LOGIC   -- D8 pin 6 (Q1n) -> horizontal speed circuit
    );
end CatchKickHorizontalDirection;

architecture Structural of CatchKickHorizontalDirection is
    -- E8 (LS00) internal signals
    signal e8_8  : STD_LOGIC;  -- gate 3 output: NAND(BALL, BLIP) = HIT EXTENDER
    signal e8_3  : STD_LOGIC;  -- gate 1 output: NAND(ONE_PLAYER, WINDOWS)
    signal e8_11 : STD_LOGIC;  -- gate 4 output: NAND(e8_3, H256n) = HORIZ DIR

    -- C8 (LS00) internal signals
    signal c8_3  : STD_LOGIC;  -- gate 1 output: NAND(TEAM, HIT)
    signal c8_6  : STD_LOGIC;  -- gate 2 output: NAND(HIT, DEFENSEMENn)
    signal c8_11 : STD_LOGIC;  -- gate 4 output: NAND(TEAMn, HIT)

    -- D8 (LS74) internal signals
    signal d8_q2 : STD_LOGIC;  -- FF2 Q2 = CATCH_TRIGGER

    -- D5 (LS74) internal signals
    signal d5_q1 : STD_LOGIC;  -- FF1 Q1 (ball-off-paddle)
    signal d5_q2 : STD_LOGIC;  -- FF2 Q2 (VRESET sampled)

    -- A8 (LS04) internal signals
    signal a8_6_teamn : STD_LOGIC;  -- gate 3 output: NOT(TEAM)

    -- D9 (LS04) internal signals
    signal d9_10 : STD_LOGIC;  -- gate 5 output: NOT(CHECKED_KICK)
    signal d9_12 : STD_LOGIC;  -- gate 6 output: NOT(SOLID_KICK)

    -- C9 (LS02) internal signals
    signal c9_1 : STD_LOGIC;   -- gate 1 output: NOR(c8_11, d9_12)
    signal c9_4 : STD_LOGIC;   -- gate 2 output: NOR(d9_10, c8_3)

    -- K8 (LS02) internal signals
    signal k8_4 : STD_LOGIC;   -- gate 2 output: NOR(c9_4, c9_1)

begin

    -- E8 (LS00): quad 2-input NAND
    -- Gate 3 (9,10->8): NAND(BALL, BLIP) = HIT EXTENDER -> D8 SET2n
    -- Gate 1 (1,2->3): NAND(ONE_PLAYER, WINDOWS)
    -- Gate 4 (12,13->11): NAND(e8_3, H256n) = HORIZ DIR -> D8 D1
    -- Gate 2: unused
    U_E8: entity work.LS00
        port map(
            P1_A1  => ONE_PLAYER,  P2_B1  => WINDOWS,  P3_Y1  => e8_3,
            P4_A2  => '1',         P5_B2  => '1',      P6_Y2  => open,   -- gate 2 unused
            P9_A3  => BALL,        P10_B3 => BLIP,     P8_Y3  => e8_8,
            P12_A4 => e8_3,        P13_B4 => H256n,    P11_Y4 => e8_11
        );

    -- C8 (LS00): quad 2-input NAND
    -- Gate 1 (1,2->3): NAND(TEAM, HIT) -> D8 SET1n, C9 gate 2 pin 6
    -- Gate 2 (4,5->6): NAND(HIT, DEFENSEMENn) -> D8 CLR2n
    -- Gate 4 (12,13->11): NAND(TEAMn, HIT) -> D8 CLR1n, C9 gate 1 pin 2
    -- Gate 3: unused
    U_C8: entity work.LS00
        port map(
            P1_A1  => TEAM,        P2_B1  => HIT,      P3_Y1  => c8_3,
            P4_A2  => HIT,         P5_B2  => DEFENSEMENn, P6_Y2 => c8_6,
            P9_A3  => '1',         P10_B3 => '1',      P8_Y3  => open,   -- gate 3 unused
            P12_A4 => a8_6_teamn,  P13_B4 => HIT,      P11_Y4 => c8_11
        );

    -- D8 (LS74): dual D flip-flop
    -- FF2 (catch): D2='0', CLK2='0' (no clock), SET2n=e8_8 (HIT EXTENDER), CLR2n=c8_6
    --   Q2 = CATCH_TRIGGER (to J5 ch1 A1)
    -- FF1 (horiz dir): D1=e8_11, CLK1=H_BOUNCE, CLR1n=c8_11, SET1n=c8_3
    --   Q1n = HORIZ_DIR_Qn (to horizontal speed circuit)
    U_D8: entity work.LS74
        port map(
            -- FF1 (horizontal direction)
            P1_CLR1n  => c8_11,     -- NAND(TEAMn, HIT)
            P2_D1     => e8_11,     -- HORIZ DIR (E8 gate 4)
            P3_CLK1   => H_BOUNCE,  -- from bounce circuit
            P4_SET1n  => c8_3,      -- NAND(TEAM, HIT)
            P5_Q1     => open,
            P6_Q1n    => HORIZ_DIR_Qn,
            -- FF2 (catch)
            P8_Q2n    => open,
            P9_Q2     => d8_q2,     -- CATCH_TRIGGER
            P10_SET2n => e8_8,      -- HIT EXTENDER (E8 gate 3)
            P11_CLK2  => '0',       -- no clock (async only)
            P12_D2    => '0',       -- tied low
            P13_CLR2n => c8_6       -- NAND(HIT, DEFENSEMENn)
        );

    CATCH_TRIGGER <= d8_q2;

    -- D5 (LS74): dual D flip-flop
    -- FF1 (ball-off-paddle): D1='1', CLK1=HIT, SET1n=STOP, CLR1n=VSYNCn
    --   Q1 -> D5 FF2 D2
    -- FF2 (VRESET sampler): D2=d5_q1, CLK2=VRESET, SET2n='1', CLR2n='1'
    --   Q2 -> C5 gate 1 pin 2
    U_D5: entity work.LS74
        port map(
            -- FF1 (ball-off-paddle)
            P1_CLR1n  => VSYNCn,    -- cleared each frame
            P2_D1     => '1',       -- always latches HIGH on HIT
            P3_CLK1   => HIT,       -- clocked by hit
            P4_SET1n  => STOP,      -- set by STOP (from J5 ch1)
            P5_Q1     => d5_q1,     -- -> FF2 D2
            P6_Q1n    => open,
            -- FF2 (VRESET sampler)
            P8_Q2n    => open,
            P9_Q2     => d5_q2,     -- -> C5 gate 1 pin 2
            P10_SET2n => '1',       -- VCC
            P11_CLK2  => VRESET,    -- clocked by VRESET
            P12_D2    => d5_q1,     -- from FF1 Q1
            P13_CLR2n => '1'        -- VCC
        );

    -- A8 (LS04): hex inverter - gate 3 (pin 5 -> 6): NOT(TEAM)
    -- Other gates of A8 belong to other circuits
    U_A8: entity work.LS04
        port map(
            P1_A1  => '0',    P2_Y1  => open,    -- gate 1 unused
            P3_A2  => '0',    P4_Y2  => open,    -- gate 2 unused
            P5_A3  => TEAM,   P6_Y3  => a8_6_teamn,  -- gate 3: NOT(TEAM)
            P9_A4  => '0',    P8_Y4  => open,    -- gate 4 unused
            P11_A5 => '0',    P10_Y5 => open,    -- gate 5 unused
            P13_A6 => '0',    P12_Y6 => open     -- gate 6 unused
        );

    -- D9 (LS04): hex inverter
    -- Gate 5 (pin 11 -> 10): NOT(CHECKED_KICK)
    -- Gate 6 (pin 13 -> 12): NOT(SOLID_KICK)
    -- Other gates of D9 belong to other circuits
    U_D9: entity work.LS04
        port map(
            P1_A1  => '0',           P2_Y1  => open,    -- gate 1 unused
            P3_A2  => '0',           P4_Y2  => open,    -- gate 2 unused
            P5_A3  => '0',           P6_Y3  => open,    -- gate 3 unused
            P9_A4  => '0',           P8_Y4  => open,    -- gate 4 unused
            P11_A5 => CHECKED_KICK,  P10_Y5 => d9_10,   -- gate 5: NOT(CHECKED_KICK)
            P13_A6 => SOLID_KICK,    P12_Y6 => d9_12    -- gate 6: NOT(SOLID_KICK)
        );

    -- C9 (LS02): quad 2-input NOR
    -- Gate 1 (2,3->1): NOR(c8_11, d9_12) - solid team kick
    -- Gate 2 (5,6->4): NOR(d9_10, c8_3) - checked team kick
    -- Other gates of C9 belong to other circuits
    U_C9: entity work.LS02
        port map(
            P2_A1  => c8_11,   P3_B1  => d9_12,   P1_Y1  => c9_1,    -- gate 1
            P5_A2  => d9_10,   P6_B2  => c8_3,    P4_Y2  => c9_4,    -- gate 2
            P8_A3  => '0',     P9_B3  => '0',     P10_Y3 => open,    -- gate 3 unused
            P11_A4 => '0',     P12_B4 => '0',     P13_Y4 => open     -- gate 4 unused
        );

    -- K8 (LS02): quad 2-input NOR
    -- Gate 2 (5,6->4): NOR(c9_4, c9_1) - merged kick output
    -- Other gates of K8 belong to other circuits
    U_K8: entity work.LS02
        port map(
            P2_A1  => '0',    P3_B1  => '0',    P1_Y1  => open,     -- gate 1 unused
            P5_A2  => c9_4,   P6_B2  => c9_1,   P4_Y2  => k8_4,    -- gate 2
            P8_A3  => '0',    P9_B3  => '0',    P10_Y3 => open,     -- gate 3 unused
            P11_A4 => '0',    P12_B4 => '0',    P13_Y4 => open      -- gate 4 unused
        );

    -- C5 (LS08): quad 2-input AND
    -- Gate 1 (1,2->3): AND(k8_4, d5_q2) -> CATCH_CLRn (to J5 ch1 CLR1n)
    -- Other gates of C5 belong to other circuits
    U_C5: entity work.LS08
        port map(
            P1_A1  => k8_4,   P2_B1  => d5_q2,  P3_Y1  => CATCH_CLRn,  -- gate 1
            P4_A2  => '0',    P5_B2  => '0',     P6_Y2  => open,        -- gate 2 unused
            P9_A3  => '0',    P10_B3 => '0',     P8_Y3  => open,        -- gate 3 unused
            P12_A4 => '0',    P13_B4 => '0',     P11_Y4 => open         -- gate 4 unused
        );

end Structural;
