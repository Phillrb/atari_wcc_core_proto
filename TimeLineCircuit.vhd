-- Time Line Circuit for Goal IV (WCC) - TM-035 Figure 8
--
-- The time line is a vertical bar physically to the left of the playfield
-- (H = 102..105, ~8 px gap to playfield left at 113 in PNG). Height decreases during play.
-- When the line disappears, the game ends (END_OF_GAME).
--
-- Manual: resistors R6,R7,R14,R15,R17; pots R10,R18; caps C4,C5; transistors
-- Q4,Q5; timer E9 (555); inverters D9-8, J2-10; NAND A2-8 (LS10); negative-true
-- AND N4-6 (LS27); flip-flop K1-5 (LS74). Window: 102H-105H for ~8 px gap (schematic 128H),
-- V pulse 80V-240V from playfield. TIME LINE = NAND(window, V_pulse, D9-8).
--
-- IC grid (README): A2=LS10, N4=LS27, K1=LS74, D9=LS04, E9=555, J2=LS04.
-- The 555+RC ramp is modelled digitally: a start_V register advances each
-- field when ATRC='0', so the visible line shrinks from the top over time.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TimeLineCircuit is
	Generic ( START_V_INIT : natural := 80 );  -- initial timeline top (for GIF keyframes: run with 80,100,...,235)
	Port (
		CLOCK_7  : in  STD_LOGIC;
		VRESETn  : in  STD_LOGIC;   -- vertical reset (start of field), active low
		H1      : in  STD_LOGIC;
		H2      : in  STD_LOGIC;
		H4      : in  STD_LOGIC;
		H8      : in  STD_LOGIC;
		H16     : in  STD_LOGIC;
		H32     : in  STD_LOGIC;
		H64     : in  STD_LOGIC;
		H128    : in  STD_LOGIC;
		H256    : in  STD_LOGIC;
		V1      : in  STD_LOGIC;
		V2      : in  STD_LOGIC;
		V4      : in  STD_LOGIC;
		V8      : in  STD_LOGIC;
		V16     : in  STD_LOGIC;
		V32     : in  STD_LOGIC;
		V64     : in  STD_LOGIC;
		V128    : in  STD_LOGIC;
		V128n   : in  STD_LOGIC;
		V256    : in  STD_LOGIC;
		C_PLUS_Dn : in  STD_LOGIC;  -- (C+D)n from playfield: top/bottom wall position
		ATRC    : in  STD_LOGIC;    -- attract mode high => time line full / game off
		TIME_LINEn : out STD_LOGIC; -- active low when time line segment is drawn
		END_OF_GAME : out STD_LOGIC
	);
end TimeLineCircuit;

architecture Behavioral of TimeLineCircuit is

	-- Vertical window pulse 80V..240V (V pulse from playfield description)
	signal V_pulse     : STD_LOGIC;
	-- Horizontal window 102H..105H (4 px wide; ~8 px gap to playfield left at 113H in PNG)
	signal H_window    : STD_LOGIC;
	-- Digital equivalent of D9-8: high when we are in the "draw" part of the field
	-- (past the 555 delay). As game time advances, this becomes true later in the field.
	signal D9_8       : STD_LOGIC;

	-- Game-time state: vertical position at which the time line "starts" (top of bar).
	constant V_END        : unsigned(8 downto 0) := to_unsigned(240, 9);
	constant V_END_GAME   : unsigned(8 downto 0) := to_unsigned(244, 9); -- end when bar nearly gone

	signal start_V    : unsigned(8 downto 0) := to_unsigned(START_V_INIT, 9);
	signal V_int      : unsigned(8 downto 0);
	signal H_int      : unsigned(8 downto 0);

	-- A2-8 (LS10 gate 3): TIME_LINE = NAND(H_window, V_pulse, D9_8) -> active low when draw
	signal TIME_LINE_raw : STD_LOGIC;
	-- N4-6 (LS27 gate 2): END_OF_GAME = NOR(C_PLUS_Dn, D9_8, V128n)
	signal end_of_game_i : STD_LOGIC;

	-- VRESETn edge detection: advance start_V once per field when ATRC='0'
	signal vreset_prev : STD_LOGIC := '1';

begin

	V_int <= unsigned(std_logic_vector'(V256 & V128 & V64 & V32 & V16 & V8 & V4 & V2 & V1));
	H_int <= unsigned(std_logic_vector'(H256 & H128 & H64 & H32 & H16 & H8 & H4 & H2 & H1));

	-- V pulse: match playfield vertical extent - start at top (84), end before bottom (234)
	-- Manual 80V-240V; adjusted so timeline aligns with playfield top and ends before bottom line.
	V_pulse <= '1' when (V_int >= to_unsigned(84, 9) and V_int <= to_unsigned(234, 9)) else '0';

	-- Horizontal window: 102H to 105H (4 px; ~8 px gap to playfield left in output)
	H_window <= '1' when (H_int >= to_unsigned(102, 9) and H_int < to_unsigned(106, 9)) else '0';

	-- D9-8 (inverted 555 output): high when we are past the "delay" for this field.
	-- Behavioural: high when V >= start_V and within 80..240. So bar runs from start_V down to 240.
	D9_8 <= '1' when (V_int >= start_V and V_int <= V_END) else '0';

	-- Advance start_V at the end of each vertical reset (once per field) when game is on (ATRC='0').
	-- Pot adjustment equivalent: start_V can start at 80 (trim) and rate is fixed here (time rate pot).
	process (CLOCK_7)
	begin
		if rising_edge(CLOCK_7) then
			vreset_prev <= VRESETn;
			if vreset_prev = '0' and VRESETn = '1' then
				if ATRC = '0' then
					if start_V < V_END_GAME then
						start_V <= start_V + 1;
					end if;
				else
					start_V <= to_unsigned(START_V_INIT, 9);
				end if;
			end if;
		end if;
	end process;

	-- A2-8 (LS10): TIME_LINE = NAND(H_window, V_pulse, D9_8); output active low when line drawn
	IC_A2: entity work.LS10
		port map(
			P8_Y3   => TIME_LINE_raw,
			P9_A3   => H_window,
			P10_B3  => V_pulse,
			P11_C3  => D9_8
		);
	TIME_LINEn <= TIME_LINE_raw;

	-- END_OF_GAME: N4-6 (LS27 gate 2): NOR(C_PLUS_Dn, D9_8, V128n)
	-- When all three are low: C+D active, 555 delay has passed, and V128=1 (V128n=0)
	IC_N4: entity work.LS27
		port map(
			P1_A1 => '0', P2_B1 => '0', P13_C1 => '0', P12_Y1 => open,  -- gate 1 unused
			P3_A2 => C_PLUS_Dn, P4_B2 => D9_8, P5_C2 => V128n,          -- gate 2: END_OF_GAME
			P6_Y2 => end_of_game_i,
			P9_A3 => '0', P10_B3 => '0', P11_C3 => '0', P8_Y3 => open   -- gate 3 unused
		);
	END_OF_GAME <= end_of_game_i;

end Behavioral;
