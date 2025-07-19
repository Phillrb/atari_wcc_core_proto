library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--        74LS83
--   4-bit Binary Full Adder
--       ___  ___
--      |   \/   |
--  A1 -| 1   16 |- VCC
--  B1 -| 2   15 |- S1
--  A2 -| 3   14 |- B2
--  S2 -| 4   13 |- S3
--  A3 -| 5   12 |- B3
--  S4 -| 6   11 |- A4
--  B4 -| 7   10 |- C4
--  GND-| 8    9 |- C0
--      |________|

entity LS83 is
    Port (
        P1_A1  : in  STD_LOGIC := '0';
        P2_B1  : in  STD_LOGIC := '0';
        P3_A2  : in  STD_LOGIC := '0';
        P4_S2  : out STD_LOGIC;
        P5_A3  : in  STD_LOGIC := '0';
        P6_S4  : out STD_LOGIC;
        P7_B4  : in  STD_LOGIC := '0';
        -- P8 : GND
        P9_C0  : in  STD_LOGIC := '0';
        P10_C4 : out STD_LOGIC;
        P11_A4 : in  STD_LOGIC := '0';
        P12_B3 : in  STD_LOGIC := '0';
        P13_S3 : out STD_LOGIC;
        P14_B2 : in  STD_LOGIC := '0';
        P15_S1 : out STD_LOGIC
        -- P16 : VCC
    );
end LS83;

architecture Behavioral of LS83 is
    signal c1, c2, c3 : STD_LOGIC;
begin
    -- Bit 1 (LSB)
    P15_S1 <= P1_A1 xor P2_B1 xor P9_C0;
    c1     <= (P1_A1 and P2_B1) or (P1_A1 and P9_C0) or (P2_B1 and P9_C0);

    -- Bit 2
    P4_S2  <= P3_A2 xor P14_B2 xor c1;
    c2     <= (P3_A2 and P14_B2) or (P3_A2 and c1) or (P14_B2 and c1);

    -- Bit 3
    P13_S3 <= P5_A3 xor P12_B3 xor c2;
    c3     <= (P5_A3 and P12_B3) or (P5_A3 and c2) or (P12_B3 and c2);

    -- Bit 4 (MSB)
    P6_S4  <= P11_A4 xor P7_B4 xor c3;
    P10_C4 <= (P11_A4 and P7_B4) or (P11_A4 and c3) or (P7_B4 and c3);
end Behavioral; 