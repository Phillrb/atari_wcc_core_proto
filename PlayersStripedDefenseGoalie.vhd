-- Striped Defense/Goalie (right-team defense) - Goal IV (WCC) TM-035 Figure 11
--
-- Pin-level per user: H9(555) pin 4 <- RAMP_VALUE (eventually); H9-3 -> J8-13; J8-12 -> J7-9 (LDn).
-- J7 (9316): 3,4,5,6=0; 1,10=1; CLK=HSYNC; 13=B4, 12=C4, 11=D4; 15 -> J8-11; J8-10 -> J7-7, E8-5, F7-12.
-- F7 (LS107): 2->1 (J1=Q1n), 3->8 (J2=Q1), 6->4 (K1=Q2n), 5->K6-1; VSYNCn -> 10,13; J8-10 -> 12 (CLK1); 3->L6-13,K6-2.
-- E8 (LS86) gate 2: J9-12 -> pin 4 (A2), J8-10 -> pin 5 (B2), pin 6 -> J6-13.
-- L6 (LS86): GOALIE -> 12 (A2), F7-3 (Q1) -> 13 (B2), 11 (Y2) -> J6-2.
-- K6 gate 1: F7-5 (Q2) -> 1 (A1), F7-3 (Q1) -> 2 (B1). K6 gate 2: J8-10 -> 5 (B2); 5 -> J6-1.
-- J6 (LS27) gate 1: K6-5 (same as J8-10) -> 1 (A1), L6-11 -> 2 (B1), E8-6 -> 13 (C1); 12 (Y1) = E4.
--
-- H9 (555) modelled like N8 in solid defense: comparator -> 555 -> J8 inverters, J7 counter, F7 FFs.
-- J9 pin 12 is input (from J9 one-shot when implemented); for now can tie to '0' or segment signal.
--
-- FIX: Goalie/defensemen column swap. The E4 symbol is active AFTER the counter maxes out
-- (J8_10=0), so F7 has already clocked to its NEW state. The schematic's L6 XOR(GOALIE, Q1)
-- filters incorrectly because Q1 is post-clock. Fix: disconnect L6 from J6 NOR, add
-- goalie_segment = F7_Q2 AND NOT F7_Q1 (correct for post-clock states: middle segment = goalie),
-- then gate E4 by goalie_segment XNOR GOALIE (same approach as solid side).

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PlayersStripedDefenseGoalie is
    Generic (ATTRACT_POSITION : natural := 0); -- fixed analogue-model fallback
    Port (
        HSYNC      : in  STD_LOGIC;
        VSYNCn     : in  STD_LOGIC;
        RAMP_VALUE : in  STD_LOGIC_VECTOR(9 downto 0);
        POSITION   : in  STD_LOGIC_VECTOR(9 downto 0);
        ATRCn      : in  STD_LOGIC;
        GOALIE     : in  STD_LOGIC;
        J9_P12     : in  STD_LOGIC := '0';   -- J9 pin 12 -> E8 pin 4 (when J9 implemented)
        E4         : out STD_LOGIC;
        B4         : out STD_LOGIC;
        C4         : out STD_LOGIC;
        D4         : out STD_LOGIC
    );
end PlayersStripedDefenseGoalie;

architecture Schematic of PlayersStripedDefenseGoalie is
    signal comparator_out : STD_LOGIC;
    -- 555 timing constants: tuned to match solid defense vertical layout.
    -- The striped circuit's symbol appears AFTER the counter maxes out (J8_10='0'),
    -- unlike the solid circuit where the symbol is active DURING counting (count 0..14).
    -- This timing difference means:
    --   figure height = SEGMENT_LEN - 14  (solid: SEGMENT_LEN - 1)
    --   start offset  = INITIAL_GAP + SEGMENT_GAP + 15  (solid: INITIAL_GAP + SEGMENT_GAP)
    -- To match solid's 15-line figures, 53-line gap, and same V start (offset 103):
    --   SEGMENT_LEN = 29 (29 - 14 = 15 lines), SEGMENT_GAP = 5, INITIAL_GAP = 83 (83+5+15 = 103).
    -- Previous values were INITIAL_GAP=85, SEGMENT_GAP=6, SEGMENT_LEN=30, giving 16-line
    -- figures, 56-line gap, and 3-scanline vertical offset vs solid side.
    constant INITIAL_GAP  : INTEGER := 83;
    constant SEGMENT_GAP  : INTEGER := 5;
    constant SEGMENT_LEN  : INTEGER := 29;
    constant PHASE_MAX    : INTEGER := INITIAL_GAP + 3 * (SEGMENT_GAP + SEGMENT_LEN) - 1;
    signal phase_count    : INTEGER range 0 to 511 := 0;
    signal H9_3           : STD_LOGIC;
    signal J8_12          : STD_LOGIC;   -- J8 pin 12 -> J7 pin 9 (LDn)
    signal J8_10          : STD_LOGIC;   -- J8 pin 10 -> J7 CEP, E8-5, F7-12, K6-5, J6-1
    signal J7_QB, J7_QC, J7_QD : STD_LOGIC;
    signal J7_RC          : STD_LOGIC;
    signal F7_Q1, F7_Q1n  : STD_LOGIC;
    signal F7_Q2, F7_Q2n  : STD_LOGIC;
    signal E8_Y2          : STD_LOGIC;   -- E8 pin 6 -> J6-13
    signal L6_Y2          : STD_LOGIC;   -- L6 pin 11 (unused, disconnected from J6)
    signal K6_Y1          : STD_LOGIC;
    signal J6_Y1          : STD_LOGIC;   -- raw symbol from J6 NOR
    -- Goalie/defensemen gating (fix for post-clock F7 state)
    signal goalie_segment : STD_LOGIC;   -- F7_Q2 AND NOT F7_Q1: 1 = middle segment (goalie)
    signal F7_Q1_inv      : STD_LOGIC;
    signal slot_ok_xor    : STD_LOGIC;   -- goalie_segment XOR GOALIE
    signal slot_ok_xnor   : STD_LOGIC;   -- NOT slot_ok_xor = goalie_segment XNOR GOALIE
begin
    -- Q7/CR7 disconnect the controls in attract; symbols still run.
    -- The fallback preserves the existing board positions, pending analogue calibration.
    comparator_out <= '1' when
        (ATRCn = '1' and UNSIGNED(RAMP_VALUE) >= UNSIGNED(POSITION)) or
        (ATRCn = '0' and UNSIGNED(RAMP_VALUE) >= ATTRACT_POSITION) else '0';

    -- H9 (555) behavioural: same pattern as N8 in solid defense.
    -- VSYNCn='0' resets the counter each frame; needed because POSITION=0 means comparator is always '1'.
    process(HSYNC)
    begin
        if rising_edge(HSYNC) then
            if VSYNCn = '0' or comparator_out = '0' then
                phase_count <= 0;
            elsif phase_count < PHASE_MAX then
                phase_count <= phase_count + 1;
            else
                phase_count <= 0;
            end if;
        end if;
    end process;
    H9_3 <= '1' when (comparator_out = '1' and (
        phase_count < INITIAL_GAP or
        (phase_count - INITIAL_GAP) mod (SEGMENT_GAP + SEGMENT_LEN) < SEGMENT_GAP
    )) else '0';

    -- J8 (LS04) gate 6: pin 13 = A6 = H9_3, pin 12 = Y6 = J8_12 -> J7 LDn
    U_J8_6: entity work.LS04
        port map(
            P13_A6  => H9_3,
            P12_Y6  => J8_12,
            P1_A1   => '0', P2_Y1 => open, P3_A2 => '0', P4_Y2 => open,
            P5_A3   => '0', P6_Y3 => open, P9_A4 => '0', P8_Y4 => open,
            P11_A5  => '0', P10_Y5 => open
        );

    -- J7 (IC9316): CLK=HSYNC, LDn=J8_12, CEP=J8_10, CET=1; load 0; 15(RC)->J8-11; 13=B4, 12=C4, 11=D4
    U_J7: entity work.IC9316
        port map(
            P1_CLRn => '1',
            P2_CLK  => HSYNC,
            P3_A    => '0',
            P4_B    => '0',
            P5_C    => '0',
            P6_D    => '0',
            P7_CEP  => J8_10,
            P9_LDn  => J8_12,
            P10_CET => '1',
            P11_QD  => J7_QD,
            P12_QC  => J7_QC,
            P13_QB  => J7_QB,
            P14_QA  => open,
            P15_RC  => J7_RC
        );
    B4 <= J7_QB;
    C4 <= J7_QC;
    D4 <= J7_QD;

    -- J8 (LS04) gate 5: pin 11 = A5 = J7_RC, pin 10 = Y5 = J8_10
    U_J8_5: entity work.LS04
        port map(
            P11_A5  => J7_RC,
            P10_Y5  => J8_10,
            P1_A1   => '0', P2_Y1 => open, P3_A2 => '0', P4_Y2 => open,
            P5_A3   => '0', P6_Y3 => open, P9_A4 => '0', P8_Y4 => open,
            P13_A6  => '0', P12_Y6 => open
        );

    -- F7 (LS107): J1=Q1n(2->1), J2=Q1(3->8), K1=Q2n(6->4), K2=Q1(3->11); CLK1=J8_10(12); CLR1n/CLR2n=VSYNCn
    U_F7: entity work.LS107
        port map(
            P1_J1     => F7_Q1n,
            P2_Q1n    => F7_Q1n,
            P3_Q1     => F7_Q1,
            P4_K1     => F7_Q2n,
            P5_Q2     => F7_Q2,
            P6_Q2n    => F7_Q2n,
            P8_J2     => F7_Q1,
            P9_CLK2   => J8_10,
            P10_CLR2n => VSYNCn,
            P11_K2    => F7_Q1,
            P12_CLK1  => J8_10,
            P13_CLR1n => VSYNCn
        );

    -- E8 (LS86) gate 2: A2=J9_P12 (pin 4), B2=J8_10 (pin 5), Y2 (pin 6) -> J6-13
    U_E8: entity work.LS86
        port map(
            P4_A2   => J9_P12,
            P5_B2   => J8_10,
            P6_Y2   => E8_Y2,
            P1_A1   => '0', P2_B1 => '0', P3_Y1 => open,
            P9_A3   => '0', P10_B3 => '0', P8_Y3 => open,
            P12_A4  => '0', P13_B4 => '0', P11_Y4 => open
        );

    -- L6 (LS86) original: GOALIE XOR F7_Q1. Disconnected from J6 NOR (see FIX note).
    -- Kept for schematic traceability but output unused.
    U_L6: entity work.LS86
        port map(
            P12_A4  => GOALIE,
            P13_B4  => F7_Q1,
            P11_Y4  => L6_Y2,
            P1_A1   => '0', P2_B1 => '0', P3_Y1 => open,
            P4_A2   => '0', P5_B2 => '0', P6_Y2 => open,
            P9_A3   => '0', P10_B3 => '0', P8_Y3 => open
        );

    -- K6 (LS08) gate 1: A1=F7_Q2 (pin 1), B1=F7_Q1 (pin 2), Y1 (pin 3)
    U_K6_g1: entity work.LS08
        port map(
            P1_A1   => F7_Q2,
            P2_B1   => F7_Q1,
            P3_Y1   => K6_Y1,
            P4_A2   => '0', P5_B2 => J8_10, P6_Y2 => open,
            P9_A3   => '0', P10_B3 => '0', P8_Y3 => open,
            P12_A4  => '0', P13_B4 => '0', P11_Y4 => open
        );

    -- J6 (LS27) gate 1: A1=J8_10, B1='0' (L6 disconnected; see FIX note), C1=E8_Y2; Y1 -> raw symbol
    U_J6: entity work.LS27
        port map(
            P1_A1   => J8_10,
            P2_B1   => '0',       -- L6 disconnected: its XOR(GOALIE,Q1) is wrong for post-clock F7
            P13_C1  => E8_Y2,
            P12_Y1  => J6_Y1,
            P3_A2   => '0', P4_B2 => '0', P5_C2 => '0', P6_Y2 => open,
            P9_A3   => '0', P10_B3 => '0', P11_C3 => '0', P8_Y3 => open
        );

    -- FIX: Gate E4 by goalie_segment XNOR GOALIE (same approach as solid defense).
    -- goalie_segment = F7_Q2 AND NOT F7_Q1: identifies the middle segment (goalie) in
    -- the post-clock F7 state. Post-clock states are (1,0)=top, (0,1)=middle, (1,1)=bottom.

    -- Invert F7_Q1 (J8 spare gate)
    U_J8_inv_Q1: entity work.LS04
        port map(
            P1_A1   => F7_Q1,
            P2_Y1   => F7_Q1_inv,
            P3_A2   => '0', P4_Y2 => open, P5_A3 => '0', P6_Y3 => open,
            P9_A4   => '0', P8_Y4 => open, P11_A5  => '0', P10_Y5 => open,
            P13_A6  => '0', P12_Y6 => open
        );

    -- goalie_segment = F7_Q2 AND NOT F7_Q1 (K6 spare gate)
    U_K6_gs: entity work.LS08
        port map(
            P1_A1   => F7_Q2,
            P2_B1   => F7_Q1_inv,
            P3_Y1   => goalie_segment,
            P4_A2   => '0', P5_B2 => '0', P6_Y2 => open,
            P9_A3   => '0', P10_B3 => '0', P8_Y3 => open,
            P12_A4  => '0', P13_B4 => '0', P11_Y4 => open
        );

    -- slot_ok_xor = goalie_segment XOR GOALIE (L6 repurposed)
    U_L6_xor: entity work.LS86
        port map(
            P1_A1   => goalie_segment,
            P2_B1   => GOALIE,
            P3_Y1   => slot_ok_xor,
            P4_A2   => '0', P5_B2 => '0', P6_Y2 => open,
            P9_A3   => '0', P10_B3 => '0', P8_Y3 => open,
            P12_A4  => '0', P13_B4 => '0', P11_Y4 => open
        );

    -- slot_ok_xnor = NOT slot_ok_xor (J8 spare gate)
    U_J8_xnor: entity work.LS04
        port map(
            P1_A1   => slot_ok_xor,
            P2_Y1   => slot_ok_xnor,
            P3_A2   => '0', P4_Y2 => open, P5_A3 => '0', P6_Y3 => open,
            P9_A4   => '0', P8_Y4 => open, P11_A5  => '0', P10_Y5 => open,
            P13_A6  => '0', P12_Y6 => open
        );

    -- E4 = J6_Y1 AND slot_ok_xnor (K6 spare gate)
    U_K6_e4: entity work.LS08
        port map(
            P1_A1   => J6_Y1,
            P2_B1   => slot_ok_xnor,
            P3_Y1   => E4,
            P4_A2   => '0', P5_B2 => '0', P6_Y2 => open,
            P9_A3   => '0', P10_B3 => '0', P8_Y3 => open,
            P12_A4  => '0', P13_B4 => '0', P11_Y4 => open
        );
end Schematic;
