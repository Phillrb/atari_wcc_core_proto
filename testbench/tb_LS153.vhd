library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_LS153 is
end tb_LS153;

architecture sim of tb_LS153 is
    signal Ea, Eb         : std_logic := '0';
    signal S0, S1         : std_logic := '0';
    signal I0a, I1a, I2a, I3a : std_logic := '0';
    signal I0b, I1b, I2b, I3b : std_logic := '0';
    signal Ya, Yb         : std_logic;
begin

    uut: entity work.LS153
        port map (
            P1_Ea   => Ea,
            P2_S1   => S1,
            P3_1I3  => I3a,
            P4_1I2  => I2a,
            P5_1I1  => I1a,
            P6_1I0  => I0a,
            P7_1Y   => Ya,
            P9_2Y   => Yb,
            P10_2I0 => I0b,
            P11_2I1 => I1b,
            P12_2I2 => I2b,
            P13_2I3 => I3b,
            P14_S0  => S0,
            P15_Eb  => Eb
        );

    process
    begin
        report "Testing LS153 Dual 4-to-1 Multiplexer";

        -- Test 1: Mux 1 selection with enable active (Ea=LOW)
        Ea <= '0';
        I0a <= '1'; I1a <= '0'; I2a <= '1'; I3a <= '0';
        -- data: I0=1, I1=0, I2=1, I3=0

        S1 <= '0'; S0 <= '0'; wait for 10 ns;
        assert Ya = '1' report "Mux1: sel=00 should output I0=1" severity error;

        S1 <= '0'; S0 <= '1'; wait for 10 ns;
        assert Ya = '0' report "Mux1: sel=01 should output I1=0" severity error;

        S1 <= '1'; S0 <= '0'; wait for 10 ns;
        assert Ya = '1' report "Mux1: sel=10 should output I2=1" severity error;

        S1 <= '1'; S0 <= '1'; wait for 10 ns;
        assert Ya = '0' report "Mux1: sel=11 should output I3=0" severity error;

        -- Test 2: Mux 1 disabled (Ea=HIGH) => output LOW
        Ea <= '1'; wait for 10 ns;
        assert Ya = '0' report "Mux1: disabled should output 0" severity error;
        Ea <= '0';

        -- Test 3: Mux 2 selection with enable active (Eb=LOW)
        Eb <= '0';
        I0b <= '0'; I1b <= '1'; I2b <= '0'; I3b <= '1';

        S1 <= '0'; S0 <= '0'; wait for 10 ns;
        assert Yb = '0' report "Mux2: sel=00 should output I0=0" severity error;

        S1 <= '0'; S0 <= '1'; wait for 10 ns;
        assert Yb = '1' report "Mux2: sel=01 should output I1=1" severity error;

        S1 <= '1'; S0 <= '0'; wait for 10 ns;
        assert Yb = '0' report "Mux2: sel=10 should output I2=0" severity error;

        S1 <= '1'; S0 <= '1'; wait for 10 ns;
        assert Yb = '1' report "Mux2: sel=11 should output I3=1" severity error;

        -- Test 4: Mux 2 disabled (Eb=HIGH) => output LOW
        Eb <= '1'; wait for 10 ns;
        assert Yb = '0' report "Mux2: disabled should output 0" severity error;
        Eb <= '0';

        -- Test 5: Shared select lines affect both muxes
        I0a <= '1'; I1a <= '0'; I2a <= '0'; I3a <= '0';
        I0b <= '0'; I1b <= '0'; I2b <= '0'; I3b <= '1';
        S1 <= '0'; S0 <= '0'; wait for 10 ns;
        assert Ya = '1' report "Shared sel: Mux1 sel=00 should be 1" severity error;
        assert Yb = '0' report "Shared sel: Mux2 sel=00 should be 0" severity error;

        S1 <= '1'; S0 <= '1'; wait for 10 ns;
        assert Ya = '0' report "Shared sel: Mux1 sel=11 should be 0" severity error;
        assert Yb = '1' report "Shared sel: Mux2 sel=11 should be 1" severity error;

        -- Test 6: Independent enable control
        Ea <= '1'; Eb <= '0';
        S1 <= '0'; S0 <= '0'; wait for 10 ns;
        assert Ya = '0' report "Mux1 disabled, should be 0" severity error;
        assert Yb = '0' report "Mux2 enabled, sel=00, I0b=0" severity error;

        Ea <= '0'; Eb <= '1'; wait for 10 ns;
        assert Ya = '1' report "Mux1 enabled, sel=00, I0a=1" severity error;
        assert Yb = '0' report "Mux2 disabled, should be 0" severity error;

        report "All LS153 tests passed!" severity note;
        wait;
    end process;
end sim;
