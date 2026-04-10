library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- D type Flip-flop with present and clear

entity D_flip_flop is
	Port (
		clk, D, prs, clr : in  STD_LOGIC;
		Q : out STD_LOGIC;
		Qnot : out STD_LOGIC
	);
end D_flip_flop;

architecture Behavioral of D_flip_flop is

signal Dn : STD_LOGIC;

begin

Dn <= not D;

JKFF: entity work.JK_flip_flop
	port map(
		clk, D, Dn, prs, clr,
		Q, Qnot
	);

end Behavioral;
