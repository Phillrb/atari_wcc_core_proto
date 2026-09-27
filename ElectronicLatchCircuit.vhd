-- Electronic Latch Circuit for Goal IV (WCC) - TM-035 Figure 8
--
-- Consists of transistors Q1, Q2, Q3 and inverter A8-12 (README: A8=LS04).
-- Four functions:
--   1) Power on: latch off, preset active -> attract mode.
--   2) Coin accepted: pulse turns on Q3 then Q1; latch holds -> preset released (can start).
--   3) Static (antenna): Q2 on -> Q1 off -> preset active -> attract.
--   4) Credit expired: A9-9/8 Q high (Qn low) -> Q1 off -> preset active -> attract.
--
-- We model the transistor latch as a flip-flop: latched = true after coin pulse
-- until STATIC or CREDIT_EXPIRED; output goes through A8-12 to form LATCH_PRESETn.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ElectronicLatchCircuit is
	Port (
		CLOCK_7            : in  STD_LOGIC;
		COIN_ACCEPTED_PULSE: in  STD_LOGIC := '0';  -- from Credit (NAND C8-8); pulse when coin in
		STATIC             : in  STD_LOGIC := '0';  -- antenna; high when static sensed
		CREDIT_EXPIRED     : in  STD_LOGIC := '0';  -- from Credit/1P/2P (A9-9/8 Q high (Qn low))
		LATCH_PRESETn      : out STD_LOGIC          -- to B9-9/8 and A9-9/8; low = preset active
	);
end ElectronicLatchCircuit;

architecture Behavioral of ElectronicLatchCircuit is
	-- Q1 collector: high when Q1 off (not latched), low when Q1 on (latched after coin)
	signal Q1_collector : STD_LOGIC := '1';  -- power-on: Q1 off
begin
	-- Latch state: set on coin pulse, clear on static or credit expired
	process (CLOCK_7)
	begin
		if rising_edge(CLOCK_7) then
			if STATIC = '1' then
				Q1_collector <= '1';  -- Q1 off, unlatch
			elsif COIN_ACCEPTED_PULSE = '1' then
				Q1_collector <= '0';  -- CR5 coin drive overrides the expired-credit state
			elsif CREDIT_EXPIRED = '1' then
				Q1_collector <= '1';
			end if;
		end if;
	end process;

	-- A8-12 (LS04): inverts Q1 collector to form preset line to B9/A9
	-- High at A8-12 input (Q1 off) -> low output (preset active). Low input (Q1 on) -> high output (preset released).
	U_A8_12: entity work.LS04
		port map(
			P1_A1  => '0',
			P3_A2  => '0',
			P5_A3  => '0',
			P9_A4  => '0',
			P11_A5 => '0',
			P13_A6 => Q1_collector,
			P2_Y1  => open,
			P4_Y2  => open,
			P6_Y3  => open,
			P8_Y4  => open,
			P10_Y5 => open,
			P12_Y6 => LATCH_PRESETn
		);
end Behavioral;
