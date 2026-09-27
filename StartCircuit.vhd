-- Start Circuit for Goal IV (WCC) - TM-035 Figure 8
--
-- Consists of flip-flops A8-10/C9-10 (debounce), B9-5/6 (START), B9-9/8 (ATRC).
-- When credit is lit and ATRC is active (attract), pressing start produces a pulse
-- that is clocked by 256V into B9-5/6 (START). STARTn clears B9-9/8 so ATRC goes low
-- (play mode). END_OF_GAME clocks B9-9/8 to set ATRC high again (attract).
--
-- IC grid (README): A8=LS04, C9=LS02, B9=LS74.
-- This module implements B9 (LS74) and the start-pulse logic (A8/C9 debounce
-- contact memory supplied by the JAMMA adapter; C9 retains attract gating).

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity StartCircuit is
	Port (
		CLOCK_7     : in  STD_LOGIC;
		V256        : in  STD_LOGIC;   -- 256V from vertical sync (clocks B9-5/6)
		CREDIT      : in  STD_LOGIC;   -- from credit circuit; high = credit established
		START_BUTTON: in  STD_LOGIC;   -- start pushbutton (active high when pressed)
		END_OF_GAME : in  STD_LOGIC;   -- from time line circuit; high when game over
		LATCH_PRESETn : in STD_LOGIC := '1';  -- from electronic latch; active low preset B9-9/8
		START       : out STD_LOGIC;   -- high for one 256V period when game starts
		STARTn      : out STD_LOGIC;   -- active low
		ATRC        : out STD_LOGIC;  -- high = attract mode, low = play mode
		ATRCn       : out STD_LOGIC   -- active low
	);
end StartCircuit;

architecture Structural of StartCircuit is
	-- B9 (LS74): first FF = B9-5/6 (START), second FF = B9-9/8 (ATRC)
	signal start_req   : STD_LOGIC; -- D input to B9-5: pressed while in attract
	signal released : STD_LOGIC;
	signal B9_Q1       : STD_LOGIC;  -- START
	signal B9_Q1n      : STD_LOGIC;  -- STARTn
	signal B9_Q2       : STD_LOGIC;  -- ATRC
	signal B9_Q2n      : STD_LOGIC;  -- ATRCn
	signal clr1_n      : STD_LOGIC;  -- B9-5/6 clear: inactive when CREDIT high
	signal clr2_n      : STD_LOGIC;  -- B9-9/8 clear: STARTn
begin
	-- Clear B9-5/6 when no credit (manual: "enabled by a high clear level from the credit circuit")
	clr1_n <= CREDIT;
	clr2_n <= B9_Q1n;  -- low START clears B9-9/8

    -- A8/C9 contact memory is represented by the board adapter's settled
    -- switch state. Preserve C9 gate 3 attract inhibit: NOR(released, ATRCn).
    -- Pressing Start while already playing cannot generate another START.
    U_A8: entity work.LS04 port map(
        P11_A5=>START_BUTTON, P10_Y5=>released,
        P2_Y1=>open, P4_Y2=>open, P6_Y3=>open, P8_Y4=>open, P12_Y6=>open);
    U_C9: entity work.LS02 port map(
        P8_A3=>released, P9_B3=>B9_Q2n, P10_Y3=>start_req,
        P1_Y1=>open, P4_Y2=>open, P13_Y4=>open);

	-- B9 (LS74): dual D flip-flop
	-- B9-5/6: D=start_req, CLK=256V, CLR1n=CREDIT -> Q1=START, Q1n=STARTn
	-- B9-9/8: D2='1', CLK2=END_OF_GAME, CLR2n=STARTn, SET2n=LATCH_PRESETn -> Q2=ATRC, Q2n=ATRCn
	IC_B9: entity work.LS74
		port map(
			P1_CLR1n  => clr1_n,
			P2_D1     => start_req,
			P3_CLK1   => V256,
			P4_SET1n  => '1',
			P5_Q1     => B9_Q1,
			P6_Q1n    => B9_Q1n,
			P8_Q2n    => B9_Q2n,
			P9_Q2     => B9_Q2,
			P10_SET2n => LATCH_PRESETn,
			P11_CLK2  => END_OF_GAME,
			P12_D2    => '1',
			P13_CLR2n => clr2_n
		);

	START  <= B9_Q1;
	STARTn <= B9_Q1n;
	ATRC   <= B9_Q2;
	ATRCn  <= B9_Q2n;
end Structural;
