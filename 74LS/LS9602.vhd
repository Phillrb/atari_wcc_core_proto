library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--        74LS9602
--   Dual Retriggerable Monostable
--   Multivibrator with Clear
--       ___  ___
--      |   \/   |
--  1A -| 1   16 |- VCC
--  1B -| 2   15 |- 2B
--  1Q -| 3   14 |- 2A
--  1Qn-| 4   13 |- 2Q
-- 1CLR-| 5   12 |- 2Qn
-- 1RC -| 6   11 |- 2CLR
-- GND -| 7   10 |- 2RC
--      | 8    9 |- NC
--      |________|

entity LS9602 is
    Port (
        P1_1A   : in  STD_LOGIC := '0';
        P2_1B   : in  STD_LOGIC := '0';
        P3_1Q   : out STD_LOGIC;
        P4_1Qn  : out STD_LOGIC;
        P5_1CLR : in  STD_LOGIC := '1';
        P6_1RC  : in  STD_LOGIC := '0';
        -- P7 : GND
        -- P8 : NC
        -- P9 : NC
        P10_2RC : in  STD_LOGIC := '0';
        P11_2CLR: in  STD_LOGIC := '1';
        P12_2Qn : out STD_LOGIC;
        P13_2Q  : out STD_LOGIC;
        P14_2A  : in  STD_LOGIC := '0';
        P15_2B  : in  STD_LOGIC := '0'
        -- P16 : VCC
    );
end LS9602;

architecture Behavioral of LS9602 is
begin
    -- Simple implementation: outputs follow inputs with delay
    -- This is a simplified version for testing
    
    -- Monostable 1: Q follows A or B input with delay (clear is active low)
    P3_1Q <= P1_1A or P2_1B after 1 ns when P5_1CLR = '0' else '0';
    P4_1Qn <= not (P1_1A or P2_1B) after 1 ns when P5_1CLR = '0' else '1';
    
    -- Monostable 2: Q follows A or B input with delay (clear is active low)
    P13_2Q <= P14_2A or P15_2B after 1 ns when P11_2CLR = '0' else '0';
    P12_2Qn <= not (P14_2A or P15_2B) after 1 ns when P11_2CLR = '0' else '1';
    
end Behavioral; 