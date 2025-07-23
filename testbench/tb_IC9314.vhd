library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_IC9314 is
end tb_IC9314;

architecture test of tb_IC9314 is
    -- Test signals for each pin
    signal P1_OEn  : std_logic := '1';
    signal P2_S0n  : std_logic := '1';
    signal P3_D0   : std_logic := '0';
    signal P4_D1   : std_logic := '0';
    signal P5_S2n  : std_logic := '1';
    signal P6_D2   : std_logic := '0';
    signal P7_D3   : std_logic := '0';
    signal P9_MRn  : std_logic := '1';
    signal P10_Q3  : std_logic;
    signal P11_S3n : std_logic := '1';
    signal P12_Q2  : std_logic;
    signal P13_Q1  : std_logic;
    signal P14_S1n : std_logic := '1';
    signal P15_Q0  : std_logic;
    signal Q_vec   : std_logic_vector(3 downto 0);

    component IC9314 is
        Port (
            P1_OEn  : in  STD_LOGIC;
            P2_S0n  : in  STD_LOGIC;
            P3_D0   : in  STD_LOGIC;
            P4_D1   : in  STD_LOGIC;
            P5_S2n  : in  STD_LOGIC;
            P6_D2   : in  STD_LOGIC;
            P7_D3   : in  STD_LOGIC;
            -- P8_GND : in  STD_LOGIC := '0';
            P9_MRn  : in  STD_LOGIC;
            P10_Q3  : out STD_LOGIC;
            P11_S3n : in  STD_LOGIC;
            P12_Q2  : out STD_LOGIC;
            P13_Q1  : out STD_LOGIC;
            P14_S1n : in  STD_LOGIC;
            P15_Q0  : out STD_LOGIC
            -- P16_VCC : in  STD_LOGIC := '1'
        );
    end component;

    function slv_to_str(slv : std_logic_vector) return string is
        variable result : string(1 to slv'length);
    begin
        for i in slv'range loop
            result(i - slv'low + 1) := character'VALUE(std_ulogic'image(slv(i)));
        end loop;
        return result;
    end function;

begin
    Q_vec <= P10_Q3 & P12_Q2 & P13_Q1 & P15_Q0;

    dut: IC9314
        port map (
            P1_OEn  => P1_OEn,
            P2_S0n  => P2_S0n,
            P3_D0   => P3_D0,
            P4_D1   => P4_D1,
            P5_S2n  => P5_S2n,
            P6_D2   => P6_D2,
            P7_D3   => P7_D3,
            P9_MRn  => P9_MRn,
            P10_Q3  => P10_Q3,
            P11_S3n => P11_S3n,
            P12_Q2  => P12_Q2,
            P13_Q1  => P13_Q1,
            P14_S1n => P14_S1n,
            P15_Q0  => P15_Q0
        );

    stimulus: process
    begin
        report "Starting IC9314 testbench...";

        -- Enable outputs before reset
        P1_OEn <= '0';
        -- Master reset: all latches should clear
        P9_MRn <= '0';
        wait for 5 ns;
        P9_MRn <= '1';
        wait for 5 ns;
        report "After reset: Q_vec=" & slv_to_str(Q_vec);
        assert Q_vec = "0000" report "After reset, Q should be 0000" severity error;

        -- Set Q0 to 1
        P3_D0 <= '1'; P2_S0n <= '0'; wait for 5 ns; P2_S0n <= '1';
        report "After set Q0: Q_vec=" & slv_to_str(Q_vec);
        assert P15_Q0 = '1' report "Q0 should be 1 after set" severity error;
        -- Set Q1 to 1
        P4_D1 <= '1'; P14_S1n <= '0'; wait for 5 ns; P14_S1n <= '1';
        report "After set Q1: Q_vec=" & slv_to_str(Q_vec);
        assert P13_Q1 = '1' report "Q1 should be 1 after set" severity error;
        -- Set Q2 to 1
        P6_D2 <= '1'; P5_S2n <= '0'; wait for 5 ns; P5_S2n <= '1';
        report "After set Q2: Q_vec=" & slv_to_str(Q_vec);
        assert P12_Q2 = '1' report "Q2 should be 1 after set" severity error;
        -- Set Q3 to 1
        P7_D3 <= '1'; P11_S3n <= '0'; wait for 5 ns; P11_S3n <= '1';
        report "After set Q3: Q_vec=" & slv_to_str(Q_vec);
        assert P10_Q3 = '1' report "Q3 should be 1 after set" severity error;
        assert Q_vec = "1111" report "All Q should be 1 after all sets" severity error;

        -- Change D0, D1, D2, D3 to 0, strobe should not affect unless set input is low
        P3_D0 <= '0'; P4_D1 <= '0'; P6_D2 <= '0'; P7_D3 <= '0';
        wait for 5 ns;
        report "After D inputs set to 0 (no strobe): Q_vec=" & slv_to_str(Q_vec);
        assert Q_vec = "1111" report "Q should hold values unless set input is low" severity error;

        -- Set Q0 to 0
        P2_S0n <= '0'; P3_D0 <= '0'; wait for 5 ns; P2_S0n <= '1';
        report "After set Q0 to 0: Q_vec=" & slv_to_str(Q_vec);
        assert P15_Q0 = '0' report "Q0 should be 0 after set to 0" severity error;
        -- Set Q1 to 0
        P14_S1n <= '0'; P4_D1 <= '0'; wait for 5 ns; P14_S1n <= '1';
        report "After set Q1 to 0: Q_vec=" & slv_to_str(Q_vec);
        assert P13_Q1 = '0' report "Q1 should be 0 after set to 0" severity error;
        -- Set Q2 to 0
        P5_S2n <= '0'; P6_D2 <= '0'; wait for 5 ns; P5_S2n <= '1';
        report "After set Q2 to 0: Q_vec=" & slv_to_str(Q_vec);
        assert P12_Q2 = '0' report "Q2 should be 0 after set to 0" severity error;
        -- Set Q3 to 0
        P11_S3n <= '0'; P7_D3 <= '0'; wait for 5 ns; P11_S3n <= '1';
        report "After set Q3 to 0: Q_vec=" & slv_to_str(Q_vec);
        assert P10_Q3 = '0' report "Q3 should be 0 after set to 0" severity error;
        assert Q_vec = "0000" report "All Q should be 0 after all sets to 0" severity error;

        -- Test 3-state output
        P1_OEn <= '1'; wait for 5 ns;
        report "After OE high (3-state): Q_vec=" & slv_to_str(Q_vec);
        assert Q_vec = "ZZZZ" report "Q should be high-Z when OE is high" severity error;
        P1_OEn <= '0'; wait for 5 ns;
        report "After OE low (outputs enabled): Q_vec=" & slv_to_str(Q_vec);
        assert Q_vec = "0000" report "Q should return to 0000 after OE is low again" severity error;

        -- Test master reset from nonzero state
        P3_D0 <= '1'; P2_S0n <= '0'; wait for 5 ns; P2_S0n <= '1';
        P4_D1 <= '1'; P14_S1n <= '0'; wait for 5 ns; P14_S1n <= '1';
        report "Before master reset: Q_vec=" & slv_to_str(Q_vec);
        assert Q_vec = "0011" report "Q should be 0011 before reset" severity error;
        P9_MRn <= '0'; wait for 5 ns; P9_MRn <= '1'; wait for 5 ns;
        report "After master reset: Q_vec=" & slv_to_str(Q_vec);
        assert Q_vec = "0000" report "Q should be 0000 after master reset" severity error;

        report "All tests completed for IC9314.";
        wait;
    end process;

end test; 