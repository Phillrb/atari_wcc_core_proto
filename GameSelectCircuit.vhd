-- Game Select Circuit for Goal IV (WCC) - TM-035 Figure 10
--
-- Flip-flop D9-2/4 and AND gate C5-11. Switch 1 = set FF (one-player), switch 2 = reset (two-player).
-- C5-11 enabled by ATRCn (play mode); in attract (ATRC high) 1 PLAYER is forced low.
-- README: C5=LS08 (quad AND). D9 in manual is flip-flop; using LS74 (one half).
--
-- Output 1_PLAYER conditions playfield (WINDOWS), players, window/miss/bounce, etc.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity GameSelectCircuit is
	Port (
		GAME_SELECT_1 : in  STD_LOGIC := '1';   -- '1' = switch position 1 (one player), '0' = position 2 (two players)
		ATRC          : in  STD_LOGIC;          -- from Start; high = attract, low = play
		ONE_PLAYER    : out STD_LOGIC           -- 1 PLAYER signal: high in play mode when switch=1
	);
end GameSelectCircuit;

architecture Behavioral of GameSelectCircuit is
	signal ATRCn      : STD_LOGIC;
	signal D9_SET1n   : STD_LOGIC;
	signal D9_Q1      : STD_LOGIC;
	signal D9_Q1n     : STD_LOGIC;
begin
	-- Play mode enable: gate passes switch state only when not in attract
	ATRCn <= not ATRC;
	D9_SET1n <= not GAME_SELECT_1;

	-- D9-2/4 (LS74 first half): set when switch=1, reset when switch=2
	-- SET1n = not(GAME_SELECT_1), CLR1n = GAME_SELECT_1 so 1P -> Q=1, 2P -> Q=0
	U_D9: entity work.LS74
		port map(
			P1_CLR1n  => GAME_SELECT_1,
			P2_D1     => '0',
			P3_CLK1   => '0',
			P4_SET1n  => D9_SET1n,
			P5_Q1     => D9_Q1,
			P6_Q1n    => D9_Q1n,
			P8_Q2n    => open,
			P9_Q2     => open,
			P10_SET2n => '1',
			P11_CLK2  => '0',
			P12_D2    => '0',
			P13_CLR2n => '1'
		);

	-- C5-11 (LS08 one AND): 1_PLAYER = D9_Q AND ATRCn (0 in attract)
	U_C5_11: entity work.LS08
		port map(
			P1_A1  => '0',
			P2_B1  => '0',
			P4_A2  => '0',
			P5_B2  => '0',
			P9_A3  => D9_Q1,
			P10_B3 => ATRCn,
			P12_A4 => '0',
			P13_B4 => '0',
			P3_Y1  => open,
			P6_Y2  => open,
			P8_Y3  => ONE_PLAYER,
			P11_Y4 => open
		);
end Behavioral;
