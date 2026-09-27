-- Striped Forwards (right-team forwards) - Goal IV (WCC) TM-035 Figure 11
--
-- Per user pin list:
--   J9 (9602): pin 12 = RAMP_VALUE (comparator); 11 = P2 (Logic 1); 15/14 = Rext/Cext (variable R + cap);
--   pin 10 (Q2) -> K8 pin 11 (1k pull-up, 0.01uF cap); pin 13 = CLR2n (Logic 1);
--   pin 9 (Q2n) -> K8 pin 12 (1k pull-down, 0.01uF cap).
--   K8 pin 13 -> N7 pin 9 (LDn).
--   N7 (9316): 3,4,5,6 = 0; 1,10 = 1; HSYNC -> pin 2; pin 13 = B3, 12 = C3, 11 = D3;
--   N7 pin 15 (RC) -> J8 pin 9; J8 pin 8 -> N7 pin 7 (CEP) and Signal E3.
--
-- Same structure as solid forwards: comparator -> J9 one-shot -> differentiator -> K8 NOR -> N7 LDn;
-- N7 counts HSYNC when not loading; J8 inverts RC for E3 and N7 CEP.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PlayersStripedForwards is
    Generic (ATTRACT_POSITION : natural := 100); -- fixed analogue-model fallback
    Port (
        HSYNC      : in  STD_LOGIC;
        RAMP_VALUE : in  STD_LOGIC_VECTOR(9 downto 0);
        POSITION   : in  STD_LOGIC_VECTOR(9 downto 0);
        ATRCn      : in  STD_LOGIC;
        E3         : out STD_LOGIC;
        B3         : out STD_LOGIC;
        C3         : out STD_LOGIC;
        D3         : out STD_LOGIC
    );
end PlayersStripedForwards;

architecture Schematic of PlayersStripedForwards is
    signal comparator_out   : STD_LOGIC;
    signal J9_Q2            : STD_LOGIC;
    signal spike_leading    : STD_LOGIC := '0';
    signal spike_trailing   : STD_LOGIC := '0';
    signal J9_Q2_prev       : STD_LOGIC := '0';
    signal K8_Y1            : STD_LOGIC;   -- K8 NOR output -> N7 LDn
    signal N7_QB, N7_QC, N7_QD : STD_LOGIC;
    signal N7_RC            : STD_LOGIC;
    signal J8_Y1            : STD_LOGIC;   -- E3 = not N7_RC, also N7 CEP
begin
    -- Q7/CR7 disconnect the controls in attract; symbols still run.
    -- The fallback preserves the existing board positions, pending analogue calibration.
    comparator_out <= '1' when
        (ATRCn = '1' and UNSIGNED(RAMP_VALUE) >= UNSIGNED(POSITION)) or
        (ATRCn = '0' and UNSIGNED(RAMP_VALUE) >= ATTRACT_POSITION) else '0';

    -- J9 (IC9602) channel 2: trigger on comparator (A2); B2=1, CLR2n=1. Pulse width sets forward spacing.
    J9: entity work.IC9602
        generic map (
            PULSE_WIDTH_CLKS  => 1000,
            PULSE_WIDTH_CLKS2 => 66
        )
        port map (
            CLK       => HSYNC,
            P3_CLR1n  => '1',
            P4_B1     => '1',
            P5_A1     => '0',
            P6_Q1     => open,
            P7_Q1n    => open,
            P9_Q2n    => open,
            P10_Q2    => J9_Q2,
            P11_A2    => comparator_out,
            P12_B2    => '1',
            P13_CLR2n => '1',
            P1_CEXT1  => '0', P2_REXT1 => '0', P14_REXT2 => '0', P15_CEXT2 => '0'
        );

    -- Differentiator (digital model of RC on J9 Q2 / Q2n): edge spikes
    process(HSYNC)
    begin
        if rising_edge(HSYNC) then
            spike_leading  <= '0';
            spike_trailing <= '0';
            if J9_Q2 = '1' and J9_Q2_prev = '0' then
                spike_leading <= '1';
            elsif J9_Q2 = '0' and J9_Q2_prev = '1' then
                spike_trailing <= '1';
            end if;
            J9_Q2_prev <= J9_Q2;
        end if;
    end process;

    -- K8 (LS02) gate 1: NOR(spike_leading, spike_trailing) -> low when either spike; output (pin 11) -> N7 LDn (pin 9)
    U_K8: entity work.LS02
        port map (
            P2_A1   => spike_leading,
            P3_B1   => spike_trailing,
            P1_Y1   => K8_Y1,
            P5_A2   => '0', P6_B2 => '0', P4_Y2 => open,
            P8_A3   => '0', P9_B3 => '0', P10_Y3 => open,
            P11_A4  => '0', P12_B4 => '0', P13_Y4 => open
        );

    -- N7 (IC9316): CLK=HSYNC, load 0 when K8_Y1 low (LDn = K8 pin 11 -> N7 pin 9), CEP from J8 (E3)
    U_N7: entity work.IC9316
        port map (
            P1_CLRn => '1',
            P2_CLK  => HSYNC,
            P3_A    => '0',
            P4_B    => '0',
            P5_C    => '0',
            P6_D    => '0',
            P7_CEP  => J8_Y1,
            P9_LDn  => K8_Y1,
            P10_CET => '1',
            P11_QD  => N7_QD,
            P12_QC  => N7_QC,
            P13_QB  => N7_QB,
            P14_QA  => open,
            P15_RC  => N7_RC
        );

    -- J8 (LS04) gate 4: N7 RC (pin 15) -> pin 9 (A4), pin 8 (Y4) = J8_Y1 -> N7 CEP (pin 7) and E3
    U_J8: entity work.LS04
        port map (
            P9_A4   => N7_RC,
            P8_Y4   => J8_Y1,
            P1_A1   => '0', P2_Y1 => open,
            P3_A2   => '0', P4_Y2 => open,
            P5_A3   => '0', P6_Y3 => open,
            P11_A5  => '0', P10_Y5 => open,
            P13_A6  => '0', P12_Y6 => open
        );

    E3 <= J8_Y1;
    B3 <= N7_QB;
    C3 <= N7_QC;
    D3 <= N7_QD;
end Schematic;
