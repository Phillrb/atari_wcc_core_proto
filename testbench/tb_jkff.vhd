library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_jkff is
end entity tb_jkff;

architecture test of tb_jkff is

signal clk_in, J_in, K_in, prs_in, clr_in  : std_logic := '0';
signal Q_out, Qn_out : std_logic;

component JK_flip_flop is
	Port (
		clk, J, K, prs, clr : in  STD_LOGIC;
		Q : out STD_LOGIC;
		Qnot : out STD_LOGIC
	);
end component;

begin
 clk_in <= not clk_in after 1 ns;

dut : JK_flip_flop
port map (
	clk => clk_in,
	J => J_in,
	K => K_in,
	prs => prs_in,
	clr => clr_in,
	Q => Q_out,
	Qnot => Qn_out
);

stimulus:

process begin

wait until clk_in = '0';

-- test Set
J_in <= '1';
wait for 2 ns;
assert Q_out = '1';
assert Qn_out = '0';

J_in <= '0';
wait for 4 ns;
assert Q_out = '1';
assert Qn_out = '0';

-- test Reset
K_in <= '1';
wait for 2ns;
assert Q_out = '0';
assert Qn_out = '1';

K_in <= '0';
wait for 4ns;
assert Q_out = '0';
assert Qn_out = '1';

-- test Preset acts immediately
wait for 2 ns;
prs_in <= '1';
wait for 1 ns;
assert Q_out = '1';
assert Qn_out = '0';
wait for 1 ns;

prs_in <= '0';
wait for 1 ns;
assert Q_out = '1';
assert Qn_out = '0';
wait for 1 ns;

-- test Clear acts immediately
clr_in <= '1';
wait for 1 ns;
assert Q_out = '0';
assert Qn_out = '1';
wait for 1 ns;

clr_in <= '0';
wait for 1 ns;
assert Q_out = '0';
assert Qn_out = '1';
wait for 1 ns;

-- Test Toggle mode
J_in <= '1';
K_in <= '1';
wait for 2 ns;
assert Q_out = '1';
assert Qn_out = '0';
wait for 2 ns;
assert Q_out = '0';
assert Qn_out = '1';
wait for 2 ns;
assert Q_out = '1';
assert Qn_out = '0';
wait for 2 ns;
assert Q_out = '0';
assert Qn_out = '1';

-- clean up
wait for 2 ns;
J_in <= '0';
K_in <= '0';
clr_in <= '1';
wait for 1 ns;
clr_in <= '0';
wait for 2 ns;

end process stimulus;

end test;