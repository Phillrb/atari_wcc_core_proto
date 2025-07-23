library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--          9602
--   Dual Retriggerable, 
--   Resettable One-Shot
--        ___  ___
--       |   \/   |
-- CEXT1-| 1   16 |- VCC
-- REXT1-| 2   15 |- CEXT2
-- CLR1!-| 3   14 |- REXT2
--   B1 -| 4   13 |- CLR2!
--   A1 -| 5   12 |- B2
--   Q1 -| 6   11 |- A2
--  Q1! -| 7   10 |- Q2
--  GND -| 8    9 |- Q2!
--       |________|
--
-- P1_CEXT1      : External timing capacitor 1
-- P2_REXT1      : External timing resistor/capacitor 1
-- P3_CLR1n      : Clear 1 (active low)
-- P4_B1         : Trigger B1 (active low)
-- P5_A1         : Trigger A1 (active high)
-- P6_Q1         : Q1 output
-- P7_Q1n        : Q1n output
-- P8_GND        : GND (not implemented)
-- P9_Q2n        : Q2n output
-- P10_Q2        : Q2 output
-- P11_A2        : Trigger A2 (active high)
-- P12_B2        : Trigger B2 (active low)
-- P13_CLR2n     : Clear 2 (active low)
-- P14_REXT2     : External timing resistor/capacitor 2
-- P15_CEXT2     : External timing capacitor 2
-- P16_VCC       : VCC (not implemented)

entity IC9602 is
    generic (
        PULSE_WIDTH_NS : time := 10 ns  -- Simulated pulse width
    );
    Port (
        P1_CEXT1   : in  STD_LOGIC := '0';
        P2_REXT1   : in  STD_LOGIC := '0';
        P3_CLR1n   : in  STD_LOGIC := '1';
        P4_B1      : in  STD_LOGIC := '1';
        P5_A1      : in  STD_LOGIC := '0';
        P6_Q1      : out STD_LOGIC;
        P7_Q1n     : out STD_LOGIC;
        -- P8_GND  : in  STD_LOGIC := '0';
        P9_Q2n     : out STD_LOGIC;
        P10_Q2     : out STD_LOGIC;
        P11_A2     : in  STD_LOGIC := '0';
        P12_B2     : in  STD_LOGIC := '1';
        P13_CLR2n  : in  STD_LOGIC := '1';
        P14_REXT2  : in  STD_LOGIC := '0';
        P15_CEXT2  : in  STD_LOGIC := '0'
        -- P16_VCC : in  STD_LOGIC := '1'
    );
end IC9602;

architecture Behavioral of IC9602 is
    signal q1, q2 : std_logic := '0';
    signal timer1, timer2 : time := 0 ns;
    signal pulse_active1, pulse_active2 : boolean := false;
    signal last_A1, last_B1, last_A2, last_B2 : std_logic := '0';

begin
    -- Monostable 1: Simple process
    process
    begin
        wait for 1 ns;
        if P3_CLR1n = '0' then
            if q1 = '1' or pulse_active1 then
                report "[IC9602] Monostable 1 cleared at " & time'image(now);
            end if;
            q1 <= '0';
            pulse_active1 <= false;
            timer1 <= 0 ns;
        elsif ((last_A1 = '0' and P5_A1 = '1') or (last_B1 = '1' and P4_B1 = '0')) then
            if pulse_active1 then
                report "[IC9602] Monostable 1 retriggered at " & time'image(now);
            else
                report "[IC9602] Monostable 1 triggered at " & time'image(now);
            end if;
            q1 <= '1';
            pulse_active1 <= true;
            timer1 <= now;
        elsif pulse_active1 and (now - timer1 >= PULSE_WIDTH_NS) then
            report "[IC9602] Monostable 1 pulse ended at " & time'image(now);
            q1 <= '0';
            pulse_active1 <= false;
        end if;
        last_A1 <= P5_A1;
        last_B1 <= P4_B1;
    end process;

    -- Monostable 2: Simple process
    process
    begin
        wait for 1 ns;
        if P13_CLR2n = '0' then
            if q2 = '1' or pulse_active2 then
                report "[IC9602] Monostable 2 cleared at " & time'image(now);
            end if;
            q2 <= '0';
            pulse_active2 <= false;
            timer2 <= 0 ns;
        elsif ((last_A2 = '0' and P11_A2 = '1') or (last_B2 = '1' and P12_B2 = '0')) then
            if pulse_active2 then
                report "[IC9602] Monostable 2 retriggered at " & time'image(now);
            else
                report "[IC9602] Monostable 2 triggered at " & time'image(now);
            end if;
            q2 <= '1';
            pulse_active2 <= true;
            timer2 <= now;
        elsif pulse_active2 and (now - timer2 >= PULSE_WIDTH_NS) then
            report "[IC9602] Monostable 2 pulse ended at " & time'image(now);
            q2 <= '0';
            pulse_active2 <= false;
        end if;
        last_A2 <= P11_A2;
        last_B2 <= P12_B2;
    end process;

    -- Output assignments
    P6_Q1  <= q1;
    P7_Q1n <= not q1;
    P10_Q2 <= q2;
    P9_Q2n <= not q2;

end Behavioral; 