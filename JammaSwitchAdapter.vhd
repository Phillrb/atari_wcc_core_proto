-- FPGA board boundary, not an IC on the TM-035 PCB.
-- Normally-open switch to GND; external/FPGA pull-up supplies idle HIGH.
-- Two-stage synchronizer followed by stable-level debounce. PRESSED models
-- the settled output of the original SPDT contact latch, not its two wires.
-- This explicit boundary replaces the analogue/contact behaviour of A8's
-- cross-coupled switch latch; it must not replace downstream TTL game logic.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity JammaSwitchAdapter is
    generic (STABLE_CLOCKS : positive := 35714); -- 5 ms at board CLOCK_7
    port (CLK : in std_logic; SWITCHn : in std_logic;
          PRESSED : out std_logic);
end JammaSwitchAdapter;
architecture BoardAdapter of JammaSwitchAdapter is
    signal sync_meta, sync_level : std_logic := '1';
    signal settled : std_logic := '1';
    signal count : natural range 0 to STABLE_CLOCKS-1 := 0;
    attribute altera_attribute : string;
    attribute altera_attribute of sync_meta : signal is
        "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
begin
    process(CLK)
    begin
        if rising_edge(CLK) then
            sync_meta <= SWITCHn;
            sync_level <= sync_meta;
            if sync_level = settled then
                count <= 0;
            elsif sync_level = '0' or sync_level = '1' then
                if count = STABLE_CLOCKS-1 then
                    settled <= sync_level;
                    count <= 0;
                else
                    count <= count + 1;
                end if;
            else
                count <= 0;
            end if;
        end if;
    end process;
    PRESSED <= not settled; -- polarity conversion at the board boundary
end BoardAdapter;
