-- Figures 14 + 16: verify scanline movement, not just adder output codes.
-- REQUIRE_REVERSAL=false records the original 313-line raster mismatch.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
entity tb_VerticalBallMotion is
    generic (REQUIRE_REVERSAL : boolean := true);
end;
architecture test of tb_VerticalBallMotion is
    signal clk, hs, motion_run, ball, hit, bounce, stop : std_logic := '0';
    signal manual_bounce, wall_bounce : std_logic := '0';
    signal stop_n, v128_n, ball_n, cd_n : std_logic := '1';
    signal wall_feedback : boolean := false;
    signal top_events, bottom_events : natural := 0;
    signal pp : std_logic_vector(2 downto 0) := "000";
    signal speed : std_logic_vector(3 downto 0);
    constant CAPTURE_LINES : integer := 180*313;
    signal done : boolean := false;
begin
    clk <= not clk after 5 ns when not done else '0';
    bounce <= wall_bounce when wall_feedback else manual_bounce;
    walls: entity work.WindowMissBounce
        port map(V64=>'0', H256n=>'0', ONE_PLAYER=>'0', ATRC=>'0', HOLE=>'0',
                 BALLn=>ball_n, A_PLUS_Bn=>'1', C_PLUS_Dn=>cd_n,
                 WINDOWS=>open, WINDOWSn=>open, V_BOUNCE=>wall_bounce,
                 H_BOUNCE=>open, BOUNCEn=>open, MISS=>open);
    wall_monitor: process(wall_bounce)
    begin
        if wall_feedback and rising_edge(wall_bounce) then
            if v128_n='1' then top_events<=top_events+1;
            else bottom_events<=bottom_events+1; end if;
        end if;
    end process;
    direction: entity work.VerticalDirectionAndSpeed
        port map(V128n=>v128_n, VBOUNCE=>bounce, HIT=>hit,
                 PP2=>pp(0), PP3=>pp(1), PP4=>pp(2), SERVEn=>'1',
                 STOPP=>stop, STOPn=>stop_n, VSPEED=>speed, HITn=>open);
    motion: entity work.BallMotionCircuit
        port map(CLOCK_7=>clk, HSYNCn=>hs, HBLANKn=>'1', SERVE=>motion_run,
                 HSPEED=>"1010", VSPEED=>speed, BALL=>ball,
                 BALLn=>ball_n, HIT_TONE=>open);
    process
        file trace : text open write_mode is "vertical_ball_periods.csv";
        file trajectory : text open write_mode is "vertical_ball_trajectory.csv";
        variable row : line;
        variable original_code, magnitude : integer;
        variable raster_line : natural;
        variable trajectory_seen : boolean;
        procedure measure(label_text : string; expected_drift : integer) is
            variable seen, previous : boolean := false;
            variable last_line, pulses, period : integer := 0;
        begin
            -- Preserve direction while restarting the motion counters.
            motion_run<='0'; hs<='0'; wait for 100 ns; motion_run<='1';
            for scanline in 1 to 1600 loop
                hs<='0'; wait for 50 ns; hs<='1'; seen:=false;
                -- Enough clocks to observe at least one horizontal ball window.
                for pixel in 1 to 455 loop
                    wait for 10 ns;
                    if ball='1' then seen:=true; end if;
                end loop;
                if seen and not previous then
                    pulses:=pulses+1;
                    if pulses=3 then
                        period:=scanline-last_line;
                        report label_text & ": code=" & integer'image(to_integer(unsigned(speed))) &
                            " period=" & integer'image(period) &
                            " drift=" & integer'image(period-313) &
                            " expected=" & integer'image(expected_drift);
                        write(row,label_text & "," & integer'image(to_integer(unsigned(speed))) &
                            "," & integer'image(period) & "," & integer'image(period-313) &
                            "," & integer'image(expected_drift));
                        writeline(trace,row);
                        assert not REQUIRE_REVERSAL or period-313=expected_drift
                            report label_text & ": vertical motion disagrees with STOP/wall direction"
                            severity failure;
                        exit;
                    end if;
                    last_line:=scanline;
                end if;
                previous:=seen;
            end loop;
            assert pulses=3 report "ball window missing" severity failure;
        end procedure;
    begin
        write(row,string'("case,code,period_lines,drift_lines,expected_drift")); writeline(trace,row);
        hit<='1'; wait for 50 ns; hit<='0';
        stop<='1'; stop_n<='0'; wait for 50 ns;
        measure("STOP",0);
        stop<='0'; stop_n<='1'; wait for 50 ns;
        for segment in 0 to 7 loop
            pp<=std_logic_vector(to_unsigned(segment,3)); hit<='1'; wait for 50 ns;
            hit<='0'; wait for 50 ns;
            if segment<4 then original_code:=13-segment;
            else original_code:=14-segment; end if;
            magnitude:=abs(original_code-10);
            measure("hit" & integer'image(segment),10-original_code);
            v128_n<='1'; wait for 50 ns; manual_bounce<='1'; wait for 50 ns;
            manual_bounce<='0'; wait for 50 ns;
            measure("top" & integer'image(segment),magnitude);
            v128_n<='0'; wait for 50 ns; manual_bounce<='1'; wait for 50 ns;
            manual_bounce<='0'; wait for 50 ns;
            measure("bottom" & integer'image(segment),-magnitude);
        end loop;
        report "Vertical ball period measurements complete";
        -- Close the Figure 19 -> 14 -> 16 feedback loop over 180 PAL fields.
        -- Testbench supplies the Figure 9 wall coordinates and 128V polarity.
        -- Align the first ball window near mid-field, clear of either wall.
        pp<="000"; hit<='1'; motion_run<='0'; hs<='0'; wait for 100 ns;
        hit<='0'; motion_run<='1'; wall_feedback<=true;
        write(row,string'("frame,line,ball")); writeline(trajectory,row);
        for scanline in 0 to CAPTURE_LINES-1 loop
            raster_line:=(scanline+225) mod 313;
            if raster_line<128 then v128_n<='1'; else v128_n<='0'; end if;
            if (raster_line>=80 and raster_line<=83) or
               (raster_line>=240 and raster_line<=243) then cd_n<='0';
            else cd_n<='1'; end if;
            hs<='0'; wait for 50 ns; hs<='1'; trajectory_seen:=false;
            for pixel in 1 to 455 loop
                wait for 10 ns;
                if ball='1' then trajectory_seen:=true; end if;
            end loop;
            if trajectory_seen then
                write(row,integer'image((scanline+225)/313) & "," & integer'image(raster_line) & ",1");
                writeline(trajectory,row);
                assert not REQUIRE_REVERSAL or (raster_line>=77 and raster_line<=246)
                    report "ball escaped the vertical playfield" severity failure;
            end if;
        end loop;
        assert not REQUIRE_REVERSAL or (top_events>0 and bottom_events>0)
            report "closed loop failed to reach both walls" severity failure;
        report "Closed-loop vertical bounce capture complete: top pixels=" & integer'image(top_events) &
            " bottom pixels=" & integer'image(bottom_events);
        done <= true;
        wait;
    end process;
end;
