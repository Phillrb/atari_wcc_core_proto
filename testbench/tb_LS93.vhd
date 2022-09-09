library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;

entity tb_LS93 is
end entity tb_LS93;

architecture test of tb_LS93 is

signal CP1n_in, MR1_in, MR2_in, CP0n_in : std_logic := '0';
signal Q0_out, Q1_out, Q2_out, Q3_out : std_logic;
signal Q_output : std_logic_vector (3 downto 0);

component LS93 is
	Port (
		P1_CP1n 	: in  STD_LOGIC;
		P2_MR1 	: in  STD_LOGIC;
		P3_MR2	: in  STD_LOGIC;
		-- P4 : NC
		-- P5 : VCC
		-- P6 : NC
		-- P7 : NC
		P8_Q2 	: out STD_LOGIC;
		P9_Q1 	: out STD_LOGIC;
		-- P10 : GND
		P11_Q3	: out STD_LOGIC;
		P12_Q0	: out STD_LOGIC;
		-- P13 : NC
		P14_CP0n : in  STD_LOGIC
	);
end component;

begin

dut : LS93
port map (
	P1_CP1n => CP1n_in,
	P2_MR1 => MR1_in,
	P3_MR2 => MR2_in,
	P8_Q2 => Q2_out,
	P9_Q1 => Q1_out,
	P11_Q3 => Q3_out,
	P12_Q0 => Q0_out,
	P14_CP0n => CP0n_in
);

-- link first JK to others for full 4-bit binary counter
CP1n_in <= Q0_out;

-- Easier reading output
Q_output <= Q3_out & Q2_out & Q1_out & Q0_out;

stimulus:

process 
	variable counter : integer;
begin

report "TEST LS93 4-bit binary counter - START";

-- Do not clear
MR1_in <= '1';
MR2_in <= '1';
CP0n_in <= '1';

-- settle
wait for 10 ns;

-- clock until "0000"
while Q_output /= "0000" loop
CP0n_in <= not CP0n_in;
wait for 1 ns;
end loop;
assert Q_output = "0000" report "Q output not 0000 at start" severity error;

-- check Q is counting up
for i in 1 to 15 loop

	-- Clock on
	CP0n_in <= not CP0n_in;
	wait for 1 ns;
	CP0n_in <= not CP0n_in;
	wait for 1 ns;

	-- validate output
	if(Q0_out = '1') then
		counter := 1;
	else 
		counter := 0;
	end if;

	if(Q1_out = '1') then
		counter := counter + 2;
	end if;

	if(Q2_out = '1') then
		counter := counter + 4;
	end if;

	if(Q3_out = '1') then
		counter := counter + 8;
	end if;

	report "i=" & integer'image(i) & " counter=" & integer'image(counter);
	assert (counter = i) report "Q output not as expected" severity error;
end loop;

-- Roll over
CP0n_in <= not CP0n_in;
wait for 1 ns;
CP0n_in <= not CP0n_in;
wait for 1 ns;
assert Q_output = "0000" report "Q output not 0000 after count increment" severity error;

-- TEST MR
report "Testing MR1";
-- clock on a few
for i in 1 to 3 loop
CP0n_in <= not CP0n_in;
wait for 1 ns;
CP0n_in <= not CP0n_in;
wait for 1 ns;
end loop;
assert Q_output /= "0000" report "Q output is 0000 after a few further increments" severity error;

-- reset to 0 with MR1
MR1_in <= '0';
wait for 1 ns;
assert Q_output = "0000" report "Q output is not 0000 after reset MR1" severity error;

-- put MR1 back 
wait for 1 ns;
MR1_in <= '1';
wait for 1 ns;
assert Q_output = "0000" report "Q output is not 0000 after reset MR1" severity error;

-- clock on a few
for i in 1 to 3 loop
CP0n_in <= not CP0n_in;
wait for 1 ns;
CP0n_in <= not CP0n_in;
wait for 1 ns;
end loop;
assert Q_output /= "0000" report "Q output is 0000 after MR1 and a few further increments" severity error;

report "Testing MR2";
-- reset to 0 with MR2
MR2_in <= '0';
wait for 1 ns;
assert Q_output = "0000" report "Q output is not 0000 after reset MR2" severity error;

-- put MR2 back 
wait for 1 ns;
MR2_in <= '1';
wait for 1 ns;
assert Q_output = "0000" report "Q output is not 0000 after reset MR2" severity error;

-- clock on a few
for i in 1 to 3 loop
CP0n_in <= not CP0n_in;
wait for 1 ns;
CP0n_in <= not CP0n_in;
wait for 1 ns;
end loop;
assert Q_output /= "0000" report "Q output is 0000 after MR2 and a few further increments" severity error;

report "Testing MR1 and MR2";
-- reset to 0 with MR2 and MR1
MR2_in <= '0';
MR1_in <= '0';
wait for 1 ns;
assert Q_output = "0000" report "Q output is not 0000 after reset MR2 and MR1" severity error;

-- put MR2 back 
wait for 1 ns;
MR2_in <= '1';
MR1_in <= '1';
wait for 1 ns;
assert Q_output = "0000" report "Q output is not 0000 after reset MR2 and MR1" severity error;

-- clock on a few
for i in 1 to 3 loop
CP0n_in <= not CP0n_in;
wait for 1 ns;
CP0n_in <= not CP0n_in;
wait for 1 ns;
end loop;
assert Q_output /= "0000" report "Q output is 0000 after MR2 and MR1 and a few further increments" severity error;

report "TEST LS93 - COMPLETE";

wait;

end process stimulus;

end test;