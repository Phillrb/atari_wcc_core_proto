-- Board top-level for atari_wcc: 50 MHz -> PLL -> 14.285714 MHz, MaSTer-style video output.
-- Use this as Quartus top when targeting the EP2C5 board; same pinout as MaSTer games.
-- Simulation continues to use atari_wcc directly with testbench-driven CLOCK_14.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity atari_wcc_board is
	Generic (
        SPINNER_POSITION_MIN : natural := 82;
        SPINNER_POSITION_MAX : natural := 154;
        SPINNER_STEP_SIZE : positive := 8;
        SPINNER_REVERSE : boolean := false
    );
	Port (
		SpinnerA_I, SpinnerB_I : in STD_LOGIC := '0';
		Clk_50_I   : in  STD_LOGIC;
        Coin1_I : in STD_LOGIC; -- NO switch to GND, pull-up on pin 120
        GameSelect_I : in STD_LOGIC := '1'; -- low=1P, high=2P; connect JAMMA TEST
        Start1_I : in STD_LOGIC; -- NO switch to GND, pull-up on pin 112
		Reset_I    : in  STD_LOGIC;
		Sync_O     : out STD_LOGIC;
		VideoW_O   : out STD_LOGIC;
		VideoB_O   : out STD_LOGIC;
		LED0       : out STD_LOGIC;
		Audio1_O   : out STD_LOGIC; -- Sprint2 audio connector, FPGA pin 71
		Clock_out  : out STD_LOGIC
	);
end atari_wcc_board;

architecture rtl of atari_wcc_board is
	signal clock_14 : STD_LOGIC;
	signal pushbtn_i : STD_LOGIC;
	signal hsync    : STD_LOGIC;
	signal vsync    : STD_LOGIC;
	signal csync    : STD_LOGIC;
	signal video    : STD_LOGIC;
	signal clk7_dbg : STD_LOGIC;
	signal hblank   : STD_LOGIC;
    signal solid_fwd_position : STD_LOGIC_VECTOR(9 downto 0);
begin
    -- Use CLOCK_7 throughout: no asynchronous multi-bit position crossing.
    U_SPINNER: entity work.SpinnerAdapter
        generic map(POSITION_MIN=>SPINNER_POSITION_MIN,
                    POSITION_MAX=>SPINNER_POSITION_MAX,
                    STEP_SIZE=>SPINNER_STEP_SIZE,
                    REVERSE_DIRECTION=>SPINNER_REVERSE)
        port map(CLK=>clk7_dbg, RESETn=>Reset_I,
                 QUAD_A=>SpinnerA_I, QUAD_B=>SpinnerB_I,
                 FRAME_SYNC=>vsync, COUNT_OUT=>open,
                 POSITION_OUT=>solid_fwd_position);
	-- Board button is active low; preserve the core's active-high button interface.
	pushbtn_i <= not Reset_I;
	-- PLL: 50 MHz -> 14.285714 MHz (same stack as MaSTer)
	PLL: entity work.clk_pll
		port map(
			inclk0 => Clk_50_I,
			c0     => clock_14
		);

	-- Core design (expects CLOCK_14)
	U_CORE: entity work.atari_wcc
		port map(
            SolidFwdPosition_I=>solid_fwd_position,
            Coin1_I=>Coin1_I, Start1_I=>Start1_I, GameSelect_I=>GameSelect_I,
            ATTRACT_DBG=>open, CREDIT_DBG=>open, START_DBG=>open, SERVE_DBG=>open,
			CLOCK_14   => clock_14,
			HSYNC      => hsync,
			VSYNC      => vsync,
			CSYNC      => csync,
			VIDEO      => video,
			CLOCK_7_DBG => clk7_dbg,
			HBLANK_DBG  => hblank,
			PushBtn    => pushbtn_i,
			LED0       => LED0,
			SOUND_OUT  => Audio1_O,
			Clock_out  => Clock_out
		);

	-- MaSTer-compatible video outputs (same resistor ladder as other MaSTer games)
	Sync_O   <= csync;
	VideoW_O <= video;
	VideoB_O <= '0';
end rtl;
