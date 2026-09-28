-- Time Line Circuit for Goal IV (WCC) - TM-035 Figure 8
--
-- The time line is a vertical bar physically to the left of the playfield
-- Height decreases during play.When the line disappears, the game ends (END_OF_GAME).
--
-- Manual: resistors R6,R7,R14,R15,R17; pots R10,R18; caps C4,C5; transistors
-- Q4,Q5; timer E9 (555); inverters D9-8, J2-10; NAND A2-8 (LS10); negative-true
-- AND N4-6 (LS27); flip-flop K1-5 (LS74).
-- V pulse 80V-240V from playfield. TIME LINE = NAND(window, V_pulse, D9-8).
--
-- IC grid (README): A2=LS10, N4=LS27, K1=LS74, D9=LS04, E9=555, J2=LS04.
-- The 555+RC ramp is modelled digitally: a start_V register advances each
-- timed step when ATRC='0', so the visible line shrinks over 120 seconds.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TimeLineCircuit is
	Generic ( START_V_INIT : natural := 80; GAME_CLOCKS : positive := 857142840 );  -- initial timeline top (for GIF keyframes: run with 80,100,...,235)
	Port (
		CLOCK_7  : in  STD_LOGIC;
		VRESETn  : in  STD_LOGIC;   -- vertical reset (start of field), active low
		H1n		: in  STD_LOGIC;
		H4      : in  STD_LOGIC;
		H128    : in  STD_LOGIC;
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
	-- Horizontal window
	signal H_window    : STD_LOGIC;
	-- Digital equivalent of D9-8: high when we are in the "draw" part of the field
	-- (past the 555 delay). As game time advances, this becomes true later in the field.
	signal D9_8       : STD_LOGIC;

	-- Game-time state: vertical position at which the time line "starts" (top of bar).
	constant V_END_GAME   : unsigned(8 downto 0) := to_unsigned(244, 9); -- end when bar nearly gone

	signal start_V    : unsigned(8 downto 0) := to_unsigned(START_V_INIT, 9);
	signal V_int      : unsigned(8 downto 0);

	-- A2-8 (LS10 gate 3): TIME_LINE = NAND(H_window, V_pulse, D9_8) -> active low when draw
	signal TIME_LINE_raw : STD_LOGIC;
	-- N4-6 (LS27 gate 2): END_OF_GAME = NOR(C_PLUS_Dn, D9_8, V128n)
	signal end_of_game_i : STD_LOGIC;

	-- Digital approximation of the adjustable C4 charging time. Default 120 s.
    constant STEP_CLOCKS : positive := GAME_CLOCKS / (241 - START_V_INIT);
    signal elapsed_step : natural range 0 to STEP_CLOCKS-1 := 0;

	signal H4n : STD_LOGIC;
begin

	V_int <= unsigned(std_logic_vector'(V256 & V128 & V64 & V32 & V16 & V8 & V4 & V2 & V1));

	-- V pulse: match playfield vertical extent - start at top (84), end before bottom (234)
	-- Manual 80V-240V; adjusted so timeline aligns with playfield top and ends before bottom line.
	V_pulse <= '1' when (V_int >= to_unsigned(84, 9) and V_int <= to_unsigned(234, 9)) else '0';

	-- D9-8 (inverted 555 output): high when we are past the "delay" for this field.
	-- E9 remains low after expiry until the next field; D9-8 must stay HIGH
	-- beyond V=240, otherwise N4 falsely ends a newly started game.
	D9_8 <= '1' when (V_int >= start_V) else '0';

    -- C4 discharges in attract; during play its rising control voltage
    -- lengthens the E9 pulse. The last step reaches V=241 after GAME_CLOCKS
    -- clocks (rounded down by <161 clocks), then N4 ends play at the wall.
    process (CLOCK_7)
    begin
        if rising_edge(CLOCK_7) then
            if ATRC = '1' then
                start_V <= to_unsigned(START_V_INIT, 9);
                elapsed_step <= 0;
            elsif elapsed_step = STEP_CLOCKS-1 then
                elapsed_step <= 0;
                if start_V < V_END_GAME then
                    start_V <= start_V + 1;
                end if;
            else
                elapsed_step <= elapsed_step + 1;
            end if;
        end if;
    end process;

	IC_J2: entity work.LS04
		port map(
			P10_Y5 => H4n,
			P11_A5 => H4
		);

	IC_K1: entity work.LS74
		port map(
			P1_CLR1n => H4n,
			P2_D1 => H1n,
			P3_CLK1 => H128,
			P4_SET1n => '1',
			P5_Q1 => H_window
		);

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
