-- Approved adapter regression: ignore subpixel pulses; retain real events.
library ieee;
use ieee.std_logic_1164.all;
entity tb_CollisionSampling is end;
architecture test of tb_CollisionSampling is
 signal clock14 : std_logic := '0';
 signal clock7, clock7n, sample_clk : std_logic;
 signal done : boolean := false;
 signal ball, blip, hit, defn, team, kick, hb : std_logic := '0';
 signal d,q : std_logic_vector(7 downto 0) := (others=>'0');
 signal trig, clrn, stop, stopn, dir : std_logic;
 signal vr : std_logic := '0';
begin
 clock14<=not clock14 after 35 ns when not done else '0';
 clock: entity work.ComputerClock port map(clock14,clock7);
 inv: entity work.LS04 port map(P1_A1=>clock7,P2_Y1=>clock7n);
 gate: entity work.LS08 port map(P1_A1=>clock14,P2_B1=>clock7n,P3_Y1=>sample_clk);
 d <= "000000" & hb & hit;
 bank: entity work.CollisionSampleBank port map(sample_clk,d,q);
 catch: entity work.CatchKickHorizontalDirection generic map(SAMPLE_COLLISIONS=>true)
 port map(SAMPLE_CLK=>sample_clk,HIT_SAMPLED=>q(0),BALL=>ball,BLIP=>blip,HIT=>hit,
 DEFENSEMENn=>defn,TEAM=>team,ONE_PLAYER=>'0',WINDOWS=>'0',H256n=>'0',H_BOUNCE=>q(1),
 VSYNCn=>'1',VRESET=>vr,STOP=>stop,SOLID_KICK=>kick,CHECKED_KICK=>kick,
 CATCH_TRIGGER=>trig,CATCH_CLRn=>clrn,HORIZ_DIR_Qn=>dir);
 timer: entity work.ServeTimingCircuit generic map(12,12)
 port map(clock7,'1','0','0','0','0',open,open,trig,clrn,stop,stopn);
 process
 begin
  wait for 500 ns; vr<='1';wait for 140 ns;vr<='0';
  for side in 0 to 1 loop
   if side=0 then team<='0';else team<='1';end if;
   hit<='0';ball<='1';blip<='1';defn<='0';wait for 500 ns;
   assert trig='1' report "catch extender did not arm" severity failure;
   -- Full defender contact must bounce without catching, on both teams.
   hit<='1';wait for 500 ns;
   assert stop='0' and trig='1' report "defender caught ball" severity failure;
   wait until falling_edge(sample_clk);wait for 10 ns;
   defn<='1';hb<='1';wait for 1 ns;defn<='0';hb<='0';wait for 300 ns;
   assert stop='0' and trig='1' and q(1)='0' report "subpixel collision escaped adapter" severity failure;
   -- Qualifying goalie/forward hit must still catch; kick must release it.
   defn<='1';wait for 500 ns;
   assert stop='1' report "qualifying hit did not catch" severity failure;
   kick<='1';wait for 400 ns;
   assert stop='0' report "kick did not release" severity failure;
   hit<='0';ball<='0';blip<='0';kick<='0';wait for 400 ns;
  end loop;
  -- Real wall/goal-length event survives with one sample per pixel.
  hb<='1';wait for 500 ns;
  assert q(1)='1' report "real wall event lost" severity failure;
  hb<='0';wait for 300 ns;assert q(1)='0' severity failure;
  report "PASS: both defender teams reject catch, goalie/forward catches and kicks, glitch rejection and real wall event";
  done<=true;wait;
 end process;
end;
