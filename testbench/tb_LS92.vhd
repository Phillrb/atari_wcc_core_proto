library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_LS92 is
end tb_LS92;

architecture Behavioral of tb_LS92 is
    component LS92
        Port (
            P1_CP1n  : in  STD_LOGIC;
            P6_MR1   : in  STD_LOGIC;
            P7_MR2   : in  STD_LOGIC;
            P8_Q3    : out STD_LOGIC;
            P9_Q2    : out STD_LOGIC;
            P11_Q1   : out STD_LOGIC;
            P12_Q0   : out STD_LOGIC;
            P14_CP0n : in  STD_LOGIC
        );
    end component;

    signal CP1n, CP0n : std_logic := '1';
    signal MR1, MR2 : std_logic := '0';
    signal Q0, Q1, Q2, Q3 : std_logic;
    signal Q_vec : std_logic_vector(3 downto 0);

    -- Utility function to print std_logic_vector as string
    function slv_to_str(slv : std_logic_vector) return string is
        variable result : string(1 to slv'length);
    begin
        for i in 0 to slv'length-1 loop
            if slv(slv'high - i) = '1' then
                result(i + 1) := '1';
            else
                result(i + 1) := '0';
            end if;
        end loop;
        return result;
    end;

begin
    Q_vec <= Q0 & Q1 & Q2 & Q3;  -- LSB to MSB order to match internal count

    DUT: LS92
        port map (
            P1_CP1n  => CP1n,
            P6_MR1   => MR1,
            P7_MR2   => MR2,
            P8_Q3    => Q3,
            P9_Q2    => Q2,
            P11_Q1   => Q1,
            P12_Q0   => Q0,
            P14_CP0n => CP0n
        );

    stimulus: process
        procedure clock_0 is
        begin
            CP0n <= '0'; wait for 5 ns;
            CP0n <= '1'; wait for 5 ns;
        end procedure;
        
        procedure clock_1 is
        begin
            CP1n <= '0'; wait for 5 ns;
            CP1n <= '1'; wait for 5 ns;
        end procedure;
        
    begin
        report "Starting LS92 divide-by-12 counter testbench...";

        -- Test 1: Reset functionality
        report "Test 1: Reset functionality";
        MR1 <= '1'; wait for 2 ns;
        report "After MR1=1: Q_vec=" & slv_to_str(Q_vec);
        assert Q_vec = "0000" report "Counter should be 0000 after MR1 reset" severity error;
        MR1 <= '0'; wait for 2 ns;
        
        MR2 <= '1'; wait for 2 ns;
        report "After MR2=1: Q_vec=" & slv_to_str(Q_vec);
        MR2 <= '0'; wait for 2 ns;

        -- Test 2: Count on CP0n (active low edge) - full cycle 0-11
        report "Test 2: Count on CP0n (active low edge) - full cycle 0-11";
        for i in 0 to 15 loop  -- Count through 2 full cycles
            clock_0;
            wait for 1 ns;
            report "After CP0n count " & integer'image(i) & ": Q_vec=" & slv_to_str(Q_vec);
        end loop;

        -- Test 3: Count on CP1n (active low edge) - full cycle 0-11
        report "Test 3: Count on CP1n (active low edge) - full cycle 0-11";
        for i in 0 to 15 loop  -- Count through 2 full cycles
            clock_1;
            wait for 1 ns;
            report "After CP1n count " & integer'image(i) & ": Q_vec=" & slv_to_str(Q_vec);
        end loop;

        -- Test 4: Reset during counting
        report "Test 4: Reset during counting";
        clock_0; clock_0; clock_0; -- Count to 3
        report "Before reset: Q_vec=" & slv_to_str(Q_vec);
        MR1 <= '1'; wait for 2 ns; MR1 <= '0'; wait for 2 ns;
        report "After reset: Q_vec=" & slv_to_str(Q_vec);
        assert Q_vec = "0000" report "Counter should be 0000 after reset" severity error;

        -- Test 5: Divide-by-12 behavior (should not count past 11)
        report "Test 5: Divide-by-12 behavior (should not count past 11)";
        for i in 0 to 20 loop  -- Count through multiple cycles
            clock_0;
            wait for 1 ns;
            report "After count " & integer'image(i) & ": Q_vec=" & slv_to_str(Q_vec);
        end loop;

        report "All LS92 divide-by-12 counter tests completed.";
        wait;
    end process;
end Behavioral; 