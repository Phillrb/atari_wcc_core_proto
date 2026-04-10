-- Atari WCC (Goal IV) top-level - TM-035
-- Display stack: clock, sync, playfield, ball, players.
-- Use as simulation and Quartus top.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity atari_wcc is
	Port (
		CLOCK_14   : in  STD_LOGIC;
		HSYNC      : out STD_LOGIC;
		VSYNC      : out STD_LOGIC;
		CSYNC      : out STD_LOGIC;
		VIDEO      : out STD_LOGIC;
		CLOCK_7_DBG : out STD_LOGIC;
		HBLANK_DBG : out STD_LOGIC;
		PushBtn    : in  STD_LOGIC;
		LED0       : out STD_LOGIC;
		Clock_out  : out STD_LOGIC
	);
end atari_wcc;

architecture Behavioral of atari_wcc is

-- Internal signals
signal clk7           : STD_LOGIC;
signal hsync_i       : STD_LOGIC;
signal hsyncn_i      : STD_LOGIC;
signal vsync_i       : STD_LOGIC;
signal vsyncn_i      : STD_LOGIC;
signal hreset_i      : STD_LOGIC;
signal hresetn_i     : STD_LOGIC;
signal vresetn_i     : STD_LOGIC;
signal hblank_i      : STD_LOGIC;
signal hblankn_i     : STD_LOGIC;
signal h1_i, h2_i, h4_i, h8_i, h16_i, h32_i, h64_i, h64n_i, h128_i, h256_i, h256n_i : STD_LOGIC;
signal v1_i, v2_i, v4_i, v8_i, v16_i, v32_i, v64_i, v64n_i, v128_i, v128n_i, v256_i, v256n_i : STD_LOGIC;

-- Playfield and ball signals
signal playfield_n   : STD_LOGIC;
signal henab_i      : STD_LOGIC;
signal venab_i      : STD_LOGIC;
signal video_playfield : STD_LOGIC;
signal video_paddles : STD_LOGIC;
signal ramp_value_i  : STD_LOGIC_VECTOR(9 downto 0);
signal team_i        : STD_LOGIC;
signal q_i, qn_i     : STD_LOGIC;
signal player_windown_i : STD_LOGIC;
signal defensemen_n_i : STD_LOGIC;
signal symbol_i      : STD_LOGIC;
signal paddles_i     : STD_LOGIC;
signal hit_i         : STD_LOGIC;
signal atrcn_i      : STD_LOGIC := '0';  -- ATRCn: '0' = play mode (controls enabled)
signal solid_fwd_e2, solid_fwd_b2, solid_fwd_c2, solid_fwd_d2 : STD_LOGIC;
signal solid_def_e1, solid_def_b1, solid_def_c1, solid_def_d1 : STD_LOGIC;
signal striped_fwd_e3, striped_fwd_b3, striped_fwd_c3, striped_fwd_d3 : STD_LOGIC;
signal striped_def_e4, striped_def_b4, striped_def_c4, striped_def_d4 : STD_LOGIC;
signal goalie_i : STD_LOGIC;
signal serve_i, serve_n_i : STD_LOGIC;
-- AUTO-SERVE NOTE: serve_circuit_i/n hold the real ServeTimingCircuit outputs.
-- serve_i is overridden to '1' below so the ball is always in play during simulation
-- (no player button press is simulated). When Start/Credit circuits are wired, remove
-- the override and connect serve_i <= serve_circuit_i instead.
signal serve_circuit_i, serve_n_circuit_i : STD_LOGIC;
signal vreset_i        : STD_LOGIC;
signal blip_i          : STD_LOGIC;
signal stop_i          : STD_LOGIC;
signal stopn_i         : STD_LOGIC;
signal catch_trigger_i : STD_LOGIC;
signal catch_clrn_i    : STD_LOGIC;
signal horiz_dir_qn_i  : STD_LOGIC;
signal a_plus_b_n_i    : STD_LOGIC;   -- (A+B)n from playfield: L/R wall position
signal c_plus_d_n_i    : STD_LOGIC;   -- (C+D)n from playfield: T/B wall position
signal windows_i       : STD_LOGIC;   -- Goal window signal from WindowMissBounce
signal v_bounce_i      : STD_LOGIC;
signal h_bounce_i      : STD_LOGIC;
signal bounce_n_i      : STD_LOGIC;
signal miss_i          : STD_LOGIC;
signal hspeed_i        : STD_LOGIC_VECTOR(3 downto 0);
signal slow_i          : STD_LOGIC;
signal pp2_i, pp3_i, pp4_i : STD_LOGIC;
signal vspeed_i        : STD_LOGIC_VECTOR(3 downto 0);
signal hitn_i          : STD_LOGIC;
signal ball_i          : STD_LOGIC;
signal ball_n_i        : STD_LOGIC;
signal hit_tone_i      : STD_LOGIC;
signal time_line_n_i   : STD_LOGIC;
signal end_of_game_i   : STD_LOGIC;
signal video_timeline  : STD_LOGIC;

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
		V256    => v256_i,
		V256n   => v256n_i,
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
		C_PLUS_Dn => c_plus_d_n_i
	);

-- Players circuit: vertical window generator (Fig 11). TEAM, GOALIE, DEFENSEMEN, Q, PLAYER_WINDOWn for mux/summing later.
U_PLAYERS_VW: entity work.PlayersVerticalWindow
	port map(
		H4             => h4_i,
		H8             => h8_i,
		HRESET         => hreset_i,
		HRESETn        => hresetn_i,
		H_ENABLE       => henab_i,
		V_ENABLE       => venab_i,
		PLAYER         => '0',     -- 2-player mode (1 = one-player)
		TEAM           => team_i,
		GOALIE         => goalie_i,
		DEFENSEMENn    => defensemen_n_i,
		Q              => q_i,
		Qn             => qn_i,
		BLIP           => blip_i,
		PLAYER_WINDOWn => player_windown_i
	);

-- Players multiplexer (Fig 11): L7, H7. Select=TEAM,Qn. H7 Eb=PLAYER_WINDOWn (horizontal gating).
-- Solid Forwards E2,B2,C2,D2; Solid Defense/Goalie E1,B1,C1,D1. Striped slots tied '0' until implemented.
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

-- Players summing (Fig 11): check pattern, one-player defeat, M1, K6 -> PADDLES
U_PLAYERS_SUM: entity work.PlayersSumming
	port map(
		H1          => h1_i,
		V1          => v1_i,
		TEAM        => team_i,
		DEFENSEMENn => defensemen_n_i,
		ONE_PLAYER  => '0',
		SYMBOL      => symbol_i,
		BALL        => ball_i,
		PADDLES     => paddles_i,
		HIT         => hit_i
	);

-- Players ramp generator (Fig 11): digital ramp for forwards/defensemen vertical position comparison.
U_RAMP: entity work.PlayersRampGenerator
	port map(
		HSYNC      => hsync_i,
		V256       => v256_i,
		V_ENABLE   => venab_i,
		V128n      => v128n_i,
		RAMP_VALUE => ramp_value_i
	);

-- Solid Forwards (Fig 11): comparator N9, one-shot M9, differentiator K8, counter K7 -> E2, B2, C2, D2
U_SOLID_FWD: entity work.PlayersSolidForwards
	port map(
		HSYNC      => hsync_i,
		RAMP_VALUE => ramp_value_i,
		POSITION   => "0001100100",  -- 100: ramp=100 at ~line 148 (20 lines into lower half)
		ATRCn      => atrcn_i,       -- '0' = play mode (controls enabled)
		E2         => solid_fwd_e2,
		B2         => solid_fwd_b2,
		C2         => solid_fwd_c2,
		D2         => solid_fwd_d2
	);

-- Solid Defense/Goalie (Fig 11): comparator N9-10, 555 N8, J8-2/4, M7 (9316), H8 (LS107), L8, E6, K6 -> E1, B1, C1, D1
U_SOLID_DEF: entity work.PlayersSolidDefenseGoalie
	port map(
		HSYNC      => hsync_i,
		VSYNCn     => vsyncn_i,
		RAMP_VALUE => ramp_value_i,
		POSITION   => "0000000000",
		ATRCn      => atrcn_i,
		GOALIE     => goalie_i,
		E1         => solid_def_e1,
		B1         => solid_def_b1,
		C1         => solid_def_c1,
		D1         => solid_def_d1
	);

-- Striped Forwards (Fig 11): J9(9602), K8(LS02), N7(9316), J8(LS04) -> E3, B3, C3, D3
U_STRIPED_FWD: entity work.PlayersStripedForwards
	port map(
		HSYNC      => hsync_i,
		RAMP_VALUE => ramp_value_i,
		POSITION   => "0001100100",  -- match solid forwards position (100)
		ATRCn      => atrcn_i,
		E3         => striped_fwd_e3,
		B3         => striped_fwd_b3,
		C3         => striped_fwd_c3,
		D3         => striped_fwd_d3
	);

-- Striped Defense (Fig 11): H9(555), J8, J7(9316), F7(LS107), E8, L6, K6, J6 -> E4, B4, C4, D4
U_STRIPED_DEF: entity work.PlayersStripedDefenseGoalie
	port map(
		HSYNC      => hsync_i,
		VSYNCn     => vsyncn_i,
		RAMP_VALUE => ramp_value_i,
		POSITION   => "0000000000",
		ATRCn      => atrcn_i,
		GOALIE     => goalie_i,
		J9_P12     => '0',   -- from J9 when implemented
		E4         => striped_def_e4,
		B4         => striped_def_b4,
		C4         => striped_def_c4,
		D4         => striped_def_d4
	);

-- Serve Timing Circuit (Figure 12): J5(9602), L5(LS74), H4(LS02 gate 4)
-- START='0' triggers one-shot at sim start (B2 falling edge); GOALn='1' (no goal circuit yet)
U_SERVE: entity work.ServeTimingCircuit
	generic map(
		SERVE_DELAY_CLKS => 10,  -- very short for ball visibility test; normal: 50000
		STOP_DELAY_CLKS  => 50000
	)
	port map(
		CLOCK_7       => clk7,
		GOALn         => '1',        -- no goal circuit yet (idle)
		START         => '0',        -- triggers initial serve at sim start
		V128n         => v128n_i,
		H_ENABLE      => henab_i,
		H256n         => h256n_i,
		SERVE         => serve_circuit_i,
		SERVEn        => serve_n_circuit_i,
		CATCH_TRIGGER => catch_trigger_i,
		CATCH_CLRn    => catch_clrn_i,
		STOP          => stop_i,
		STOPn         => stopn_i
	);

-- SERVE TIMING (simulation): hold SERVE='0' (ball counters cleared) until V~205,
-- then go HIGH. Counting 264 scanlines from V=205 gives first ball at V~156 (centre).
serve_proc: process
begin
    serve_i   <= '0';
    serve_n_i <= '1';
    wait for 13029 us;   -- ~93275 pixel-clocks = V~205 at 7.159 MHz
    serve_i   <= '1';
    serve_n_i <= '0';
    wait;
end process;

-- Window/Miss/Bounce circuit (Figure 19): F5(LS08), F4(LS02), H5(LS02), E3(LS04)
U_WINDOW_MISS_BOUNCE: entity work.WindowMissBounce
	port map(
		V64        => v64_i,
		H256n      => h256n_i,
		ONE_PLAYER => '0',              -- 2-player mode
		ATRC       => '0',              -- play mode (ATRC low)
		HOLE       => '1',              -- no moving hole yet (inactive high)
		BALLn      => ball_n_i,
		A_PLUS_Bn  => a_plus_b_n_i,
		C_PLUS_Dn  => c_plus_d_n_i,
		WINDOWS    => windows_i,
		WINDOWSn   => open,
		V_BOUNCE   => v_bounce_i,
		H_BOUNCE   => h_bounce_i,
		BOUNCEn    => bounce_n_i,
		MISS       => miss_i
	);

-- Catch/Kick/Horizontal Direction (Figure 13): E8,C8,D8,D5,C5,C9,K8,A8,D9
U_CATCH_KICK: entity work.CatchKickHorizontalDirection
	port map(
		BALL          => ball_i,
		BLIP          => blip_i,
		HIT           => hit_i,
		DEFENSEMENn   => defensemen_n_i,
		TEAM          => team_i,
		ONE_PLAYER    => '0',           -- 2-player mode
		WINDOWS       => windows_i,
		H256n         => h256n_i,
		H_BOUNCE      => h_bounce_i,
		VSYNCn        => vsyncn_i,
		VRESET        => vreset_i,
		STOP          => stop_i,
		SOLID_KICK    => '0',           -- no pushbuttons in sim
		CHECKED_KICK  => '0',
		CATCH_TRIGGER => catch_trigger_i,
		CATCH_CLRn    => catch_clrn_i,
		HORIZ_DIR_Qn  => horiz_dir_qn_i
	);

-- Horizontal Direction and Speed (Figure 15): B6,A6,A5,B5,F6,B7,C6,F5
-- Idle in sim (BALL='0' so no goalie/forward hits fire)
U_HORIZ_SPEED: entity work.HorizontalDirectionAndSpeed
	port map(
		VRESET         => vreset_i,
		STOPn          => stopn_i,
		HORIZ_DIR      => horiz_dir_qn_i,
		GOAL           => '0',             -- no score circuit yet
		SCORE_SOUNDn   => '1',             -- no score sound yet (inactive high)
		ONE_PLAYER     => '0',             -- 2-player mode
		ATRC           => '0',             -- play mode (not attract)
		GOALIE_FWD_HIT => '1',             -- no hit pulse yet (inactive high for NAND)
		HSPEED         => hspeed_i,
		SLOW           => slow_i
	);

-- Vertical Direction and Speed (Figure 14): D7(9314), D6(LS74), C7(LS86), B7(LS02), F6(LS00), C6(LS04), A7(LS83)
-- Converts player-segment data PP2,PP3,PP4 into vertical-motion code VSPEED(3:0)
U_VERT_SPEED: entity work.VerticalDirectionAndSpeed
	port map(
		V128n   => v128n_i,
		VBOUNCE => v_bounce_i,
		HIT     => hit_i,
		PP2     => pp2_i,
		PP3     => pp3_i,
		PP4     => pp4_i,
		SERVEn  => serve_i,    -- D7 MRn: resets during serve (SERVE=0), enabled during play
		STOPP   => stop_i,
		STOPn   => stopn_i,
		VSPEED  => vspeed_i,
		HITn    => hitn_i
	);

-- Convert active-low playfield to active-high video signal and apply blanking
video_playfield <= (not playfield_n) and hblankn_i;

-- Ball motion circuit (Figure 16): A4,D4,B4,C4(IC9316), B3(LS107),
-- A3,A2(LS10), D3(LS08), C3(LS00), E3(LS04)
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

-- Time Line Circuit (Figure 8): A2(LS10), N4(LS27), digital 555 model
U_TIMELINE: entity work.TimeLineCircuit
	port map(
		CLOCK_7  => clk7,
		VRESETn  => vresetn_i,
		H1       => h1_i,
		H2       => h2_i,
		H4       => h4_i,
		H8       => h8_i,
		H16      => h16_i,
		H32      => h32_i,
		H64      => h64_i,
		H128     => h128_i,
		H256     => h256_i,
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
		C_PLUS_Dn => c_plus_d_n_i,
		ATRC     => '0',           -- play mode
		TIME_LINEn => time_line_n_i,
		END_OF_GAME => end_of_game_i
	);

-- Convert PADDLES to video (active-high, apply blanking)
video_paddles <= paddles_i and hblankn_i;

-- Convert time line to video (active-low -> active-high, apply blanking)
video_timeline <= (not time_line_n_i) and hblankn_i;

-- Output video: combine playfield, paddles, ball, and timeline (per Fig 22 video summing)
VIDEO <= video_playfield or video_paddles or (ball_i and hblankn_i) or video_timeline;

-- Output assignments
HSYNC       <= hsync_i;
VSYNC       <= vsync_i;
CLOCK_7_DBG <= clk7;
HBLANK_DBG  <= hblank_i;

-- Board / debug
LED0      <= not PushBtn;
Clock_out <= clk7;

end Behavioral;
