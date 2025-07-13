library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package components_pkg is

-- LS00 Quad 2-Input NAND Gate component declaration
component LS00 is
    Port (
        P1_A1  : in  STD_LOGIC := '0';
        P2_B1  : in  STD_LOGIC := '0';
        P3_Y1  : out STD_LOGIC;
        
        P4_A2  : in  STD_LOGIC := '0';
        P5_B2  : in  STD_LOGIC := '0';
        P6_Y2  : out STD_LOGIC;
        
        P8_Y3  : out STD_LOGIC;
        P9_A3  : in  STD_LOGIC := '0';
        P10_B3 : in  STD_LOGIC := '0';
        
        P11_Y4 : out STD_LOGIC;
        P12_A4 : in  STD_LOGIC := '0';
        P13_B4 : in  STD_LOGIC := '0'
    );
end component;

-- LS02 Quad 2-Input NOR Gate component declaration
component LS02 is
    Port (
        P1_Y1  : out STD_LOGIC;
        P2_A1  : in  STD_LOGIC := '0';
        P3_B1  : in  STD_LOGIC := '0';
        P4_Y2  : out STD_LOGIC;
        P5_A2  : in  STD_LOGIC := '0';
        P6_B2  : in  STD_LOGIC := '0';
        -- P7 : GND
        P8_A3  : in  STD_LOGIC := '0';
        P9_B3  : in  STD_LOGIC := '0';
        P10_Y3 : out STD_LOGIC;
        P11_A4 : in  STD_LOGIC := '0';
        P12_B4 : in  STD_LOGIC := '0';
        P13_Y4 : out STD_LOGIC
        -- P14 : VCC
    );
end component;

-- LS04 Hex Inverter component declaration
component LS04 is
    Port (
        P1_A1  : in  STD_LOGIC := '0';
        P2_Y1  : out STD_LOGIC;
        P3_A2  : in  STD_LOGIC := '0';
        P4_Y2  : out STD_LOGIC;
        P5_A3  : in  STD_LOGIC := '0';
        P6_Y3  : out STD_LOGIC;
        -- P7 : GND
        P8_Y4  : out STD_LOGIC;
        P9_A4  : in  STD_LOGIC := '0';
        P10_Y5 : out STD_LOGIC;
        P11_A5 : in  STD_LOGIC := '0';
        P12_Y6 : out STD_LOGIC;
        P13_A6 : in  STD_LOGIC := '0'
        -- P14 : VCC    
    );
end component;

-- LS08 Quad 2-Input AND Gate component declaration
component LS08 is
    Port (
        P1_A1  : in  STD_LOGIC := '0';
        P2_B1  : in  STD_LOGIC := '0';
        P3_Y1  : out STD_LOGIC;
        
        P4_A2  : in  STD_LOGIC := '0';
        P5_B2  : in  STD_LOGIC := '0';
        P6_Y2  : out STD_LOGIC;
        
        P8_Y3  : out STD_LOGIC;
        P9_A3  : in  STD_LOGIC := '0';
        P10_B3 : in  STD_LOGIC := '0';
        
        P11_Y4 : out STD_LOGIC;
        P12_A4 : in  STD_LOGIC := '0';
        P13_B4 : in  STD_LOGIC := '0'
    );
end component;

-- LS20 Dual 4-Input NAND Gate component declaration
component LS20 is
    Port (
        P1_A1  : in  STD_LOGIC := '0';
        P2_B1  : in  STD_LOGIC := '0';
        -- P3  : NC
        P4_C1  : in  STD_LOGIC := '0';
        P5_D1  : in  STD_LOGIC := '0';
        P6_Y1  : out STD_LOGIC;
        -- P7  : GND
        P8_Y2  : out STD_LOGIC;
        P9_D2  : in  STD_LOGIC := '0';
        P10_C2 : in  STD_LOGIC := '0';
        -- P11 : NC
        P12_B2 : in  STD_LOGIC := '0';
        P13_A2 : in  STD_LOGIC := '0'
        -- P14 : VCC
    );
end component;

-- LS30 8-Input NAND Gate component declaration
component LS30 is
    Port (
        P1_A   : in  STD_LOGIC := '0';
        P2_B   : in  STD_LOGIC := '0';
        P3_C   : in  STD_LOGIC := '0';
        P4_D   : in  STD_LOGIC := '0';
        P5_E   : in  STD_LOGIC := '0';
        P6_F   : in  STD_LOGIC := '0';
        -- P7  : GND
        P8_Y   : out STD_LOGIC;
        -- P9  : NC
        -- P10 : NC
        P11_G  : in  STD_LOGIC := '0';
        P12_H  : in  STD_LOGIC := '0'
        -- P13 : NC
        -- P14 : VCC
    );
end component;

-- LS74 Dual D Flip-Flop component declaration
component LS74 is
    Port (
        P1_CLR1n  : in  STD_LOGIC := '1';
        P2_D1     : in  STD_LOGIC := '0';
        P3_CLK1   : in  STD_LOGIC := '0';
        P4_SET1n  : in  STD_LOGIC := '1';
        P5_Q1     : out STD_LOGIC;
        P6_Q1n    : out STD_LOGIC;
        -- P7 : GND
        P8_Q2n    : out STD_LOGIC;
        P9_Q2     : out STD_LOGIC;
        P10_SET2n : in  STD_LOGIC := '1';
        P11_CLK2  : in  STD_LOGIC := '0';
        P12_D2    : in  STD_LOGIC := '0';
        P13_CLR2n : in  STD_LOGIC := '1'
        -- P14 : VCC
    );
end component;

-- LS86 Quad 2-Input XOR Gate component declaration
component LS86 is
    Port (
        P1_A1  : in  STD_LOGIC := '0';
        P2_B1  : in  STD_LOGIC := '0';
        P3_Y1  : out STD_LOGIC;
        P4_A2  : in  STD_LOGIC := '0';
        P5_B2  : in  STD_LOGIC := '0';
        P6_Y2  : out STD_LOGIC;
        -- P7 : GND
        P8_Y3  : out STD_LOGIC;
        P9_A3  : in  STD_LOGIC := '0';
        P10_B3 : in  STD_LOGIC := '0';
        P11_Y4 : out STD_LOGIC;
        P12_A4 : in  STD_LOGIC := '0';
        P13_B4 : in  STD_LOGIC := '0'
        -- P14 : VCC
    );
end component;

-- LS93 4-Bit Binary Counter component declaration
component LS93 is
    Port (
        P1_CP1n  : in  STD_LOGIC := '1';
        P2_MR1   : in  STD_LOGIC := '1';
        P3_MR2   : in  STD_LOGIC := '1';
        -- P4 : NC
        -- P5 : VCC
        -- P6 : NC
        -- P7 : NC
        P8_Q2    : out STD_LOGIC;
        P9_Q1    : out STD_LOGIC;
        -- P10 : GND
        P11_Q3   : out STD_LOGIC;
        P12_Q0   : out STD_LOGIC;
        -- P13 : NC
        P14_CP0n : in  STD_LOGIC := '1'
    );
end component;

-- LS107 Dual J-K Flip-Flop component declaration
component LS107 is
    Port (
        P1_J1      : in  STD_LOGIC := '0';
        P2_Q1n     : out STD_LOGIC;
        P3_Q1      : out STD_LOGIC;
        P4_K1      : in  STD_LOGIC := '0';
        P5_Q2      : out STD_LOGIC;
        P6_Q2n     : out STD_LOGIC;
        -- P7 : GND
        P8_J2      : in  STD_LOGIC := '0';
        P9_CLK2    : in  STD_LOGIC := '1';
        P10_CLR2n  : in  STD_LOGIC := '1';
        P11_K2     : in  STD_LOGIC := '0';
        P12_CLK1   : in  STD_LOGIC := '1';
        P13_CLR1n  : in  STD_LOGIC := '1'
        -- P14 : VCC
    );
end component;

end package components_pkg; 