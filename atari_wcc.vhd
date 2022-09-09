library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity atari_wcc is
	Port (
		Clock_50 : in  STD_LOGIC;
		PushBtn 	: in  STD_LOGIC;
		LED0 		: out STD_LOGIC;
		LED1 		: out STD_LOGIC;
		LED2 		: out STD_LOGIC;
		CSync_out 	: out STD_LOGIC
	);
end atari_wcc;

architecture Behavioral of atari_wcc is

signal CLOCK_READY, CLOCK_14_RAW, CLOCK_14: STD_LOGIC;

component clock_divider is
port( inclk0	: in  STD_LOGIC := '0';
		c0			: out STD_LOGIC;
		locked	: out STD_LOGIC);
end component;

component CompSync is
port( CLOCK_14 : in  STD_LOGIC;
		CSYNC 	: out STD_LOGIC);
end component;
	
begin

	clock: clock_divider 
		port map(
			Clock_50,
			CLOCK_14_RAW,
			CLOCK_READY 
		);
	
	-- Get a 14Mhz clock only when PLL is locked
	CLOCK_14 <= CLOCK_14_RAW and CLOCK_READY;

	csync: CompSync
		port map(
			CLOCK_14,
			CSync_out
		);

	-- DEBUG
   LED0 <= not PushBtn;
   LED1 <= PushBtn;
   LED2 <= '1';
	
end Behavioral;
