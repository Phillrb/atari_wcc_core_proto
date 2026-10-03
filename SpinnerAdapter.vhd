-- Temporary Arkanoid spinner test: FPGA input boundary, not a TM-035 TTL IC.
-- One count step per valid A rising edge; B=1 increases, B=0 decreases.
-- Synchronize both phases, reject two-bit jumps, saturate instead of wrapping.
-- Map the 10-bit count into Fig. 11 ramp thresholds; latch at vertical sync.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SpinnerAdapter is
    generic (
        POSITION_MIN : natural := 82;
        POSITION_MAX : natural := 154;
        STEP_SIZE : positive := 8; -- 128 A rising edges for approximately full travel
        REVERSE_DIRECTION : boolean := false
    );
    port (
        CLK : in std_logic;
        RESETn : in std_logic;
        QUAD_A, QUAD_B : in std_logic;
        FRAME_SYNC : in std_logic;
        COUNT_OUT : out std_logic_vector(9 downto 0);
        POSITION_OUT : out std_logic_vector(9 downto 0)
    );
end SpinnerAdapter;

architecture BoardAdapter of SpinnerAdapter is
    signal reset_pipe : std_logic_vector(1 downto 0) := "00";
    signal sync_a, sync_b : std_logic_vector(2 downto 0) := "000";
    signal previous_ab : std_logic_vector(1 downto 0) := "00";
    signal ready : natural range 0 to 4 := 0;
    signal count : natural range 0 to 1023 := 512;
    signal previous_frame : std_logic := '0';
    function mapped_position(value : natural) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(
            POSITION_MIN + (value * (POSITION_MAX-POSITION_MIN) + 511)/1023, 10));
    end function;
    signal position : std_logic_vector(9 downto 0) := mapped_position(512);
    attribute altera_attribute : string;
    attribute altera_attribute of sync_a, sync_b, reset_pipe : signal is
        "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
begin
    assert POSITION_MIN < POSITION_MAX and POSITION_MAX <= 1023
        report "Spinner position limits must be ordered and fit 10 bits" severity failure;
    assert STEP_SIZE <= 1023 report "Spinner STEP_SIZE exceeds counter range" severity failure;

    -- Asynchronous assertion, synchronous release in the game's CLOCK_7 domain.
    process(CLK, RESETn)
    begin
        if RESETn='0' then reset_pipe <= "00";
        elsif rising_edge(CLK) then reset_pipe <= reset_pipe(0) & '1';
        end if;
    end process;

    process(CLK)
        variable ab : std_logic_vector(1 downto 0);
        variable increase : boolean;
    begin
        if rising_edge(CLK) then
            if reset_pipe(1)='0' then
                sync_a <= "000"; sync_b <= "000";
                previous_ab <= "00"; ready <= 0; count <= 512;
                previous_frame <= FRAME_SYNC; position <= mapped_position(512);
            else
                sync_a <= sync_a(1 downto 0) & QUAD_A;
                sync_b <= sync_b(1 downto 0) & QUAD_B;
                ab := sync_a(2) & sync_b(2);
                previous_ab <= ab;
                if ready < 4 then
                    ready <= ready + 1; -- seed history; no invented edge at startup
                elsif (previous_ab="00" and ab="10") or
                      (previous_ab="01" and ab="11") then
                    increase := ab(0)='1';
                    if REVERSE_DIRECTION then increase := not increase; end if;
                    if increase then
                        if count > 1023-STEP_SIZE then count <= 1023;
                        else count <= count + STEP_SIZE; end if;
                    else
                        if count < STEP_SIZE then count <= 0;
                        else count <= count - STEP_SIZE; end if;
                    end if;
                end if;
                previous_frame <= FRAME_SYNC;
                if FRAME_SYNC='1' and previous_frame='0' then
                    position <= mapped_position(count);
                end if;
            end if;
        end if;
    end process;
    COUNT_OUT <= std_logic_vector(to_unsigned(count, 10));
    POSITION_OUT <= position;
end BoardAdapter;
