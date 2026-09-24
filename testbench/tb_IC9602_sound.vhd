library ieee;
use ieee.std_logic_1164.all;
entity tb_IC9602_sound is end;
architecture test of tb_IC9602_sound is
 signal clk : std_logic := '0';
 signal a,b,clr,q,qn,q2,q2n : std_logic := '0';
 signal width : positive := 4;
 signal done : boolean := false;
begin
 clk <= not clk after 5 ns when not done else '0';
 dut: entity work.IC9602 generic map(PULSE_WIDTH_CLKS=>4, PULSE_WIDTH_CLKS2=>4, PIN_ACCURATE=>true)
 port map(CLK=>clk, WIDTH1_CLKS=>width, P5_A1=>a,P4_B1=>b,P3_CLR1n=>clr,
 P6_Q1=>q,P7_Q1n=>qn,P11_A2=>a,P12_B2=>b,P13_CLR2n=>clr,P10_Q2=>q2,P9_Q2n=>q2n);
 process
 procedure tick is begin wait until rising_edge(clk); wait for 1 ns; end;
 begin
 tick; clr<='1'; a<='1'; tick; tick;
 assert q='0' and q2='0' report "startup must not trigger" severity failure;
 b<='1';tick;
 assert q='1' and qn='0' and q2='1' and q2n='0' report "B rising trigger" severity failure;
 b<='0';tick; tick;
 b<='1';tick; -- retrigger
 tick; tick; tick;
 assert q='1' and q2='1' report "retrigger duration" severity failure;
 tick; assert q='0' and q2='0' report "exact four-cycle expiry" severity failure;
 a<='0';tick; assert q='0' and q2='0' report "A falling inhibited by B high" severity failure;
 b<='0';tick; b<='1';tick;
 assert q='0' and q2='0' report "B rising inhibited by A low" severity failure;
 b<='0';a<='1';tick; width<=2; a<='0';tick;
 assert q='1' and q2='1' report "A falling trigger" severity failure;
 tick; assert q='1' severity failure;
 tick; assert q='0' and q2='1' report "independent dynamic width" severity failure;
 clr<='0';wait for 1 ns;
 assert q='0' and q2='0' and qn='1' and q2n='1' report "asynchronous clear" severity failure;
 report "IC9602 sound mode PASS";done<=true;wait;
 end process;
end;
