-- Start Circuit for Goal IV (WCC) - TM-035 Figure 8
--
-- Consists of flip-flops A8-10/C9-10 (debounce), B9-5/6 (START), B9-9/8 (ATRC).
-- When credit is lit and ATRC is active (attract), pressing start produces a pulse
-- that is clocked by 256V into B9-5/6 (START). STARTn clears B9-9/8 so ATRC goes low
-- (play mode). END_OF_GAME clocks B9-9/8 to set ATRC high again (attract).
--
-- IC grid (README): A8=LS04, C9=LS02, B9=LS74.
-- This module implements B9 (LS74) and the start-pulse logic (A8/C9 debounce
-- modelled as a single pulse lasting one 256V period).

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

architecture Behavioral of StartCircuit is
	-- B9 (LS74): first FF = B9-5/6 (START), second FF = B9-9/8 (ATRC)
	signal start_req   : STD_LOGIC := '0';  -- D input to B9-5; set by button, cleared on 256V rise
	signal v256_prev   : STD_LOGIC := '0';
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

	-- Start-pulse: set when button and credit and attract; clear on 256V rising edge
	-- (models A8-10/C9-10 debounce producing one pulse to D of B9-5)
	process (CLOCK_7)
	begin
		if rising_edge(CLOCK_7) then
			v256_prev <= V256;
			if v256_prev = '0' and V256 = '1' then
				start_req <= '0';
			else
				start_req <= start_req or (START_BUTTON and CREDIT and B9_Q2);
			end if;
		end if;
	end process;

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
end Behavioral;
