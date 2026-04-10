library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--        74LS30
--     8-Input NAND Gate
--       ___  ___
--      |   \/   |
--   A -| 1   14 |- VCC
--   B -| 2   13 |- NC
--   C -| 3   12 |- H
--   D -| 4   11 |- G
--   E -| 5   10 |- NC
--   F -| 6    9 |- NC
-- GND -| 7    8 |- Y
--      |________|

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

P8_Y <= not(P1_A and P2_B and P3_C and P4_D and P5_E and P6_F and P11_G and P12_H);

end Behavioral;
