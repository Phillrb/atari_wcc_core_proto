library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity tb_JammaSwitchAdapter is end;
architecture test of tb_JammaSwitchAdapter is
    signal clk : std_logic := '0';
    signal sw : std_logic := '1';
    signal pressed : std_logic;
    signal done : boolean := false;
begin
    clk <= not clk after 5 ns when not done else '0';
    dut: entity work.JammaSwitchAdapter generic map(STABLE_CLOCKS=>4)
        port map(clk, sw, pressed);
    process
    begin
        wait for 30 ns;
        assert pressed='0' report "idle must not press" severity failure;
        sw<='0'; wait for 20 ns; sw<='1'; wait for 80 ns;
        assert pressed='0' report "short contact bounce accepted" severity failure;
        sw<='0'; wait for 80 ns;
        assert pressed='1' report "stable active-low press lost" severity failure;
        sw<='1'; wait for 20 ns; sw<='0'; wait for 80 ns;
        assert pressed='1' report "release bounce accepted" severity failure;
        wait for 100 ns;
        assert pressed='1' report "held switch must remain pressed" severity failure;
        sw<='1'; wait for 80 ns;
        assert pressed='0' report "release lost" severity failure;
        report "JAMMA switch synchronization/debounce tests passed";
        done<=true; wait;
    end process;
end;
