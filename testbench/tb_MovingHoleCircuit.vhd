-- Figure 18 pin-netlist regression. Timing expectations follow the confirmed
-- 9/11 presets, not the inconsistent numeric values in the manual prose.
library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
entity tb_MovingHoleCircuit is end;
architecture test of tb_MovingHoleCircuit is
    constant SCAN_LINES : integer := 313*400;
    signal hs_n : std_logic := '0';
    signal start_n : std_logic := '0';
    signal boundary_n : std_logic := '1';
    signal v128 : std_logic := '0';
    signal hole : std_logic;
    signal windows, windows_n : std_logic;
    signal one_player : std_logic := '1';
    signal h256n : std_logic := '0';
    signal v64 : std_logic := '0';
    signal attract : std_logic := '0';
begin
    DUT: entity work.MovingHoleCircuit
        port map(C_PLUS_Dn=>boundary_n, HSYNCn=>hs_n, STARTn=>start_n,
                 V128=>v128, HOLE=>hole);
    WINDOW_DUT: entity work.WindowMissBounce
        port map(V64=>v64, H256n=>h256n, ONE_PLAYER=>one_player,
                 ATRC=>attract, HOLE=>hole, BALLn=>'1',
                 A_PLUS_Bn=>'1', C_PLUS_Dn=>boundary_n,
                 WINDOWS=>windows, WINDOWSn=>windows_n,
                 V_BOUNCE=>open, H_BOUNCE=>open, BOUNCEn=>open, MISS=>open);
    stimulus: process
        file trace : text open write_mode is "moving_hole_trace.csv";
        variable row : line;
        variable width, previous_rise, rise_count : integer := 0;
        variable previous_hole : std_logic := '0';
        procedure tick is
        begin
            hs_n<='0'; wait for 10 ns;
            hs_n<='1'; wait for 10 ns;
        end procedure;
        procedure reset is
        begin
            hs_n<='0'; start_n<='0'; wait for 10 ns;
            assert hole='0' report "STARTn must asynchronously clear HOLE" severity failure;
            for i in 1 to 20 loop
                tick;
                assert hole='0' report "HOLE asserted while reset held" severity failure;
            end loop;
            start_n<='1'; wait for 10 ns;
        end procedure;
        procedure expect_first_pulse is
        begin
            for i in 1 to 495 loop
                tick;
                assert hole='0' report "HOLE asserted before count 496" severity failure;
            end loop;
            tick;
            assert hole='1' report "HOLE missing at count 496" severity failure;
        end procedure;
        procedure finish_pulse is
        begin
            for i in 1 to 15 loop
                tick;
                assert hole='1' report "HOLE shorter than sixteen lines" severity failure;
            end loop;
            tick;
            assert hole='0' report "HOLE longer than sixteen lines" severity failure;
        end procedure;
        procedure next_pulse(period : positive) is
        begin
            -- Called immediately after the sixteen-line pulse finishes.
            for i in 1 to period-17 loop
                tick;
                assert hole='0' report "HOLE recurrence too early" severity failure;
            end loop;
            tick;
            assert hole='1' report "HOLE recurrence too late" severity failure;
        end procedure;
    begin
        reset;
        expect_first_pulse;
        assert windows='1' and windows_n='0'
            report "Figure 19 must accept positive HOLE on the right" severity failure;
        -- Sample bottom boundary (V128=1), choosing preset 11.
        v128<='1'; wait for 2 ns; boundary_n<='0'; wait for 2 ns;
        boundary_n<='1'; wait for 2 ns;
        finish_pulse;
        assert windows='0' report "Right opening remained asserted" severity failure;
        next_pulse(309);
        -- Sample top boundary (V128=0), choosing preset 9.
        v128<='0'; wait for 2 ns; boundary_n<='0'; wait for 2 ns;
        boundary_n<='1'; wait for 2 ns;
        finish_pulse;
        -- Boundary while HOLE is absent must not change K1.
        v128<='1'; wait for 2 ns; boundary_n<='0'; wait for 2 ns;
        boundary_n<='1'; wait for 2 ns;
        next_pulse(311);
        -- Reset during a pulse; counters reset, K1 direction remains intact.
        reset;
        expect_first_pulse;
        finish_pulse;
        next_pulse(311);
        v128<='1'; wait for 2 ns; boundary_n<='0'; wait for 2 ns;
        boundary_n<='1'; wait for 2 ns;
        reset;
        expect_first_pulse;
        finish_pulse;
        next_pulse(309);

        -- Figure 19 mode/attract gating, independent of moving-hole phase.
        one_player<='0'; v64<='0'; wait for 2 ns;
        assert windows='1' report "Two-player fixed opening absent" severity failure;
        v64<='1'; wait for 2 ns;
        assert windows='0' report "Two-player path depends on HOLE" severity failure;
        one_player<='1'; h256n<='1'; v64<='0'; wait for 2 ns;
        assert windows='1' report "One-player left fixed opening absent" severity failure;
        v64<='1'; wait for 2 ns;
        assert windows='0' report "Left opening ignores V64" severity failure;
        attract<='1'; wait for 2 ns;
        assert windows='0' report "Attract must suppress openings" severity failure;
        attract<='0'; h256n<='0';

        -- Long scan: 400 PAL fields, including boundary sampling. Export actual
        -- DUT signal samples for a diagnostic animation, not an invented path.
        reset;
        write(row, string'("frame,line,hole")); writeline(trace,row);
        for n in 0 to SCAN_LINES-1 loop
            if (n mod 313)/128 mod 2=1 then v128<='1'; else v128<='0'; end if;
            if (n mod 313>=80 and n mod 313<=83) or
               (n mod 313>=240 and n mod 313<=243) then
                boundary_n<='0';
            else boundary_n<='1'; end if;
            tick;
            if hole='1' then
                width:=width+1;
                if previous_hole='0' then
                    if rise_count>0 then
                        assert n-previous_rise=309 or n-previous_rise=311
                            report "Unexpected recurrence in long scan" severity failure;
                    end if;
                    previous_rise:=n; rise_count:=rise_count+1;
                end if;
            elsif previous_hole='1' then
                assert width=16 report "Long-scan pulse width is not 16" severity failure;
                width:=0;
            end if;
            previous_hole:=hole;
            assert windows=hole report "Right window polarity mismatch" severity failure;
            write(row,n/313); write(row,string'(",")); write(row,n mod 313);
            write(row,string'(","));
            if hole='1' then write(row,1); else write(row,0); end if;
            writeline(trace,row);
        end loop;
        assert rise_count>390 report "Long scan did not exercise repeated pulses" severity failure;
        report "Moving-hole reset, width, presets, boundary gating, mode and long-scan tests passed";
        wait;
    end process;
end test;
