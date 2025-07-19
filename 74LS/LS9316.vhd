library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--        74LS9316
--  4-Bit Synchronous Binary Counter
--  with Asynchronous Reset
--        ___  ___
--       |   \/   |
--  CLK -| 1   16 |- VCC
--  RST -| 2   15 |- Q3
--  ENP -| 3   14 |- Q2
--  ENT -| 4   13 |- Q1
--  Q0  -| 5   12 |- Q0
--  LD  -| 6   11 |- TC
--  A   -| 7   10 |- B
--  GND -| 8    9 |- C
--       |________|

entity LS9316 is
    Port (
        P1_CLK  : in  STD_LOGIC := '0';
        P2_RST  : in  STD_LOGIC := '1';
        P3_ENP  : in  STD_LOGIC := '1';
        P4_ENT  : in  STD_LOGIC := '1';
        P5_Q0   : out STD_LOGIC;
        P6_LD   : in  STD_LOGIC := '1';
        P7_A    : in  STD_LOGIC := '0';
        -- P8 : GND
        P9_C    : in  STD_LOGIC := '0';
        P10_B   : in  STD_LOGIC := '0';
        P11_TC  : out STD_LOGIC;
        P12_Q0  : out STD_LOGIC;
        P13_Q1  : out STD_LOGIC;
        P14_Q2  : out STD_LOGIC;
        P15_Q3  : out STD_LOGIC
        -- P16 : VCC
    );
end LS9316;

architecture Behavioral of LS9316 is
    signal count : unsigned(3 downto 0) := "0000";
    signal load_data : STD_LOGIC_VECTOR(3 downto 0);
begin
    -- Load data from inputs (A, B, C, D where D is not connected in this implementation)
    load_data <= P7_A & P10_B & P9_C & '0';
    
    -- Main counter process
    process(P1_CLK, P2_RST)
    begin
        if P2_RST = '0' then
            -- Asynchronous reset
            count <= "0000";
        elsif rising_edge(P1_CLK) then
            if P6_LD = '0' then
                -- Load data
                count <= unsigned(load_data);
            elsif P3_ENP = '1' and P4_ENT = '1' then
                -- Count up only when both enables are high
                count <= count + 1;
            end if;
        end if;
    end process;
    
    -- Output assignments
    P5_Q0 <= count(0);
    P12_Q0 <= count(0);
    P13_Q1 <= count(1);
    P14_Q2 <= count(2);
    P15_Q3 <= count(3);
    
    -- Terminal count (TC) output - high when count reaches 1111 and ENT is high
    P11_TC <= '1' when count = "1111" and P4_ENT = '1' else '0';
    
end Behavioral; 