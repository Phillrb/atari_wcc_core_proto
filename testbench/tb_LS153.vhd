library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_LS153 is
end tb_LS153;

architecture sim of tb_LS153 is
    -- Test signals for multiplexer 1
    signal mux1_data : std_logic_vector(3 downto 0) := "0000";
    signal mux1_select : std_logic_vector(1 downto 0) := "00";
    signal mux1_output : std_logic;
    
    -- Test signals for multiplexer 2
    signal mux2_data : std_logic_vector(3 downto 0) := "0000";
    signal mux2_select : std_logic_vector(1 downto 0) := "00";
    signal mux2_output : std_logic;
    
    -- Map LS153 pins to signals
    signal P1_1Y, P15_2Y : std_logic;
    signal P2_1A, P3_1B, P4_1C, P5_1D : std_logic := '0';
    signal P6_1S0, P7_1S1 : std_logic := '0';
    signal P9_2S1, P10_2S0 : std_logic := '0';
    signal P11_2D, P12_2C, P13_2B, P14_2A : std_logic := '0';

begin
    -- Connect signals
    P2_1A <= mux1_data(0);
    P3_1B <= mux1_data(1);
    P4_1C <= mux1_data(2);
    P5_1D <= mux1_data(3);
    P6_1S0 <= mux1_select(0);
    P7_1S1 <= mux1_select(1);
    mux1_output <= P1_1Y;
    
    P14_2A <= mux2_data(0);
    P13_2B <= mux2_data(1);
    P12_2C <= mux2_data(2);
    P11_2D <= mux2_data(3);
    P10_2S0 <= mux2_select(0);
    P9_2S1 <= mux2_select(1);
    mux2_output <= P15_2Y;

    uut: entity work.LS153
        port map (
            P1_1Y => P1_1Y,
            P2_1A => P2_1A,
            P3_1B => P3_1B,
            P4_1C => P4_1C,
            P5_1D => P5_1D,
            P6_1S0 => P6_1S0,
            P7_1S1 => P7_1S1,
            P9_2S1 => P9_2S1,
            P10_2S0 => P10_2S0,
            P11_2D => P11_2D,
            P12_2C => P12_2C,
            P13_2B => P13_2B,
            P14_2A => P14_2A,
            P15_2Y => P15_2Y
        );

    process
    begin
        report "Testing LS153 Dual 4-to-1 Multiplexer";
        
        -- Test 1: Multiplexer 1 - All select combinations with fixed data
        mux1_data <= "1010";  -- A=0, B=1, C=0, D=1
        
        for sel in 0 to 3 loop
            mux1_select <= std_logic_vector(to_unsigned(sel, 2));
            wait for 10 ns;
            
            case sel is
                when 0 => assert (mux1_output = '0') report "Mux1: Select 00 should output A=0" severity error;
                when 1 => assert (mux1_output = '1') report "Mux1: Select 01 should output B=1" severity error;
                when 2 => assert (mux1_output = '0') report "Mux1: Select 10 should output C=0" severity error;
                when 3 => assert (mux1_output = '1') report "Mux1: Select 11 should output D=1" severity error;
            end case;
        end loop;
        
        -- Test 2: Multiplexer 2 - All select combinations with fixed data
        mux2_data <= "1100";  -- A=0, B=0, C=1, D=1
        
        for sel in 0 to 3 loop
            mux2_select <= std_logic_vector(to_unsigned(sel, 2));
            wait for 10 ns;
            
            case sel is
                when 0 => assert (mux2_output = '0') report "Mux2: Select 00 should output A=0" severity error;
                when 1 => assert (mux2_output = '0') report "Mux2: Select 01 should output B=0" severity error;
                when 2 => assert (mux2_output = '1') report "Mux2: Select 10 should output C=1" severity error;
                when 3 => assert (mux2_output = '1') report "Mux2: Select 11 should output D=1" severity error;
            end case;
        end loop;
        
        -- Test 3: Both multiplexers simultaneously with different data
        mux1_data <= "1111";  -- All inputs high
        mux2_data <= "0000";  -- All inputs low
        
        for sel in 0 to 3 loop
            mux1_select <= std_logic_vector(to_unsigned(sel, 2));
            mux2_select <= std_logic_vector(to_unsigned(sel, 2));
            wait for 10 ns;
            
            assert (mux1_output = '1') report "Mux1: All inputs high should output 1" severity error;
            assert (mux2_output = '0') report "Mux2: All inputs low should output 0" severity error;
        end loop;
        
        -- Test 4: Alternating data patterns
        mux1_data <= "0101";
        mux2_data <= "1010";
        
        for sel in 0 to 3 loop
            mux1_select <= std_logic_vector(to_unsigned(sel, 2));
            mux2_select <= std_logic_vector(to_unsigned(sel, 2));
            wait for 10 ns;
            
            -- Verify alternating pattern for mux1
            case sel is
                when 0 => assert (mux1_output = '1') report "Mux1: Pattern test failed for select 00" severity error;
                when 1 => assert (mux1_output = '0') report "Mux1: Pattern test failed for select 01" severity error;
                when 2 => assert (mux1_output = '1') report "Mux1: Pattern test failed for select 10" severity error;
                when 3 => assert (mux1_output = '0') report "Mux1: Pattern test failed for select 11" severity error;
            end case;
            
            -- Verify alternating pattern for mux2
            case sel is
                when 0 => assert (mux2_output = '0') report "Mux2: Pattern test failed for select 00" severity error;
                when 1 => assert (mux2_output = '1') report "Mux2: Pattern test failed for select 01" severity error;
                when 2 => assert (mux2_output = '0') report "Mux2: Pattern test failed for select 10" severity error;
                when 3 => assert (mux2_output = '1') report "Mux2: Pattern test failed for select 11" severity error;
            end case;
        end loop;
        
        -- Test 5: Independent operation
        mux1_data <= "0011";  -- A=1, B=1, C=0, D=0
        mux2_data <= "1100";  -- A=0, B=0, C=1, D=1
        mux1_select <= "10";  -- Select C (should be 0)
        mux2_select <= "01";  -- Select B (should be 0)
        wait for 10 ns;
        
        -- mux1_select "10" means S0=0, S1=1, so selects P4_1C = mux1_data(2) = 0
        -- mux2_select "01" means S0=1, S1=0, so selects P13_2B = mux2_data(1) = 0
        assert (mux1_output = '0') report "Mux1: Independent operation failed - expected 0, got " & std_logic'image(mux1_output) severity error;
        assert (mux2_output = '0') report "Mux2: Independent operation failed - expected 0, got " & std_logic'image(mux2_output) severity error;
        
        report "All LS153 tests passed!" severity note;
        wait;
    end process;
end sim; 