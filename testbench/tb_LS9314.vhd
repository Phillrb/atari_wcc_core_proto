library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_LS9314 is
end tb_LS9314;

architecture sim of tb_LS9314 is
    -- Test signals
    signal clk, rst, enp, ent, ld : std_logic := '0';
    signal a, b, c : std_logic := '0';
    signal q0, q1, q2, q3, tc : std_logic;
    signal count_output : std_logic_vector(3 downto 0);
    
    -- Component declaration
    component LS9314 is
        Port (
            P1_CLK  : in  STD_LOGIC;
            P2_RST  : in  STD_LOGIC;
            P3_ENP  : in  STD_LOGIC;
            P4_ENT  : in  STD_LOGIC;
            P5_Q0   : out STD_LOGIC;
            P6_LD   : in  STD_LOGIC;
            P7_A    : in  STD_LOGIC;
            P9_C    : in  STD_LOGIC;
            P10_B   : in  STD_LOGIC;
            P11_TC  : out STD_LOGIC;
            P12_Q0  : out STD_LOGIC;
            P13_Q1  : out STD_LOGIC;
            P14_Q2  : out STD_LOGIC;
            P15_Q3  : out STD_LOGIC
        );
    end component;

begin
    -- Instantiate the device under test
    dut : LS9314
        port map (
            P1_CLK  => clk,
            P2_RST  => rst,
            P3_ENP  => enp,
            P4_ENT  => ent,
            P5_Q0   => q0,
            P6_LD   => ld,
            P7_A    => a,
            P9_C    => c,
            P10_B   => b,
            P11_TC  => tc,
            P12_Q0  => open, -- Same as P5_Q0
            P13_Q1  => q1,
            P14_Q2  => q2,
            P15_Q3  => q3
        );
    
    -- Combine outputs for easier testing
    count_output <= q3 & q2 & q1 & q0;
    
    -- Clock generation
    clk <= not clk after 5 ns;
    
    -- Test stimulus
    stimulus : process
    begin
        report "Starting LS9314 testbench...";
        
        -- Initialize
        rst <= '1';
        enp <= '1';
        ent <= '1';
        ld <= '1';
        a <= '0';
        b <= '0';
        c <= '0';
        wait for 10 ns;
        
        -- Test 1: Reset functionality
        report "Test 1: Reset functionality";
        rst <= '0';
        wait for 10 ns;
        assert count_output = "0000" report "Counter not reset to 0000" severity error;
        assert tc = '0' report "TC should be 0 after reset" severity error;
        
        rst <= '1';
        wait for 10 ns;
        report "Reset test completed";
        
        -- Test 2: Basic counting
        report "Test 2: Basic counting";
        
        -- Reset and set up for counting
        rst <= '0';
        enp <= '0';
        ent <= '0';
        ld <= '1';
        wait for 10 ns;
        
        rst <= '1';
        wait for 10 ns;
        
        -- Count through first few values (counter starts at 0 after reset)
        for i in 0 to 5 loop
            if i = 0 then
                -- First count should be 0 after reset
                assert to_integer(unsigned(count_output)) = 0 report "Initial count should be 0" severity error;
                -- Enable counting
                enp <= '1';
                ent <= '1';
            else
                wait until rising_edge(clk);
                wait for 1 ns;
                report "Count = " & integer'image(to_integer(unsigned(count_output)));
                assert to_integer(unsigned(count_output)) = i report "Count mismatch" severity error;
            end if;
        end loop;
        
        -- Test 3: Enable/disable counting
        report "Test 3: Enable/disable counting";
        
        -- Reset and start fresh
        rst <= '0';
        enp <= '0';
        ent <= '0';
        wait for 10 ns;
        rst <= '1';
        wait for 10 ns;
        
        -- Test ENP disable
        enp <= '0';
        ent <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert to_integer(unsigned(count_output)) = 0 report "Counter should not increment when ENP=0" severity error;
        
        -- Test ENT disable
        enp <= '1';
        ent <= '0';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert to_integer(unsigned(count_output)) = 0 report "Counter should not increment when ENT=0" severity error;
        
        -- Test both enables high
        enp <= '1';
        ent <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert to_integer(unsigned(count_output)) = 1 report "Counter should increment when both enables are high" severity error;
        
        -- Test 4: Load functionality
        report "Test 4: Load functionality";
        ld <= '0';
        a <= '1';  -- MSB
        b <= '0';
        c <= '1';
        -- d is not connected, so it's always 0
        wait until rising_edge(clk);
        wait for 1 ns;
        assert count_output = "1010" report "Load data not loaded correctly" severity error;
        
        ld <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert count_output = "1011" report "Counter should continue counting after load" severity error;
        
        -- Test 5: Terminal count
        report "Test 5: Terminal count";
        
        -- Reset and count to 15
        rst <= '0';
        enp <= '1';
        ent <= '1';
        wait for 10 ns;
        rst <= '1';
        
        -- Count to 15
        for i in 0 to 14 loop
            wait until rising_edge(clk);
            wait for 1 ns;
            report "Count = " & integer'image(to_integer(unsigned(count_output)));
        end loop;
        
        -- Check that we reached 15 (1111)
        assert count_output = "1111" report "Counter should reach 1111" severity error;
        assert tc = '1' report "TC should be high when count=1111 and ENT=1" severity error;
        
        -- Test 6: Rollover
        report "Test 6: Rollover";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert count_output = "0000" report "Counter should rollover to 0000" severity error;
        
        -- Test 7: Reset during counting
        report "Test 7: Reset during counting";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert count_output = "0001" report "Counter should be 0001" severity error;
        
        rst <= '0';
        wait for 10 ns;
        assert count_output = "0000" report "Counter should reset to 0000" severity error;
        
        -- Test 8: Load during counting
        report "Test 8: Load during counting";
        
        -- Reset and set up load data
        rst <= '0';
        enp <= '1';
        ent <= '1';
        ld <= '1';
        a <= '1';
        b <= '0';
        c <= '0';
        wait for 10 ns;
        rst <= '1';
        
        -- Count a few times
        for i in 0 to 2 loop
            wait until rising_edge(clk);
            wait for 1 ns;
        end loop;
        
        -- Load data (should load 1000 = 8, since A=1, B=0, C=0, D=0)
        ld <= '0';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert count_output = "1000" report "Counter should be loaded with 1000" severity error;
        
        ld <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert count_output = "1001" report "Counter should continue counting after load" severity error;
        
        report "All LS9314 tests completed successfully!";
        wait;
    end process stimulus;

end architecture sim; 