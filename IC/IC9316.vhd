library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--          9316
--    Synchronous 4-Bit
--        Counter
--        ___  ___
--       |   \/   |
-- CLR! -| 1   16 |- VCC
--  CLK -| 2   15 |- RC
--    A -| 3   14 |- QA
--    B -| 4   13 |- QB
--    C -| 5   12 |- QC
--    D -| 6   11 |- QD
--  CEP -| 7   10 |- CET
--  GND -| 8    9 |- LD!
--       |________|
--
-- P1_CLRn  : Clear (active low)
-- P2_CLK   : Clock
-- P3_A     : Parallel load data A
-- P4_B     : Parallel load data B
-- P5_C     : Parallel load data C
-- P6_D     : Parallel load data D
-- P7_CEP   : Count Enable Parallel (P)
-- P8_GND   : GND (not implemented)
-- P9_LDn   : Load (active low)
-- P10_CET  : Count Enable Trickle (T)
-- P11_QD   : QD output
-- P12_QC   : QC output
-- P13_QB   : QB output
-- P14_QA   : QA output
-- P15_RC   : Ripple carry
-- P16_VCC  : VCC (not implemented)

entity IC9316 is
    Port (
        P1_CLRn  : in  STD_LOGIC;      -- Pin 1: Clear (active low)
        P2_CLK   : in  STD_LOGIC;      -- Pin 2: Clock
        P3_A     : in  STD_LOGIC;      -- Pin 3: Parallel load data A
        P4_B     : in  STD_LOGIC;      -- Pin 4: Parallel load data B
        P5_C     : in  STD_LOGIC;      -- Pin 5: Parallel load data C
        P6_D     : in  STD_LOGIC;      -- Pin 6: Parallel load data D
        P7_CEP   : in  STD_LOGIC;      -- Pin 7: Count Enable Parallel (P)
        -- P8_GND : in  STD_LOGIC := '0'; -- Pin 8: GND (not implemented)
        P9_LDn   : in  STD_LOGIC;      -- Pin 9: Load (active low)
        P10_CET  : in  STD_LOGIC;      -- Pin 10: Count Enable Trickle (T)
        P11_QD   : out STD_LOGIC;      -- Pin 11: QD output
        P12_QC   : out STD_LOGIC;      -- Pin 12: QC output
        P13_QB   : out STD_LOGIC;      -- Pin 13: QB output
        P14_QA   : out STD_LOGIC;      -- Pin 14: QA output
        P15_RC   : out STD_LOGIC       -- Pin 15: Ripple carry
        -- P16_VCC : in  STD_LOGIC := '1' -- Pin 16: VCC (not implemented)
    );
end IC9316;

architecture Behavioral of IC9316 is
    signal count : unsigned(3 downto 0) := (others => '0');
    signal load_data : unsigned(3 downto 0);

    -- Utility function for debug
    function u4_to_str(u : unsigned) return string is
        variable s : string(1 to 4);
    begin
        for i in 0 to 3 loop
            s(4-i) := character'VALUE(std_ulogic'image(std_logic(u(i))));
        end loop;
        return s;
    end function;

begin
    -- Parallel load data
    load_data <= P6_D & P5_C & P4_B & P3_A;

    -- Synchronous counter process with debug
    process(P2_CLK, P1_CLRn)
    begin
        if P1_CLRn = '0' then
            count <= (others => '0');
            report "[IC9316] Async clear: count=" & u4_to_str(count);
        elsif rising_edge(P2_CLK) then
            if P9_LDn = '0' then
                count <= load_data;
                report "[IC9316] Parallel load: load_data=" & u4_to_str(load_data) & " -> count=" & u4_to_str(load_data);
            elsif (P7_CEP = '1' and P10_CET = '1') then
                count <= count + 1;
                report "[IC9316] Count increment: count=" & u4_to_str(count + 1);
            else
                report "[IC9316] No count: count=" & u4_to_str(count);
            end if;
        end if;
    end process;

    -- Outputs (always driven)
    P14_QA <= std_logic(count(0));
    P13_QB <= std_logic(count(1));
    P12_QC <= std_logic(count(2));
    P11_QD <= std_logic(count(3));

    -- Ripple carry: high when count is 1111 and both enables are high
    P15_RC <= '1' when (count = "1111" and P7_CEP = '1' and P10_CET = '1') else '0';

end Behavioral; 