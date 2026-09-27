-- Solid Forwards - Goal IV (WCC) TM-035 Figure 11
--
-- Schematic: Comparator N9-12 -> M9 (IC9602) -> differentiator (R39-C21, R40-C22) -> K8 (LS02)
-- -> K7 (IC9316), J8 (LS04) -> E2, B2, C2, D2.
-- M9 one-shot triggered on comparator high; differentiated edges drive K8 NOR low -> K7 loads 0;
-- when spikes decay K8 high -> K7 counts HSYNC. Trailing edge of M9 resets K7 again (bottom forward).

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PlayersSolidForwards is
    Generic (ATTRACT_POSITION : natural := 100); -- fixed analogue-model fallback
    Port (
        HSYNC      : in  STD_LOGIC;
        RAMP_VALUE : in  STD_LOGIC_VECTOR(9 downto 0);
        POSITION   : in  STD_LOGIC_VECTOR(9 downto 0);  -- Pot position (0-1023)
        ATRCn      : in  STD_LOGIC;  -- ATRCn from D9 pin 5 (high = play; low = attract)
        E2         : out STD_LOGIC;
        B2         : out STD_LOGIC;
        C2         : out STD_LOGIC;
        D2         : out STD_LOGIC
    );
end PlayersSolidForwards;

architecture Schematic of PlayersSolidForwards is
    signal comparator_out   : STD_LOGIC;
    signal M9_Q1            : STD_LOGIC;  -- M9 one-shot output
    signal spike_leading    : STD_LOGIC := '0';  -- differentiator: leading edge of M9_Q1
    signal spike_trailing   : STD_LOGIC := '0';  -- differentiator: trailing edge of M9_Q1
    signal M9_Q1_prev       : STD_LOGIC := '0';
    signal K8_Y1            : STD_LOGIC;  -- K8 NOR output -> K7 LDn
    signal K7_QA, K7_QB, K7_QC, K7_QD : STD_LOGIC;
    signal K7_RC            : STD_LOGIC;
    signal J8_Y1            : STD_LOGIC;  -- E2 = not K7_RC, also feeds K7 CEP
begin
    -- Q7/CR7 disconnect the controls in attract; symbols still run.
    -- The fallback preserves the existing board positions, pending analogue calibration.
    comparator_out <= '1' when
        (ATRCn = '1' and UNSIGNED(RAMP_VALUE) >= UNSIGNED(POSITION)) or
        (ATRCn = '0' and UNSIGNED(RAMP_VALUE) >= ATTRACT_POSITION) else '0';

    -- M9 (IC9602) clock-driven one-shot: trigger on comparator (A1); pulse width in HSYNC cycles
    M9: entity work.IC9602
        generic map ( PULSE_WIDTH_CLKS => 66 )  -- spacing between top and bottom forward
        port map (
            CLK      => HSYNC,
            P3_CLR1n => '1',
            P4_B1    => '1',       -- B1 inactive (active low trigger not used)
            P5_A1    => comparator_out,
            P6_Q1    => M9_Q1,
            P7_Q1n   => open,
            P9_Q2n   => open,
            P10_Q2   => open,
            P11_A2   => '0', P12_B2 => '1', P13_CLR2n => '1',
            P1_CEXT1 => '0', P2_REXT1 => '0', P14_REXT2 => '0', P15_CEXT2 => '0'
        );

    -- Differentiator (digital model of R39-C21, R40-C22): edge spikes from M9_Q1
    process(HSYNC)
    begin
        if rising_edge(HSYNC) then
            spike_leading  <= '0';
            spike_trailing <= '0';
            if M9_Q1 = '1' and M9_Q1_prev = '0' then
                spike_leading <= '1';
            elsif M9_Q1 = '0' and M9_Q1_prev = '1' then
                spike_trailing <= '1';
            end if;
            M9_Q1_prev <= M9_Q1;
        end if;
    end process;

    -- K8 (LS02) gate 1: NOR(spike_leading, spike_trailing) -> low when either spike; drives K7 LDn
    IC_K8: entity work.LS02
        port map (
            P2_A1   => spike_leading,
            P3_B1   => spike_trailing,
            P1_Y1   => K8_Y1,
            P5_A2   => '0', P6_B2 => '0', P4_Y2 => open,
            P8_A3   => '0', P9_B3 => '0', P10_Y3 => open,
            P11_A4  => '0', P12_B4 => '0', P13_Y4 => open
        );

    -- K7 (IC9316): CLK=HSYNC, load 0 when K8_Y1 low (LDn = K8 output), count when high; CEP from J8 (E2)
    IC_K7: entity work.IC9316
        port map(
            P1_CLRn => '1',
            P2_CLK  => HSYNC,
            P3_A    => '0',
            P4_B    => '0',
            P5_C    => '0',
            P6_D    => '0',
            P7_CEP  => J8_Y1,
            P9_LDn  => K8_Y1,
            P10_CET => '1',
            P11_QD  => K7_QD,
            P12_QC  => K7_QC,
            P13_QB  => K7_QB,
            P14_QA  => K7_QA,
            P15_RC  => K7_RC
        );

    -- J8 (LS04): K7 RC -> invert -> J8_Y1 (E2) and to K7 CEP
    IC_J8: entity work.LS04
        port map(
            P5_A3   => K7_RC,
            P6_Y3   => J8_Y1,
            P1_A1   => '0', P2_Y1 => open,
            P3_A2   => '0', P4_Y2 => open,
            P9_A4   => '0', P8_Y4 => open,
            P11_A5  => '0', P10_Y5 => open,
            P13_A6  => '0', P12_Y6 => open
        );

    E2 <= J8_Y1;
    B2 <= K7_QB;
    C2 <= K7_QC;
    D2 <= K7_QD;
end Schematic;
