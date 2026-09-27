library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity tb_TimeLineControl is end;
architecture test of tb_TimeLineControl is
 signal clk : std_logic := '0';
 signal attract : std_logic := '1';
 signal v : std_logic_vector(8 downto 0) := "011110000"; -- V=240, lower wall
 signal line_n, finish : std_logic;
 signal done : boolean := false;
begin
 clk <= not clk after 5 ns when not done else '0';
 dut: entity work.TimeLineCircuit generic map(START_V_INIT=>80,GAME_CLOCKS=>1610)
 port map(CLOCK_7=>clk,VRESETn=>'1',H1=>'0',H2=>'0',H4=>'0',H8=>'1',H16=>'0',H32=>'1',H64=>'1',H128=>'0',H256=>'0',
 V1=>v(0),V2=>v(1),V4=>v(2),V8=>v(3),V16=>v(4),V32=>v(5),V64=>v(6),V128=>v(7),V128n=>'0',V256=>v(8),C_PLUS_Dn=>'0',ATRC=>attract,TIME_LINEn=>line_n,END_OF_GAME=>finish);
 process
 begin
  wait for 100 ns;
  assert finish='0' report "attract must reset timer" severity failure;
  v<="011110011"; wait for 10 ns; -- V=243 still lower wall
  assert finish='0' report "555 expiry must stay high beyond V240" severity failure;
  v<="011110000"; attract<='0';
  wait for 16000 ns;
  assert finish='0' report "timer expired early" severity failure;
  wait for 110 ns;
  assert finish='1' report "timer did not expire at configured duration" severity failure;
  attract<='1'; wait for 20 ns;
  assert finish='0' report "timer did not rearm in attract" severity failure;
  report "Two-minute timer model (scaled clock count) tests passed";
  done<=true; wait;
 end process;
end;
