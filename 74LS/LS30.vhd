library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- 		  74LS30 
--        8-Input
--		 NAND Gate
--		 ___  ___
-- 	    |   \/   |
--  A1 -| 1   14 |- VCC
--  B1 -| 2	  13 |- B4
--  Y1 -| 3	  12 |- A4 
--  A2 -| 4	  11 |- Y4
--  B2 -| 5	  10 |- B3
--  Y2 -| 6	   9 |- A3
-- GND -| 7	   8 |- Y3
--		|________|

entity LS30 is
	Port (
		P1_A	 : in  STD_LOGIC := '1';
		P2_B 	 : in  STD_LOGIC := '1';
		P3_C	 : in  STD_LOGIC := '1';
		P4_D 	 : in  STD_LOGIC := '1';
		P5_E	 : in  STD_LOGIC := '1';
		P6_F 	 : in  STD_LOGIC := '1';
		-- P7  : GND
		P8_Y 	 : out STD_LOGIC;
		-- P9  : NC
		-- P10 : NC
		P11_G  : in  STD_LOGIC := '1';
		P12_H  : in  STD_LOGIC := '1'
		-- P13 : NC
		-- P14 : VCC
	);
end LS30;

architecture Behavioral of LS30 is
begin
	P8_Y <= (((((((P1_A nand P2_B) nand P3_C) nand P4_D) nand P5_E) nand P6_F) nand P11_G) nand P12_H);
end Behavioral;
