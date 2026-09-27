library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity tb_GameControl is end;
architecture test of tb_GameControl is
    signal clk : std_logic := '0';
    signal coin, button, v32, v256, finish : std_logic := '0';
    signal credit, accepted, expired, presetn, start, startn, attract, attractn : std_logic_vector(0 to 1);
    signal done : boolean := false;
begin
    clk <= not clk after 5 ns when not done else '0';
    modes: for i in 0 to 1 generate
        constant one_play : std_logic := std_logic'val(i+2); -- 0: two plays, 1: one play
    begin
        c: entity work.CreditCircuit port map(clk,coin,one_play,v32,v256,attract(i),presetn(i),credit(i),accepted(i),expired(i));
        l: entity work.ElectronicLatchCircuit port map(clk,accepted(i),'0',expired(i),presetn(i));
        s: entity work.StartCircuit port map(clk,v256,credit(i),button,finish,presetn(i),start(i),startn(i),attract(i),attractn(i));
    end generate;
    process
        procedure tick(signal s : out std_logic) is
        begin s<='0'; wait for 30 ns; s<='1'; wait for 30 ns; s<='0'; wait for 30 ns; end;
    begin
        wait for 100 ns;
        assert attract="11" and credit="00" report "power-up must attract without credit" severity failure;
        button<='1'; tick(v256); button<='0'; tick(v256);
        assert attract="11" and start="00" report "unpaid start accepted" severity failure;
        coin<='1'; wait for 30 ns; tick(v32); tick(v32);
        assert accepted="00" report "coin accepted before count three" severity failure;
        coin<='0'; wait for 40 ns;
        assert credit="00" report "short coin accepted" severity failure;
        coin<='1'; wait for 30 ns; tick(v32); tick(v32); tick(v32);
        assert accepted="11" and presetn="11" report "valid coin did not release latch" severity failure;
        assert credit="00" report "start enabled before coin release" severity failure;
        coin<='0'; wait for 40 ns;
        assert credit="11" report "coin release did not enable start" severity failure;
        button<='1'; tick(v256);
        assert start="11" and attract="00" and attractn="11" report "paid start failed" severity failure;
        tick(v256);
        assert start="00" report "START must last one field even while held" severity failure;
        button<='0'; tick(v256);
        button<='1'; tick(v256);
        assert start="00" report "start during game restarted it" severity failure;
        button<='0'; tick(finish);
        assert attract="11" and credit="10" report "end game / plays-per-coin incorrect" severity failure;
        button<='1'; tick(v256); button<='0'; tick(v256);
        assert attract="01" report "second play entitlement incorrect" severity failure;
        tick(finish);
        assert attract="11" and credit="00" report "second game must exhaust two-play credit" severity failure;
        report "Figure 8 credit/start/latch tests passed";
        done<=true; wait;
    end process;
end;
