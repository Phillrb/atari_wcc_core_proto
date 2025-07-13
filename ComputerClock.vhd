library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.components_pkg.ALL;

entity ComputerClock is
	Port (
		CLOCK_14 : in STD_LOGIC;  -- 14.318180 MHz
		CLOCK_7 : out STD_LOGIC   --  7.159090 MHz
	);
end ComputerClock;

architecture Behavioral of ComputerClock is

-- Internal signals
signal E2_p8, A1_p4: STD_LOGIC;
	
begin
	
-- A1: LS04 hex inverter
-- A1-12 and A1-10 form the oscillator (not explicitly modeled here)
-- A1-4 is the inverter that routes signal to E2-9/8
A1: LS04
	port map(
		P3_A2 => CLOCK_14, -- A1-4 input (14.318180 MHz)
		P4_Y2 => A1_p4  -- A1-4 output (inverted clock)
	);
	
-- E2: LS74 dual D flip-flop
-- E2-9/8 is the flip-flop that divides by 2
E2: LS74
	port map(
		P8_Q2n => E2_p8,
		P9_Q2 => CLOCK_7, -- E2-9 output (7.159090 MHz)
		P10_SET2n => '1', -- Set disabled
		P11_CLK2 => A1_p4, -- inverse clock input
		P12_D2 => E2_p8,   
		P13_CLR2n => '1' -- Clear disabled
	);
	
end Behavioral;
