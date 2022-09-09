library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- JK Flip-flop with present and clear 

entity JK_flip_flop is
	Port (
		clk, J, K, prs, clr : in  STD_LOGIC;
		Q : out STD_LOGIC;
		Qnot : out STD_LOGIC
	);
end JK_flip_flop;

architecture Behavioral of JK_flip_flop is
signal nxt_state, prv_state : STD_LOGIC := '0';
signal input: STD_LOGIC_VECTOR(1 downto 0);
begin
	input <= J & K;
	process (clk, prs, clr) is
	begin
	if(clr = '1') then
		nxt_state <= '0';
	elsif (prs = '1') then
		nxt_state <= '1';
	elsif (clk'event and clk = '1') then
		case (input) is
			when "10" => nxt_state <= '1';
			when "01" => nxt_state <= '0';
			when "00" => nxt_state <= prv_state;
			when "11" => nxt_state <= not prv_state;
			when others => null;
		end case;
	end if;
	end process;
	Q <= nxt_state;
	Qnot <= not nxt_state;
	prv_state <= nxt_state;
end Behavioral;
