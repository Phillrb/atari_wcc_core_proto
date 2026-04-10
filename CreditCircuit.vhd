-- Credit Circuit for Goal IV (WCC) - TM-035 Figure 8
--
-- Coin switch debounce (A8-4/2), 32V delay counter (B8-5/6, B8-9/8), NAND C8-8,
-- 1P/2P flip-flops A9-5 and A9-9/8, NOR C9-13, inverter A8-8 (credit LED).
-- README: A8=LS04, B8=LS74, C8=LS00, C9=LS27, A9=LS74.
--
-- Coin in -> debounce high -> count 3 x 32V -> C8-8 low -> clear A9-5/A9-9/8,
-- trigger electronic latch, release start. A9-9/8 clocked by ATRC (game over);
-- 1P = one game per coin, 2P = two games per coin.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CreditCircuit is
	Port (
		CLOCK_7         : in  STD_LOGIC;
		COIN_SWITCH     : in  STD_LOGIC := '0';   -- high while coin blocks microswitch
		ONE_PLAYER      : in  STD_LOGIC := '1';   -- '1' = 1P (one game/coin), '0' = 2P
		V32             : in  STD_LOGIC;          -- from VerticalSync
		V256            : in  STD_LOGIC;          -- from VerticalSync (clocks A9-5)
		ATRC            : in  STD_LOGIC;          -- from Start (game over clocks A9-9/8)
		LATCH_PRESETn   : in  STD_LOGIC;          -- from Latch; low = preset A9-9/8 (power-on)
		CREDIT          : out STD_LOGIC;          -- high = credit established (can start)
		COIN_ACCEPTED_PULSE : out STD_LOGIC;      -- active high when C8-8 goes low (to Latch)
		CREDIT_EXPIRED  : out STD_LOGIC           -- A9-9/8 Q high (to Latch)
	);
end CreditCircuit;

architecture Behavioral of CreditCircuit is
	-- Coin debounce: high while coin in (manual: A8-4/2)
	signal debounce_Q   : STD_LOGIC := '0';
	-- B8 counter: two FFs, clocked by V32, cleared when debounce low
	signal B8_Q1       : STD_LOGIC;
	signal B8_Q1n      : STD_LOGIC;
	signal B8_Q2       : STD_LOGIC;
	signal B8_Q2n      : STD_LOGIC;
	signal B8_clrn     : STD_LOGIC;
	-- C8-8: NAND of B8 bits; low when count = 3
	signal C8_8_out    : STD_LOGIC;
	-- A9: 1P/2P and credit-expired FFs
	signal A9_5_Q      : STD_LOGIC;
	signal A9_5_Qn     : STD_LOGIC;
	signal A9_9_8_Q    : STD_LOGIC;
	signal A9_9_8_Qn   : STD_LOGIC;
	signal C9_13_out   : STD_LOGIC;
begin
	-- Debounce: level-sensitive (coin switch closed = high)
	debounce_Q <= COIN_SWITCH;

	-- B8 (LS74): 2-bit counter, clocked by V32, clear when debounce low
	-- FF1: toggle (D1 = Q1n); FF2: D2 = Q1
	B8_clrn <= debounce_Q;
	U_B8: entity work.LS74
		port map(
			P1_CLR1n  => B8_clrn,
			P2_D1     => B8_Q1n,
			P3_CLK1   => V32,
			P4_SET1n  => '1',
			P5_Q1     => B8_Q1,
			P6_Q1n    => B8_Q1n,
			P8_Q2n    => B8_Q2n,
			P9_Q2     => B8_Q2,
			P10_SET2n => '1',
			P11_CLK2  => V32,
			P12_D2    => B8_Q1,
			P13_CLR2n => B8_clrn
		);

	-- C8-8 (LS00): NAND(B8_Q1, B8_Q2); low when count = 3 (valid coin)
	U_C8_8: entity work.LS00
		port map(
			P1_A1  => '1',
			P2_B1  => '1',
			P4_A2  => '1',
			P5_B2  => '1',
			P9_A3  => B8_Q1,
			P10_B3 => B8_Q2,
			P12_A4 => '1',
			P13_B4 => '1',
			P3_Y1  => open,
			P6_Y2  => open,
			P8_Y3  => C8_8_out,
			P11_Y4 => open
		);

	-- Coin-accepted pulse for Latch: high when C8-8 output is low
	COIN_ACCEPTED_PULSE <= not C8_8_out;

	-- A9 (LS74): first FF = A9-5 (1P/2P), second FF = A9-9/8 (credit expired)
	-- A9-5: D = ONE_PLAYER, CLK = V256, CLRn = C8_8_out (clear on coin)
	-- A9-9/8: D = A9_5_Q, CLK = ATRC, CLRn = C8_8_out, SET2n = LATCH_PRESETn (preset at power on)
	U_A9: entity work.LS74
		port map(
			P1_CLR1n  => C8_8_out,
			P2_D1     => ONE_PLAYER,
			P3_CLK1   => V256,
			P4_SET1n  => '1',
			P5_Q1     => A9_5_Q,
			P6_Q1n    => A9_5_Qn,
			P8_Q2n    => A9_9_8_Qn,
			P9_Q2     => A9_9_8_Q,
			P10_SET2n => LATCH_PRESETn,
			P11_CLK2  => ATRC,
			P12_D2    => A9_5_Q,
			P13_CLR2n => C8_8_out
		);

	CREDIT_EXPIRED <= A9_9_8_Q;

	-- C9-13 (LS27): NOR(A9_9_8_Q, debounce_Q); high = credit (can start) when no coin in and credit not expired
	U_C9_13: entity work.LS27
		port map(
			P1_A1  => A9_9_8_Q,
			P2_B1  => debounce_Q,
			P13_C1 => '0',
			P3_A2  => '0',
			P4_B2  => '0',
			P5_C2  => '0',
			P9_A3  => '0',
			P10_B3 => '0',
			P11_C3 => '0',
			P6_Y2  => open,
			P8_Y3  => open,
			P12_Y1 => C9_13_out
		);

	CREDIT <= C9_13_out;

	-- A8-8 (LS04): inverts for credit LED; we output CREDIT (high = light on) directly
	-- LED drive would be A8-8 output = not C9_13_out; not needed as separate port
end Behavioral;
