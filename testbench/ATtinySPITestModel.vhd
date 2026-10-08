-- Behavioral wire-level ATtiny84 model for the documented USI firmware.
-- Emulates delayed ISR preload, takes a packet snapshot at CS falling,
-- advances after complete bytes, and checks mode-0 clock/CS timing.
library ieee;
use ieee.std_logic_1164.all;
entity ATtinySPITestModel is
    port(CSn, SCLK, MOSI : in std_logic;
         PACKET : in std_logic_vector(63 downto 0);
         MISO : out std_logic);
end;
architecture test of ATtinySPITestModel is
begin
    process
        variable data : std_logic_vector(63 downto 0);
        variable selected_at, rose_at, fell_at, deselected_at : time := 0 ns;
        variable aborted : boolean;
    begin
        MISO<='1';
        wait until falling_edge(CSn);
        assert SCLK='0' report "mode 0 requires idle-low SCLK" severity failure;
        if deselected_at>0 ns then
            assert now-deselected_at>=1 ms report "insufficient ADC acquisition time between polls" severity failure;
        end if;
        selected_at:=now; data:=PACKET; aborted:=false;
        MISO<=data(63) after 50 us;
        for bit in 63 downto 0 loop
            wait until rising_edge(SCLK) or CSn='1';
            if CSn='1' then aborted:=true;exit;end if;
            if bit=63 then
                assert now-selected_at>=100 us report "CS setup shorter than firmware contract" severity failure;
            else
                assert now-fell_at>=4 us report "SCLK low pulse too short" severity failure;
                if bit mod 8=7 then
                    assert now-fell_at>=100 us report "missing USI inter-byte service pause" severity failure;
                end if;
            end if;
            assert MOSI='0' report "expected dummy zero MOSI" severity failure;
            rose_at:=now;
            wait until falling_edge(SCLK) or CSn='1';
            if CSn='1' then aborted:=true;exit;end if;
            assert now-rose_at>=4 us report "SCLK high pulse truncated" severity failure;
            fell_at:=now;
            if bit>0 then
                if bit mod 8=0 then MISO<=data(bit-1) after 50 us;
                else MISO<=data(bit-1) after 200 ns;end if;
            end if;
        end loop;
        if not aborted then
            wait until CSn='1' or rising_edge(SCLK);
            assert CSn='1' report "more than 64 clocks in packet" severity failure;
            assert now-fell_at>=100 us report "missing final-byte hold" severity failure;
        end if;
        deselected_at:=now;
        MISO<='1';
    end process;
end;
