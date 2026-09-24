library ieee;
use ieee.std_logic_1164.all;
entity tb_SoundCircuit is end;
architecture test of tb_SoundCircuit is
 signal clk : std_logic := '0';
 signal miss,hit,tone,v32 : std_logic := '0';
 signal stopn,slow,bounce,enable : std_logic := '1';
 signal goal,goaln,score,audio : std_logic;
 signal done : boolean := false;
begin
 clk <= not clk after 500 ns when not done else '0';
 dut: entity work.SoundCircuit
 generic map(CLOCK_HZ=>1000000,GOAL_US=>12,HIT_SLOW_US=>8,HIT_FAST_US=>3,BOUNCE_DELAY_US=>2,BOUNCE_PULSE_US=>5)
 port map(CLOCK_7=>clk,MISS=>miss,HIT=>hit,STOPn=>stopn,SLOW=>slow,HIT_TONE=>tone,V32=>v32,BOUNCEn=>bounce,ATRCn=>enable,
 GOAL=>goal,GOALn=>goaln,SCORE_SOUNDn=>score,SOUND_OUT=>audio);
 process
 procedure tick(n : positive := 1) is begin for i in 1 to n loop wait until rising_edge(clk);wait for 1 ns;end loop;end;
 begin
 tick(3); assert goal='0' and goaln='1' and score='1' and audio='0' report "idle" severity failure;
 -- Miss path and both polarities; falling MISS must not retrigger.
 miss<='1';v32<='1';tick;
 assert goal='1' and goaln='0' and score='0' and audio='1' report "MISS rising" severity failure;
 miss<='0';v32<='0';tick;
 assert score='1' and audio='0' report "32V low" severity failure;
 v32<='1';tick(10);assert goal='1' severity failure;
 tick;assert goal='0' and score='1' and audio='0' report "goal expiry" severity failure;
 -- STOP inhibits hit; fast and slow envelopes pass the original tone.
 tone<='1';stopn<='0';hit<='1';tick(2);
 assert audio='0' report "STOP hit inhibition" severity failure;
 hit<='0';stopn<='1';tick;hit<='1';tick;
 assert audio='1' report "slow HIT" severity failure;
 hit<='0';tone<='0';tick;assert audio='0' report "tone low passes" severity failure;
 tone<='1';tick(6);assert audio='1' severity failure;
 tick;assert audio='0' report "slow hit expiry" severity failure;
 slow<='0';hit<='1';tick;hit<='0';tick(2);
 assert audio='1' severity failure;
 tick;assert audio='0' report "fast hit expiry" severity failure;
 -- Bounce ch2 falling Qn starts ch1 one clock later, not after ch2 expires.
 bounce<='0';tick;assert audio='0' severity failure;
 tick;assert audio='1' report "bounce cascade leading edge" severity failure;
 bounce<='1';tick(4);assert audio='1' severity failure;
 tick;assert audio='0' report "bounce pulse expiry" severity failure;
 -- Mix simultaneous score and hit; mute overrides every tone level.
 miss<='1';hit<='1';v32<='1';tone<='1';tick;assert audio='1' severity failure;
 v32<='0';tick;assert audio='1' report "hit remains with score low" severity failure;
 enable<='0';tone<='0';tick;assert audio='1' report "attract DC mute" severity failure;
 tick(15);assert audio='1' report "mute at idle" severity failure;
 enable<='1';tick;assert audio='0' report "unmute at idle" severity failure;
 report "SoundCircuit PASS";done<=true;wait;
 end process;
end;
