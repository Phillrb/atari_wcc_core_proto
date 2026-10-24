-- Board top-level for atari_wcc: 50 MHz -> PLL -> 14.285714 MHz, MaSTer-style video output.
-- Use this as Quartus top when targeting the EP2C5 board; same pinout as MaSTer games.
-- Simulation continues to use atari_wcc directly with testbench-driven CLOCK_14.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity atari_wcc_board is
    Generic (
        CONTROL_ADC_MIN : natural := 700;
        CONTROL_ADC_MAX : natural := 1023;
        CONTROL_DEF_TOP : natural := 10;
        CONTROL_DEF_BOTTOM : natural := 82;
        CONTROL_FWD_TOP : natural := 82;
        CONTROL_FWD_BOTTOM : natural := 154;
        SOLID_DEF_REVERSE : boolean := false;
        SOLID_FWD_REVERSE : boolean := false;
        CHECKS_DEF_REVERSE : boolean := false;
        CHECKS_FWD_REVERSE : boolean := false
    );
    Port (
        ControlsSCLK_O, ControlsCSn_O, ControlsMOSI_O : out STD_LOGIC;
        ControlsMISO_I : in STD_LOGIC := '1';
		Clk_50_I     : in STD_LOGIC;
      Coin1_I      : in STD_LOGIC; -- NO switch to GND, pull-up on pin 120
      GameSelect_I : in STD_LOGIC; -- NO switch to GND, pull-up on pin 41
      Start1_I     : in STD_LOGIC; -- NO switch to GND, pull-up on pin 112
		KickChecks_I : in STD_LOGIC; -- NO switch to GND, pull-up on pin 58
		KickSolids_I : in STD_LOGIC; -- NO switch to GND, pull-up on pin 57
		Reset_I      : in  STD_LOGIC;
		Sync_O     : out STD_LOGIC;
		VideoW_O   : out STD_LOGIC;
		VideoB_O   : out STD_LOGIC;
		LED0       : out STD_LOGIC;
        CreditLEDn : out STD_LOGIC := '1'; -- active-low credit lamp, FPGA pin 7
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
    signal solid_fwd_position, solid_def_position, checks_fwd_position, checks_def_position : STD_LOGIC_VECTOR(9 downto 0);
begin
    -- SPI transport and game use CLOCK_7; publish all four positions at VSYNC.
    U_CONTROLS: entity work.SPIAdapter
        generic map(
            SD_ADC_MIN=>CONTROL_ADC_MIN, SD_ADC_MAX=>CONTROL_ADC_MAX,
            SF_ADC_MIN=>CONTROL_ADC_MIN, SF_ADC_MAX=>CONTROL_ADC_MAX,
            CD_ADC_MIN=>CONTROL_ADC_MIN, CD_ADC_MAX=>CONTROL_ADC_MAX,
            CF_ADC_MIN=>CONTROL_ADC_MIN, CF_ADC_MAX=>CONTROL_ADC_MAX,
            DEF_TOP=>CONTROL_DEF_TOP, DEF_BOTTOM=>CONTROL_DEF_BOTTOM,
            FWD_TOP=>CONTROL_FWD_TOP, FWD_BOTTOM=>CONTROL_FWD_BOTTOM,
            SD_REVERSE=>SOLID_DEF_REVERSE, SF_REVERSE=>SOLID_FWD_REVERSE,
            CD_REVERSE=>CHECKS_DEF_REVERSE, CF_REVERSE=>CHECKS_FWD_REVERSE)
        port map(CLK=>clk7_dbg, RESETn=>Reset_I, FRAME_SYNC=>vsync,
            SPI_MISO=>ControlsMISO_I, SPI_SCLK=>ControlsSCLK_O,
            SPI_CSn=>ControlsCSn_O, SPI_MOSI=>ControlsMOSI_O,
            SOLID_DEF=>solid_def_position, SOLID_FWD=>solid_fwd_position,
            CHECKS_DEF=>checks_def_position, CHECKS_FWD=>checks_fwd_position,
            RAW_SD=>open, RAW_SF=>open, RAW_CD=>open, RAW_CF=>open,
            PACKET_VALID=>open, PACKET_ERROR=>open);
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
        generic map(SOLID_DEF_PLAY_GAP=>57, CHECKS_DEF_PLAY_GAP=>55)
		port map(
            SolidFwdPosition_I=>solid_fwd_position,
            SolidDefPosition_I=>solid_def_position,
            StripedFwdPosition_I=>checks_fwd_position,
            StripedDefPosition_I=>checks_def_position,
            Coin1_I=>Coin1_I,
				Start1_I=>Start1_I,
				GameSelect_I=>GameSelect_I,
				KickChecks_I=>KickChecks_I,
				KickSolids_I=>KickSolids_I,
            ATTRACT_DBG=>open,
				CREDIT_DBG=>open,
                CREDIT_LEDn=>CreditLEDn,
				START_DBG=>open,
				SERVE_DBG=>open,
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
