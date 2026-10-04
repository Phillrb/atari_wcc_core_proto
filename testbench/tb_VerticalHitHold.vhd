-- Figures 17 -> 14: moving player data must not steer a non-contacting ball.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity tb_VerticalHitHold is end;
architecture test of tb_VerticalHitHold is
    signal ball, symbol, hit, hit_n, paddles : std_logic := '0';
    signal pp : std_logic_vector(2 downto 0) := "000";
    signal serve_n, bounce, stop : std_logic := '0';
    signal stop_n, v128_n : std_logic := '1';
    signal speed : std_logic_vector(3 downto 0);
begin
    summing: entity work.PlayersSumming
        port map(H1=>'0', V1=>'0', TEAM=>'0', DEFENSEMENn=>'1',
                 ONE_PLAYER=>'0', SYMBOL=>symbol, BALL=>ball,
                 PADDLES=>paddles, HIT=>hit);
    direction: entity work.VerticalDirectionAndSpeed
        port map(V128n=>v128_n, VBOUNCE=>bounce, HIT=>hit,
                 PP2=>pp(0), PP3=>pp(1), PP4=>pp(2), SERVEn=>serve_n,
                 STOPP=>stop, STOPn=>stop_n, VSPEED=>speed, HITn=>hit_n);
    process
        variable held : std_logic_vector(3 downto 0);
        variable expected : natural;
    begin
        -- Clock D6 to a known state while D7 is reset.
        v128_n <= '0'; wait for 20 ns;
        bounce <= '1'; wait for 20 ns; bounce <= '0';
        serve_n <= '1'; wait for 20 ns;
        assert speed="1101" report "serve motion code" severity failure;
        for segment in 0 to 7 loop
            held := speed;
            -- Player pixels without ball pixels: no collision anywhere on this scan.
            symbol <= '1'; ball <= '0';
            for moving in 0 to 7 loop
                pp <= std_logic_vector(to_unsigned(moving,3)); wait for 20 ns;
                assert hit='0' and hit_n='1' and speed=held
                    report "player data changed ball speed without contact" severity failure;
            end loop;
            -- Ball pixels outside the player window also cannot load D7.
            symbol <= '0'; wait for 20 ns; ball <= '1';
            for moving in 0 to 7 loop
                pp <= std_logic_vector(to_unsigned(moving,3)); wait for 20 ns;
                assert hit='0' and speed=held
                    report "ball outside player window changed speed" severity failure;
            end loop;
            -- Actual overlap loads the selected player segment.
            pp <= std_logic_vector(to_unsigned(segment,3)); wait for 20 ns;
            symbol <= '1'; wait for 20 ns;
            if segment < 4 then expected := 13-segment;
            else expected := 14-segment; end if;
            assert hit='1' and unsigned(speed)=expected
                report "real hit did not load player segment" severity failure;
            ball <= '0'; wait for 20 ns;
        end loop;
        -- Wall bounce and STOP remain independent of the player latch enable.
        v128_n <= '0'; bounce <= '1'; wait for 20 ns;
        assert speed="1101" report "wall bounce failed" severity failure;
        bounce <= '0'; stop <= '1'; stop_n <= '0'; wait for 20 ns;
        assert speed="1010" report "STOP motion code failed" severity failure;
        stop <= '0'; stop_n <= '1'; wait for 20 ns;
        assert speed="1101" report "STOP release changed stored motion" severity failure;
        serve_n <= '0'; wait for 20 ns;
        assert speed="0111" report "serve did not reset stored segment" severity failure;
        report "No-contact movement, all hit segments, bounce, STOP and serve passed";
        wait;
    end process;
end;
