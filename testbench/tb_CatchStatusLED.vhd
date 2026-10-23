library ieee;
use ieee.std_logic_1164.all;
entity tb_CatchStatusLED is end;
architecture test of tb_CatchStatusLED is
    signal mode, solid, checked, stopn, ledn : std_logic := '0';
begin
    dut: entity work.CatchStatusLED port map(mode,solid,checked,stopn,ledn);
    process
    begin
        for m in 0 to 1 loop
            for s in 0 to 1 loop
                for c in 0 to 1 loop
                    for n in 0 to 1 loop
                        mode<=std_logic'val(m+2); solid<=std_logic'val(s+2);
                        checked<=std_logic'val(c+2); stopn<=std_logic'val(n+2);
                        wait for 10 ns;
                        if m=0 then
                            assert ledn=stopn report "2P LED must display STOP" severity failure;
                        else
                            assert (ledn='0')=(s=1 or c=1)
                                report "1P LED must display either kick" severity failure;
                        end if;
                    end loop;
                end loop;
            end loop;
        end loop;
        report "PASS: diagnostic LED truth table (both modes, both kicks, STOP)";
        wait;
    end process;
end;
