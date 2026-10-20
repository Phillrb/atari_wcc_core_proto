-- Real horizontal raster, player column decode and checked video pattern.
-- A stationary eight-pixel ball must not restart J5 on each checked pixel.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity tb_CatchTimeout is
 generic (CHECK_PARITY : std_logic := '0');
end;
architecture test of tb_CatchTimeout is
 signal clock14 : std_logic := '0';
 signal clk, clkn, sample_clk, hr, hrn : std_logic;
 signal h : std_logic_vector(8 downto 0);
 signal team, defn, blip, window_n, symbol, hit, ball : std_logic;
 signal trig, clrn, stop, stopn, vr : std_logic := '0';
 signal sample_d, sample_q : std_logic_vector(1 downto 0);
 signal ball_x : integer := -20;
 signal done : boolean := false;
 constant HOLD_CLOCKS : positive := 455*12;
begin
 watchdog: process
 begin
  wait for 20 ms;
  assert done report "Catch timeout regression did not complete" severity failure;
  wait;
 end process;
 clock14 <= not clock14 after 35 ns when not done else '0';
 clock: entity work.ComputerClock port map(clock14,clk);
 inv: entity work.LS04 port map(P1_A1=>clk,P2_Y1=>clkn,
     P3_A2=>window_n,P4_Y2=>symbol);
 gate: entity work.LS08 port map(P1_A1=>clock14,P2_B1=>clkn,P3_Y1=>sample_clk);
 raster: entity work.HorizontalSync port map(CLOCK_7=>clk,
     H1=>h(0),H2=>h(1),H4=>h(2),H8=>h(3),H16=>h(4),H32=>h(5),
     H64=>h(6),H128=>h(7),H256=>h(8),HRESET=>hr,HRESETn=>hrn,
     HSYNC=>open,HSYNCn=>open,H64n=>open,H256n=>open,HBLANK=>open,HBLANKn=>open);
 columns: entity work.PlayersVerticalWindow port map(
     H4=>h(2),H8=>h(3),HRESET=>hr,HRESETn=>hrn,H_ENABLE=>'1',V_ENABLE=>'1',
     PLAYER=>'0',TEAM=>team,GOALIE=>open,DEFENSEMENn=>defn,Q=>open,Qn=>open,
     BLIP=>blip,PLAYER_WINDOWn=>window_n);
 ball <= '1' when to_integer(unsigned(h)) >= ball_x and
     to_integer(unsigned(h)) < ball_x+8 else '0';
 players: entity work.PlayersSumming port map(H1=>h(0),V1=>CHECK_PARITY,TEAM=>team,
     DEFENSEMENn=>defn,ONE_PLAYER=>'0',SYMBOL=>symbol,BALL=>ball,
     PADDLES=>open,HIT=>hit);
 sample_d <= '0' & hit;
 bank: entity work.CollisionSampleBank generic map(WIDTH=>2)
     port map(sample_clk,sample_d,sample_q);
 catch: entity work.CatchKickHorizontalDirection generic map(SAMPLE_COLLISIONS=>true)
     port map(SAMPLE_CLK=>sample_clk,HIT_SAMPLED=>sample_q(0),
     BALL=>ball,BLIP=>blip,HIT=>hit,DEFENSEMENn=>defn,TEAM=>team,
     ONE_PLAYER=>'0',WINDOWS=>'0',H256n=>'0',H_BOUNCE=>'0',
     VSYNCn=>'1',VRESET=>vr,STOP=>stop,SOLID_KICK=>'0',CHECKED_KICK=>'0',
     CATCH_TRIGGER=>trig,CATCH_CLRn=>clrn,HORIZ_DIR_Qn=>open);
 timer: entity work.ServeTimingCircuit generic map(10,HOLD_CLOCKS)
     port map(clk,'1','0','0','0','0',open,open,trig,clrn,stop,stopn);
 process
  variable caught_at : time;
  variable x : integer;
 begin
  wait for 100 us;
  vr<='1';wait for 1 us;vr<='0';
  for side in 0 to 1 loop
   -- Select a genuine forward/goalie column of each team, away from HRESET.
   loop
    wait until falling_edge(window_n);wait for 1 ns;
    exit when defn='1' and team=std_logic'val(side+2) and unsigned(h)>80;
   end loop;
   x:=to_integer(unsigned(h));
   report "Catch column team=" & integer'image(side) & " H=" & integer'image(x);
   -- Exercise five partial/full overlaps with the four-pixel player column.
   for offset in integer range -4 to 0 loop
    ball_x<=x+24;wait for 100 us;ball_x<=-20;wait for 100 us;
    ball_x<=x+offset;
    wait until stop='1' for 200 us;
    assert stop='1' report "Stationary ball did not catch" severity failure;
    caught_at:=now;
    wait until stop='0' for (HOLD_CLOCKS+2)*140 ns;
    assert stop='0'
        report "Held catch repeatedly retriggers instead of auto-kicking" severity failure;
    assert now-caught_at=HOLD_CLOCKS*140 ns
        report "Catch did not last its configured timeout" severity failure;
    wait for 200 us;
    assert stop='0' report "Same stationary contact caught again after timeout" severity failure;
    ball_x<=-20;wait for 100 us;
   end loop;
  end loop;
  report "PASS: both teams auto-kick at the deadline across five ball alignments";
  done<=true;wait;
 end process;
end;
