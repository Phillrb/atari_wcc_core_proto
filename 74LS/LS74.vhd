library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- 		    74LS74 
--    DUAL D-TYPE POSITIVE
--  EDGE-TRIGGERED FLIP-FLOP
--		      ___  ___
--    	  |   \/   |
--  !CLR1 -| 1   14 |- VCC
--     D1 -| 2	  13 |- !CLR2
--   CLK1 -| 3	  12 |- D2
--  !SET1 -| 4	  11 |- CLK2
--     Q1 -| 5	  10 |- !SET2
--    !Q1 -| 6	   9 |- Q2
--    GND -| 7	   8 |- !Q2
--		     |________|

entity LS74 is
	Port (
		P1_CLR1n : in  STD_LOGIC;
		P2_D1 	: in  STD_LOGIC;
		P3_CLK1	: in  STD_LOGIC;
		P4_SET1n : in  STD_LOGIC;
		P5_Q1    : out STD_LOGIC;
		P6_Q1n   : out STD_LOGIC;
		-- P7 : GND
		P8_Q2n 	: out STD_LOGIC;
		P9_Q2 	: out STD_LOGIC;
		P10_SET2n : in STD_LOGIC;
		P11_CLK2	:  in STD_LOGIC;
		P12_D2	:  in STD_LOGIC;
		P13_CLR2n : in STD_LOGIC
		-- P14 : VCC
	);
end LS74;

architecture Behavioral of LS74 is

component D_flip_flop is
	Port (
		clk, D, prs, clr : in  STD_LOGIC := '0';
		Q    : out STD_LOGIC;
		Qnot : out STD_LOGIC
	);
end component;

signal SET1, SET2, CLR1, CLR2 : STD_LOGIC;

begin

SET1 <= not P4_SET1n;
CLR1 <= not P1_CLR1n;
SET2 <= not P10_SET2n;
CLR2 <= not P13_CLR2n;

DFF1: D_flip_flop 
	port map(
		P3_CLK1, P2_D1, SET1, CLR1,
		P5_Q1, P6_Q1n
	);
	
DFF2: D_flip_flop 
	port map(
		P11_CLK2, P12_D2, SET2, CLR2,
		P9_Q2, P8_Q2n
	);
	
end Behavioral;
