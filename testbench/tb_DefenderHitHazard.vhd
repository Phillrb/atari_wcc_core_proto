-- Diagnostic for the CURRENT zero-delay model, not a desired-behaviour regression.
-- E1/E4 held HIGH excludes both vertical defender generators from the failure.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity tb_DefenderHitHazard is
 generic (VALID_SOLID_OVERLAP : boolean := false);
end;
architecture diagnostic of tb_DefenderHitHazard is
 signal clk : std_logic := '0';
 signal h : std_logic_vector(8 downto 0);
 signal hr,hrn,team,goalie,defn,qn,blip,window_n,symbol,paddles,hit,audio : std_logic;
 signal ball : std_logic := '0';
 signal solid_glitch,striped_hit : boolean := false;
 signal done : boolean := false;
begin
 clk<=not clk after 70 ns when not done else '0';
 sync: entity work.HorizontalSync port map(CLOCK_7=>clk,HSYNC=>open,HSYNCn=>open,
 H1=>h(0),H2=>h(1),H4=>h(2),H8=>h(3),H16=>h(4),H32=>h(5),H64=>h(6),H64n=>open,
 H128=>h(7),H256=>h(8),H256n=>open,HRESET=>hr,HRESETn=>hrn,HBLANK=>open,HBLANKn=>open);
 windows: entity work.PlayersVerticalWindow port map(h(2),h(3),hr,hrn,'1','1','0',team,goalie,defn,open,qn,blip,window_n);
 mux: entity work.PlayersMultiplexer port map(TEAM=>team,Qn=>qn,PLAYER_WINDOWn=>window_n,
 B1=>'0',B2=>'0',B3=>'0',B4=>'0',C1=>'0',C2=>'0',C3=>'0',C4=>'0',D1=>'0',D2=>'0',D3=>'0',D4=>'0',
 E1=>'1',E2=>'0',E3=>'0',E4=>'1',PP2=>open,PP3=>open,PP4=>open,SYMBOL=>symbol);
 summing: entity work.PlayersSumming port map(h(0),'1',team,defn,'0',symbol,ball,paddles,hit);
 sound: entity work.SoundCircuit port map(CLOCK_7=>clk,MISS=>'0',HIT=>hit,STOPn=>'1',SLOW=>'1',HIT_TONE=>'1',V32=>'0',BOUNCEn=>'1',ATRCn=>'1',
 GOAL=>open,GOALn=>open,SCORE_SOUNDn=>open,SOUND_OUT=>audio);
 -- Begin after one whole line to allow the real ripple/window reset sequence.
 stimulus: process
  variable x : natural;
 begin
  wait until falling_edge(clk);wait for 1 ns;
  x:=to_integer(unsigned(h));
  if now > 64 us and ((not VALID_SOLID_OVERLAP and x>=207 and x<=211) or
      (VALID_SOLID_OVERLAP and x>=196 and x<=205) or (x>=344 and x<=350)) then ball<='1';else ball<='0';end if;
 end process;
 pulses: process
  variable started : time;
  variable hit_team : std_logic;
 begin
  wait until rising_edge(hit);started:=now;hit_team:=team;
  wait until falling_edge(hit);
  if hit_team='0' then
   if VALID_SOLID_OVERLAP then
    assert now-started=560 ns report "valid solid overlap must last four pixels" severity failure;
    report "solid: 560 ns HIT for real overlap";
   else
    assert now=started report "solid pulse is no longer zero-time; revisit diagnosis" severity failure;
    report "solid: zero-time HIT with constant E1";
   end if;
   solid_glitch<=true;
  else
   assert now-started=140 ns report "striped pulse differs from one pixel" severity failure;
   striped_hit<=true;
   report "striped: 140 ns HIT with constant E4";
  end if;
 end process;
 checks: process
 begin
  wait for 96 us;
  assert solid_glitch report "solid collision case missing" severity failure;
  if VALID_SOLID_OVERLAP then
   assert audio='1' report "real solid hit must trigger sound" severity failure;
  else
   assert audio='0' report "solid hazard / missed sound not reproduced" severity failure;
  end if;
  wait for 20 us;
  assert striped_hit and audio='1' report "striped valid hit / sound not reproduced" severity failure;
  report "Defender hit diagnostic passed; VALID_SOLID_OVERLAP=" & boolean'image(VALID_SOLID_OVERLAP);
  done<=true;wait;
 end process;
end;
