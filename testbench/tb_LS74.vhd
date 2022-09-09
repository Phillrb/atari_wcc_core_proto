library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;

entity tb_LS74 is
end entity tb_LS74;

architecture test of tb_LS74 is

signal CLR1n_in, D1_in, CLK1_in, SET1n_in : std_logic := '0';
signal Q1_out, Q1n_out : std_logic;
signal CLR2n_in, D2_in, CLK2_in, SET2n_in : std_logic := '0';
signal Q2_out, Q2n_out : std_logic;

component LS74 is
	Port (
		P1_CLR1n : in  STD_LOGIC;
		P2_D1 	: in  STD_LOGIC;
		P3_CLK1	: in  STD_LOGIC;
		P4_SET1n : in  STD_LOGIC;
		P5_Q1    : out STD_LOGIC;
		P6_Q1n   : out STD_LOGIC;
		-- P7 : GND
		P8_Q2n 	: out STD_LOGIC;
		P9_Q2 	: out STD_LOGIC;
		P10_SET2n : in STD_LOGIC;
		P11_CLK2	:  in STD_LOGIC;
		P12_D2	:  in STD_LOGIC;
		P13_CLR2n : in STD_LOGIC
		-- P14 : VCC
	);
end component;

begin

dut : LS74
port map (
		P1_CLR1n => CLR1n_in,
		P2_D1 => D1_in,
		P3_CLK1 => CLK1_in,
		P4_SET1n => SET1n_in,
		P5_Q1 => Q1_out,
		P6_Q1n => Q1n_out,
		
		P8_Q2n => Q2n_out,
		P9_Q2 => Q2_out,
		P10_SET2n => SET2n_in,
		P11_CLK2 => CLK2_in,
		P12_D2 => D2_in,
		P13_CLR2n => CLR2n_in
);

stimulus:

process 
begin

report "TEST LS74 dual D type flip-flops - START";

-- Do not clear
CLR1n_in <= '1';
CLR2n_in <= '1';
-- Do not preset
SET1n_in <= '1';
SET2n_in <= '1';
-- clock low
CLK1_in <= '0';
CLK2_in <= '0';

-- settle
wait for 10 ns;

-- Clock in D as 0
D1_in <= '0';
wait for 1 ns;
CLK1_in <= '1';
wait for 1 ns;

assert (Q1_out = '0') report "Q1 output not as expected" severity error;
assert (Q1n_out = '1') report "Q1n output not as expected" severity error;

-- Clock in D as 1
CLK1_in <= '0';
wait for 1 ns;
D1_in <= '1';
wait for 1 ns;
CLK1_in <= '1';
wait for 1 ns;

assert (Q1_out = '1') report "Q1 output not as expected" severity error;
assert (Q1n_out = '0') report "Q1n output not as expected" severity error;

-- Check preset
-- Clock in D as 0
CLK1_in <= '0';
wait for 1 ns;
D1_in <= '0';
wait for 1 ns;
CLK1_in <= '1';
wait for 1 ns;

assert (Q1_out = '0') report "Q1 output not as expected" severity error;
assert (Q1n_out = '1') report "Q1n output not as expected" severity error;

-- Preset should act immediately
SET1n_in <= '0';
wait for 1 ns;

assert (Q1_out = '1') report "Q1 output not as expected - preset set" severity error;
assert (Q1n_out = '0') report "Q1n output not as expected" severity error;

-- remove preset (should remain)
SET1n_in <= '1';
wait for 1 ns;

assert (Q1_out = '1') report "Q1 output not as expected - preset unset" severity error;
assert (Q1n_out = '0') report "Q1n output not as expected" severity error;

-- Check clear
-- Clock in D as 1
CLK1_in <= '0';
wait for 1 ns;
D1_in <= '1';
wait for 1 ns;
CLK1_in <= '1';
wait for 1 ns;

assert (Q1_out = '1') report "Q1 output not as expected" severity error;
assert (Q1n_out = '0') report "Q1n output not as expected" severity error;

-- Clear should act immediately
CLR1n_in <= '0';
wait for 1 ns;

assert (Q1_out = '0') report "Q1 output not as expected - clear set" severity error;
assert (Q1n_out = '1') report "Q1n output not as expected" severity error;

-- check 2nd D flip flop
report "Test 2nd D Flip-flop";

-- Clock in D as 0
D2_in <= '0';
wait for 1 ns;
CLK2_in <= '1';
wait for 1 ns;

assert (Q2_out = '0') report "Q2 output not as expected" severity error;
assert (Q2n_out = '1') report "Q2n output not as expected" severity error;

-- Clock in D as 1
CLK2_in <= '0';
wait for 1 ns;
D2_in <= '1';
wait for 1 ns;
CLK2_in <= '1';
wait for 1 ns;

assert (Q2_out = '1') report "Q2 output not as expected" severity error;
assert (Q2n_out = '0') report "Q2n output not as expected" severity error;

-- Check preset
-- Clock in D as 0
CLK2_in <= '0';
wait for 1 ns;
D2_in <= '0';
wait for 1 ns;
CLK2_in <= '1';
wait for 1 ns;

assert (Q2_out = '0') report "Q2 output not as expected" severity error;
assert (Q2n_out = '1') report "Q2n output not as expected" severity error;

-- Preset should act immediately
SET2n_in <= '0';
wait for 1 ns;

assert (Q2_out = '1') report "Q2 output not as expected - preset set" severity error;
assert (Q2n_out = '0') report "Q2n output not as expected" severity error;

-- remove preset (should remain)
SET2n_in <= '1';
wait for 1 ns;

assert (Q2_out = '1') report "Q2 output not as expected - preset unset" severity error;
assert (Q2n_out = '0') report "Q2n output not as expected" severity error;

-- Check clear
-- Clock in D as 1
CLK2_in <= '0';
wait for 1 ns;
D2_in <= '1';
wait for 1 ns;
CLK2_in <= '1';
wait for 1 ns;

assert (Q2_out = '1') report "Q2 output not as expected" severity error;
assert (Q2n_out = '0') report "Q2n output not as expected" severity error;

-- Clear should act immediately
CLR2n_in <= '0';
wait for 1 ns;

assert (Q2_out = '0') report "Q2 output not as expected - clear set" severity error;
assert (Q2n_out = '1') report "Q2n output not as expected" severity error;

report "TEST LS74 - COMPLETE";

wait;

end process stimulus;

end test;