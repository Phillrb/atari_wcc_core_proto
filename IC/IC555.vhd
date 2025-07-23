library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--           555
--        TIMER IC
--(DIGITAL BEHAVIORAL MODEL)
--        ___  ___
--       |   \/   |
--  GND -| 1    8 |- VCC
-- TRIG -| 2    7 |- DISCH
--  OUT -| 3    6 |- THRES
--  RST -| 4    5 |- CTRL
--       |________|

entity 555_timer is
	Port (
		P1_GND   : in  STD_LOGIC := '0';  -- Ground
		P2_TRIG  : in  STD_LOGIC := '1';  -- Trigger input
		P3_OUT   : out STD_LOGIC;         -- Output
		P4_RST   : in  STD_LOGIC := '1';  -- Reset (active low)
		P5_CTRL  : in  STD_LOGIC := '0';  -- Control voltage (not used in digital)
		P6_THRES : in  STD_LOGIC := '0';  -- Threshold input
		P7_DISCH : out STD_LOGIC;         -- Discharge output
		P8_VCC   : in  STD_LOGIC := '1'   -- Power supply
	);
end 555_timer;

architecture Behavioral of 555_timer is

-- Internal signals for timer state
signal timer_state : STD_LOGIC := '0';  -- '0' = stable, '1' = unstable
signal output_state : STD_LOGIC := '0';
signal discharge_state : STD_LOGIC := '1';

-- Timer constants (can be adjusted for different timing)
constant TRIGGER_THRESHOLD : STD_LOGIC := '0';  -- Trigger when input goes below this
constant THRESHOLD_LEVEL : STD_LOGIC := '1';    -- Threshold when input goes above this

begin

-- Main timer logic
process(P2_TRIG, P6_THRES, P4_RST)
begin
    if P4_RST = '0' then
        -- Reset condition
        timer_state <= '0';
        output_state <= '0';
        discharge_state <= '1';
    else
        -- Normal operation
        if P2_TRIG = TRIGGER_THRESHOLD and timer_state = '0' then
            -- Trigger condition - start timer
            timer_state <= '1';
            output_state <= '1';
            discharge_state <= '0';
        elsif P6_THRES = THRESHOLD_LEVEL and timer_state = '1' then
            -- Threshold condition - end timer
            timer_state <= '0';
            output_state <= '0';
            discharge_state <= '1';
        end if;
    end if;
end process;

-- Output assignments
P3_OUT <= output_state;
P7_DISCH <= discharge_state;

end Behavioral; 