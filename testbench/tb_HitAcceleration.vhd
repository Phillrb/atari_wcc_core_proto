library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity tb_HitAcceleration is end;
architecture test of tb_HitAcceleration is
    signal clk : std_logic := '0';
    signal done : boolean := false;
    signal ball, blip, hit, sampled_hit : std_logic := '0';
    signal eligible, team, stopn, vr : std_logic := '1';
    signal goal, attract, mode, direction : std_logic := '0';
    signal score_n, trigger, slow, clear_n, unused_dir : std_logic;
    signal hit_q : std_logic_vector(1 downto 0);
    signal speed : std_logic_vector(3 downto 0);
begin
    clk <= not clk after 5 ns when not done else '0';
    score_n <= not goal;
    sampled_hit <= hit_q(0);
    sample_hit: entity work.CollisionSampleBank generic map(WIDTH=>2)
        port map(SAMPLE_CLK=>clk, D(0)=>hit, D(1)=>'0', Q=>hit_q);
    catch: entity work.CatchKickHorizontalDirection generic map(SAMPLE_COLLISIONS=>true)
        port map(SAMPLE_CLK=>clk, HIT_SAMPLED=>sampled_hit,
            BALL=>ball, BLIP=>blip, HIT=>hit, DEFENSEMENn=>eligible,
            TEAM=>team, ONE_PLAYER=>mode, WINDOWS=>'0', H256n=>'1',
            H_BOUNCE=>'0', VSYNCn=>'1', VRESET=>vr, STOP=>'0',
            SOLID_KICK=>'0', CHECKED_KICK=>'0', CATCH_TRIGGER=>trigger,
            CATCH_CLRn=>clear_n, HORIZ_DIR_Qn=>unused_dir);
    speed_circuit: entity work.HorizontalDirectionAndSpeed
        port map(VRESET=>vr, STOPn=>stopn, HORIZ_DIR=>direction,
            GOAL=>goal, SCORE_SOUNDn=>score_n, ONE_PLAYER=>mode,
            ATRC=>attract, GOALIE_FWD_HIT=>trigger, HSPEED=>speed, SLOW=>slow);
    process
        procedure check_count(n : natural) is
            variable code : natural;
        begin
            -- Figure 15 C/D decode, with approved base-9 raster adaptation.
            code := 2 + n/4;
            for d in 0 to 1 loop
                if d=0 then direction<='0'; else direction<='1'; end if;
                wait for 20 ns;
                if d=0 then
                    assert unsigned(speed)=9+code report "positive motion code mismatch" severity failure;
                else
                    assert unsigned(speed)=9-code report "negative motion code mismatch" severity failure;
                end if;
            end loop;
            if n=15 then assert slow='0' report "missing saturation/fast sound" severity failure;
            else assert slow='1' report "early saturation" severity failure; end if;
            stopn<='0'; wait for 20 ns;
            assert speed="1001" report "STOP must retain stationary preset" severity failure;
            stopn<='1'; vr<='0'; wait for 20 ns;
            assert speed="1001" report "speed leaked outside VRESET" severity failure;
            vr<='1'; wait for 20 ns;
        end;
        procedure contact(qualifies : std_logic) is
        begin
            hit<='0'; ball<='1'; blip<='1'; wait for 40 ns;
            assert trigger='1' report "D8 did not arm" severity failure;
            blip<='0'; eligible<=qualifies; hit<='1'; wait for 40 ns;
            if qualifies='1' then
                assert trigger='0' report "qualifying contact did not trigger" severity failure;
            else assert trigger='1' report "defender triggered catch" severity failure; end if;
            -- Held contact and repeated HIT edges without rearming must not count again.
            wait for 100 ns;
            hit<='0'; wait for 40 ns; hit<='1'; wait for 40 ns;
            hit<='0'; ball<='0'; wait for 40 ns;
        end;
        variable n : natural;
    begin
        wait for 40 ns;
        for m in 0 to 1 loop
            if m=0 then mode<='0'; else mode<='1'; end if;
            goal<='0'; wait for 30 ns; goal<='1'; wait for 30 ns;
            goal<='0'; wait for 30 ns;
            n:=4*m; check_count(n);
            contact('0'); check_count(n);
            for h in 1 to 18 loop
                if h mod 2=0 then team<='0'; else team<='1'; end if;
                contact('1');
                if n<15 then n:=n+1; end if;
                check_count(n);
            end loop;
            ball<='1'; blip<='1'; wait for 40 ns;
            ball<='0'; blip<='0'; wait for 40 ns;
            goal<='1'; wait for 40 ns; goal<='0'; wait for 40 ns;
            check_count(4*m);
        end loop;
        mode<='0'; attract<='1'; contact('1'); check_count(0);
        report "PASS: hit acceleration, defender exclusion, held contacts, saturation, presets, goal reset and STOP";
        done<=true; wait;
    end process;
end;
