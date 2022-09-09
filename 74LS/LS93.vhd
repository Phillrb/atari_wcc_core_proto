library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- 		    74LS93 
--    4-Bit Binary Counter
--		      ___  ___
--    	  |   \/   |
--   !CP1 -| 1   14 |- !CP0
--    MR1 -| 2	  13 |- NC
--    MR2 -| 3	  12 |- Q0 
--     NC -| 4	  11 |- Q3
--    VCC -| 5	  10 |- GND
--     NC -| 6	   9 |- Q1
--     NC -| 7	   8 |- Q2
--		     |________|

entity LS93 is
	Port (
		P1_CP1n 	: in  STD_LOGIC;
		P2_MR1 	: in  STD_LOGIC;
		P3_MR2	: in  STD_LOGIC;
		-- P4 : NC
		-- P5 : VCC
		-- P6 : NC
		-- P7 : NC
		P8_Q2 	: out STD_LOGIC;
		P9_Q1 	: out STD_LOGIC;
		-- P10 : GND
		P11_Q3	: out STD_LOGIC;
		P12_Q0	: out STD_LOGIC;
		-- P13 : NC
		P14_CP0n : in  STD_LOGIC
	);
end LS93;

architecture Behavioral of LS93 is

signal MR, Q1, Q2, Q3 : STD_LOGIC;
signal Q0_in, Q1_in, Q2_in, Q3_in : STD_LOGIC;

component JK_flip_flop is
	Port (
		clk, J, K, prs, clr : in  STD_LOGIC := '0';
		Q    : out STD_LOGIC;
		Qnot : out STD_LOGIC
	);
end component;

begin

MR <= P2_MR1 nand P3_MR2;
Q0_in <= not P14_CP0n;

Q0_JKFF: JK_flip_flop 
	port map(
		Q0_in, '1', '1', '0', MR,
		P12_Q0
	);
	
Q1_in <= not P1_CP1n;
	
Q1_JKFF: JK_flip_flop 
	port map(
		Q1_in, '1', '1', '0', MR,
		Q1
	);

P9_Q1 <= Q1;
Q2_in <= not Q1;
	
Q2_JKFF: JK_flip_flop 
	port map(
		Q2_in, '1', '1', '0', MR,
		Q2
	);

P8_Q2 <= Q2;
Q3_in <= not Q2;

Q3_JKFF: JK_flip_flop 
	port map(
		Q3_in, '1', '1', '0', MR,
		Q3
	);
	
P11_Q3 <= Q3;
	
end Behavioral;
