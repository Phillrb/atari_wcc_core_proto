library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--           74LS107
--      DUAL J-K NEGATIVE
--   EDGE-TRIGGERED FLIP-FLOPS
--         WITH CLEAR
--          ___  ___
--         |   \/   |
--     J1 -| 1   14 |- VCC
--    !Q1 -| 2   13 |- CLR1!
--     Q1 -| 3   12 |- CLK1!
--     K1 -| 4   11 |- K2
--     Q2 -| 5   10 |- CLR2!
--    !Q2 -| 6    9 |- CLK2!
--    GND -| 7    8 |- J2
--         |________|

entity LS107 is
    -- Original 74107: master accepts J/K while clock is high, slave updates
    -- on its falling edge. Default preserves the existing LS107A-style model.
    -- https://www.ti.com/product/SN54107
    generic (MASTER_SLAVE : boolean := false);
	Port (
		P1_J1    : in  STD_LOGIC := '0';
		P2_Q1n   : out STD_LOGIC;
		P3_Q1    : out STD_LOGIC;
		P4_K1    : in  STD_LOGIC := '0';
		P5_Q2    : out STD_LOGIC;
		P6_Q2n   : out STD_LOGIC;
		-- P7 : GND
		P8_J2    : in STD_LOGIC := '0';
		P9_CLK2  : in STD_LOGIC := '0';
		P10_CLR2n : in STD_LOGIC := '1';
		P11_K2   : in STD_LOGIC := '0';
		P12_CLK1 : in STD_LOGIC := '0';
		P13_CLR1n : in STD_LOGIC := '1'
		-- P14 : VCC
	);
end LS107;

architecture Behavioral of LS107 is

signal CLK1n, CLK2n, CLR1, CLR2 : STD_LOGIC;
signal j1_i, k1_i, j2_i, k2_i : STD_LOGIC;

begin

    -- The transparent master closes at the external falling clock edge,
    -- before the internally inverted slave clock advances. In particular,
    -- data changing with that edge cannot be sampled by the slave.
    original_inputs: if MASTER_SLAVE generate
        process(P12_CLK1, P13_CLR1n, P1_J1, P4_K1)
        begin
            if P13_CLR1n='0' then
                j1_i<='0'; k1_i<='0';
            elsif P12_CLK1='1' then
                j1_i<=P1_J1; k1_i<=P4_K1;
            end if;
        end process;
        process(P9_CLK2, P10_CLR2n, P8_J2, P11_K2)
        begin
            if P10_CLR2n='0' then
                j2_i<='0'; k2_i<='0';
            elsif P9_CLK2='1' then
                j2_i<=P8_J2; k2_i<=P11_K2;
            end if;
        end process;
    end generate;

-- Negative edge clks
CLK1n <= not P12_CLK1;
CLK2n <= not P9_CLK2;

-- Clear is active low
CLR1 <= not P13_CLR1n;
CLR2 <= not P10_CLR2n;

edge_slaves: if not MASTER_SLAVE generate
    JKFF1: entity work.JK_flip_flop
        port map(CLK1n, P1_J1, P4_K1, '0', CLR1, P3_Q1, P2_Q1n);
    JKFF2: entity work.JK_flip_flop
        port map(CLK2n, P8_J2, P11_K2, '0', CLR2, P5_Q2, P6_Q2n);
end generate;
original_slaves: if MASTER_SLAVE generate
    JKFF1: entity work.JK_flip_flop
        port map(CLK1n, j1_i, k1_i, '0', CLR1, P3_Q1, P2_Q1n);
    JKFF2: entity work.JK_flip_flop
        port map(CLK2n, j2_i, k2_i, '0', CLR2, P5_Q2, P6_Q2n);
end generate;
end Behavioral;
