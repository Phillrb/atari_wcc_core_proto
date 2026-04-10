library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--         74LS92
--       DIVIDE-BY-12
--         COUNTER
--        ___  ___
--       |   \/   |
-- CP1n -| 1   14 |- CP0n
--   NC -| 2   13 |- NC
--   NC -| 3   12 |- Q0
--   NC -| 4   11 |- Q1
--  VCC -| 5   10 |- GND
--  MR1 -| 6    9 |- Q2
--  MR2 -| 7    8 |- Q3
--       |________|
--
-- Section A: Divide-by-2 (CP0n -> Q0)
-- Section B: Divide-by-6 (CP1n -> Q1, Q2, Q3)
-- For divide-by-12, connect Q0 externally to CP1n.
-- MR1 AND MR2 = reset all to 0.

entity LS92 is
    Port (
        P1_CP1n  : in  STD_LOGIC := '0';  -- Clock for section B (falling edge)
        -- P2   : NC
        -- P3   : NC
        -- P4   : NC
        -- P5   : VCC
        P6_MR1   : in  STD_LOGIC := '0';  -- Master Reset 1
        P7_MR2   : in  STD_LOGIC := '0';  -- Master Reset 2
        P8_Q3    : out STD_LOGIC;          -- Q3 output
        P9_Q2    : out STD_LOGIC;          -- Q2 output
        -- P10  : GND
        P11_Q1   : out STD_LOGIC;          -- Q1 output
        P12_Q0   : out STD_LOGIC;          -- Q0 output
        -- P13  : NC
        P14_CP0n : in  STD_LOGIC := '0'   -- Clock for section A (falling edge)
    );
end LS92;

architecture Behavioral of LS92 is
    signal MR : STD_LOGIC;
    signal Q1_i, Q2_i, Q3_i : STD_LOGIC;
    signal CLK_A, CLK_B : STD_LOGIC;
    -- J/K inputs for section B
    signal J2, K2, J3, K3 : STD_LOGIC;
begin
    -- Both MR pins must be HIGH to reset
    MR <= P6_MR1 and P7_MR2;

    -- Invert active-low clocks for rising_edge JK FFs
    CLK_A <= not P14_CP0n;
    CLK_B <= not P1_CP1n;

    -- Section A: Divide-by-2 (toggle FF on falling edge of CP0n)
    FF_A: entity work.JK_flip_flop
        port map(
            clk => CLK_A, J => '1', K => '1',
            prs => '0', clr => MR,
            Q => P12_Q0
        );

    -- Section B: Divide-by-6 (mod-6 counter on falling edge of CP1n)
    -- Counts: 000->001->010->011->100->101->000
    --
    -- FF-B (Q1): J=1, K=1 (always toggle)
    FF_B: entity work.JK_flip_flop
        port map(
            clk => CLK_B, J => '1', K => '1',
            prs => '0', clr => MR,
            Q => Q1_i
        );

    -- FF-C (Q2): J=Q1*!Q3, K=Q1
    J2 <= Q1_i and (not Q3_i);
    K2 <= Q1_i;
    FF_C: entity work.JK_flip_flop
        port map(
            clk => CLK_B, J => J2, K => K2,
            prs => '0', clr => MR,
            Q => Q2_i
        );

    -- FF-D (Q3): J=Q1*Q2, K=Q1
    J3 <= Q1_i and Q2_i;
    K3 <= Q1_i;
    FF_D: entity work.JK_flip_flop
        port map(
            clk => CLK_B, J => J3, K => K3,
            prs => '0', clr => MR,
            Q => Q3_i
        );

    -- Output assignments
    P11_Q1 <= Q1_i;
    P9_Q2  <= Q2_i;
    P8_Q3  <= Q3_i;

end Behavioral;
