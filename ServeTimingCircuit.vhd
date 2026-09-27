-- Serve Timing Circuit for Goal IV (WCC) - TM-035 Figure 12
-- ICs: J5(9602 ch1+ch2), L5(LS74), H4(LS02 gate 4)
-- Develops SERVE and SERVEn signals used to initiate ball serve.
-- Also provides STOP/STOPn from J5 ch1 (catch timing for Figure 13).
--
-- J5 ch2 one-shot (~3s) triggered by GOALn falling (A2, START low) or START rising (B2, GOALn high).
-- Output Q2n normally HIGH, goes LOW during pulse.
-- J5 Q2n -> L5 CLR1n (pin 1) and D1 (pin 2): clears FF1 and holds D=0 during pulse.
-- After delay, V128n rising edge clocks L5-5 (Q1=HIGH since D1=HIGH).
-- H4 NOR(H_ENABLE, H256n) provides right-edge-of-playfield clock to L5-9/8.
-- L5-9/8 clocks D2=Q1=HIGH -> SERVE goes HIGH.
--
-- J5 ch1 one-shot: triggered by catch circuit (D8-9 Q2 -> A1).
-- Cleared by C5-3 output. Output STOP/STOPn used by ball-off-paddle logic.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ServeTimingCircuit is
    Generic (
        SERVE_DELAY_CLKS : natural := 21428571;  -- J5 ch2 pulse width in CLK cycles (3 seconds at the current board clock)
        STOP_DELAY_CLKS  : natural := 21428571   -- J5 ch1 pulse width in CLK cycles (3 seconds at the current board clock)
    );
    Port (
        CLOCK_7  : in  STD_LOGIC;   -- 7.159 MHz clock for IC9602 timing
        GOALn    : in  STD_LOGIC;   -- J5 pin 11 (A2); normally HIGH, LOW on goal scored
        START    : in  STD_LOGIC;   -- J5 pin 12 (B2); from Start circuit
        V128n    : in  STD_LOGIC;   -- L5 pin 3 (CLK1); inverted 128V from vertical sync
        H_ENABLE : in  STD_LOGIC;   -- H4 pin 12 (B4); from Playfield circuit
        H256n    : in  STD_LOGIC;   -- H4 pin 11 (A4); inverted 256H from horizontal sync
        SERVE    : out STD_LOGIC;   -- L5 pin 9 (Q2)
        SERVEn   : out STD_LOGIC;   -- L5 pin 8 (Q2n)
        -- J5 channel 1: catch timing (Figure 13)
        CATCH_TRIGGER : in  STD_LOGIC;  -- J5 pin 5 (A1); from D8-9 Q2
        CATCH_CLRn    : in  STD_LOGIC;  -- J5 pin 3 (CLR1n); from C5-3 output
        STOP          : out STD_LOGIC;  -- J5 pin 6 (Q1)
        STOPn         : out STD_LOGIC   -- J5 pin 7 (Q1n)
    );
end ServeTimingCircuit;

architecture Structural of ServeTimingCircuit is
    signal j5_q2n : STD_LOGIC;  -- J5 pin 9: Q2n (normally HIGH, LOW during pulse)
    signal l5_q1  : STD_LOGIC;  -- L5 pin 5: Q1
    signal h4_13  : STD_LOGIC;  -- H4 pin 13: NOR(H_ENABLE, H256n) = right-edge pulse
begin

    -- J5 (IC9602, dual): ch1 = catch/stop, ch2 = serve delay
    -- Ch1: Pin 5 (A1) = CATCH_TRIGGER, Pin 4 (B1) = '0' (unused trigger)
    --       Pin 3 (CLR1n) = CATCH_CLRn, Pin 1 (CEXT1) = '1', Pin 2 (REXT1) = '1'
    --       Output: Pin 6 (Q1) = STOP, Pin 7 (Q1n) = STOPn
    -- Ch2: Pin 11 (A2) = GOALn, Pin 12 (B2) = START
    --       Pin 13 (CLR2n) = '1', Pin 14 (REXT2) = '1', Pin 15 (CEXT2) = '1'
    --       Output: Pin 9 (Q2n) normally HIGH, goes LOW for SERVE_DELAY_CLKS
    U_J5: entity work.IC9602
        generic map(
            PIN_ACCURATE     => true,
            PULSE_WIDTH_CLKS  => STOP_DELAY_CLKS,
            PULSE_WIDTH_CLKS2 => SERVE_DELAY_CLKS
        )
        port map(
            CLK       => CLOCK_7,
            -- Channel 1: catch/stop
            P1_CEXT1  => '1',           -- VCC through 100uF cap
            P2_REXT1  => '1',           -- VCC through resistor
            P3_CLR1n  => CATCH_CLRn,    -- C5-3 output
            P4_B1     => '0',           -- B trigger unused
            P5_A1     => CATCH_TRIGGER, -- D8-9 Q2
            P6_Q1     => STOP,          -- STOP output
            P7_Q1n    => STOPn,         -- STOPn output
            -- Channel 2: serve delay
            P9_Q2n    => j5_q2n,
            P10_Q2    => open,
            P11_A2    => GOALn,
            P12_B2    => START,
            P13_CLR2n => '1',
            P14_REXT2 => '1',
            P15_CEXT2 => '1'
        );

    -- L5 (LS74): dual D flip-flop
    -- FF1 (L5-5): CLR1n=J5 Q2n (pin 1), D1=J5 Q2n (pin 2), CLK1=V128n (pin 3), SET1n='1' (pin 4)
    -- FF2 (L5-9/8): CLR2n='1' (pin 13), D2=Q1 (pin 12), CLK2=H4 out (pin 11), SET2n='1' (pin 10)
    -- Q2=SERVE (pin 9), Q2n=SERVEn (pin 8)
    U_L5: entity work.LS74
        port map(
            P1_CLR1n  => j5_q2n,    -- J5 pin 9 (Q2n)
            P2_D1     => j5_q2n,    -- J5 pin 9 (Q2n)
            P3_CLK1   => V128n,     -- inverted 128V
            P4_SET1n  => '1',       -- VCC
            P5_Q1     => l5_q1,     -- -> D2 (pin 12)
            P6_Q1n    => open,
            P8_Q2n    => SERVEn,    -- SERVEn output
            P9_Q2     => SERVE,     -- SERVE output
            P10_SET2n => '1',       -- VCC
            P11_CLK2  => h4_13,     -- H4 gate 4 output (pin 13)
            P12_D2    => l5_q1,     -- L5 pin 5 (Q1)
            P13_CLR2n => '1'        -- VCC (not cleared by one-shot)
        );

    -- H4 (LS02, gate 4: pins 11,12 -> 13): negative-true AND
    -- NOR(H_ENABLE, H256n) -> HIGH when both LOW = right edge of playfield
    -- Other gates of H4 belong to PlayfieldCircuit
    U_H4: entity work.LS02
        port map(
            -- Gate 1: unused
            P2_A1  => '0',  P3_B1  => '0',  P1_Y1  => open,
            -- Gate 2: unused
            P5_A2  => '0',  P6_B2  => '0',  P4_Y2  => open,
            -- Gate 3: unused
            P8_A3  => '0',  P9_B3  => '0',  P10_Y3 => open,
            -- Gate 4: H_ENABLE (pin 12) NOR H256n (pin 11)
            P11_A4 => H256n,
            P12_B4 => H_ENABLE,
            P13_Y4 => h4_13
        );

end Structural;
