library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_IC9316 is
end tb_IC9316;

architecture test of tb_IC9316 is
    -- Test signals for each pin
    signal P1_CLRn  : std_logic := '1';
    signal P2_CLK   : std_logic := '0';
    signal P3_A     : std_logic := '0';
    signal P4_B     : std_logic := '0';
    signal P5_C     : std_logic := '0';
    signal P6_D     : std_logic := '0';
    signal P7_CEP   : std_logic := '1';
    signal P9_LDn   : std_logic := '1';
    signal P10_CET  : std_logic := '1';
    signal P11_QD   : std_logic;
    signal P12_QC   : std_logic;
    signal P13_QB   : std_logic;
    signal P14_QA   : std_logic;
    signal P15_RC   : std_logic;
    signal Q_vec    : std_logic_vector(3 downto 0);

    component IC9316 is
        Port (
            P1_CLRn  : in  STD_LOGIC;
            P2_CLK   : in  STD_LOGIC;
            P3_A     : in  STD_LOGIC;
            P4_B     : in  STD_LOGIC;
            P5_C     : in  STD_LOGIC;
            P6_D     : in  STD_LOGIC;
            P7_CEP   : in  STD_LOGIC;
            -- P8_GND : in  STD_LOGIC := '0';
            P9_LDn   : in  STD_LOGIC;
            P10_CET  : in  STD_LOGIC;
            P11_QD   : out STD_LOGIC;
            P12_QC   : out STD_LOGIC;
            P13_QB   : out STD_LOGIC;
            P14_QA   : out STD_LOGIC;
            P15_RC   : out STD_LOGIC
            -- P16_VCC : in  STD_LOGIC := '1'
        );
    end component;

    -- Utility function to print std_logic_vector as string
    function slv_to_str(slv : std_logic_vector) return string is
        variable result : string(1 to slv'length);
    begin
        for i in slv'range loop
            result(i - slv'low + 1) := character'VALUE(std_ulogic'image(slv(i)));
        end loop;
        return result;
    end function;

begin
    Q_vec <= P11_QD & P12_QC & P13_QB & P14_QA;

    dut: IC9316
        port map (
            P1_CLRn  => P1_CLRn,
            P2_CLK   => P2_CLK,
            P3_A     => P3_A,
            P4_B     => P4_B,
            P5_C     => P5_C,
            P6_D     => P6_D,
            P7_CEP   => P7_CEP,
            P9_LDn   => P9_LDn,
            P10_CET  => P10_CET,
            P11_QD   => P11_QD,
            P12_QC   => P12_QC,
            P13_QB   => P13_QB,
            P14_QA   => P14_QA,
            P15_RC   => P15_RC
        );

    stimulus: process
        procedure clock is
        begin
            P2_CLK <= '1'; wait for 5 ns;
            P2_CLK <= '0'; wait for 5 ns;
        end procedure;
        variable expected : unsigned(3 downto 0);
    begin
        report "Starting IC9316 testbench...";

        -- Test async clear
        P1_CLRn <= '0'; wait for 2 ns;
        report "After async clear: Q_vec=" & slv_to_str(Q_vec);
        assert Q_vec = "0000" report "Counter should be 0000 after clear" severity error;
        P1_CLRn <= '1'; wait for 2 ns;

        -- Test synchronous load
        P3_A <= '1'; P4_B <= '0'; P5_C <= '1'; P6_D <= '1';
        wait for 1 ns;
        P9_LDn <= '0';
        clock; -- load on rising edge
        P9_LDn <= '1';
        report "After load 1101: Q_vec=" & slv_to_str(Q_vec);
        assert Q_vec = "1101" report "Counter should be 1101 after load" severity error;

        -- Test counting with enables
        expected := "1101";
        for i in 1 to 5 loop
            clock;
            if (P7_CEP = '1' and P10_CET = '1') then
                expected := expected + 1;
            end if;
            report "After count " & integer'image(i) & ": Q_vec=" & slv_to_str(Q_vec);
            assert Q_vec = std_logic_vector(expected) report "Counter mismatch at count " & integer'image(i) severity error;
        end loop;

        -- Test disables: counter should not increment
        P7_CEP <= '0';
        clock;
        report "After CEP low: Q_vec=" & slv_to_str(Q_vec);
        assert Q_vec = std_logic_vector(expected) report "Counter should not increment when CEP=0" severity error;
        P7_CEP <= '1';
        P10_CET <= '0';
        clock;
        report "After CET low: Q_vec=" & slv_to_str(Q_vec);
        assert Q_vec = std_logic_vector(expected) report "Counter should not increment when CET=0" severity error;
        P10_CET <= '1';

        -- Test ripple carry
        -- Set to 1110, count to 1111, check RC
        P3_A <= '0'; P4_B <= '1'; P5_C <= '1'; P6_D <= '1';
        wait for 1 ns;
        P9_LDn <= '0'; clock; P9_LDn <= '1';
        expected := "1110";
        clock; expected := expected + 1;
        report "After count to 1111: Q_vec=" & slv_to_str(Q_vec) & " RC=" & std_logic'image(P15_RC);
        assert Q_vec = "1111" report "Counter should be 1111" severity error;
        assert P15_RC = '1' report "RC should be 1 when counter is 1111 and enables high" severity error;
        clock; expected := expected + 1;
        report "After overflow: Q_vec=" & slv_to_str(Q_vec) & " RC=" & std_logic'image(P15_RC);
        assert Q_vec = "0000" report "Counter should wrap to 0000 after 1111" severity error;
        assert P15_RC = '0' report "RC should be 0 after overflow" severity error;

        report "All tests completed for IC9316.";
        wait;
    end process;

end test; 