library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- 		  74LS02 
--      Quad 2-Input
--		 NOR Gates
--		 ___  ___
-- 	    |   \/   |
--  Y1 -| 1   14 |- VCC
--  A1 -| 2	  13 |- Y4
--  B1 -| 3	  12 |- B4 
--  Y2 -| 4	  11 |- A4
--  A2 -| 5	  10 |- Y3
--  B2 -| 6	   9 |- B3
-- GND -| 7	   8 |- A3
--		|________|

entity LS02 is
	Port (
		P1_Y1 	: out STD_LOGIC;
		P2_A1 	: in  STD_LOGIC := '0';
		P3_B1	: in  STD_LOGIC := '0';
		P4_Y2 	: out STD_LOGIC;
		P5_A2	: in  STD_LOGIC := '0';
		P6_B2 	: in  STD_LOGIC := '0';
		-- P7 : GND
		P8_A3 	: in  STD_LOGIC := '0';
		P9_B3 	: in  STD_LOGIC := '0';
		P10_Y3 	: out	STD_LOGIC;
		P11_A4	: in  STD_LOGIC := '0';
		P12_B4 	: in  STD_LOGIC := '0';
		P13_Y4	: out STD_LOGIC
		-- P14 : VCC
	);
end LS02;

architecture Behavioral of LS02 is
begin
	P1_Y1 <= P2_A1 nor P3_B1;
	P4_Y2 <= P5_A2 nor P6_B2;
	P10_Y3 <= P8_A3 nor P9_B3;
	P13_Y4 <= P11_A4 nor P12_B4;
end Behavioral;
