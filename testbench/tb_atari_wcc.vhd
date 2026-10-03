library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;

entity tb_atari_wcc is
    generic (ONE_PLAYER_MODE : STD_LOGIC := '0'; SPINNER_TEST : boolean := false);
end tb_atari_wcc;

architecture Behavioral of tb_atari_wcc is

-- Match board PLL: 50 MHz * 2/7 = 14.285714 MHz (70 ns period).
constant CLK_HALF : time := 35 ns;

signal audio_o : STD_LOGIC;
signal coin_n, start_button_n : STD_LOGIC := '1';
signal attract, credit, start_pulse, serve : STD_LOGIC;
signal served_in_play : boolean := false;
signal clk14     : STD_LOGIC := '0';
signal hsync_o   : STD_LOGIC;
signal vsync_o   : STD_LOGIC;
signal csync_o   : STD_LOGIC;
signal video_o   : STD_LOGIC;
signal clk7_dbg  : STD_LOGIC;
signal hblank_dbg : STD_LOGIC;

signal clk7_prev : STD_LOGIC := '0';
signal vsync_prev : STD_LOGIC := '0';
signal frame_count : integer := 0;
signal capture_en : boolean := true;
signal spinner_a, spinner_b : std_logic := '0';
signal spinner_count, spinner_position : std_logic_vector(9 downto 0);
signal solid_position : std_logic_vector(9 downto 0) := "0001100100";

begin

spinner_enabled: if SPINNER_TEST generate
    input_adapter: entity work.SpinnerAdapter
        port map(CLK=>clk7_dbg, RESETn=>'1', QUAD_A=>spinner_a, QUAD_B=>spinner_b,
                 FRAME_SYNC=>vsync_o, COUNT_OUT=>spinner_count, POSITION_OUT=>spinner_position);
    solid_position <= spinner_position;
    sweep: process
        procedure state(value : std_logic_vector(1 downto 0)) is
        begin spinner_a<=value(1);spinner_b<=value(0);wait for 20 us;end;
        procedure turn(up : boolean) is
        begin
            if up then state("01");state("11");state("10");state("00");
            else state("10");state("11");state("01");state("00");end if;
        end;
    begin
        wait for 200 ms;
        for i in 1 to 70 loop turn(false);end loop;
        wait for 40 ms;
        assert unsigned(spinner_count)=0 and unsigned(spinner_position)=82
            report "spinner top limit not reached" severity failure;
        wait for 15 ms;
        for i in 1 to 140 loop turn(true);wait for 700 us;end loop;
        wait for 40 ms;
        assert unsigned(spinner_count)=1023 and unsigned(spinner_position)=154
            report "spinner bottom limit not reached" severity failure;
        report "Full core spinner sweep reached both limits";
        wait;
    end process;
end generate;
spinner_disabled: if not SPINNER_TEST generate
    solid_position <= "0001100100";
end generate;

-- 14.318 MHz clock generation
clk14 <= not clk14 after CLK_HALF;

-- Device under test
DUT: entity work.atari_wcc
    generic map(GAME_CLOCKS=>2142857, SERVE_DELAY_CLOCKS=>357143) -- 300 ms game, 50 ms serve
	port map(
        SolidFwdPosition_I=>solid_position,
        Coin1_I=>coin_n, Start1_I=>start_button_n, GameSelect_I=>not ONE_PLAYER_MODE,
        ATTRACT_DBG=>attract, CREDIT_DBG=>credit, START_DBG=>start_pulse, SERVE_DBG=>serve,
		CLOCK_14    => clk14,
		HSYNC       => hsync_o,
		VSYNC       => vsync_o,
		CSYNC       => csync_o,
		VIDEO       => video_o,
		CLOCK_7_DBG => clk7_dbg,
		HBLANK_DBG  => hblank_dbg,
		PushBtn     => '0',
		LED0        => open,
		SOUND_OUT   => audio_o,
		Clock_out   => open
	);

-- Same normally-open inputs as hardware: no automatic start in the core.
control_sequence: process
begin
    wait for 20 ms;
    assert attract='1' and credit='0' report "power-on attract failed" severity failure;
    start_button_n<='0'; wait for 30 ms; start_button_n<='1';
    wait for 30 ms;
    assert attract='1' and start_pulse='0' and audio_o='1'
        report "unpaid start or attract mute failed" severity failure;
    wait for 20 ms;
    coin_n<='0'; wait for 30 ms; coin_n<='1'; wait for 30 ms;
    assert credit='1' and attract='1' report "coin must grant credit without starting" severity failure;
    start_button_n<='0'; wait for 30 ms; start_button_n<='1';
    assert attract='0' and serve='0' report "paid start / serve delay failed" severity failure;
    wait for 100 ms;
    assert attract='0' and served_in_play report "real serve circuit did not release ball" severity failure;
    wait for 250 ms;
    assert attract='1' and credit='0' and audio_o='1'
        report "time expiry must restore silent attract and exhaust credit" severity failure;
    start_button_n<='0'; wait for 30 ms; start_button_n<='1'; wait for 30 ms;
    assert attract='1' report "expired credit allowed restart" severity failure;
    report "Full core attract / coin / start / serve / expiry sequence passed";
    wait;
end process;

serve_monitor: process(serve)
begin
    if rising_edge(serve) and attract='0' then served_in_play<=true; end if;
end process;

control_trace: process(attract, credit, start_pulse, serve)
begin
    report "control ATRC=" & std_logic'image(attract) & " CREDIT=" & std_logic'image(credit) &
           " START=" & std_logic'image(start_pulse) & " SERVE=" & std_logic'image(serve);
end process;

-- Frame counter: count VSYNC falling edges, enable capture every 2nd frame
frame_counter: process
begin
	wait until rising_edge(clk14);
	if vsync_o = '0' and vsync_prev = '1' then
		frame_count <= frame_count + 1;
		-- Capture every frame (odd and even) to get all positions
		capture_en <= true;
	end if;
	vsync_prev <= vsync_o;
end process;

-- Capture data on CLOCK_7 rising edges and write to file
capture: process
	file out_file : TEXT open WRITE_MODE is "frame_data.txt";
	variable line_out : LINE;
	variable hsync_val, vsync_val, hblank_val, video_val : character;
begin
	-- Wait for clock edge
	wait until rising_edge(clk14);

	-- Detect CLOCK_7 rising edge
	if clk7_dbg = '1' and clk7_prev = '0' then
		if capture_en then
			-- Convert signals to characters
			if hsync_o = '1' then hsync_val := '1'; else hsync_val := '0'; end if;
			if vsync_o = '1' then vsync_val := '1'; else vsync_val := '0'; end if;
			if hblank_dbg = '1' then hblank_val := '1'; else hblank_val := '0'; end if;
			if video_o = '1' then video_val := '1'; else video_val := '0'; end if;

			write(line_out, hsync_val);
			write(line_out, ' ');
			write(line_out, vsync_val);
			write(line_out, ' ');
			write(line_out, hblank_val);
			write(line_out, ' ');
			write(line_out, video_val);
			writeline(out_file, line_out);
		end if;
	end if;

	clk7_prev <= clk7_dbg;
end process;

-- Frame-count stop: set high so the timeout below is the normal stopping condition.
-- Lower this (e.g. 10) for fast single-frame debug runs.
stop_after_frames: process
begin
	wait until frame_count >= 500;
	assert false report "Stopped after 500 frames" severity failure;
end process;

-- Safety timeout: 60 seconds of sim time.  In practice GHDL --stop-time terminates
-- the run first; this just guards against a hung simulation with no VSYNC.
timeout: process
begin
	wait for 60000 ms;
	assert false report "Simulation timeout (60s)" severity failure;
end process;

end Behavioral;
