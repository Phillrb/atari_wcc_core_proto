library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- 		  74LS00 
--     Quad 2-Input
--		NAND Gates
--		 ___  ___
-- 	    |   \/   |
--  A1 -| 1   14 |- VCC
--  B1 -| 2	  13 |- B4
--  Y1 -| 3	  12 |- A4 
--  A2 -| 4	  11 |- Y4
--  B2 -| 5	  10 |- B3
--  Y2 -| 6	   9 |- A3
-- GND -| 7	   8 |- Y3
--      |________|

entity LS00 is
	Port (
		P1_A1 	: in  STD_LOGIC := '1';
		P2_B1 	: in  STD_LOGIC := '1';
		P3_Y1	: out STD_LOGIC;
		P4_A2 	: in  STD_LOGIC := '1';
		P5_B2	: in  STD_LOGIC := '1';
		P6_Y2 	: out STD_LOGIC;
		-- P7 : GND
		P8_Y3 	: out STD_LOGIC;
		P9_A3 	: in  STD_LOGIC := '1';
		P10_B3 	: in  STD_LOGIC := '1';
		P11_Y4	: out STD_LOGIC;
		P12_A4 	: in  STD_LOGIC := '1';
		P13_B4	: in  STD_LOGIC := '1'
		-- P14 : VCC
	);
end LS00;

architecture Behavioral of LS00 is
begin
	P3_Y1 <= P1_A1 nand P2_B1;
	P6_Y2 <= P4_A2 nand P5_B2;
	P8_Y3 <= P9_A3 nand P10_B3;
	P11_Y4 <= P12_A4 nand P13_B4;
end Behavioral;
