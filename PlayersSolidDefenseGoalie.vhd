-- Solid Defense/Goalie - Goal IV (WCC) TM-035 Figure 11
--
-- Schematic: Comparator N9-10 -> 555 N8-3 -> J8-2 (LS04) -> M7 LDn, L8. J8-4 (LS04) M7_RC -> M7 CEP, H8 CLK, L8.
-- L8 (LS00) gate 3: NAND(J8-4, J8-2) -> L8-8 -> J6-11. J8-2 -> M7-9 (LDn), L8-10. J8-4 -> L8-9.
-- H8 (LS107): J1=Q1n (pin 2->1), J2=Q1 (pin 3->8); Q1->E6-2,K6-10; Q2->K6-9. GOALIE (L6 pin 3) -> E6-1.
-- E6 (LS86) gate 1: Use local "goalie segment" (Q1 and not Q2) on E6 pin 1 so all 3 segments show in one column:
-- top defenseman (0,0), goalie (1,0), bottom defenseman (0,1). E6_Y1=0 for those, 1 for (1,1). Without this,
-- vertical-window GOALIE (L6 pin 3) is constant per column so only 1 segment type would show per column.
-- J6 (LS27) gate 3: NOR(K6-8, E6 out, L8-8) -> J6-8 = E1.
-- 555 modelled as counter: when comparator high, N8_3 = high for 1 HSYNC then low for 16, repeat 3x.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PlayersSolidDefenseGoalie is
    Port (
        HSYNC      : in  STD_LOGIC;
        VSYNCn     : in  STD_LOGIC;   -- H8 pin 13 (CLR1n), pin 10 (CLR2n): clear both FFs at vertical sync
        RAMP_VALUE : in  STD_LOGIC_VECTOR(9 downto 0);
        POSITION   : in  STD_LOGIC_VECTOR(9 downto 0);
        ATRCn      : in  STD_LOGIC;
        GOALIE     : in  STD_LOGIC;   -- from vertical window L6 pin 3 (E6 pin 1)
        E1         : out STD_LOGIC;
        B1         : out STD_LOGIC;
        C1         : out STD_LOGIC;
        D1         : out STD_LOGIC
    );
end PlayersSolidDefenseGoalie;

architecture Schematic of PlayersSolidDefenseGoalie is
    signal comparator_out : STD_LOGIC;
    signal controls_ena   : STD_LOGIC;
    -- 555 (N8) model: INITIAL_GAP (no draw) then 3 blocks of (SEGMENT_GAP + SEGMENT_LEN). Time adjust to lower group on screen.
    constant INITIAL_GAP  : INTEGER := 85;   -- phases at start with N8_3 high (no draw) -> block higher on playfield
    constant SEGMENT_GAP  : INTEGER := 18;   -- scanlines between segments (~1/3 playfield height between defensemen)
    constant SEGMENT_LEN  : INTEGER := 16;   -- count 0..15 per segment
    constant PHASE_MAX    : INTEGER := INITIAL_GAP + 3 * (SEGMENT_GAP + SEGMENT_LEN) - 1;
    signal phase_count    : INTEGER range 0 to 511 := 0;
    signal N8_3           : STD_LOGIC;
    -- J8-2: invert N8_3 -> M7 LDn
    signal J8_2_out       : STD_LOGIC;
    -- M7 (IC9316)
    signal M7_QA, M7_QB, M7_QC, M7_QD : STD_LOGIC;
    signal M7_RC          : STD_LOGIC;
    -- J8-4: invert M7_RC -> M7 CEP and H8 CLK
    signal J8_4_out       : STD_LOGIC;
    -- L8 (LS00) gate 3: NAND(J8_4_out, J8_2_out) -> L8_8 -> J6 pin 11
    signal L8_8           : STD_LOGIC;
    -- H8 (LS107) Q1 -> E6-2, K6-10; Q2 -> K6-9. E6 pin 1 = goalie_segment (Q1 and not Q2) for 3-segment display.
    signal H8_Q1, H8_Q1n  : STD_LOGIC;
    signal H8_Q2, H8_Q2n  : STD_LOGIC;
    signal goalie_segment : STD_LOGIC;   -- Q1 and not Q2: high in goalie segment; E6 pin 1 so all 3 segments show
    signal E6_Y1         : STD_LOGIC;   -- E6 gate 1: goalie_segment xor Q1 -> J6-10
    signal K6_Y3         : STD_LOGIC;   -- K6 gate 3: Q1 and Q2 -> J6-9
    signal J6_Y3         : STD_LOGIC;   -- J6 gate 3: NOR(K6_8, E6_out, L8_8) -> raw symbol
    signal slot_ok_xor   : STD_LOGIC;   -- goalie_segment xor GOALIE (for xnor)
    signal slot_ok_xnor  : STD_LOGIC;   -- goalie_segment xnor GOALIE: 1 = show this slot
begin
    controls_ena   <= not ATRCn;
    comparator_out <= '1' when (controls_ena = '1' and UNSIGNED(RAMP_VALUE) >= UNSIGNED(POSITION)) else '0';

    -- 555 (N8) behavioural: when comparator high, run 0..PHASE_MAX. N8_3 high during INITIAL_GAP then per-block gap (load, no draw).
    -- VSYNCn='0' resets the counter each frame; needed because POSITION=0 means comparator is always '1'
    -- (ramp >= 0 is always true), so the comparator-low path never fires and without VSYNCn the counter
    -- would free-run across frame boundaries, drifting the player position by ~127 lines per frame.
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
    -- N8_3 high = load (no draw): initial gap, or gap within each of the 3 blocks
    N8_3 <= '1' when (comparator_out = '1' and (
        phase_count < INITIAL_GAP or
        (phase_count - INITIAL_GAP) mod (SEGMENT_GAP + SEGMENT_LEN) < SEGMENT_GAP
    )) else '0';

    -- J8-2 (LS04): invert N8_3
    U_J8_2: entity work.LS04
        port map(
            P1_A1   => N8_3,
            P2_Y1   => J8_2_out,
            P3_A2   => '0', P4_Y2 => open, P5_A3 => '0', P6_Y3 => open,
            P9_A4   => '0', P8_Y4 => open, P11_A5  => '0', P10_Y5 => open,
            P13_A6  => '0', P12_Y6 => open
        );

    -- M7 (IC9316): CLK=HSYNC, LDn=J8_2_out (load 0 when N8_3 high), CEP=J8_4_out (stop at 15).
    -- Pins 3,4,5,6 = load data A,B,C,D = logic 0. B1=M7 pin 13 (QB), C1=M7 pin 12 (QC), D1=M7 pin 11 (QD).
    U_M7: entity work.IC9316
        port map(
            P1_CLRn => '1',
            P2_CLK  => HSYNC,
            P3_A    => '0',   -- pin 3 load data
            P4_B    => '0',   -- pin 4
            P5_C    => '0',   -- pin 5
            P6_D    => '0',   -- pin 6
            P7_CEP  => J8_4_out,
            P9_LDn  => J8_2_out,
            P10_CET => '1',
            P11_QD  => M7_QD,
            P12_QC  => M7_QC,
            P13_QB  => M7_QB,
            P14_QA  => M7_QA,
            P15_RC  => M7_RC
        );

    -- J8-4 (LS04) gate 2: M7 pin 15 (RC) -> J8 pin 3 (A2), pin 4 (Y2) = J8_4_out
    U_J8_4: entity work.LS04
        port map(
            P1_A1   => '0', P2_Y1 => open,
            P3_A2   => M7_RC,
            P4_Y2   => J8_4_out,
            P5_A3   => '0', P6_Y3 => open,
            P9_A4   => '0', P8_Y4 => open, P11_A5  => '0', P10_Y5 => open,
            P13_A6  => '0', P12_Y6 => open
        );

    -- L8 (LS00) gate 3: pin 9=A3=J8_4_out, pin 10=B3=J8_2_out, pin 8=Y3=L8_8 -> J6 pin 11
    U_L8: entity work.LS00
        port map(
            P1_A1   => '1', P2_B1 => '1', P3_Y1 => open,
            P4_A2   => '1', P5_B2 => '1', P6_Y2 => open,
            P9_A3   => J8_4_out,
            P10_B3  => J8_2_out,
            P8_Y3   => L8_8,
            P11_Y4  => open, P12_A4 => '1', P13_B4 => '1'
        );

    -- H8 (LS107): J1=Q1n (pin 2->1), J2=Q1 (pin 3->8). Pin 6 (Q2n) -> pin 11 (K2) and pin 4 (K1). CLR1n/CLR2n=VSYNCn. CLK=J8_4_out.
    U_H8: entity work.LS107
        port map(
            P1_J1     => H8_Q1n,
            P2_Q1n    => H8_Q1n,
            P3_Q1     => H8_Q1,
            P4_K1     => H8_Q2n,
            P5_Q2     => H8_Q2,
            P6_Q2n    => H8_Q2n,
            P8_J2     => H8_Q1,
            P9_CLK2   => J8_4_out,
            P10_CLR2n => VSYNCn,
            P11_K2    => H8_Q2n,
            P12_CLK1  => J8_4_out,
            P13_CLR1n => VSYNCn
        );

    -- E6 (LS86) gate 1: pin 1=A1=goalie_segment (Q1 and not Q2), pin 2=B1=Q1 -> E6_Y1=0 for (0,0),(1,0),(0,1)
    goalie_segment <= H8_Q1 and (not H8_Q2);
    U_E6: entity work.LS86
        port map(
            P1_A1   => goalie_segment,
            P2_B1   => H8_Q1,
            P3_Y1   => E6_Y1,
            P4_A2   => '0', P5_B2 => '0', P6_Y2 => open,
            P9_A3   => '0', P10_B3 => '0', P8_Y3 => open,
            P12_A4  => '0', P13_B4 => '0', P11_Y4 => open
        );

    -- K6 (LS08) gate 3: pin 9=A3=Q2, pin 10=B3=Q1, pin 8=Y3 -> J6 pin 9
    U_K6: entity work.LS08
        port map(
            P1_A1   => '0', P2_B1 => '0', P3_Y1 => open,
            P4_A2   => '0', P5_B2 => '0', P6_Y2 => open,
            P9_A3   => H8_Q2,
            P10_B3  => H8_Q1,
            P8_Y3   => K6_Y3,
            P11_Y4  => open, P12_A4 => '0', P13_B4 => '0'
        );

    -- J6 (LS27) gate 3: pin 9=A3=K6_8, pin 10=B3=E6_out, pin 11=C3=L8_8, pin 8=Y3 -> raw symbol
    U_J6: entity work.LS27
        port map(
            P1_A1   => '0', P2_B1 => '0', P13_C1 => '0', P12_Y1 => open,
            P3_A2   => '0', P4_B2 => '0', P5_C2 => '0', P6_Y2 => open,
            P9_A3   => K6_Y3,
            P10_B3  => E6_Y1,
            P11_C3  => L8_8,
            P8_Y3   => J6_Y3
        );

    -- Gate E1 by vertical-window GOALIE so goalie column shows only middle segment, defensemen column only top+bottom.
    -- GOALIE=1 (goalie 4H slot): show only when goalie_segment. GOALIE=0 (defensemen 4H slot): show only when not goalie_segment.
    -- So E1 = J6_Y3 and (goalie_segment xnor GOALIE). XNOR via XOR (LS86) + inverter (LS04), then AND (LS08).
    U_E6_g2: entity work.LS86
        port map(
            P1_A1   => goalie_segment,
            P2_B1   => GOALIE,
            P3_Y1   => slot_ok_xor,
            P4_A2   => '0', P5_B2 => '0', P6_Y2 => open,
            P9_A3   => '0', P10_B3 => '0', P8_Y3 => open,
            P12_A4  => '0', P13_B4 => '0', P11_Y4 => open
        );
    U_J8_slot: entity work.LS04
        port map(
            P1_A1   => slot_ok_xor,
            P2_Y1   => slot_ok_xnor,
            P3_A2   => '0', P4_Y2 => open, P5_A3 => '0', P6_Y3 => open,
            P9_A4   => '0', P8_Y4 => open, P11_A5  => '0', P10_Y5 => open,
            P13_A6  => '0', P12_Y6 => open
        );
    U_K6_g4: entity work.LS08
        port map(
            P1_A1   => J6_Y3,
            P2_B1   => slot_ok_xnor,
            P3_Y1   => E1,
            P4_A2   => '0', P5_B2 => '0', P6_Y2 => open,
            P9_A3   => '0', P10_B3 => '0', P8_Y3 => open,
            P11_Y4  => open, P12_A4 => '0', P13_B4 => '0'
        );

    -- B1 = M7 pin 13 (QB), C1 = M7 pin 12 (QC), D1 = M7 pin 11 (QD).
    B1 <= M7_QB;
    C1 <= M7_QC;
    D1 <= M7_QD;
end Schematic;
