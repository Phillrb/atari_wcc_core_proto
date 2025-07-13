library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.components_pkg.ALL;

entity SyncSumming is
	Port (
		HSYNC    : in  STD_LOGIC;
		VSYNCn   : in  STD_LOGIC;
		CSYNC    : out STD_LOGIC
	);
end SyncSumming;

architecture Behavioral of SyncSumming is

begin

-- Sync summing - combines HSYNC and VSYNC into CSYNC
A5: LS86
	port map (
		P4_A2 => VSYNCn,
		P5_B2 => HSYNC,
		P6_Y2 => CSYNC
	);

end Behavioral;
