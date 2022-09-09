library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- 		 74LS04 
--     Hex Inverter
--		   ___  ___
-- 	  |   \/   |
--  A1 -| 1   14 |- VCC
--  Y1 -| 2	  13 |- A6
--  A2 -| 3	  12 |- Y6 
--  Y2 -| 4	  11 |- A5
--  A3 -| 5	  10 |- Y5
--  Y3 -| 6	   9 |- A4
-- GND -| 7	   8 |- Y4
--		  |________|

entity LS04 is
	Port (
		P1_A1 	: in  STD_LOGIC;
		P2_Y1 	: out STD_LOGIC;
		P3_A2		: in  STD_LOGIC;
		P4_Y2 	: out STD_LOGIC;
		P5_A3		: in  STD_LOGIC;
		P6_Y3 	: out STD_LOGIC;
		-- P7 : GND
		P8_Y4 	: out STD_LOGIC;
		P9_A4 	: in  STD_LOGIC;
		P10_Y5 	: out STD_LOGIC;
		P11_A5	: in  STD_LOGIC;
		P12_Y6 	: out STD_LOGIC;
		P13_A6	: in  STD_LOGIC
		-- P14 : VCC
	);
end LS04;

architecture Behavioral of LS04 is
begin
	P2_Y1 <= not P1_A1;
	P4_Y2 <= not P3_A2;
	P6_Y3 <= not P5_A3;
	P8_Y4 <= not P9_A4;
	P10_Y5 <= not P11_A5;
	P12_Y6 <= not P13_A6;
end Behavioral;
