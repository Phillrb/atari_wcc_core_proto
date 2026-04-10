library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- JK Flip-flop with preset and clear

entity JK_flip_flop is
	Port (
		clk, J, K, prs, clr : in  STD_LOGIC;
		Q : out STD_LOGIC;
		Qnot : out STD_LOGIC
	);
end JK_flip_flop;

architecture Behavioral of JK_flip_flop is
signal nxt_state : STD_LOGIC := '0';
signal input: STD_LOGIC_VECTOR(1 downto 0);
begin
	input <= J & K;
	process (clk, prs, clr) is
		variable state_before_edge : STD_LOGIC;  -- value of Q at start of this evaluation (avoids tardy first edge after reset)
	begin
	if(clr = '1') then
		nxt_state <= '0';
	elsif (prs = '1') then
		nxt_state <= '1';
	elsif rising_edge(clk) then
		state_before_edge := nxt_state;  -- use current output (from previous cycle), not a separate "prv" signal
		case (input) is
			when "10" => nxt_state <= '1';
			when "01" => nxt_state <= '0';
			when "00" => nxt_state <= state_before_edge;
			when "11" => nxt_state <= not state_before_edge;
			when others => null;
		end case;
	end if;
	end process;
	Q <= nxt_state;
	Qnot <= not nxt_state;
end Behavioral;
