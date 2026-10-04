-- Exhaustive binary truth table, each channel and previous output state.
-- Reference: IC/data/9314.PDF, page 3. Pin 1 is latch enable, not output enable.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity tb_IC9314 is end;
architecture test of tb_IC9314 is
    signal enable_n, reset_n : std_logic := '1';
    signal d, s : std_logic_vector(3 downto 0) := "1111";
    signal q : std_logic_vector(3 downto 0);
begin
    dut: entity work.IC9314
        port map(P1_OEn=>enable_n, P2_S0n=>s(0), P3_D0=>d(0),
                 P4_D1=>d(1), P5_S2n=>s(2), P6_D2=>d(2), P7_D3=>d(3),
                 P9_MRn=>reset_n, P10_Q3=>q(3), P11_S3n=>s(3),
                 P12_Q2=>q(2), P13_Q1=>q(1), P14_S1n=>s(1), P15_Q0=>q(0));
    process
        variable inputs : std_logic_vector(3 downto 0);
        variable previous, expected : std_logic_vector(3 downto 0);
    begin
        for initial in 0 to 15 loop
            for channel in 0 to 3 loop
                for combination in 0 to 15 loop
                    previous := std_logic_vector(to_unsigned(initial,4));
                    -- Seed any previous output pattern in D mode.
                    reset_n <= '1'; enable_n <= '0'; s <= "0000"; d <= previous;
                    wait for 10 ns;
                    assert q=previous report "transparent D mode failed" severity failure;
                    enable_n <= '1'; wait for 10 ns;
                    -- Other channels retain their current state in R/S mode.
                    s <= "1111"; d <= "1111";
                    inputs := std_logic_vector(to_unsigned(combination,4));
                    reset_n <= inputs(3); enable_n <= inputs(2);
                    d(channel) <= inputs(1); s(channel) <= inputs(0);
                    expected := previous;
                    if inputs(3)='0' then expected := "0000";
                    elsif inputs(2)='0' then
                        if inputs(1)='0' then expected(channel):='0';
                        elsif inputs(0)='0' then expected(channel):='1'; end if;
                    end if;
                    wait for 10 ns;
                    assert q=expected report "9314 truth table failed" severity failure;
                end loop;
            end loop;
        end loop;
        -- Data must continue to follow while enabled, then hold when disabled.
        reset_n<='1'; enable_n<='0'; s<="0000"; d<="1010"; wait for 10 ns;
        assert q="1010" severity failure;
        d<="0101"; wait for 10 ns; assert q="0101" severity failure;
        enable_n<='1'; wait for 10 ns; d<="1111"; wait for 10 ns;
        assert q="0101" report "disabled latch did not hold driven outputs" severity failure;
        reset_n<='0'; wait for 10 ns; assert q="0000" severity failure;
        reset_n<='1'; wait for 10 ns;
        assert q="0000" report "reset release loaded disabled latch" severity failure;
        report "9314 exhaustive truth table, transparency, hold and reset passed";
        wait;
    end process;
end;
