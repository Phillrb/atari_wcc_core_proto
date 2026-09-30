library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity tb_LS107 is
end entity tb_LS107;

architecture test of tb_LS107 is

signal J1_in, K1_in, J2_in, K2_in, CLK1_in, CLK2_in, CLR1_in, CLR2_in : std_logic := '0';
signal Q1_out, Q1n_out, Q2_out, Q2n_out : std_logic;

begin

 CLK1_in <= not CLK1_in after 1 ns;
 CLK2_in <= not CLK2_in after 1 ns;

dut : entity work.LS107
port map (
	P1_J1     => J1_in,
	P2_Q1n 	 => Q1n_out,
	P3_Q1 	 => Q1_out,
	P4_K1     => K1_in,
	P5_Q2     => Q2_out,
	P6_Q2n    => Q2n_out,
	P8_J2 	 => J2_in,
	P9_CLK2 	 => CLK2_in,
	P10_CLR2n => CLR2_in,
	P11_K2	 => K2_in,
	P12_CLK1	 => CLK1_in,
	P13_CLR1n => CLR1_in
);

stimulus:

process begin

report "TEST LS107 - START";

-- Do not clear
CLR1_in <= '1';
CLR2_in <= '1';

wait until CLK1_in = '1';

-- test Set
J1_in <= '1';
wait for 2 ns;
assert Q1_out = '1';
assert Q1n_out = '0';

J1_in <= '0';
wait for 4 ns;
assert Q1_out = '1';
assert Q1n_out = '0';

-- test Reset
K1_in <= '1';
wait for 2 ns;
assert Q1_out = '0';
assert Q1n_out = '1';

K1_in <= '0';
wait for 4 ns;
assert Q1_out = '0';
assert Q1n_out = '1';

-- test Clear acts immediately
CLR1_in <= '0';
wait for 1 ns;
assert Q1_out = '0';
assert Q1n_out = '1';
wait for 1 ns;

CLR1_in <= '1';
wait for 1 ns;
assert Q1_out = '0';
assert Q1n_out = '1';
wait for 1 ns;

-- Test Toggle mode
J1_in <= '1';
K1_in <= '1';
wait for 2 ns;
assert Q1_out = '1';
assert Q1n_out = '0';
wait for 2 ns;
assert Q1_out = '0';
assert Q1n_out = '1';
wait for 2 ns;
assert Q1_out = '1';
assert Q1n_out = '0';
wait for 2 ns;
assert Q1_out = '0';
assert Q1n_out = '1';

-- clean up
wait for 2 ns;
J1_in <= '0';
K1_in <= '0';
CLR1_in <= '1';
wait for 1 ns;
CLR1_in <= '0';
wait for 2 ns;

report "Test JK 2";

wait until CLK2_in = '1';

-- test Set
J2_in <= '1';
wait for 2 ns;
assert Q2_out = '1';
assert Q2n_out = '0';

J2_in <= '0';
wait for 4 ns;
assert Q2_out = '1';
assert Q2n_out = '0';

-- test Reset
K2_in <= '1';
wait for 2 ns;
assert Q2_out = '0';
assert Q2n_out = '1';

K2_in <= '0';
wait for 4 ns;
assert Q2_out = '0';
assert Q2n_out = '1';

-- test Clear acts immediately
CLR2_in <= '0';
wait for 1 ns;
assert Q2_out = '0';
assert Q2n_out = '1';
wait for 1 ns;

CLR2_in <= '1';
wait for 1 ns;
assert Q2_out = '0';
assert Q2n_out = '1';
wait for 1 ns;

-- Test Toggle mode
J2_in <= '1';
K2_in <= '1';
wait for 2 ns;
assert Q2_out = '1';
assert Q2n_out = '0';
wait for 2 ns;
assert Q2_out = '0';
assert Q2n_out = '1';
wait for 2 ns;
assert Q2_out = '1';
assert Q2n_out = '0';
wait for 2 ns;
assert Q2_out = '0';
assert Q2n_out = '1';

-- clean up
wait for 2 ns;
J2_in <= '0';
K2_in <= '0';
CLR2_in <= '1';
wait for 1 ns;
CLR1_in <= '0';
wait for 2 ns;


report "TEST LS107 - COMPLETE";

wait;

end process stimulus;

end test;