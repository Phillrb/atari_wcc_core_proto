library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity tb_ServeControl is end;
architecture test of tb_ServeControl is
 signal clk : std_logic := '0';
 signal goaln : std_logic := '1';
 signal start, v128n : std_logic := '0';
 signal h_enable : std_logic := '1';
 signal serve, serven, stop, stopn : std_logic;
 signal catch_trigger, catch_clear : std_logic := '1';
 signal done : boolean := false;
begin
 clk <= not clk after 5 ns when not done else '0';
 dut: entity work.ServeTimingCircuit generic map(10,10)
 port map(clk,goaln,start,v128n,h_enable,'0',serve,serven,catch_trigger,catch_clear,stop,stopn);
 process
  procedure raster is
  begin
   v128n<='0'; h_enable<='1'; wait for 2 ns;
   v128n<='1'; wait for 2 ns; h_enable<='0'; wait for 2 ns;
  end;
 begin
  wait for 30 ns; raster;
  assert serve='1' report "idle attract must run ball" severity failure;
  start<='1'; wait for 20 ns; raster;
  assert serve='0' and serven='1' report "START rising must hold serve" severity failure;
  start<='0'; wait for 120 ns; raster;
  assert serve='1' report "serve delay did not expire" severity failure;
  goaln<='0'; wait for 20 ns; raster;
  assert serve='0' report "GOALn falling must hold serve" severity failure;
  goaln<='1'; wait for 120 ns; raster;
  assert serve='1' report "goal serve delay did not expire" severity failure;
  catch_trigger<='0'; wait for 20 ns;
  assert stop='1' and stopn='0' report "catch leading edge failed" severity failure;
  catch_clear<='0'; wait for 1 ns;
  assert stop='0' report "catch clear must be asynchronous" severity failure;
  report "Figure 12 serve/catch tests passed";
  done<=true; wait;
 end process;
end;
