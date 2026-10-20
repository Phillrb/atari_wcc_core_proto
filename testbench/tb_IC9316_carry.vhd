-- Exhaustive stable-pin equivalence for the FPGA carry implementation.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity tb_IC9316_carry is end;
architecture test of tb_IC9316_carry is
 signal clk : std_logic := '0';
 signal clr, ld, cep, cet : std_logic := '1';
 signal d : std_logic_vector(3 downto 0) := "0000";
 signal q_ref, q_safe : std_logic_vector(3 downto 0);
 signal rc_ref, rc_safe : std_logic;
begin
 reference: entity work.IC9316 port map(clr,clk,d(0),d(1),d(2),d(3),cep,ld,cet,
   q_ref(3),q_ref(2),q_ref(1),q_ref(0),rc_ref);
 safe: entity work.IC9316 generic map(REGISTERED_CARRY=>true)
 port map(clr,clk,d(0),d(1),d(2),d(3),cep,ld,cet,
   q_safe(3),q_safe(2),q_safe(1),q_safe(0),rc_safe);
 process
  procedure check is
  begin
   wait for 1 ns;
   assert q_ref=q_safe and rc_ref=rc_safe report "carry implementation differs" severity failure;
   assert (rc_safe='1') = (q_safe="1111" and cet='1') report "carry truth table" severity failure;
  end;
  procedure tick is
  begin
   clk<='1'; check; clk<='0'; check;
  end;
 begin
  clr<='0'; check; clr<='1'; check;
  for preset in 0 to 15 loop
   for enables in 0 to 3 loop
    d<=std_logic_vector(to_unsigned(preset,4));
    if enables mod 2=0 then cep<='0';else cep<='1';end if;
    if enables<2 then cet<='0';else cet<='1';end if;
    ld<='0';check;tick;
    assert unsigned(q_safe)=preset report "load must override enables" severity failure;
    ld<='1';check;tick;
    -- CET must suppress/reassert terminal carry without a clock; CEP must not.
    cep<='0';cet<='0';check;cet<='1';check;tick;
    cep<='1';check;
    for n in 1 to 17 loop tick; end loop;
    clr<='0';check;
    assert q_safe="0000" and rc_safe='0' report "asynchronous clear" severity failure;
    clr<='1';check;
   end loop;
  end loop;
  report "PASS: all presets/enables, load priority, rollover, CET gating and clear";
  wait;
 end process;
end;
