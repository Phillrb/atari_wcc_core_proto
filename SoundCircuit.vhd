-- Sound Circuit - Goal IV / WCC, TM-035 Figure 20.
-- ICs: J9(9602 ch1), M9(9602 ch1), E5(9602 both), L8(7400), E7(7420).
-- The other halves of J9/M9 and L8 gate 3 live in the player circuits.
-- P2 is +5V. R50 (1k) and the monitor's analogue audio input are external.
-- ATRCn low forces SOUND_OUT high (DC mute); high enables sound transitions.
-- RC timing is clock-quantized. M9 widths are approved adjustable estimates,
-- NOT measured hardware values; see docs/SOUND_CIRCUIT_FIG20.md.
library ieee;
use ieee.std_logic_1164.all;
entity SoundCircuit is
 generic (
  CLOCK_HZ : positive := 7159090;
  GOAL_US : positive := 81600; -- .34*(47k+1k)*5uF
  HIT_SLOW_US : positive := 23460;
  HIT_FAST_US : positive := 3808;
  BOUNCE_DELAY_US : positive := 39; -- .34*(22k+1k)*5nF = 39.1us
  BOUNCE_PULSE_US : positive := 116 -- .34*(33k+1k)*10nF = 115.6us
 );
 port (
  CLOCK_7, MISS, HIT, STOPn, SLOW, HIT_TONE, V32, BOUNCEn, ATRCn : in std_logic;
  GOAL, GOALn, SCORE_SOUNDn, SOUND_OUT : out std_logic
 );
end;
architecture Structural of SoundCircuit is
 function clocks(us : positive) return positive is
 begin return positive(integer(real(CLOCK_HZ)*real(us)/1000000.0)); end;
 constant slow_clks : positive := clocks(HIT_SLOW_US);
 signal hit_width : positive range 1 to slow_clks;
 signal goal_i, score_n, hit_trigger_n, hit_window, hit_sound_n, bounce_delay_n, bounce_sound_n : std_logic;
begin
 assert HIT_FAST_US <= HIT_SLOW_US report "fast hit width exceeds slow width" severity failure;
 -- Digital abstraction of R47/R44/C28, not an extra PCB logic gate.
 hit_width <= slow_clks when SLOW='1' else clocks(HIT_FAST_US);
 GOAL <= goal_i;
 SCORE_SOUNDn <= score_n;
 J9: entity work.IC9602
 generic map(PIN_ACCURATE=>true, PULSE_WIDTH_CLKS=>clocks(GOAL_US))
 port map(CLK=>CLOCK_7, P1_CEXT1=>'1', P2_REXT1=>'1',
 P3_CLR1n=>'1', P4_B1=>MISS, P5_A1=>'1', P6_Q1=>goal_i, P7_Q1n=>GOALn,
 P9_Q2n=>open,P10_Q2=>open,P11_A2=>'1',P12_B2=>'0',P13_CLR2n=>'0',P14_REXT2=>'0',P15_CEXT2=>'0');
 M9: entity work.IC9602
 generic map(PIN_ACCURATE=>true, PULSE_WIDTH_CLKS=>slow_clks)
 port map(CLK=>CLOCK_7, WIDTH1_CLKS=>hit_width, P1_CEXT1=>'1',P2_REXT1=>'1',
 P3_CLR1n=>'1',P4_B1=>'0',P5_A1=>hit_trigger_n,P6_Q1=>hit_window,P7_Q1n=>open,
 P9_Q2n=>open,P10_Q2=>open,P11_A2=>'1',P12_B2=>'0',P13_CLR2n=>'0',P14_REXT2=>'0',P15_CEXT2=>'0');
 E5: entity work.IC9602
 generic map(PIN_ACCURATE=>true, PULSE_WIDTH_CLKS=>clocks(BOUNCE_PULSE_US),PULSE_WIDTH_CLKS2=>clocks(BOUNCE_DELAY_US))
 port map(CLK=>CLOCK_7,P1_CEXT1=>'1',P2_REXT1=>'1',P3_CLR1n=>'1',P4_B1=>'0',
 P5_A1=>bounce_delay_n,P6_Q1=>open,P7_Q1n=>bounce_sound_n,
 P9_Q2n=>bounce_delay_n,P10_Q2=>open,P11_A2=>BOUNCEn,P12_B2=>'0',P13_CLR2n=>'1',P14_REXT2=>'1',P15_CEXT2=>'1');
 -- E5 ch1 triggers at the falling (leading) edge of ch2 Qn, not its expiry.
 L8: entity work.LS00
 port map(P1_A1=>hit_window,P2_B1=>HIT_TONE,P3_Y1=>hit_sound_n,
 P4_A2=>STOPn,P5_B2=>HIT,P6_Y2=>hit_trigger_n,
 P9_A3=>'1',P10_B3=>'1',P8_Y3=>open,
 P12_A4=>V32,P13_B4=>goal_i,P11_Y4=>score_n);
 E7: entity work.LS20
 port map(P1_A1=>hit_sound_n,P2_B1=>ATRCn,P4_C1=>score_n,P5_D1=>bounce_sound_n,P6_Y1=>SOUND_OUT,
 P9_D2=>'1',P10_C2=>'1',P12_B2=>'1',P13_A2=>'1',P8_Y2=>open);
end;
