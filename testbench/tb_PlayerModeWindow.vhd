-- Figure 11: one-player mode suppresses checked-team symbol windows.
-- Compare both modes over actual horizontal timing, after ripple signals settle.
library ieee;
use ieee.std_logic_1164.all;
entity tb_PlayerModeWindow is end;
architecture test of tb_PlayerModeWindow is
    signal clk : std_logic := '0';
    signal h4, h8, reset, reset_n : std_logic;
    signal team, goalie, defense_n, window_n : std_logic_vector(0 to 1);
    signal done : boolean := false;
begin
    clk <= not clk after 70 ns when not done else '0';
    sync: entity work.HorizontalSync
        port map(CLOCK_7=>clk, HSYNC=>open, HSYNCn=>open,
            H1=>open, H2=>open, H4=>h4, H8=>h8, H16=>open, H32=>open,
            H64=>open, H64n=>open, H128=>open, H256=>open, H256n=>open,
            HRESET=>reset, HRESETn=>reset_n, HBLANK=>open, HBLANKn=>open);
    modes: for mode in 0 to 1 generate
        constant selection : std_logic := std_logic'val(mode+2);
    begin
        DUT: entity work.PlayersVerticalWindow
            port map(H4=>h4, H8=>h8, HRESET=>reset, HRESETn=>reset_n,
                H_ENABLE=>'1', V_ENABLE=>'1', PLAYER=>selection,
                TEAM=>team(mode), GOALIE=>goalie(mode), DEFENSEMENn=>defense_n(mode),
                Q=>open, Qn=>open, BLIP=>open, PLAYER_WINDOWn=>window_n(mode));
    end generate;
    checks: process
        variable solid_samples, checked_samples : natural := 0;
    begin
        -- Skip power-up and inspect four complete horizontal lines.
        wait for 64 us;
        for pixel in 1 to 1820 loop
            wait until falling_edge(clk);
            wait for 1 ns;
            assert team(0)=team(1) and goalie(0)=goalie(1) and defense_n(0)=defense_n(1)
                report "Mode selection changed player role decoding" severity failure;
            if team(0)='1' then
                assert window_n(1)='1'
                    report "Checked window survived one-player mode" severity failure;
                if window_n(0)='0' then checked_samples:=checked_samples+1; end if;
            else
                assert window_n(1)=window_n(0)
                    report "One-player mode suppressed a solid-team window" severity failure;
                if window_n(1)='0' then solid_samples:=solid_samples+1; end if;
            end if;
        end loop;
        assert solid_samples>0 and checked_samples>0
            report "Both teams must be exercised" severity failure;
        report "One-player windows suppress checked team and preserve solid team; two-player windows cover both";
        done<=true;
        wait;
    end process;
end;
