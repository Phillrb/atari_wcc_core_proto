library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--         74LS90
--     DECADE COUNTER
--      (BCD Count)
--        ___  ___
--       |   \/   |
-- CP1n -| 1   14 |- CP0n
--  MR1 -| 2   13 |- NC
--  MR2 -| 3   12 |- Q0
--   NC -| 4   11 |- Q3
--  VCC -| 5   10 |- GND
--  MS1 -| 6    9 |- Q1
--  MS2 -| 7    8 |- Q2
--       |________|
--
-- Section A: Divide-by-2 (CP0n -> Q0)
-- Section B: Divide-by-5 (CP1n -> Q1, Q2, Q3)
-- For BCD, connect Q0 externally to CP1n.
-- MR1 AND MR2 = reset all to 0.
-- MS1 AND MS2 = set to 9 (Q3=1,Q2=0,Q1=0,Q0=1).

entity LS90 is
    Port (
        P1_CP1n  : in  STD_LOGIC := '0';  -- Clock for section B (falling edge)
        P2_MR1   : in  STD_LOGIC := '0';  -- Master Reset 1
        P3_MR2   : in  STD_LOGIC := '0';  -- Master Reset 2
        -- P4   : NC
        -- P5   : VCC
        P6_MS1   : in  STD_LOGIC := '0';  -- Master Set 1
        P7_MS2   : in  STD_LOGIC := '0';  -- Master Set 2
        P8_Q2    : out STD_LOGIC;          -- Q2 output
        P9_Q1    : out STD_LOGIC;          -- Q1 output
        -- P10  : GND
        P11_Q3   : out STD_LOGIC;          -- Q3 output
        P12_Q0   : out STD_LOGIC;          -- Q0 output
        -- P13  : NC
        P14_CP0n : in  STD_LOGIC := '0'   -- Clock for section A (falling edge)
    );
end LS90;

architecture Behavioral of LS90 is
    signal MR, MS : STD_LOGIC;
    signal Q0_i, Q1_i, Q2_i, Q3_i : STD_LOGIC;
    signal CLK_A, CLK_B : STD_LOGIC;
    -- J/K inputs for section B
    signal J1, J3 : STD_LOGIC;
    -- Clear/Preset per FF
    signal clr_0, prs_0 : STD_LOGIC;
    signal clr_1 : STD_LOGIC;
    signal clr_2 : STD_LOGIC;
    signal clr_3, prs_3 : STD_LOGIC;
begin
    -- Both MR pins must be HIGH to reset (same as LS93)
    MR <= P2_MR1 and P3_MR2;
    -- Both MS pins must be HIGH to set to 9
    MS <= P6_MS1 and P7_MS2;

    -- Invert active-low clocks for rising_edge JK FFs
    CLK_A <= not P14_CP0n;
    CLK_B <= not P1_CP1n;

    -- Clear/Preset logic per FF
    -- MR resets all; MS sets Q0=1, Q3=1, clears Q1=0, Q2=0
    -- JK FF: clr has priority over prs, so MR overrides MS
    clr_0 <= MR;
    prs_0 <= MS;
    clr_1 <= MR or MS;
    clr_2 <= MR or MS;
    clr_3 <= MR;
    prs_3 <= MS;

    -- Section A: Divide-by-2 (toggle FF on falling edge of CP0n)
    FF_A: entity work.JK_flip_flop
        port map(
            clk => CLK_A, J => '1', K => '1',
            prs => prs_0, clr => clr_0,
            Q => Q0_i
        );

    -- Section B: Divide-by-5 (mod-5 counter on falling edge of CP1n)
    -- FF-B (Q1): J=!Q3, K=1
    J1 <= not Q3_i;
    FF_B: entity work.JK_flip_flop
        port map(
            clk => CLK_B, J => J1, K => '1',
            prs => '0', clr => clr_1,
            Q => Q1_i
        );

    -- FF-C (Q2): J=Q1, K=Q1 (toggle when Q1=1, hold when Q1=0)
    FF_C: entity work.JK_flip_flop
        port map(
            clk => CLK_B, J => Q1_i, K => Q1_i,
            prs => '0', clr => clr_2,
            Q => Q2_i
        );

    -- FF-D (Q3): J=Q1&Q2, K=1
    J3 <= Q1_i and Q2_i;
    FF_D: entity work.JK_flip_flop
        port map(
            clk => CLK_B, J => J3, K => '1',
            prs => prs_3, clr => clr_3,
            Q => Q3_i
        );

    -- Output assignments
    P12_Q0 <= Q0_i;
    P9_Q1  <= Q1_i;
    P8_Q2  <= Q2_i;
    P11_Q3 <= Q3_i;

end Behavioral;
