library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- 		  74LS10 
--     TRIPLE 3-INPUT
--		 NAND GATE
--  	 ___  ___
-- 	    |   \/   |
--  A1 -| 1   14 |- VCC
--  B1 -| 2	  13 |- C1
--  A2 -| 3	  12 |- Y1 
--  B2 -| 4	  11 |- C3
--  C2 -| 5	  10 |- B3
--  Y2 -| 6	   9 |- A3
-- GND -| 7	   8 |- Y3
--		|________|

entity LS10 is
	Port (
		P1_A1  : in  STD_LOGIC := '1';
		P2_B1  : in  STD_LOGIC := '1';
		P3_A2  : in  STD_LOGIC := '1';
		P4_B2  : in  STD_LOGIC := '1';
		P5_C2  : in  STD_LOGIC := '1';
		P6_Y2  : out STD_LOGIC;
		-- P7  : GND
		P8_Y3  : out STD_LOGIC;
		P9_A3  : in  STD_LOGIC := '1';
		P10_B3 : in  STD_LOGIC := '1';
		P11_C3 : in  STD_LOGIC := '1';
		P12_Y1 : out STD_LOGIC;
		P13_C1 : in  STD_LOGIC := '1'
		-- P14 : VCC
	);
end LS10;

architecture Behavioral of LS10 is
begin
	P6_Y2 <= ((P3_A2 nand P4_B2) nand P5_C2);
	P8_Y3 <= ((P9_A3 nand P10_B3) nand P11_C3);
	P12_Y1 <= ((P1_A1 nand P2_B1) nand P13_C1);
end Behavioral;
