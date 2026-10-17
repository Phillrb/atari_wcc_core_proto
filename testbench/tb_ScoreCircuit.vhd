-- Figure 21 regression against the actual ScoreCircuit (no substitute counter).
-- VCD observations are checked by sim/check_score.py. Pixel captures are the
-- DUT's SCORE output, with timeline/playfield inactive and display enabled.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
entity tb_ScoreCircuit is end tb_ScoreCircuit;
architecture Test of tb_ScoreCircuit is
    signal h, v : std_logic_vector(8 downto 0) := (others=>'0');
    signal miss, start : std_logic := '0';
    signal score, h256n, startn : std_logic;
    signal expected_solid, expected_checks : natural := 0;
    signal sample_scores : std_logic := '0';
begin
    h256n <= not h(8);
    startn <= not start;
    DUT: entity work.ScoreCircuit port map(
        H2=>h(1), H4=>h(2), H8=>h(3), H16=>h(4), H32=>h(5),
        H64=>h(6), H128=>h(7), H256=>h(8), H256n=>h256n,
        V2=>v(1), V4=>v(2), V8=>v(3), V16=>v(4), V32=>v(5),
        V64=>v(6), V128=>v(7), MISS=>miss, START=>start, STARTn=>startn,
        SERVE=>'0', ATRCn=>'1', TIME_LINEn=>'1', PLAYFIELDn=>'1', SCORE=>score);
    stimulus: process
        file pixels : text open write_mode is "score_pixels.txt";
        variable row : line;
        procedure sample is
        begin
            wait for 100 ns; sample_scores<='1'; wait for 100 ns;
            sample_scores<='0'; wait for 100 ns;
        end;
        procedure reset_score is
        begin
            start<='1'; expected_solid<=0; expected_checks<=0;
            wait for 1 us; sample;
            start<='0'; wait for 1 us; sample;
        end;
        procedure goal(solid : boolean; expected : natural) is
        begin
            if solid then h<=std_logic_vector(to_unsigned(407,9));
            else h<=std_logic_vector(to_unsigned(143,9)); end if;
            wait for 1 us;
            miss<='1'; wait for 140 ns; miss<='0';
            if solid then expected_solid<=expected;
            else expected_checks<=expected; end if;
            sample;
        end;
        procedure capture(n : natural) is
        begin
            write(row,n); writeline(pixels,row);
            for y in 88 to 119 loop
                v<=std_logic_vector(to_unsigned(y,9));
                for x in 144 to 399 loop
                    h<=std_logic_vector(to_unsigned(x,9)); wait for 140 ns;
                    assert score='0' or score='1' report "Unknown score pixel" severity failure;
                    if score='1' then write(row,character'('1'));
                    else write(row,character'('0')); end if;
                end loop;
                writeline(pixels,row);
            end loop;
            sample; -- raster scanning must not change either counter
        end;
    begin
        reset_score;
        for i in 1 to 21 loop
            goal(true,i mod 20);
            if i>=8 and i<=12 then capture(i); end if;
        end loop;
        -- Exercise the second copy at the score-circuit input, independently
        -- of the separate gameplay problem where checks cannot reach a goal.
        for i in 1 to 21 loop goal(false,i mod 20); end loop;
        reset_score;
        for i in 1 to 12 loop goal(true,i); end loop;
        reset_score; -- reset while tens and units are nonzero
        goal(true,1);
        report "Score stimulus complete: verify VCD with check_score.py";
        wait;
    end process;
end Test;
