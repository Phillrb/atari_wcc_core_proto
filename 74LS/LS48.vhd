library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--         74LS48
--     BCD-TO-7-SEGMENT
--      DECODER/DRIVER
--    (Active HIGH outputs,
--     common cathode)
--        ___  ___
--       |   \/   |
--   B  -| 1   16 |- VCC
--   C  -| 2   15 |- f
--  LT  -| 3   14 |- g
--  BI  -| 4   13 |- a
--  RBI -| 5   12 |- b
--   D  -| 6   11 |- c
--   A  -| 7   10 |- d
--  GND -| 8    9 |- e
--       |________|
--
-- LT  (pin 3): Lamp Test (active LOW) - all segments ON when LOW
-- BI  (pin 4): Blanking Input (active LOW) - all segments OFF when LOW
-- RBI (pin 5): Ripple Blanking Input (active LOW) - blanks leading zeros
--
-- Note: Pin 4 is BI/RBO on the real chip (bidirectional).
-- Here modelled as input-only (BI). RBO output function not implemented.

entity LS48 is
    Port (
        P1_B    : in  STD_LOGIC := '0';   -- BCD input B
        P2_C    : in  STD_LOGIC := '0';   -- BCD input C
        P3_LTn  : in  STD_LOGIC := '1';   -- Lamp Test (active low)
        P4_BIn  : in  STD_LOGIC := '1';   -- Blanking Input (active low)
        P5_RBIn : in  STD_LOGIC := '1';   -- Ripple Blanking Input (active low)
        P6_D    : in  STD_LOGIC := '0';   -- BCD input D
        P7_A    : in  STD_LOGIC := '0';   -- BCD input A
        -- P8   : GND
        P9_e    : out STD_LOGIC;           -- Segment e
        P10_d   : out STD_LOGIC;           -- Segment d
        P11_c   : out STD_LOGIC;           -- Segment c
        P12_b   : out STD_LOGIC;           -- Segment b
        P13_a   : out STD_LOGIC;           -- Segment a
        P14_g   : out STD_LOGIC;           -- Segment g
        P15_f   : out STD_LOGIC            -- Segment f
        -- P16  : VCC
    );
end LS48;

architecture Behavioral of LS48 is
    signal bcd : STD_LOGIC_VECTOR(3 downto 0);
    signal seg : STD_LOGIC_VECTOR(6 downto 0); -- a,b,c,d,e,f,g
begin
    bcd <= P6_D & P2_C & P1_B & P7_A;

    -- BCD to 7-segment decode (active HIGH outputs)
    -- seg = a,b,c,d,e,f,g
    --
    -- Truth table from DM74LS48 datasheet:
    --   
    --   _a_
    -- f|   |b
    --  |_g_|
    -- e|   |c
    --  |_d_|
    --
    process(bcd, P3_LTn, P4_BIn, P5_RBIn)
    begin
        if P4_BIn = '0' then
            -- Blanking: all segments OFF
            seg <= "0000000";
        elsif P3_LTn = '0' then
            -- Lamp test: all segments ON
            seg <= "1111111";
        elsif P5_RBIn = '0' and bcd = "0000" then
            -- Ripple blanking: blank if input is 0 and RBI is active
            seg <= "0000000";
        else
            -- Normal BCD decode
            case bcd is
                --              abcdefg
                when "0000" => seg <= "1111110"; -- 0
                when "0001" => seg <= "0110000"; -- 1
                when "0010" => seg <= "1101101"; -- 2
                when "0011" => seg <= "1111001"; -- 3
                when "0100" => seg <= "0110011"; -- 4
                when "0101" => seg <= "1011011"; -- 5
                when "0110" => seg <= "0011111"; -- 6
                when "0111" => seg <= "1110000"; -- 7
                when "1000" => seg <= "1111111"; -- 8
                when "1001" => seg <= "1110011"; -- 9
                -- Invalid BCD (10-15): unique patterns per datasheet
                when "1010" => seg <= "0001101"; -- 10
                when "1011" => seg <= "0011001"; -- 11
                when "1100" => seg <= "0100011"; -- 12
                when "1101" => seg <= "1001011"; -- 13
                when "1110" => seg <= "0001111"; -- 14
                when "1111" => seg <= "0000000"; -- 15 (blank)
                when others => seg <= "0000000";
            end case;
        end if;
    end process;

    -- Map segment vector to output pins
    P13_a <= seg(6);
    P12_b <= seg(5);
    P11_c <= seg(4);
    P10_d <= seg(3);
    P9_e  <= seg(2);
    P15_f <= seg(1);
    P14_g <= seg(0);

end Behavioral;
