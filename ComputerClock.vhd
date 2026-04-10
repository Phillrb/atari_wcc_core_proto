library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

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
A1: entity work.LS04
	port map(
		P3_A2 => CLOCK_14,
		P4_Y2 => A1_p4
	);

-- E2: LS74 dual D flip-flop (divides by 2)
E2: entity work.LS74
	port map(
		P8_Q2n => E2_p8,
		P9_Q2 => CLOCK_7,
		P10_SET2n => '1',
		P11_CLK2 => A1_p4,
		P12_D2 => E2_p8,
		P13_CLR2n => '1'
	);

end Behavioral;
