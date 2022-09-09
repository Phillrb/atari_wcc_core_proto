library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- 		    74LS107 
--     DUAL J-K NEGATIVE
--  EDGE-TRIGGERED FLIP-FLOPS
--         WITH CLEAR
--		      ___  ___
--    	  |   \/   |
--     J1 -| 1   14 |- VCC
--    !Q1 -| 2	  13 |- CLR1!
--     Q1 -| 3	  12 |- CLK1!
--     K1 -| 4	  11 |- K2
--     Q2 -| 5	  10 |- CLR2!
--    !Q2 -| 6	   9 |- CLK2!
--    GND -| 7	   8 |- J2
--		     |________|

entity LS107 is
	Port (
		P1_J1    : in  STD_LOGIC;
		P2_Q1n 	: out STD_LOGIC;
		P3_Q1 	: out STD_LOGIC;
		P4_K1    : in  STD_LOGIC;
		P5_Q2    : out STD_LOGIC;
		P6_Q2n   : out STD_LOGIC;
		-- P7 : GND
		P8_J2 	 : in STD_LOGIC;
		P9_CLK2 	 : in STD_LOGIC;
		P10_CLR2n : in STD_LOGIC;
		P11_K2	 : in STD_LOGIC;
		P12_CLK1	 : in STD_LOGIC;
		P13_CLR1n : in STD_LOGIC
		-- P14 : VCC
	);
end LS107;

architecture Behavioral of LS107 is

component JK_flip_flop is
	Port (
		clk, J, K, prs, clr : in  STD_LOGIC := '0';
		Q    : out STD_LOGIC;
		Qnot : out STD_LOGIC
	);
end component;

signal CLK1n, CLK2n, CLR1, CLR2 : STD_LOGIC;

begin

-- Negative edge clks
CLK1n <= not P12_CLK1;
CLK2n <= not P9_CLK2;

-- Clear is active low
CLR1 <= not P13_CLR1n;
CLR2 <= not P10_CLR2n;

JKFF1: JK_flip_flop 
	port map(
		CLK1n, P1_J1, P4_K1, '0', CLR1,
		P3_Q1, P2_Q1n
	);
	
JKFF2: JK_flip_flop 
	port map(
		CLK2n, P8_J2, P11_K2, '0', CLR2,
		P5_Q2, P6_Q2n
	);
	
end Behavioral;
