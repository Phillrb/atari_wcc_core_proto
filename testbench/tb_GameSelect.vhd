library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity tb_GameSelect is end;
architecture test of tb_GameSelect is
    signal clk : std_logic := '0';
    signal switch_n : std_logic := '1';
    signal selected, mode : std_logic;
    signal play : std_logic := '0';
begin
    clk <= not clk after 5 ns;
    adapter: entity work.JammaSwitchAdapter
        generic map(STABLE_CLOCKS=>4)
        port map(clk, switch_n, selected);
    circuit: entity work.GameSelectCircuit port map(selected, play, mode);
    process
    begin
        wait for 100 ns;
        assert mode='0' and selected='0' severity failure;
        switch_n <= '0'; wait for 100 ns;
        assert selected='1' and mode='0' report "attract must suppress 1P" severity failure;
        play <= '1'; wait for 1 ns;
        assert mode='1' report "paid play must enable selected 1P" severity failure;
        switch_n <= '1'; wait for 10 ns; switch_n <= '0'; wait for 100 ns;
        assert mode='1' report "short contact bounce changed mode" severity failure;
        switch_n <= '1'; wait for 100 ns;
        assert mode='0' report "runtime 2P selection failed" severity failure;
        switch_n <= '0'; wait for 100 ns;
        assert mode='1' report "runtime 1P selection failed" severity failure;
        play <= '0'; wait for 1 ns;
        assert mode='0' report "expiry must restore 2P attract" severity failure;
        report "Game selector debounce, runtime transitions and attract gating passed";
        wait;
    end process;
end;
