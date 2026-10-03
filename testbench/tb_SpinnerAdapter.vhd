library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity tb_SpinnerAdapter is end;
architecture test of tb_SpinnerAdapter is
    signal clk : std_logic := '0';
    signal reset_n : std_logic := '0';
    signal a,b,vs : std_logic := '0';
    signal count, position, reverse_count : std_logic_vector(9 downto 0);
begin
    clk <= not clk after 10 ns;
    dut: entity work.SpinnerAdapter
        port map(clk,reset_n,a,b,vs,count,position);
    backwards: entity work.SpinnerAdapter
        generic map(REVERSE_DIRECTION=>true)
        port map(clk,reset_n,a,b,vs,reverse_count,open);
    process
        procedure state(value : std_logic_vector(1 downto 0)) is
        begin a<=value(1); b<=value(0); wait for 200 ns; end;
        procedure turn(up : boolean) is
        begin
            if up then state("01");state("11");state("10");state("00");
            else state("10");state("11");state("01");state("00"); end if;
        end;
        procedure frame is
        begin vs<='1';wait for 100 ns;vs<='0';wait for 100 ns;end;
    begin
        -- All four startup phase combinations must seed history without counting.
        for initial in 0 to 3 loop
            reset_n<='0'; state(std_logic_vector(to_unsigned(initial,2)));
            reset_n<='1'; wait for 400 ns;
            assert unsigned(count)=512 report "phantom startup count" severity failure;
        end loop;
        reset_n<='0';state("00");reset_n<='1';wait for 400 ns;
        turn(true);
        assert unsigned(count)=520 and unsigned(reverse_count)=504
            report "direction / x1 counting failed" severity failure;
        turn(false);
        assert unsigned(count)=512 report "reverse step failed" severity failure;
        -- Invalid simultaneous phase changes and short unsampled glitches.
        state("11");state("00");
        assert unsigned(count)=512 report "invalid transition counted" severity failure;
        wait until falling_edge(clk);a<='1';wait for 1 ns;a<='0';wait for 200 ns;
        assert unsigned(count)=512 report "sub-clock glitch counted" severity failure;
        for i in 1 to 150 loop turn(true);end loop;
        assert unsigned(count)=1023 and unsigned(reverse_count)=0
            report "upper saturation / reverse lower saturation failed" severity failure;
        assert unsigned(position)=118 report "position changed mid-frame" severity failure;
        frame;
        assert unsigned(position)=154 report "upper position mapping failed" severity failure;
        turn(false);
        assert unsigned(count)=1015 report "cannot leave upper stop" severity failure;
        for i in 1 to 150 loop turn(false);end loop;
        assert unsigned(count)=0 and unsigned(reverse_count)=1023
            report "lower saturation failed" severity failure;
        frame;
        assert unsigned(position)=82 report "lower position mapping failed" severity failure;
        turn(true);
        assert unsigned(count)=8 report "cannot leave lower stop" severity failure;
        reset_n<='0';wait for 200 ns;
        assert unsigned(count)=512 and unsigned(position)=118
            report "reset did not recenter" severity failure;
        report "Spinner startup, direction, invalid edges, limits, frame latch and reset passed";
        wait;
    end process;
end;
