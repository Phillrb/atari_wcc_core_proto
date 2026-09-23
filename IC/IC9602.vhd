library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--          9602
--   Dual Retriggerable,
--   Resettable One-Shot
--        ___   ___
--       |   \/   |
-- CEXT1-| 1   16 |- VCC
-- REXT1-| 2   15 |- CEXT2
-- CLR1!-| 3   14 |- REXT2
--    B1 -| 4   13 |- CLR2!
--    A1 -| 5   12 |- B2
--    Q1 -| 6   11 |- A2
--   Q1! -| 7   10 |- Q2
--   GND -| 8    9 |- Q2!
--        |________|
--
-- Clock-driven implementation: pulse width in CLK cycles (no wait/delta storm).
-- Trigger: A rising (0->1) OR B falling (1->0). CLK must be driven (e.g. HSYNC).

entity IC9602 is
    generic (
        PULSE_WIDTH_CLKS  : integer := 1000;  -- Channel 1 pulse length in CLK cycles
        PULSE_WIDTH_CLKS2 : integer := 1000   -- Channel 2 (default same)
    );
    Port (
        CLK       : in  STD_LOGIC;  -- Clock for pulse timing (e.g. HSYNC)
        P1_CEXT1  : in  STD_LOGIC := '0';
        P2_REXT1  : in  STD_LOGIC := '0';
        P3_CLR1n  : in  STD_LOGIC := '1';
        P4_B1     : in  STD_LOGIC := '1';
        P5_A1     : in  STD_LOGIC := '0';
        P6_Q1     : out STD_LOGIC;
        P7_Q1n    : out STD_LOGIC;
        P9_Q2n    : out STD_LOGIC;
        P10_Q2    : out STD_LOGIC;
        P11_A2    : in  STD_LOGIC := '0';
        P12_B2    : in  STD_LOGIC := '1';
        P13_CLR2n : in  STD_LOGIC := '1';
        P14_REXT2 : in  STD_LOGIC := '0';
        P15_CEXT2 : in  STD_LOGIC := '0'
    );
end IC9602;

architecture Behavioral of IC9602 is
    -- Channel 1
    signal count1   : integer range 0 to PULSE_WIDTH_CLKS := 0;
    signal active1  : std_logic := '0';
    signal a1_r     : std_logic := '0';
    signal b1_r     : std_logic := '1';

    -- Channel 2
    signal count2   : integer range 0 to PULSE_WIDTH_CLKS2 := 0;
    signal active2  : std_logic := '0';
    signal a2_r     : std_logic := '0';
    signal b2_r     : std_logic := '1';

begin

    -- Channel 1 Process
    process(CLK, P3_CLR1n)
    begin
        if P3_CLR1n = '0' then
            count1  <= 0;
            active1 <= '0';
            a1_r    <= '0';
            b1_r    <= '1';
        elsif rising_edge(CLK) then
            a1_r <= P5_A1;
            b1_r <= P4_B1;

            if (a1_r = '0' and P5_A1 = '1') or (b1_r = '1' and P4_B1 = '0') then  -- A1 rising or B1 falling
                count1  <= PULSE_WIDTH_CLKS;
                active1 <= '1';
            elsif active1 = '1' then
                if count1 > 0 then
                    count1 <= count1 - 1;
                else
                    active1 <= '0';
                end if;
            end if;
        end if;
    end process;

    -- Channel 2 Process
    process(CLK, P13_CLR2n)
    begin
        if P13_CLR2n = '0' then
            count2  <= 0;
            active2 <= '0';
            a2_r    <= '0';
            b2_r    <= '1';
        elsif rising_edge(CLK) then
            a2_r <= P11_A2;
            b2_r <= P12_B2;

            if (a2_r = '0' and P11_A2 = '1') or (b2_r = '1' and P12_B2 = '0') then  -- A2 rising or B2 falling
                count2  <= PULSE_WIDTH_CLKS2;
                active2 <= '1';
            elsif active2 = '1' then
                if count2 > 0 then
                    count2 <= count2 - 1;
                else
                    active2 <= '0';
                end if;
            end if;
        end if;
    end process;

    P6_Q1  <= active1;
    P7_Q1n <= not active1;
    P10_Q2 <= active2;
    P9_Q2n <= not active2;

end Behavioral;