-- LS90 pin-level regression: independent /2 and /5 sections, BCD feedback,
-- paired asynchronous controls and repeated 9 -> 0 rollovers.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_LS90 is end tb_LS90;
architecture Test of tb_LS90 is
    signal cp0, cp1 : std_logic := '1';
    signal mr1, mr2, ms1, ms2 : std_logic := '0';
    signal feedback : boolean := true;
    signal q0, q1, q2, q3, cp1_pin : std_logic;
    signal value : std_logic_vector(3 downto 0);
begin
    cp1_pin <= q0 when feedback else cp1;
    value <= q3 & q2 & q1 & q0;
    DUT: entity work.LS90 port map(
        P14_CP0n=>cp0, P1_CP1n=>cp1_pin,
        P2_MR1=>mr1, P3_MR2=>mr2, P6_MS1=>ms1, P7_MS2=>ms2,
        P12_Q0=>q0, P9_Q1=>q1, P8_Q2=>q2, P11_Q3=>q3);
    stimulus: process
        procedure check(expected : natural) is
        begin
            assert value=std_logic_vector(to_unsigned(expected,4))
                report "LS90 expected " & integer'image(expected) &
                       ", got " & integer'image(to_integer(unsigned(value))) severity failure;
        end;
        procedure pulse(signal clk : out std_logic) is
        begin clk<='0'; wait for 20 ns; clk<='1'; wait for 20 ns; end;
        procedure reset_counter is
        begin mr1<='1'; mr2<='1'; wait for 20 ns; check(0);
              mr1<='0'; mr2<='0'; wait for 20 ns; end;
    begin
        reset_counter;
        for i in 1 to 35 loop pulse(cp0); check(i mod 10); end loop;
        -- One reset input alone must leave a nonzero count unchanged.
        mr1<='1'; wait for 20 ns; check(5); mr1<='0'; wait for 20 ns;
        mr2<='1'; wait for 20 ns; check(5); mr2<='0'; wait for 20 ns;
        -- Neither set input alone is sufficient either.
        ms1<='1'; wait for 20 ns; check(5); ms1<='0'; wait for 20 ns;
        ms2<='1'; wait for 20 ns; check(5);
        ms1<='1'; wait for 20 ns; check(9);
        pulse(cp0); check(9); -- set dominates clock
        ms1<='0'; ms2<='0'; wait for 20 ns;
        pulse(cp0); check(0); -- first edge after release wraps 9 -> 0
        for i in 1 to 9 loop pulse(cp0); check(i); end loop;
        reset_counter; -- reset while Q3 is high
        pulse(cp0); check(1);
        reset_counter;
        feedback<=false; wait for 20 ns;
        for i in 1 to 6 loop pulse(cp0); check(i mod 2); end loop;
        -- /5 state, expressed in output bit positions: 0,2,4,6,8,0.
        for i in 1 to 15 loop pulse(cp1); check(2*(i mod 5)); end loop;
        mr1<='1'; mr2<='1'; wait for 20 ns;
        pulse(cp0); pulse(cp1); check(0); -- reset dominates both clocks
        mr1<='0'; mr2<='0'; wait for 20 ns;
        feedback<=true; wait for 20 ns;
        reset_counter;
        for i in 1 to 30 loop pulse(cp0); check(i mod 10); end loop;
        report "LS90 paired controls, independent sections and BCD rollover passed";
        wait;
    end process;
end Test;
