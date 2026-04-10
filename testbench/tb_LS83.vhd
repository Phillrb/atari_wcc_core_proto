-- tb_LS83.vhd
-- Testbench for LS83 4-bit binary full adder

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_LS83 is
end tb_LS83;

architecture Behavioral of tb_LS83 is
    component LS83
        Port (
            P1_A4  : in  STD_LOGIC := '0';
            P2_S3  : out STD_LOGIC;
            P3_A3  : in  STD_LOGIC := '0';
            P4_B3  : in  STD_LOGIC := '0';
            P6_S2  : out STD_LOGIC;
            P7_B2  : in  STD_LOGIC := '0';
            P8_A2  : in  STD_LOGIC := '0';
            P9_S1  : out STD_LOGIC;
            P10_A1 : in  STD_LOGIC := '0';
            P11_B1 : in  STD_LOGIC := '0';
            P13_CIN: in  STD_LOGIC := '0';
            P14_COUT: out STD_LOGIC;
            P15_S4 : out STD_LOGIC;
            P16_B4 : in  STD_LOGIC := '0'
        );
    end component;

    signal A, B : std_logic_vector(3 downto 0);
    signal CIN  : std_logic;
    signal S    : std_logic_vector(3 downto 0);
    signal COUT : std_logic;

    -- Utility function to print std_logic_vector as string
    function slv_to_str(slv : std_logic_vector) return string is
        variable result : string(1 to slv'length);
    begin
        for i in slv'range loop
            if slv(i) = '1' then
                result(i - slv'low + 1) := '1';
            else
                result(i - slv'low + 1) := '0';
            end if;
        end loop;
        return result;
    end;

begin
    DUT: LS83
        port map (
            P1_A4  => A(3),
            P2_S3  => S(2),
            P3_A3  => A(2),
            P4_B3  => B(2),
            P6_S2  => S(1),
            P7_B2  => B(1),
            P8_A2  => A(1),
            P9_S1  => S(0),
            P10_A1 => A(0),
            P11_B1 => B(0),
            P13_CIN=> CIN,
            P14_COUT => COUT,
            P15_S4 => S(3),
            P16_B4 => B(3)
        );

    stimulus: process
        variable expected : unsigned(4 downto 0);
        variable sum_val : integer;
        function sl_to_char(s : std_logic) return character is
        begin
            if s = '1' then return '1'; else return '0'; end if;
        end;
    begin
        -- Test all zeros
        A <= "0000"; B <= "0000"; CIN <= '0'; wait for 10 ns;
        sum_val := to_integer(unsigned(A)) + to_integer(unsigned(B));
        if CIN = '1' then sum_val := sum_val + 1; end if;
        expected := to_unsigned(sum_val, 5);
        report "A=0000, B=0000, CIN=0: S=" & slv_to_str(S) & ", COUT=" & sl_to_char(COUT);
        assert S = std_logic_vector(expected(3 downto 0)) and COUT = expected(4) report "Test 0 failed" severity error;

        -- Test all ones, no carry in
        A <= "1111"; B <= "1111"; CIN <= '0'; wait for 10 ns;
        sum_val := to_integer(unsigned(A)) + to_integer(unsigned(B));
        if CIN = '1' then sum_val := sum_val + 1; end if;
        expected := to_unsigned(sum_val, 5);
        report "A=1111, B=1111, CIN=0: S=" & slv_to_str(S) & ", COUT=" & sl_to_char(COUT);
        assert S = std_logic_vector(expected(3 downto 0)) and COUT = expected(4) report "Test 1 failed" severity error;

        -- Test all ones, carry in
        A <= "1111"; B <= "1111"; CIN <= '1'; wait for 10 ns;
        sum_val := to_integer(unsigned(A)) + to_integer(unsigned(B));
        if CIN = '1' then sum_val := sum_val + 1; end if;
        expected := to_unsigned(sum_val, 5);
        report "A=1111, B=1111, CIN=1: S=" & slv_to_str(S) & ", COUT=" & sl_to_char(COUT);
        assert S = std_logic_vector(expected(3 downto 0)) and COUT = expected(4) report "Test 2 failed" severity error;

        -- Test alternating bits
        A <= "1010"; B <= "0101"; CIN <= '0'; wait for 10 ns;
        sum_val := to_integer(unsigned(A)) + to_integer(unsigned(B));
        if CIN = '1' then sum_val := sum_val + 1; end if;
        expected := to_unsigned(sum_val, 5);
        report "A=1010, B=0101, CIN=0: S=" & slv_to_str(S) & ", COUT=" & sl_to_char(COUT);
        assert S = std_logic_vector(expected(3 downto 0)) and COUT = expected(4) report "Test 3 failed" severity error;

        -- Test with carry in
        A <= "0011"; B <= "1100"; CIN <= '1'; wait for 10 ns;
        sum_val := to_integer(unsigned(A)) + to_integer(unsigned(B));
        if CIN = '1' then sum_val := sum_val + 1; end if;
        expected := to_unsigned(sum_val, 5);
        report "A=0011, B=1100, CIN=1: S=" & slv_to_str(S) & ", COUT=" & sl_to_char(COUT);
        assert S = std_logic_vector(expected(3 downto 0)) and COUT = expected(4) report "Test 4 failed" severity error;

        -- Test random
        A <= "0110"; B <= "0011"; CIN <= '1'; wait for 10 ns;
        sum_val := to_integer(unsigned(A)) + to_integer(unsigned(B));
        if CIN = '1' then sum_val := sum_val + 1; end if;
        expected := to_unsigned(sum_val, 5);
        report "A=0110, B=0011, CIN=1: S=" & slv_to_str(S) & ", COUT=" & sl_to_char(COUT);
        assert S = std_logic_vector(expected(3 downto 0)) and COUT = expected(4) report "Test 5 failed" severity error;

        report "All LS83 tests completed.";
        wait;
    end process;
end Behavioral; 