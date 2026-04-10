library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--          9314
--       Quad Latch
--        ___  ___
--       |   \/   |
--  OE! -| 1   16 |- VCC
--  S0! -| 2   15 |- Q0
--   D0 -| 3   14 |- S1!
--   D1 -| 4   13 |- Q1
--  S2! -| 5   12 |- Q2
--   D2 -| 6   11 |- S3!
--   D3 -| 7   10 |- Q3
--  GND -| 8    9 |- MR!
--       |________|
--
-- S0! to S3! are Set Inputs (Active Low)
-- D0 to D3 are Data Inputs
-- OE! is Output Enable (active low, 3-state, pin 1)
-- MR! is Master Reset (active low, pin 9)
-- VCC is pin 16 (not implemented)

entity IC9314 is
    Port (
        P1_OEn  : in  STD_LOGIC;      -- Pin 1: Output Enable, active low
        P2_S0n  : in  STD_LOGIC;      -- Pin 2: Set Input 0 (active low)
        P3_D0   : in  STD_LOGIC;      -- Pin 3: Data 0
        P4_D1   : in  STD_LOGIC;      -- Pin 4: Data 1
        P5_S2n  : in  STD_LOGIC;      -- Pin 5: Set Input 2 (active low)
        P6_D2   : in  STD_LOGIC;      -- Pin 6: Data 2
        P7_D3   : in  STD_LOGIC;      -- Pin 7: Data 3
        -- P8_GND : in  STD_LOGIC := '0'; -- Pin 8: Ground (not implemented)
        P9_MRn  : in  STD_LOGIC;      -- Pin 9: Master Reset, active low
        P10_Q3  : out STD_LOGIC;      -- Pin 10: Q3 output (3-state)
        P11_S3n : in  STD_LOGIC;      -- Pin 11: Set Input 3 (active low)
        P12_Q2  : out STD_LOGIC;      -- Pin 12: Q2 output (3-state)
        P13_Q1  : out STD_LOGIC;      -- Pin 13: Q1 output (3-state)
        P14_S1n : in  STD_LOGIC;      -- Pin 14: Set Input 1 (active low)
        P15_Q0  : out STD_LOGIC       -- Pin 15: Q0 output (3-state)
        -- P16_VCC : in  STD_LOGIC := '1' -- Pin 16: Power (not implemented)
    );
end IC9314;

architecture Behavioral of IC9314 is
    signal latch : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');

begin
    -- Latch logic: each latch is set by its Set Input (active low), cleared by master reset (active low)
    process(P2_S0n, P14_S1n, P5_S2n, P11_S3n, P3_D0, P4_D1, P6_D2, P7_D3, P9_MRn)
    begin
        if P9_MRn = '0' then
            latch <= (others => '0');
        else
            -- P2_S0n (Set Input 0)
            if P2_S0n = '0' then
                latch(0) <= P3_D0;
            end if;
            -- P14_S1n (Set Input 1)
            if P14_S1n = '0' then
                latch(1) <= P4_D1;
            end if;
            -- P5_S2n (Set Input 2)
            if P5_S2n = '0' then
                latch(2) <= P6_D2;
            end if;
            -- P11_S3n (Set Input 3)
            if P11_S3n = '0' then
                latch(3) <= P7_D3;
            end if;
        end if;
    end process;

    -- Output logic (3-state in hardware; held in simulation)
    -- Per 9314 datasheet: Master Reset overrides all other inputs including OE.
    -- When MRn='0', outputs are driven LOW regardless of OEn.
    -- When MRn='1' and OEn='0', outputs reflect latch contents.
    -- When MRn='1' and OEn='1', hardware is tri-state; in simulation we hold latch
    -- value (no other driver exists on these nodes in the WCC PCB, so the signal
    -- would float at its last level -- outputting 'Z' propagates as 'U' through XOR
    -- gates and corrupts downstream counters).
    P15_Q0 <= '0'      when P9_MRn = '0' else latch(0);
    P13_Q1 <= '0'      when P9_MRn = '0' else latch(1);
    P12_Q2 <= '0'      when P9_MRn = '0' else latch(2);
    P10_Q3 <= '0'      when P9_MRn = '0' else latch(3);

end Behavioral; 