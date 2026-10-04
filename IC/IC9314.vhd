library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--          9314
--       Quad Latch
--        ___  ___
--       |   \/   |
--   E! -| 1   16 |- VCC
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
-- E! is the common latch enable (active low, pin 1).
-- P1_OEn retains its legacy port name for compatibility; this is NOT a tri-state OE.
-- MR! is Master Reset (active low, pin 9)
-- VCC is pin 16 (not implemented)

entity IC9314 is
    Port (
        P1_OEn  : in  STD_LOGIC;      -- Pin 1: Common latch enable, active low
        P2_S0n  : in  STD_LOGIC;      -- Pin 2: Set Input 0 (active low)
        P3_D0   : in  STD_LOGIC;      -- Pin 3: Data 0
        P4_D1   : in  STD_LOGIC;      -- Pin 4: Data 1
        P5_S2n  : in  STD_LOGIC;      -- Pin 5: Set Input 2 (active low)
        P6_D2   : in  STD_LOGIC;      -- Pin 6: Data 2
        P7_D3   : in  STD_LOGIC;      -- Pin 7: Data 3
        -- P8_GND : in  STD_LOGIC := '0'; -- Pin 8: Ground (not implemented)
        P9_MRn  : in  STD_LOGIC;      -- Pin 9: Master Reset, active low
        P10_Q3  : out STD_LOGIC;      -- Pin 10: Q3 output
        P11_S3n : in  STD_LOGIC;      -- Pin 11: Set Input 3 (active low)
        P12_Q2  : out STD_LOGIC;      -- Pin 12: Q2 output
        P13_Q1  : out STD_LOGIC;      -- Pin 13: Q1 output
        P14_S1n : in  STD_LOGIC;      -- Pin 14: Set Input 1 (active low)
        P15_Q0  : out STD_LOGIC       -- Pin 15: Q0 output
        -- P16_VCC : in  STD_LOGIC := '1' -- Pin 16: Power (not implemented)
    );
end IC9314;

architecture Behavioral of IC9314 is
    signal latch : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');

begin
    -- National Semiconductor 9314 datasheet, Functional Description / Truth Table:
    -- MRn=0 resets regardless of E. E=1 stores all four outputs.
    -- E=0: D=0 resets; D=1,S=0 sets; D=1,S=1 holds (R/S mode).
    -- Tying S low therefore gives a transparent D latch while E is low.
    process(P1_OEn, P2_S0n, P14_S1n, P5_S2n, P11_S3n,
            P3_D0, P4_D1, P6_D2, P7_D3, P9_MRn)
        variable data_inputs, set_inputs : std_logic_vector(3 downto 0);
    begin
        data_inputs := P7_D3 & P6_D2 & P4_D1 & P3_D0;
        set_inputs := P11_S3n & P5_S2n & P14_S1n & P2_S0n;
        if P9_MRn = '0' then
            latch <= (others => '0');
        elsif P1_OEn = '0' then
            for i in 0 to 3 loop
                if data_inputs(i) = '0' then
                    latch(i) <= '0';
                elsif data_inputs(i) = '1' and set_inputs(i) = '0' then
                    latch(i) <= '1';
                end if;
            end loop;
        end if;
    end process;

    -- The 9314 has actively driven outputs, including while its enable is high.
    P15_Q0 <= latch(0);
    P13_Q1 <= latch(1);
    P12_Q2 <= latch(2);
    P10_Q3 <= latch(3);
end Behavioral;
