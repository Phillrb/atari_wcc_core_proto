library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity 555_tb is
end 555_tb;

architecture Behavioral of 555_tb is

-- Component declaration
component IC555 is
    Port (
        P1_GND   : in  STD_LOGIC := '0';
        P2_TRIG  : in  STD_LOGIC := '1';
        P3_OUT   : out STD_LOGIC;
        P4_RST   : in  STD_LOGIC := '1';
        P5_CTRL  : in  STD_LOGIC := '0';
        P6_THRES : in  STD_LOGIC := '0';
        P7_DISCH : out STD_LOGIC;
        P8_VCC   : in  STD_LOGIC := '1'
    );
end component;

-- Test signals
signal GND, VCC : STD_LOGIC;
signal TRIG, THRES, RST, CTRL : STD_LOGIC;
signal OUT_sig, DISCH : STD_LOGIC;

begin

-- Instantiate the 555 timer
dut: IC555
    port map (
        P1_GND => GND,
        P2_TRIG => TRIG,
        P3_OUT => OUT_sig,
        P4_RST => RST,
        P5_CTRL => CTRL,
        P6_THRES => THRES,
        P7_DISCH => DISCH,
        P8_VCC => VCC
    );

-- Test stimulus
stim_proc: process
begin
    -- Initialize signals
    GND <= '0';
    VCC <= '1';
    TRIG <= '1';
    THRES <= '0';
    RST <= '1';
    CTRL <= '0';
    
    wait for 10 ns;
    
    -- Verify initial state
    assert (OUT_sig = '0') report "Initial output should be low" severity error;
    assert (DISCH = '1') report "Initial discharge should be high" severity error;
    
    -- Test 1: Normal trigger operation
    report "Test 1: Triggering the timer";
    TRIG <= '0';  -- Trigger the timer
    wait for 5 ns;
    assert (OUT_sig = '1') report "Output should be high after trigger" severity error;
    assert (DISCH = '0') report "Discharge should be low after trigger" severity error;
    
    TRIG <= '1';  -- Release trigger
    wait for 5 ns;
    assert (OUT_sig = '1') report "Output should remain high after trigger release" severity error;
    assert (DISCH = '0') report "Discharge should remain low after trigger release" severity error;
    
    THRES <= '1'; -- Set threshold to end timer
    wait for 5 ns;
    assert (OUT_sig = '0') report "Output should be low after threshold" severity error;
    assert (DISCH = '1') report "Discharge should be high after threshold" severity error;
    
    THRES <= '0'; -- Reset threshold
    wait for 10 ns;
    
    -- Test 2: Reset functionality
    report "Test 2: Testing reset";
    TRIG <= '0';  -- Trigger again
    wait for 5 ns;
    assert (OUT_sig = '1') report "Output should be high after trigger" severity error;
    assert (DISCH = '0') report "Discharge should be low after trigger" severity error;
    
    RST <= '0';   -- Reset the timer
    wait for 5 ns;
    assert (OUT_sig = '0') report "Output should be low after reset" severity error;
    assert (DISCH = '1') report "Discharge should be high after reset" severity error;
    
    RST <= '1';   -- Release reset
    wait for 10 ns;
    
    -- Test 3: Multiple trigger cycles
    report "Test 3: Multiple trigger cycles";
    for i in 1 to 3 loop
        TRIG <= '0';
        wait for 5 ns;
        assert (OUT_sig = '1') report "Output should be high after trigger cycle " & integer'image(i) severity error;
        assert (DISCH = '0') report "Discharge should be low after trigger cycle " & integer'image(i) severity error;
        
        TRIG <= '1';
        wait for 5 ns;
        THRES <= '1';
        wait for 5 ns;
        assert (OUT_sig = '0') report "Output should be low after threshold cycle " & integer'image(i) severity error;
        assert (DISCH = '1') report "Discharge should be high after threshold cycle " & integer'image(i) severity error;
        
        THRES <= '0';
        wait for 10 ns;
    end loop;
    
    report "555 Timer test completed successfully - all assertions passed!";
    wait;
end process;

end Behavioral; 