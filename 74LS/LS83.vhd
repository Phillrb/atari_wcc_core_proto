library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--        74LS83
--     4-bit Binary 
--      Full Adder
--       ___  ___
--      |   \/   |
--  A4 -| 1   16 |- B4
--  S3 -| 2	  15 |- S4
--  A3 -| 3	  14 |- COUT
--  B3 -| 4	  13 |- CIN
-- VCC -| 5	  12 |- GND
--  S2 -| 6	  11 |- B1
--  B2 -| 7	  10 |- A1
--  A2 -| 8	   9 |- S1
--      |________|

entity LS83 is
	Port (
		P1_A4 	: in  STD_LOGIC := '0';
		P2_S3 	: out STD_LOGIC;
		P3_A3	: in  STD_LOGIC := '0';
		P4_B3 	: in  STD_LOGIC := '0';
		-- P5 : VCC
		P6_S2 	: out STD_LOGIC;
		P7_B2 	: in  STD_LOGIC := '0';
		P8_A2 	: in  STD_LOGIC := '0';
		P9_S1 	: out STD_LOGIC;
		P10_A1 	: in  STD_LOGIC := '0';
		P11_B1	: in  STD_LOGIC := '0';
		-- P12 : GND
		P13_CIN : in  STD_LOGIC := '0';
		P14_COUT : out STD_LOGIC;
		P15_S4 : out STD_LOGIC;
		P16_B4 : in  STD_LOGIC := '0'
	);
end LS83;

architecture Behavioral of LS83 is
    signal a, b : std_logic_vector(3 downto 0);
    signal sum  : std_logic_vector(3 downto 0);
    signal carry : std_logic_vector(4 downto 0);
begin
    -- Map pins to vectors (A1 = LSB, A4 = MSB)
    a(0) <= P10_A1;
    a(1) <= P8_A2;
    a(2) <= P3_A3;
    a(3) <= P1_A4;
    b(0) <= P11_B1;
    b(1) <= P7_B2;
    b(2) <= P4_B3;
    b(3) <= P16_B4;
    carry(0) <= P13_CIN;

    -- Full adder logic
    sum(0) <= a(0) xor b(0) xor carry(0);
    carry(1) <= (a(0) and b(0)) or (a(0) and carry(0)) or (b(0) and carry(0));
    sum(1) <= a(1) xor b(1) xor carry(1);
    carry(2) <= (a(1) and b(1)) or (a(1) and carry(1)) or (b(1) and carry(1));
    sum(2) <= a(2) xor b(2) xor carry(2);
    carry(3) <= (a(2) and b(2)) or (a(2) and carry(2)) or (b(2) and carry(2));
    sum(3) <= a(3) xor b(3) xor carry(3);
    carry(4) <= (a(3) and b(3)) or (a(3) and carry(3)) or (b(3) and carry(3));

    -- Output assignments
    P9_S1  <= sum(0);
    P6_S2  <= sum(1);
    P2_S3  <= sum(2);
    P15_S4 <= sum(3);
    P14_COUT <= carry(4);
end Behavioral; 