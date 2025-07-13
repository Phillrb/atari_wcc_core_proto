library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- 		  74LS27 
--    TRIPLE 3-INPUT
--		 NOR GATE
--		 ___  ___
-- 	    |   \/   |
--  A1 -| 1   14 |- VCC
--  B1 -| 2	  13 |- C1
--  A2 -| 3	  12 |- Y1 
--  B2 -| 4	  11 |- C3
--  C2 -| 5	  10 |- B3
--  Y2 -| 6	   9 |- A3
-- GND -| 7	   8 |- Y3
--      |________|

entity LS27 is
	Port (
		P1_A1  : in  STD_LOGIC := '0';
		P2_B1  : in  STD_LOGIC := '0';
		P3_A2  : in  STD_LOGIC := '0';
		P4_B2  : in  STD_LOGIC := '0';
		P5_C2  : in  STD_LOGIC := '0';
		P6_Y2  : out STD_LOGIC;
		-- P7  : GND
		P8_Y3  : out STD_LOGIC;
		P9_A3  : in  STD_LOGIC := '0';
		P10_B3 : in  STD_LOGIC := '0';
		P11_C3 : in  STD_LOGIC := '0';
		P12_Y1 : out STD_LOGIC;
		P13_C1 : in  STD_LOGIC := '0'
		-- P14 : VCC
	);
end LS27;

architecture Behavioral of LS27 is
begin
	P6_Y2 <= ((P3_A2 nor P4_B2) nor P5_C2);
	P8_Y3 <= ((P9_A3 nor P10_B3) nor P11_C3);
	P12_Y1 <= ((P1_A1 nor P2_B1) nor P13_C1);
end Behavioral;
