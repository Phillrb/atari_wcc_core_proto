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

signal CLOCK_READY, CLOCK_14_RAW, CLOCK_14, CLOCK_7: STD_LOGIC;

-- Horizontal sync signals
signal HSYNC, HSYNCn : STD_LOGIC;
signal H1, H2, H4, H8, H16, H32, H64, H64n, H128, H256, H256n : STD_LOGIC;
signal HRESET, HRESETn : STD_LOGIC;
signal HBLANK, HBLANKn : STD_LOGIC;

-- Vertical sync signals
signal VSYNC, VSYNCn : STD_LOGIC;
signal V1, V2, V4, V8, V16, V32, V64, V128, V256, V256n : STD_LOGIC;
signal VRESET, VRESETn : STD_LOGIC;

component clock_divider is
port( inclk0	: in  STD_LOGIC := '0';
		c0			: out STD_LOGIC;
		locked	: out STD_LOGIC);
end component;

component ComputerClock is
port( CLOCK_14 : in  STD_LOGIC;
		CLOCK_7  : out STD_LOGIC);
end component;

component HorizontalSync is
port( CLOCK_7  : in  STD_LOGIC;
		HSYNC    : out STD_LOGIC;
		HSYNCn   : out STD_LOGIC;
		H1       : out STD_LOGIC;
		H2       : out STD_LOGIC;
		H4       : out STD_LOGIC;
		H8       : out STD_LOGIC;
		H16      : out STD_LOGIC;
		H32      : out STD_LOGIC;
		H64      : out STD_LOGIC;
		H64n     : out STD_LOGIC;
		H128     : out STD_LOGIC;
		H256     : out STD_LOGIC;
		H256n    : out STD_LOGIC;
		HRESET   : out STD_LOGIC;
		HRESETn  : out STD_LOGIC;
		HBLANK   : out STD_LOGIC;
		HBLANKn  : out STD_LOGIC);
end component;

component VerticalSync is
port( HRESET   : in  STD_LOGIC;
		VSYNC    : out STD_LOGIC;
		VSYNCn   : out STD_LOGIC;
		V1       : out STD_LOGIC;
		V2       : out STD_LOGIC;
		V4       : out STD_LOGIC;
		V8       : out STD_LOGIC;
		V16      : out STD_LOGIC;
		V32      : out STD_LOGIC;
		V64      : out STD_LOGIC;
		V128     : out STD_LOGIC;
		V256     : out STD_LOGIC;
		V256n    : out STD_LOGIC;
		VRESET   : out STD_LOGIC;
		VRESETn  : out STD_LOGIC);
end component;

component SyncSumming is
port( HSYNC    : in  STD_LOGIC;
		VSYNCn   : in  STD_LOGIC;
		CSYNC    : out STD_LOGIC);
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

	-- Generate CLOCK_7 from CLOCK_14
	computer_clock: ComputerClock
		port map(
			CLOCK_14 => CLOCK_14,
			CLOCK_7  => CLOCK_7
		);

	-- Generate horizontal sync signals
	horizontal_sync: HorizontalSync
		port map(
			CLOCK_7  => CLOCK_7,
			HSYNC    => HSYNC,
			HSYNCn   => HSYNCn,
			H1       => H1,
			H2       => H2,
			H4       => H4,
			H8       => H8,
			H16      => H16,
			H32      => H32,
			H64      => H64,
			H64n     => H64n,
			H128     => H128,
			H256     => H256,
			H256n    => H256n,
			HRESET   => HRESET,
			HRESETn  => HRESETn,
			HBLANK   => HBLANK,
			HBLANKn  => HBLANKn
		);

	-- Generate vertical sync signals
	vertical_sync: VerticalSync
		port map(
			HRESET   => HRESET,
			VSYNC    => VSYNC,
			VSYNCn   => VSYNCn,
			V1       => V1,
			V2       => V2,
			V4       => V4,
			V8       => V8,
			V16      => V16,
			V32      => V32,
			V64      => V64,
			V128     => V128,
			V256     => V256,
			V256n    => V256n,
			VRESET   => VRESET,
			VRESETn  => VRESETn
		);

	-- Combine horizontal and vertical sync into composite sync
	sync_summing: SyncSumming
		port map(
			HSYNC    => HSYNC,
			VSYNCn   => VSYNCn,
			CSYNC    => CSync_out
		);

	-- DEBUG
   LED0 <= not PushBtn;
   LED1 <= PushBtn;
   LED2 <= '1';
	
end Behavioral;
