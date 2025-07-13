library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- 		   74LS20 
--      DUAL 4-INPUT
--		 NAND GATE
--		 ___  ___
-- 	    |   \/   |
--  A1 -| 1   14 |- VCC
--  B1 -| 2	  13 |- A2
--  NC -| 3	  12 |- B2 
--  C1 -| 4	  11 |- NC
--  D1 -| 5	  10 |- C2
--  Y1 -| 6	   9 |- D2
-- GND -| 7	   8 |- Y2
--		|________|

entity LS20 is
	Port (
		P1_A1  : in  STD_LOGIC := '1';
		P2_B1  : in  STD_LOGIC := '1';
		-- P3  : NC
		P4_C1  : in  STD_LOGIC := '1';
		P5_D1  : in  STD_LOGIC := '1';
		P6_Y1  : out STD_LOGIC;
		-- P7  : GND
		P8_Y2  : out STD_LOGIC;
		P9_D2  : in  STD_LOGIC := '1';
		P10_C2 : in  STD_LOGIC := '1';
		-- P11 : NC
		P12_B2 : in  STD_LOGIC := '1';
		P13_A2 : in  STD_LOGIC := '1'
		-- P14 : VCC
	);
end LS20;

architecture Behavioral of LS20 is
begin
	P6_Y1 <= (((P1_A1 nand P2_B1) nand P4_C1) nand P5_D1);
	P8_Y2 <= (((P13_A2 nand P12_B2) nand P10_C2) nand P9_D2);
end Behavioral;
