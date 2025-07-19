library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--        74LS153
--   Dual 4-Input Multiplexer
--       ___  ___
--      |   \/   |
--  1Y -| 1   16 |- VCC
--  1A -| 2   15 |- 2Y
--  1B -| 3   14 |- 2A
--  1C -| 4   13 |- 2B
--  1D -| 5   12 |- 2C
--  1S0-| 6   11 |- 2D
--  1S1-| 7   10 |- 2S0
--  GND-| 8    9 |- 2S1
--      |________|

entity LS153 is
    Port (
        P1_1Y  : out STD_LOGIC;
        P2_1A  : in  STD_LOGIC := '0';
        P3_1B  : in  STD_LOGIC := '0';
        P4_1C  : in  STD_LOGIC := '0';
        P5_1D  : in  STD_LOGIC := '0';
        P6_1S0 : in  STD_LOGIC := '0';
        P7_1S1 : in  STD_LOGIC := '0';
        -- P8 : GND
        P9_2S1 : in  STD_LOGIC := '0';
        P10_2S0: in  STD_LOGIC := '0';
        P11_2D : in  STD_LOGIC := '0';
        P12_2C : in  STD_LOGIC := '0';
        P13_2B : in  STD_LOGIC := '0';
        P14_2A : in  STD_LOGIC := '0';
        P15_2Y : out STD_LOGIC
        -- P16 : VCC
    );
end LS153;

architecture Behavioral of LS153 is
begin
    -- Multiplexer 1 (1Y output)
    P1_1Y <= P2_1A when (P6_1S0 = '0' and P7_1S1 = '0') else
              P3_1B when (P6_1S0 = '1' and P7_1S1 = '0') else
              P4_1C when (P6_1S0 = '0' and P7_1S1 = '1') else
              P5_1D when (P6_1S0 = '1' and P7_1S1 = '1') else
              '0';

    -- Multiplexer 2 (2Y output)
    P15_2Y <= P14_2A when (P10_2S0 = '0' and P9_2S1 = '0') else
               P13_2B when (P10_2S0 = '1' and P9_2S1 = '0') else
               P12_2C when (P10_2S0 = '0' and P9_2S1 = '1') else
               P11_2D when (P10_2S0 = '1' and P9_2S1 = '1') else
               '0';
end Behavioral; 