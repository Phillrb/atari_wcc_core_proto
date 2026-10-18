-- Diagnostic: real Figure 4/5 raster + Figure 16 motion, fixed STOP presets.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
entity tb_HorizontalStop is generic (STOP_CODE : natural := 10); end;
architecture test of tb_HorizontalStop is
 signal clk, run_ball : std_logic := '0';
 signal h,v : std_logic_vector(8 downto 0);
 signal hr,hrn,vr,hsn,hbn,ball : std_logic;
 signal done : boolean := false;
begin
 clk<=not clk after 70 ns when not done else '0';
 sync: entity work.HorizontalSync port map(CLOCK_7=>clk,HSYNC=>open,HSYNCn=>hsn,
 H1=>h(0),H2=>h(1),H4=>h(2),H8=>h(3),H16=>h(4),H32=>h(5),H64=>h(6),H64n=>open,
 H128=>h(7),H256=>h(8),H256n=>open,HRESET=>hr,HRESETn=>hrn,HBLANK=>open,HBLANKn=>hbn);
 vertical: entity work.VerticalSync port map(HRESET=>hr,VSYNC=>open,VSYNCn=>open,
 V1=>v(0),V2=>v(1),V4=>v(2),V8=>v(3),V16=>v(4),V32=>v(5),V64=>v(6),V64n=>open,V128=>v(7),V128n=>open,V256=>v(8),V256n=>open,VRESET=>vr,VRESETn=>open);
 motion: entity work.BallMotionCircuit port map(clk,hsn,hbn,run_ball,std_logic_vector(to_unsigned(STOP_CODE,4)),"0111",ball,open,open);
 enabled_clocks: process
  variable total,active : natural := 0;
  variable last_h : natural := 0;
 begin
  wait until rising_edge(clk);
  if to_integer(unsigned(h))<last_h then
   if now>1 ms then
    assert total=455 and active=375 report "raster sample counts changed" severity failure;
   end if;
   total:=0;active:=0;
  end if;
  total:=total+1;
  if hbn='1' then active:=active+1;end if;
  last_h:=to_integer(unsigned(h));
 end process;
 trace: process
  file f : text open write_mode is "horizontal_stop.csv";
  variable row : line;
 begin
  write(row,string'("time_ns,h,v"));writeline(f,row);
  loop
   wait until rising_edge(ball);wait for 1 ns;
   if ball='1' then
    write(row,integer'image(now / 1 ns) & "," & integer'image(to_integer(unsigned(h))) & "," & integer'image(to_integer(unsigned(v))));writeline(f,row);
   end if;
  end loop;
 end process;
 checks: process
 begin
  wait for 20 ms;run_ball<='1';wait for 65 ms;
  report "Horizontal STOP trace complete; 455 clocks/line, 375 enabled clocks/line";
  done<=true;wait;
 end process;
end;
