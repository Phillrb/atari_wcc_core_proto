library ieee;
use ieee.std_logic_1164.all;
entity tb_LS107_master_slave is end;
architecture test of tb_LS107_master_slave is
    signal j, k, clk : std_logic := '0';
    signal clear_n : std_logic := '0';
    signal q1, q1n, q2, q2n : std_logic;
begin
    DUT: entity work.LS107 generic map(MASTER_SLAVE=>true)
        port map(P1_J1=>j, P4_K1=>k, P12_CLK1=>clk, P13_CLR1n=>clear_n,
                 P3_Q1=>q1, P2_Q1n=>q1n,
                 P8_J2=>j, P11_K2=>k, P9_CLK2=>clk, P10_CLR2n=>clear_n,
                 P5_Q2=>q2, P6_Q2n=>q2n);
    process
        procedure check(value : std_logic) is
        begin
            assert q1=value and q2=value and q1n=not value and q2n=not value
                report "74107 state/complement mismatch" severity failure;
        end procedure;
        procedure pulse(expected : std_logic) is
        begin
            clk<='1'; wait for 5 ns;
            clk<='0'; wait for 5 ns;
            check(expected);
        end procedure;
    begin
        wait for 5 ns; check('0'); clear_n<='1'; wait for 5 ns;
        j<='1'; k<='0'; pulse('1');
        j<='0'; k<='0'; pulse('1');
        j<='0'; k<='1'; pulse('0');
        j<='1'; k<='1'; pulse('1'); pulse('0');
        -- Simultaneous carry/clock transition: data AFTER the master's closing
        -- edge must not replace the stable data from its high-clock interval.
        j<='0'; k<='0'; clk<='1'; wait for 5 ns;
        clk<='0'; j<='1'; k<='1'; wait for 5 ns; check('0');
        pulse('1');
        clk<='1'; wait for 5 ns;
        clear_n<='0'; wait for 5 ns; check('0');
        clk<='0'; wait for 5 ns; check('0');
        clear_n<='1'; j<='0'; k<='0'; pulse('0');
        report "Original 74107 master/slave truth table, carry race and async clear passed";
        wait;
    end process;
end;
