library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_IC9602 is
end tb_IC9602;

architecture sim of tb_IC9602 is
    constant CLK_PERIOD : time := 10 ns;
    signal clk          : std_logic := '0';
    signal CLR1n        : std_logic := '1';
    signal B1, A1       : std_logic := '0';
    signal Q1, Q1n      : std_logic;
    signal CLR2n        : std_logic := '1';
    signal B2, A2       : std_logic := '0';
    signal Q2, Q2n      : std_logic;
begin
    dut : entity work.IC9602
        generic map ( PULSE_WIDTH_CLKS => 10, PULSE_WIDTH_CLKS2 => 10 )
        port map (
            CLK      => clk,
            P3_CLR1n => CLR1n,
            P4_B1    => B1,
            P5_A1    => A1,
            P6_Q1    => Q1,
            P7_Q1n   => Q1n,
            P9_Q2n   => Q2n,
            P10_Q2   => Q2,
            P11_A2   => A2,
            P12_B2   => B2,
            P13_CLR2n => CLR2n,
            P1_CEXT1 => '0', P2_REXT1 => '0',
            P14_REXT2 => '0', P15_CEXT2 => '0'
        );

    clk <= not clk after CLK_PERIOD / 2;

    stimulus : process
    begin
        report "Starting IC9602 testbench (clock-driven)...";
        A1 <= '0'; B1 <= '1'; CLR1n <= '1';
        A2 <= '0'; B2 <= '1'; CLR2n <= '1';
        wait for 5 * CLK_PERIOD;

        -- Test 1: Clear
        CLR1n <= '0'; CLR2n <= '0';
        wait for 2 * CLK_PERIOD;
        assert (Q1 = '0' and Q2 = '0') report "Outputs should be low after clear" severity error;
        CLR1n <= '1'; CLR2n <= '1';
        wait for 2 * CLK_PERIOD;

        -- Test 2: Trigger ch1 with A1 rising
        A1 <= '1';
        wait for 2 * CLK_PERIOD;
        A1 <= '0';
        wait for CLK_PERIOD;
        assert (Q1 = '1') report "Q1 should be high after A1 rising trigger" severity error;
        wait for (10 + 2) * CLK_PERIOD;  -- pulse length + margin
        assert (Q1 = '0') report "Q1 should be low after pulse" severity error;

        -- Test 3: Trigger ch1 with B1 falling
        B1 <= '0';
        wait for 2 * CLK_PERIOD;
        B1 <= '1';
        wait for CLK_PERIOD;
        assert (Q1 = '1') report "Q1 should be high after B1 falling trigger" severity error;
        wait for (10 + 2) * CLK_PERIOD;
        assert (Q1 = '0') report "Q1 should be low after pulse" severity error;

        -- Test 4: Trigger ch2 with A2 rising
        A2 <= '1';
        wait for 2 * CLK_PERIOD;
        A2 <= '0';
        wait for CLK_PERIOD;
        assert (Q2 = '1') report "Q2 should be high after A2 rising trigger" severity error;
        wait for (10 + 2) * CLK_PERIOD;
        assert (Q2 = '0') report "Q2 should be low after pulse" severity error;

        report "All IC9602 clock-driven tests completed successfully!";
        wait;
    end process;

end architecture sim;
