library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use STD.TEXTIO.ALL;

entity tb_atari_wcc is
end tb_atari_wcc;

architecture Behavioral of tb_atari_wcc is

-- Match board PLL: 50 MHz * 2/7 = 14.285714 MHz (70 ns period).
constant CLK_HALF : time := 35 ns;

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

begin

-- 14.318 MHz clock generation
clk14 <= not clk14 after CLK_HALF;

-- Device under test
DUT: entity work.atari_wcc
	port map(
		CLOCK_14    => clk14,
		HSYNC       => hsync_o,
		VSYNC       => vsync_o,
		CSYNC       => csync_o,
		VIDEO       => video_o,
		CLOCK_7_DBG => clk7_dbg,
		HBLANK_DBG  => hblank_dbg,
		PushBtn     => '0',
		LED0        => open,
		Clock_out   => open
	);

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
