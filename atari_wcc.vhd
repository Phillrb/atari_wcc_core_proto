-- Atari WCC (Goal IV) top-level - TM-035
-- Display stack: clock, sync, playfield, ball, players.
-- Quartus-compatible synthesizable version.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity atari_wcc is
    Generic (
        SOLID_DEF_PLAY_GAP : natural := 85;
        CHECKS_DEF_PLAY_GAP : natural := 83;
        INPUT_STABLE_CLOCKS : positive := 35714;
        GAME_CLOCKS : positive := 857142840; -- 120 s at 7.142857 MHz
        SERVE_DELAY_CLOCKS : positive := 21428571 -- 3 s; also catch timeout
    );
	Port (
        -- Board adapter supplies ramp thresholds, not raw ADC codes.
        SolidFwdPosition_I : in STD_LOGIC_VECTOR(9 downto 0) := "0001100100";
        SolidDefPosition_I : in STD_LOGIC_VECTOR(9 downto 0) := "0000000000";
        StripedFwdPosition_I : in STD_LOGIC_VECTOR(9 downto 0) := "0001100100";
        StripedDefPosition_I : in STD_LOGIC_VECTOR(9 downto 0) := "0000000000";
        Coin1_I : in STD_LOGIC := '1'; -- normally open to GND
        Start1_I : in STD_LOGIC := '1';
        GameSelect_I : in STD_LOGIC := '1'; -- active low: 1 player; high: 2 players
		KickChecks_I : in STD_LOGIC := '1';
		KickSolids_I : in STD_LOGIC := '1';
        ATTRACT_DBG : out STD_LOGIC;
        CREDIT_DBG : out STD_LOGIC;
        START_DBG : out STD_LOGIC;
        SERVE_DBG : out STD_LOGIC;
		CLOCK_14    : in  STD_LOGIC; -- Board PLL clock (14.285714 MHz); nominal schematic clock 14.318180 MHz
		HSYNC       : out STD_LOGIC;
		VSYNC       : out STD_LOGIC;
		CSYNC       : out STD_LOGIC;
		VIDEO       : out STD_LOGIC;
		CLOCK_7_DBG : out STD_LOGIC;
		HBLANK_DBG  : out STD_LOGIC;
		PushBtn     : in  STD_LOGIC;
		LED0        : out STD_LOGIC;
		Clock_out   : out STD_LOGIC;
		SOUND_OUT   : out STD_LOGIC
	);
end atari_wcc;

architecture Behavioral of atari_wcc is

-- Internal signals
signal selected_one_player_i, one_player_i : STD_LOGIC;
signal clk7            : STD_LOGIC;
signal hsync_i        : STD_LOGIC;
signal hsyncn_i       : STD_LOGIC;
signal vsync_i        : STD_LOGIC;
signal vsyncn_i       : STD_LOGIC;
signal hreset_i       : STD_LOGIC;
signal hresetn_i      : STD_LOGIC;
signal vresetn_i      : STD_LOGIC;
signal hblank_i       : STD_LOGIC;
signal hblankn_i      : STD_LOGIC;
signal h1_i, h1n_i, h2_i, h4_i, h8_i, h16_i, h32_i, h64_i, h64n_i, h128_i, h256_i, h256n_i : STD_LOGIC;
signal v1_i, v2_i, v4_i, v8_i, v16_i, v32_i, v64_i, v64n_i, v128_i, v128n_i, v256_i, v256n_i : STD_LOGIC;

-- Playfield and ball signals
signal playfield_n    : STD_LOGIC;
signal henab_i        : STD_LOGIC;
signal venab_i        : STD_LOGIC;
signal video_playfield : STD_LOGIC;
signal video_paddles  : STD_LOGIC;
signal ramp_value_i   : STD_LOGIC_VECTOR(9 downto 0);
signal team_i         : STD_LOGIC;
signal q_i, qn_i      : STD_LOGIC;
signal player_windown_i : STD_LOGIC;
signal defensemen_n_i : STD_LOGIC;
signal symbol_i       : STD_LOGIC;
signal paddles_i      : STD_LOGIC;
signal hit_i          : STD_LOGIC;
signal hit_raw_i, h_bounce_raw_i, v_bounce_raw_i, bounce_n_raw_i, miss_raw_i : STD_LOGIC;
signal clk7_n_sample, collision_clk : STD_LOGIC;
signal collision_d, collision_q : STD_LOGIC_VECTOR(7 downto 0);
signal pp2_next, pp3_next, pp4_next : STD_LOGIC;
signal atrcn_i, atrc_i : STD_LOGIC; -- ATRCn HIGH in play, ATRC HIGH in attract
signal coin_pressed, start_pressed, credit_i, coin_accepted_i, credit_expired_i, latch_presetn_i : STD_LOGIC;
signal solid_kick_pressed, check_kick_pressed : STD_LOGIC;
signal solid_fwd_e2, solid_fwd_b2, solid_fwd_c2, solid_fwd_d2 : STD_LOGIC;
signal solid_def_e1, solid_def_b1, solid_def_c1, solid_def_d1 : STD_LOGIC;
signal striped_fwd_e3, striped_fwd_b3, striped_fwd_c3, striped_fwd_d3 : STD_LOGIC;
signal striped_def_e4, striped_def_b4, striped_def_c4, striped_def_d4 : STD_LOGIC;
signal goalie_i : STD_LOGIC;
signal serve_i, serve_n_i : STD_LOGIC;


signal vreset_i         : STD_LOGIC;
signal blip_i           : STD_LOGIC;
signal stop_i           : STD_LOGIC;
signal stopn_i          : STD_LOGIC;
signal catch_trigger_i  : STD_LOGIC;
signal catch_clrn_i     : STD_LOGIC;
signal horiz_dir_qn_i   : STD_LOGIC;
signal a_plus_b_n_i     : STD_LOGIC;    -- (A+B)n from playfield: L/R wall position
signal c_plus_d_n_i     : STD_LOGIC;    -- (C+D)n from playfield: T/B wall position
signal windows_i        : STD_LOGIC;    -- Goal window signal from WindowMissBounce
signal v_bounce_i       : STD_LOGIC;
signal h_bounce_i       : STD_LOGIC;
signal bounce_n_i       : STD_LOGIC;
signal miss_i           : STD_LOGIC;
signal hspeed_i         : STD_LOGIC_VECTOR(3 downto 0);
signal slow_i           : STD_LOGIC;
signal pp2_i, pp3_i, pp4_i : STD_LOGIC;
signal vspeed_i         : STD_LOGIC_VECTOR(3 downto 0);
signal hitn_i           : STD_LOGIC;
signal ball_i           : STD_LOGIC;
signal ball_n_i         : STD_LOGIC;
signal hit_tone_i       : STD_LOGIC;
signal time_line_n_i    : STD_LOGIC;
signal end_of_game_i    : STD_LOGIC;
signal video_timeline   : STD_LOGIC;
signal score_i          : STD_LOGIC;
signal start_i          : STD_LOGIC;    -- score counter reset (active high)
signal start_n_i        : STD_LOGIC;    -- inverted START (active low)
signal hole_i           : STD_LOGIC;

signal sound_goal_i, sound_goaln_i, score_sound_n_i : STD_LOGIC;
signal miss_armed       : STD_LOGIC := '1';
signal miss_prev        : STD_LOGIC := '0';
signal miss_one_shot    : STD_LOGIC := '0';

begin

-- Clock divider: 14.318 MHz -> 7.159 MHz
U_CLOCK: entity work.ComputerClock
	port map(
		CLOCK_14 => CLOCK_14,
		CLOCK_7  => clk7
	);

-- Horizontal sync and counters
U_HSYNC: entity work.HorizontalSync
	port map(
		CLOCK_7 => clk7,
		HSYNC   => hsync_i,
		HSYNCn  => hsyncn_i,
		H1      => h1_i,
		H2      => h2_i,
		H4      => h4_i,
		H8      => h8_i,
		H16     => h16_i,
		H32     => h32_i,
		H64     => h64_i,
		H64n    => h64n_i,
		H128    => h128_i,
		H256    => h256_i,
		H256n   => h256n_i,
		HBLANK  => hblank_i,
		HBLANKn => hblankn_i,
		HRESET  => hreset_i,
		HRESETn => hresetn_i
	);

-- Vertical sync and counters
U_VSYNC: entity work.VerticalSync
	port map(
		HRESET => hreset_i,
		VSYNC  => vsync_i,
		VSYNCn => vsyncn_i,
		V1     => v1_i,
		V2     => v2_i,
		V4     => v4_i,
		V8     => v8_i,
		V16    => v16_i,
		V32    => v32_i,
		V64    => v64_i,
		V64n   => v64n_i,
		V128   => v128_i,
		V128n  => v128n_i,
		V256   => v256_i,
		V256n  => v256n_i,
		VRESET  => vreset_i,
		VRESETn => vresetn_i
	);

-- Sync summing: CSYNC = HSYNC XOR VSYNCn
U_SYNCSUM: entity work.SyncSumming
	port map(
		HSYNC  => hsync_i,
		VSYNCn => vsyncn_i,
		CSYNC  => CSYNC
	);

-- Playfield circuit: generates field boundaries and center line
U_PLAYFIELD: entity work.PlayfieldCircuit
	port map(
		H1       => h1_i,
		H2       => h2_i,
		H4       => h4_i,
		H8       => h8_i,
		H16      => h16_i,
		H32      => h32_i,
		H64      => h64_i,
		H128     => h128_i,
		H256     => h256_i,
		H256n    => h256n_i,
		HRESETn  => hresetn_i,
		V1       => v1_i,
		V2       => v2_i,
		V4       => v4_i,
		V8       => v8_i,
		V16      => v16_i,
		V32      => v32_i,
		V64      => v64_i,
		V128     => v128_i,
		V128n    => v128n_i,
		V256     => v256_i,
		VRESETn  => vresetn_i,
		WINDOWS  => windows_i,
		CLOCK_7  => clk7,
		PLAYFIELDn => playfield_n,
		H_ENABLE => henab_i,
		V_ENABLE => venab_i,
		A_PLUS_Bn => a_plus_b_n_i,
		C_PLUS_Dn => c_plus_d_n_i,
		H1n		  => h1n_i
	);

-- Players circuit: vertical window generator
U_PLAYERS_VW: entity work.PlayersVerticalWindow
	port map(
		H4             => h4_i,
		H8             => h8_i,
		HRESET         => hreset_i,
		HRESETn        => hresetn_i,
		H_ENABLE       => henab_i,
		V_ENABLE       => venab_i,
		PLAYER         => one_player_i, -- Figure 11 checked-team suppression
		TEAM           => team_i,
		GOALIE         => goalie_i,
		DEFENSEMENn    => defensemen_n_i,
		Q              => q_i,
		Qn             => qn_i,
		BLIP           => blip_i,
		PLAYER_WINDOWn => player_windown_i
	);

-- Players multiplexer
U_PLAYERS_MUX: entity work.PlayersMultiplexer
	port map(
		TEAM            => team_i,
		Qn              => qn_i,
		PLAYER_WINDOWn  => player_windown_i,
		B1 => solid_def_b1, B2 => solid_fwd_b2, B3 => striped_fwd_b3, B4 => striped_def_b4,
		C1 => solid_def_c1, C2 => solid_fwd_c2, C3 => striped_fwd_c3, C4 => striped_def_c4,
		D1 => solid_def_d1, D2 => solid_fwd_d2, D3 => striped_fwd_d3, D4 => striped_def_d4,
		E1 => solid_def_e1, E2 => solid_fwd_e2, E3 => striped_fwd_e3, E4 => striped_def_e4,
		PP2    => pp2_i,
		PP3    => pp3_i,
		PP4    => pp4_i,
		SYMBOL => symbol_i
	);

-- Players summing
U_PLAYERS_SUM: entity work.PlayersSumming
	port map(
		H1          => h1_i,
		V1          => v1_i,
		TEAM        => team_i,
		DEFENSEMENn => defensemen_n_i,
		ONE_PLAYER  => one_player_i,
		SYMBOL      => symbol_i,
		BALL        => ball_i,
		PADDLES     => paddles_i,
		HIT         => hit_raw_i
	);

-- Players ramp generator
U_RAMP: entity work.PlayersRampGenerator
	port map(
		HSYNC      => hsync_i,
		V256       => v256_i,
		V_ENABLE   => venab_i,
		V128n      => v128n_i,
		RAMP_VALUE => ramp_value_i
	);

-- Solid Forwards
U_SOLID_FWD: entity work.PlayersSolidForwards
	port map(
		HSYNC      => hsync_i,
		RAMP_VALUE => ramp_value_i,
		POSITION   => SolidFwdPosition_I,
		ATRCn      => atrcn_i,
		E2         => solid_fwd_e2,
		B2         => solid_fwd_b2,
		C2         => solid_fwd_c2,
		D2         => solid_fwd_d2
	);

-- Solid Defense/Goalie
U_SOLID_DEF: entity work.PlayersSolidDefenseGoalie
    generic map(PLAY_INITIAL_GAP=>SOLID_DEF_PLAY_GAP)
	port map(
		HSYNC      => hsync_i,
		VSYNCn     => vsyncn_i,
		RAMP_VALUE => ramp_value_i,
		POSITION   => SolidDefPosition_I,
		ATRCn      => atrcn_i,
		GOALIE     => goalie_i,
		E1         => solid_def_e1,
		B1         => solid_def_b1,
		C1         => solid_def_c1,
		D1         => solid_def_d1
	);

-- Striped Forwards
U_STRIPED_FWD: entity work.PlayersStripedForwards
	port map(
		HSYNC      => hsync_i,
		RAMP_VALUE => ramp_value_i,
		POSITION   => StripedFwdPosition_I,
		ATRCn      => atrcn_i,
		E3         => striped_fwd_e3,
		B3         => striped_fwd_b3,
		C3         => striped_fwd_c3,
		D3         => striped_fwd_d3
	);

-- Striped Defense
U_STRIPED_DEF: entity work.PlayersStripedDefenseGoalie
    generic map(PLAY_INITIAL_GAP=>CHECKS_DEF_PLAY_GAP)
	port map(
		HSYNC      => hsync_i,
		VSYNCn     => vsyncn_i,
		RAMP_VALUE => ramp_value_i,
		POSITION   => StripedDefPosition_I,
		ATRCn      => atrcn_i,
		GOALIE     => goalie_i,
		J9_P12     => '0',
		E4         => striped_def_e4,
		B4         => striped_def_b4,
		C4         => striped_def_c4,
		D4         => striped_def_d4
	);

-- Serve Timing Circuit
U_SERVE: entity work.ServeTimingCircuit
	generic map(
		SERVE_DELAY_CLKS => SERVE_DELAY_CLOCKS,
		STOP_DELAY_CLKS  => SERVE_DELAY_CLOCKS
	)
	port map(
		CLOCK_7       => clk7,
		GOALn         => sound_goaln_i,
		START         => start_i,
		V128n         => v128n_i,
		H_ENABLE      => henab_i,
		H256n         => h256n_i,
		SERVE         => serve_i,
		SERVEn        => serve_n_i,
		CATCH_TRIGGER => catch_trigger_i,
		CATCH_CLRn    => catch_clrn_i,
		STOP          => stop_i,
		STOPn         => stopn_i
	);

-- Figure 10: single-contact JAMMA selector replaces SPDT/D9 contact latch.
U_MODE_INPUT: entity work.JammaSwitchAdapter
    generic map(STABLE_CLOCKS=>INPUT_STABLE_CLOCKS)
    port map(clk7, GameSelect_I, selected_one_player_i);
U_GAME_SELECT: entity work.GameSelectCircuit
    port map(GAME_SELECT_1=>selected_one_player_i, ATRCn=>atrcn_i,
             ONE_PLAYER=>one_player_i);

-- Figure 8 plus the explicit JAMMA/contact-latch adaptation boundary.
U_COIN_INPUT: entity work.JammaSwitchAdapter
    generic map(STABLE_CLOCKS=>INPUT_STABLE_CLOCKS)
    port map(clk7, Coin1_I, coin_pressed);
U_START_INPUT: entity work.JammaSwitchAdapter
    generic map(STABLE_CLOCKS=>INPUT_STABLE_CLOCKS)
    port map(clk7, Start1_I, start_pressed);
U_CREDIT: entity work.CreditCircuit
    port map(CLOCK_7=>clk7, COIN_SWITCH=>coin_pressed, ONE_PLAYER=>'1',
        V32=>v32_i, V256=>v256_i, ATRC=>atrc_i, LATCH_PRESETn=>latch_presetn_i,
        CREDIT=>credit_i, COIN_ACCEPTED_PULSE=>coin_accepted_i, CREDIT_EXPIRED=>credit_expired_i);
U_LATCH: entity work.ElectronicLatchCircuit
    port map(CLOCK_7=>clk7, COIN_ACCEPTED_PULSE=>coin_accepted_i,
        STATIC=>'0', CREDIT_EXPIRED=>credit_expired_i, LATCH_PRESETn=>latch_presetn_i);
U_START: entity work.StartCircuit
    port map(CLOCK_7=>clk7, V256=>v256_i, CREDIT=>credit_i,
        START_BUTTON=>start_pressed, END_OF_GAME=>end_of_game_i,
        LATCH_PRESETn=>latch_presetn_i, START=>start_i, STARTn=>start_n_i,
        ATRC=>atrc_i, ATRCn=>atrcn_i);
ATTRACT_DBG <= atrc_i;
CREDIT_DBG <= credit_i;
START_DBG <= start_i;
SERVE_DBG <= serve_i;

-- MISS one-shot per frame
miss_one_shot_proc: process(clk7)
begin
	if rising_edge(clk7) then
		miss_prev <= miss_i;
		if vsync_i = '1' then
			miss_armed    <= '1';
			miss_one_shot <= '0';
		elsif miss_i = '1' and miss_prev = '0' and miss_armed = '1' then
			miss_one_shot <= '1';
			miss_armed    <= '0';
		else
			miss_one_shot <= '0';
		end if;
	end if;
end process;

-- Moving Hole circuit
U_MOVING_HOLE: entity work.MovingHoleCircuit
    port map (
        C_PLUS_Dn => c_plus_d_n_i,
        HSYNCn    => hsyncn_i,
        STARTn    => start_n_i,
        V128      => v128_i,
        HOLE      => hole_i
    );

-- Window/Miss/Bounce circuit
U_WINDOW_MISS_BOUNCE: entity work.WindowMissBounce
	port map(
		V64        => v64_i,
		H256n      => h256n_i,
		ONE_PLAYER => one_player_i,
		ATRC       => atrc_i,
		HOLE       => hole_i,
		BALLn      => ball_n_i,
		A_PLUS_Bn  => a_plus_b_n_i,
		C_PLUS_Dn  => c_plus_d_n_i,
		WINDOWS    => windows_i,
		WINDOWSn   => open,
		V_BOUNCE   => v_bounce_raw_i,
		H_BOUNCE   => h_bounce_raw_i,
		BOUNCEn    => bounce_n_raw_i,
		MISS       => miss_raw_i
	);

-- Approved FPGA collision boundary: CLOCK_7 changes at CLOCK_14 falling
-- edges. Sample halfway through its low phase, after the raster ripple settles.
U_COLLISION_INVERT: entity work.LS04
    port map(P1_A1=>clk7, P2_Y1=>clk7_n_sample,
        P3_A2=>'0', P4_Y2=>open, P5_A3=>'0', P6_Y3=>open,
        P9_A4=>'0', P8_Y4=>open, P11_A5=>'0', P10_Y5=>open,
        P13_A6=>'0', P12_Y6=>open);
U_COLLISION_CLOCK: entity work.LS08
    port map(P1_A1=>CLOCK_14, P2_B1=>clk7_n_sample, P3_Y1=>collision_clk,
        P4_A2=>'0', P5_B2=>'0', P6_Y2=>open,
        P9_A3=>'0', P10_B3=>'0', P8_Y3=>open,
        P12_A4=>'0', P13_B4=>'0', P11_Y4=>open);
-- Hold player segment data when there is no hit. D7's transparent latch then
-- closes on HIT without its data changing to the next raster/player segment.
U_COLLISION_PP23: entity work.LS153
    port map(P1_Ea=>'0', P2_S1=>'0', P14_S0=>hit_raw_i,
        P6_1I0=>collision_q(5), P5_1I1=>pp2_i, P4_1I2=>'0', P3_1I3=>'0', P7_1Y=>pp2_next,
        P10_2I0=>collision_q(6), P11_2I1=>pp3_i, P12_2I2=>'0', P13_2I3=>'0', P9_2Y=>pp3_next, P15_Eb=>'0');
U_COLLISION_PP4: entity work.LS153
    port map(P1_Ea=>'0', P2_S1=>'0', P14_S0=>hit_raw_i,
        P6_1I0=>collision_q(7), P5_1I1=>pp4_i, P4_1I2=>'0', P3_1I3=>'0', P7_1Y=>pp4_next,
        P10_2I0=>'0', P11_2I1=>'0', P12_2I2=>'0', P13_2I3=>'0', P9_2Y=>open, P15_Eb=>'1');
collision_d <= pp4_next & pp3_next & pp2_next & miss_raw_i & bounce_n_raw_i & v_bounce_raw_i & h_bounce_raw_i & hit_raw_i;
U_COLLISION_EVENTS: entity work.CollisionSampleBank
    port map(SAMPLE_CLK=>collision_clk, D=>collision_d, Q=>collision_q);
hit_i <= collision_q(0);
h_bounce_i <= collision_q(1);
v_bounce_i <= collision_q(2);
bounce_n_i <= collision_q(3);
miss_i <= collision_q(4);

-- Figure 13 plus the explicit JAMMA/contact-latch adaptation boundary.
U_SOLID_KICK_INPUT: entity work.JammaSwitchAdapter
    generic map(STABLE_CLOCKS=>INPUT_STABLE_CLOCKS)
    port map(clk7, KickSolids_I, solid_kick_pressed);

U_CHECKS_KICK_INPUT: entity work.JammaSwitchAdapter
    generic map(STABLE_CLOCKS=>INPUT_STABLE_CLOCKS)
    port map(clk7, KickChecks_I, check_kick_pressed);

-- Catch/Kick/Horizontal Direction
U_CATCH_KICK: entity work.CatchKickHorizontalDirection
    generic map(SAMPLE_COLLISIONS=>true)
	port map(
        SAMPLE_CLK=>collision_clk, HIT_SAMPLED=>hit_i,
		BALL          => ball_i,
		BLIP          => blip_i,
		HIT           => hit_raw_i,
		DEFENSEMENn   => defensemen_n_i,
		TEAM          => team_i,
		ONE_PLAYER    => one_player_i,
		WINDOWS       => windows_i,
		H256n         => h256n_i,
		H_BOUNCE      => h_bounce_i,
		VSYNCn        => vsyncn_i,
		VRESET        => vreset_i,
		STOP          => stop_i,
		SOLID_KICK    => solid_kick_pressed,
		CHECKED_KICK  => check_kick_pressed,
		CATCH_TRIGGER => catch_trigger_i,
		CATCH_CLRn    => catch_clrn_i,
		HORIZ_DIR_Qn  => horiz_dir_qn_i
	);

-- Figure 20: real ATRCn mutes sound during attract.
U_SOUND: entity work.SoundCircuit
 generic map(CLOCK_HZ => 7142857) -- actual board PLL / 2 and testbench clock
 port map(CLOCK_7=>clk7, MISS=>miss_i, HIT=>hit_i, STOPn=>stopn_i,
 SLOW=>slow_i, HIT_TONE=>hit_tone_i, V32=>v32_i, BOUNCEn=>bounce_n_i,
 ATRCn=>atrcn_i, GOAL=>sound_goal_i, GOALn=>sound_goaln_i,
 SCORE_SOUNDn=>score_sound_n_i, SOUND_OUT=>SOUND_OUT);

-- Horizontal Direction and Speed
U_HORIZ_SPEED: entity work.HorizontalDirectionAndSpeed
	port map(
		VRESET         => vreset_i,
		STOPn          => stopn_i,
		HORIZ_DIR      => horiz_dir_qn_i,
		GOAL           => sound_goal_i,
		SCORE_SOUNDn   => score_sound_n_i,
		ONE_PLAYER     => one_player_i,
		ATRC           => atrc_i,
		GOALIE_FWD_HIT => '1',
		HSPEED         => hspeed_i,
		SLOW           => slow_i
	);

-- Vertical Direction and Speed
U_VERT_SPEED: entity work.VerticalDirectionAndSpeed
	port map(
		V128n   => v128n_i,
		VBOUNCE => v_bounce_i,
		HIT     => hit_i,
		PP2     => collision_q(5),
		PP3     => collision_q(6),
		PP4     => collision_q(7),
		SERVEn  => serve_i,
		STOPP   => stop_i,
		STOPn   => stopn_i,
		VSPEED  => vspeed_i,
		HITn    => hitn_i
	);

-- Convert active-low playfield to active-high video signal and apply blanking
video_playfield <= (not playfield_n) and hblankn_i;

-- Ball motion circuit
U_BALL_MOTION: entity work.BallMotionCircuit
	port map(
		CLOCK_7  => clk7,
		HSYNCn   => hsyncn_i,
		HBLANKn  => hblankn_i,
		SERVE    => serve_i,
		HSPEED   => hspeed_i,
		VSPEED   => vspeed_i,
		BALL     => ball_i,
		BALLn    => ball_n_i,
		HIT_TONE => hit_tone_i
	);

-- Time Line Circuit
U_TIMELINE: entity work.TimeLineCircuit
    generic map(GAME_CLOCKS=>GAME_CLOCKS)
	port map(
		CLOCK_7   => clk7,
		VRESETn   => vresetn_i,
		H1n		  => h1n_i,
		H4        => h4_i,
		H128      => h128_i,
		V1        => v1_i,
		V2        => v2_i,
		V4        => v4_i,
		V8        => v8_i,
		V16       => v16_i,
		V32       => v32_i,
		V64       => v64_i,
		V128      => v128_i,
		V128n     => v128n_i,
		V256      => v256_i,
		C_PLUS_Dn => c_plus_d_n_i,
		ATRC      => atrc_i,
		TIME_LINEn  => time_line_n_i,
		END_OF_GAME => end_of_game_i
	);

-- Score Circuit
U_SCORE: entity work.ScoreCircuit
	port map(
		H2         => h2_i,
		H4         => h4_i,
		H8         => h8_i,
		H16        => h16_i,
		H32        => h32_i,
		H64        => h64_i,
		H128       => h128_i,
		H256       => h256_i,
		H256n      => h256n_i,
		V2         => v2_i,
		V4         => v4_i,
		V8         => v8_i,
		V16        => v16_i,
		V32        => v32_i,
		V64        => v64_i,
		V128       => v128_i,
		MISS       => miss_one_shot,
		START      => start_i,
		STARTn     => start_n_i,
		SERVE      => serve_i,
		ATRCn      => atrcn_i,
		TIME_LINEn => time_line_n_i,
		PLAYFIELDn => playfield_n,
		SCORE      => score_i
	);

-- Convert PADDLES to video
video_paddles <= paddles_i and hblankn_i;
video_timeline <= (not time_line_n_i) and hblankn_i;

-- Output video
VIDEO <= score_i or video_paddles or (ball_i and hblankn_i);

-- Output assignments
HSYNC       <= hsync_i;
VSYNC       <= vsync_i;
CLOCK_7_DBG <= clk7;
HBLANK_DBG  <= hblank_i;

-- Board / debug
LED0      <= not PushBtn;
Clock_out <= clk7;

end Behavioral;
