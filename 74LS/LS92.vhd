library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--         74LS92 
--   DIVIDE-BY-12 COUNTER
--        ___  ___
--       |   \/   |
--  R01 -| 1   14 |- VCC
--  R02 -| 2   13 |- NC
--  NC  -| 3   12 |- Q0
--  NC  -| 4   11 |- Q3
--  VCC -| 5   10 |- GND
--  NC  -| 6    9 |- Q1
--  NC  -| 7    8 |- Q2
--       |________|

entity LS92 is
	Port (
		P1_R01  : in  STD_LOGIC := '1';  -- Reset input 1
		P2_R02  : in  STD_LOGIC := '1';  -- Reset input 2
		-- P3 : NC
		-- P4 : NC
		-- P5 : VCC
		-- P6 : NC
		-- P7 : NC
		P8_Q2   : out STD_LOGIC;         -- Q2 output
		P9_Q1   : out STD_LOGIC;         -- Q1 output
		-- P10 : GND
		P11_Q3  : out STD_LOGIC;         -- Q3 output
		P12_Q0  : out STD_LOGIC;         -- Q0 output
		-- P13 : NC
		-- P14 : VCC
		CP0     : in  STD_LOGIC := '0';  -- Clock input 0 (external)
		CP1     : in  STD_LOGIC := '0'   -- Clock input 1 (external)
	);
end LS92;

architecture Behavioral of LS92 is

signal count : unsigned(3 downto 0) := "0000";
signal reset : STD_LOGIC;

begin

-- Reset logic (active low reset)
reset <= P1_R01 and P2_R02;

-- Main counter process
process(CP0, CP1, reset)
begin
    if reset = '0' then
        -- Reset condition - clear counter
        count <= "0000";
    elsif rising_edge(CP0) then
        -- Count on CP0 rising edge
        if count = "1011" then  -- 11 in decimal (0-11 = 12 states)
            count <= "0000";    -- Reset to 0
        else
            count <= count + 1;
        end if;
    elsif rising_edge(CP1) then
        -- Count on CP1 rising edge (alternative clock)
        if count = "1011" then  -- 11 in decimal (0-11 = 12 states)
            count <= "0000";    -- Reset to 0
        else
            count <= count + 1;
        end if;
    end if;
end process;

-- Output assignments
P12_Q0 <= count(0);  -- LSB
P9_Q1  <= count(1);
P8_Q2  <= count(2);
P11_Q3 <= count(3);  -- MSB

end Behavioral; 