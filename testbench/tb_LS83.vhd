library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_LS83 is
end tb_LS83;

architecture sim of tb_LS83 is
    signal A : std_logic_vector(3 downto 0) := (others => '0');
    signal B : std_logic_vector(3 downto 0) := (others => '0');
    signal C0 : std_logic := '0';
    signal S : std_logic_vector(3 downto 0);
    signal C4 : std_logic;

    -- Map LS83 pins to signals
    signal P1_A1, P3_A2, P5_A3, P11_A4 : std_logic := '0';
    signal P2_B1, P14_B2, P12_B3, P7_B4 : std_logic := '0';
    signal P9_C0 : std_logic := '0';
    signal P15_S1, P4_S2, P13_S3, P6_S4 : std_logic;
    signal P10_C4 : std_logic;

begin
    -- Connect signals to LS83 pins
    P1_A1 <= A(0); P3_A2 <= A(1); P5_A3 <= A(2); P11_A4 <= A(3);
    P2_B1 <= B(0); P14_B2 <= B(1); P12_B3 <= B(2); P7_B4 <= B(3);
    P9_C0 <= C0;
    S(0) <= P15_S1; S(1) <= P4_S2; S(2) <= P13_S3; S(3) <= P6_S4;
    C4 <= P10_C4;

    uut: entity work.LS83
        port map (
            P1_A1 => P1_A1,
            P2_B1 => P2_B1,
            P3_A2 => P3_A2,
            P4_S2 => P4_S2,
            P5_A3 => P5_A3,
            P6_S4 => P6_S4,
            P7_B4 => P7_B4,
            P9_C0 => P9_C0,
            P10_C4 => P10_C4,
            P11_A4 => P11_A4,
            P12_B3 => P12_B3,
            P13_S3 => P13_S3,
            P14_B2 => P14_B2,
            P15_S1 => P15_S1
        );

    process
    begin
        -- Test 1: 3 + 5 + 0 = 8
        A <= "0011"; B <= "0101"; C0 <= '0'; wait for 10 ns;
        assert (S = "1000" and C4 = '0')
            report "Test 1 failed: 3+5+0" severity error;

        -- Test 2: 7 + 8 + 1 = 16 (carry out)
        A <= "0111"; B <= "1000"; C0 <= '1'; wait for 10 ns;
        assert (S = "0000" and C4 = '1')
            report "Test 2 failed: 7+8+1" severity error;

        -- Test 3: 15 + 15 + 1 = 31 (overflow)
        A <= "1111"; B <= "1111"; C0 <= '1'; wait for 10 ns;
        assert (S = "1111" and C4 = '1')
            report "Test 3 failed: 15+15+1" severity error;

        -- Test 4: 0 + 0 + 0 = 0
        A <= "0000"; B <= "0000"; C0 <= '0'; wait for 10 ns;
        assert (S = "0000" and C4 = '0')
            report "Test 4 failed: 0+0+0" severity error;

        -- Test 5: 9 + 6 + 0 = 15
        A <= "1001"; B <= "0110"; C0 <= '0'; wait for 10 ns;
        assert (S = "1111" and C4 = '0')
            report "Test 5 failed: 9+6+0" severity error;

        report "All LS83 tests passed!" severity note;
        wait;
    end process;
end sim; 