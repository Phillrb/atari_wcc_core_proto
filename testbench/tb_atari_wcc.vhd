library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_atari_wcc is
end entity tb_atari_wcc ;

architecture test of tb_atari_wcc  is

signal clock_out  : STD_LOGIC := '0';
signal led0_out, led1_out, led2_out : STD_LOGIC;
signal pushbtn_out : STD_LOGIC;
signal csync_out_out : STD_LOGIC;

component atari_wcc  is
	Port (
		Clock_50 : in  STD_LOGIC;
		PushBtn 	: in  STD_LOGIC;
		LED0 		: out STD_LOGIC;
		LED1 		: out STD_LOGIC;
		LED2 		: out STD_LOGIC;
		CSync_out 	: out STD_LOGIC
	);
end component;

begin
 clock_out <= not clock_out after 1 ns;

dut : atari_wcc 
port map (
	Clock_50 => clock_out,
	PushBtn => pushbtn_out,
	LED0 => led0_out,
	LED1 => led1_out,
	LED2 => led2_out,
	CSync_out => csync_out_out
);

stimulus:

process begin


end process stimulus;


end test;