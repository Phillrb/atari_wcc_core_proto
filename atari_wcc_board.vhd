-- Board top-level for atari_wcc: 50 MHz -> PLL -> 14.285714 MHz, MaSTer-style video output.
-- Use this as Quartus top when targeting the EP2C5 board; same pinout as MaSTer games.
-- Simulation continues to use atari_wcc directly with testbench-driven CLOCK_14.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity atari_wcc_board is
	Port (
		Clk_50_I   : in  STD_LOGIC;
        Coin1_I : in STD_LOGIC; -- NO switch to GND, pull-up on pin 120
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
begin
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
            Coin1_I=>Coin1_I, Start1_I=>Start1_I,
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
