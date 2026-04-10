library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--        74LS153
--     Dual 4-Input
--      Multiplexer
--       ___  ___
--      |   \/   |
-- 1Ea -| 1   16 |- VCC
--  S1 -| 2   15 |- 2Ea
-- 1I3 -| 3   14 |- S0
-- 1I2 -| 4   13 |- 2I3
-- 1I1 -| 5   12 |- 2I2
-- 1I0 -| 6   11 |- 2I1
--  1Y -| 7   10 |- 2I0
-- GND -| 8    9 |- 2Y
--      |________|

entity LS153 is
    Port (
        P1_Ea   : in  STD_LOGIC := '0';   -- Enable Mux 1 (active low)
        P2_S1   : in  STD_LOGIC := '0';   -- Select 1 (shared)
        P3_1I3  : in  STD_LOGIC := '0';   -- Mux 1 data input 3
        P4_1I2  : in  STD_LOGIC := '0';   -- Mux 1 data input 2
        P5_1I1  : in  STD_LOGIC := '0';   -- Mux 1 data input 1
        P6_1I0  : in  STD_LOGIC := '0';   -- Mux 1 data input 0
        P7_1Y   : out STD_LOGIC;           -- Mux 1 output
        -- P8  : GND
        P9_2Y   : out STD_LOGIC;           -- Mux 2 output
        P10_2I0 : in  STD_LOGIC := '0';   -- Mux 2 data input 0
        P11_2I1 : in  STD_LOGIC := '0';   -- Mux 2 data input 1
        P12_2I2 : in  STD_LOGIC := '0';   -- Mux 2 data input 2
        P13_2I3 : in  STD_LOGIC := '0';   -- Mux 2 data input 3
        P14_S0  : in  STD_LOGIC := '0';   -- Select 0 (shared)
        P15_Eb  : in  STD_LOGIC := '0'    -- Enable Mux 2 (active low)
        -- P16 : VCC
    );
end LS153;

architecture Behavioral of LS153 is
    signal sel : STD_LOGIC_VECTOR(1 downto 0);
begin
    sel <= P2_S1 & P14_S0;

    -- Multiplexer 1: output LOW when disabled (Ea=HIGH)
    P7_1Y <= '0' when P1_Ea = '1' else
             P6_1I0 when sel = "00" else
             P5_1I1 when sel = "01" else
             P4_1I2 when sel = "10" else
             P3_1I3;  -- sel = "11"

    -- Multiplexer 2: output LOW when disabled (Eb=HIGH)
    P9_2Y <= '0' when P15_Eb = '1' else
             P10_2I0 when sel = "00" else
             P11_2I1 when sel = "01" else
             P12_2I2 when sel = "10" else
             P13_2I3; -- sel = "11"
end Behavioral;
