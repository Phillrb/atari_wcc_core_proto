library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_dff is
end entity tb_dff;

architecture test of tb_dff is

signal clk_in, D_in, prs_in, clr_in  : std_logic := '0';
signal Q_out, Qn_out : std_logic;

component D_flip_flop is
	Port (
		clk, D, prs, clr : in  STD_LOGIC;
		Q : out STD_LOGIC;
		Qnot : out STD_LOGIC
	);
end component;

begin
 clk_in <= not clk_in after 1 ns;

dut : D_flip_flop
port map (
	clk => clk_in,
	D => D_in,
	prs => prs_in,
	clr => clr_in,
	Q => Q_out,
	Qnot => Qn_out
);

stimulus:

process begin

report "Test D type Flip Flop";
wait until clk_in = '0';

-- test Set
report "Test SET";
D_in <= '1';
wait for 2 ns;
assert Q_out = '1';
assert Qn_out = '0';
wait for 2 ns;
assert Q_out = '1';
assert Qn_out = '0';

-- test Reset
report "Test RESET";
D_in <= '0';
wait for 2ns;
assert Q_out = '0';
assert Qn_out = '1';
wait for 2ns;
assert Q_out = '0';
assert Qn_out = '1';

-- test Preset acts immediately
report "Test PRESET";
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

-- clock in a set
report "Test CLEAR";
D_in <= '1';
wait for 2 ns;
assert Q_out = '1';
assert Qn_out = '0';

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

report "Test D type Flip Flop COMPLETE";

wait;

end process stimulus;

end test;