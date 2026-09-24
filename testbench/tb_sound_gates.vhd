library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity tb_sound_gates is end;
architecture test of tb_sound_gates is
 signal a : std_logic_vector(3 downto 0) := "0000";
 signal n : std_logic_vector(3 downto 0);
 signal m : std_logic_vector(1 downto 0);
begin
 nand2: entity work.LS00 port map(P1_A1=>a(0),P2_B1=>a(1),P3_Y1=>n(0),
 P4_A2=>a(0),P5_B2=>a(1),P6_Y2=>n(1),P9_A3=>a(0),P10_B3=>a(1),P8_Y3=>n(2),P12_A4=>a(0),P13_B4=>a(1),P11_Y4=>n(3));
 nand4: entity work.LS20 port map(P1_A1=>a(0),P2_B1=>a(1),P4_C1=>a(2),P5_D1=>a(3),P6_Y1=>m(0),
 P9_D2=>a(3),P10_C2=>a(2),P12_B2=>a(1),P13_A2=>a(0),P8_Y2=>m(1));
 process begin
 for i in 0 to 15 loop
 a<=std_logic_vector(to_unsigned(i,4));wait for 1 ns;
 if i mod 4=3 then assert n="0000" severity failure; else assert n="1111" severity failure;end if;
 if i=15 then assert m="00" severity failure;else assert m="11" severity failure;end if;
 end loop;
 report "sound gate truth tables PASS";wait;
 end process;
end;
