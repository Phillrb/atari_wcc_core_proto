-- Sound Circuit - Goal IV (WCC) TM-035 Figure 20
-- ICs: J9(9602 ch1), M9(9602 ch1), E5(9602 both), L8(7400), E7(7420)
-- Develops miss, hit and bounce sounds, combined by E7 for the TV monitor.
--
-- Shared ICs: the other halves of J9/M9 and L8 gate 3 live in the player circuits.
-- P2 is +5V. R50 (1k) and the monitor's analogue audio input are external.
-- ATRCn low forces SOUND_OUT high (DC mute); high enables sound transitions.
-- RC timing is clock-quantized. M9 widths are approved adjustable estimates,
-- NOT measured hardware values; see docs/SOUND_CIRCUIT_FIG20.md.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity SoundCircuit is
    Generic (
        CLOCK_HZ        : positive := 7159090;
        GOAL_US         : positive := 81600;  -- .34*(47k+1k)*5uF
        HIT_SLOW_US     : positive := 23460;
        HIT_FAST_US     : positive := 3808;
        BOUNCE_DELAY_US : positive := 39;     -- .34*(22k+1k)*5nF = 39.1us
        BOUNCE_PULSE_US : positive := 116     -- .34*(33k+1k)*10nF = 115.6us
    );
    Port (
        -- Timing and sound inputs
        CLOCK_7      : in  STD_LOGIC;   -- clock for IC9602 pulse timing
        MISS         : in  STD_LOGIC;   -- ball passed through a goal
        HIT          : in  STD_LOGIC;   -- ball hit a player
        STOPn        : in  STD_LOGIC;   -- active-low stop from J5
        SLOW         : in  STD_LOGIC;   -- selects M9 hit pulse duration
        HIT_TONE     : in  STD_LOGIC;   -- tone from ball motion counter A4
        V32          : in  STD_LOGIC;   -- 32V from vertical counter
        BOUNCEn      : in  STD_LOGIC;   -- active-low bounce from Figure 19
        ATRCn        : in  STD_LOGIC;   -- low = mute, high = sound enabled
        -- Outputs
        GOAL         : out STD_LOGIC;  -- J9 pin 6: goal pulse
        GOALn        : out STD_LOGIC;  -- J9 pin 7: inverted goal pulse
        SCORE_SOUNDn : out STD_LOGIC;  -- L8 pin 11: active-low score sound
        SOUND_OUT    : out STD_LOGIC   -- E7 pin 6: combined sound to monitor
    );
end SoundCircuit;

architecture Structural of SoundCircuit is
    -- Convert external RC pulse durations to timing-clock cycles.
    function clocks(us : positive) return positive is
    begin
        return positive(integer(real(CLOCK_HZ) * real(us) / 1000000.0));
    end;

    constant slow_clks : positive := clocks(HIT_SLOW_US);
    signal hit_width   : positive range 1 to slow_clks;

    -- Miss sound path
    signal goal_i         : STD_LOGIC;  -- J9 pin 6 -> L8 pin 13 and GOAL
    signal score_n        : STD_LOGIC;  -- L8 pin 11 -> E7 pin 4 and SCORE_SOUNDn

    -- Hit sound path
    signal hit_trigger_n  : STD_LOGIC;  -- L8 pin 6 -> M9 pin 5
    signal hit_window     : STD_LOGIC;  -- M9 pin 6 -> L8 pin 1
    signal hit_sound_n    : STD_LOGIC;  -- L8 pin 3 -> E7 pin 1

    -- Bounce sound path
    signal bounce_delay_n : STD_LOGIC;  -- E5 pin 9 -> E5 pin 5
    signal bounce_sound_n : STD_LOGIC;  -- E5 pin 7 -> E7 pin 5

begin

    assert HIT_FAST_US <= HIT_SLOW_US
        report "fast hit width exceeds slow width" severity failure;

    -- Digital abstraction of R47/R44/C28, not an extra PCB logic gate.
    hit_width <= slow_clks when SLOW = '1' else clocks(HIT_FAST_US);

    -- Output assignments (internal signals needed for readback)
    GOAL         <= goal_i;
    SCORE_SOUNDn <= score_n;

    -- ========== J9 (IC9602) - Miss sound one-shot ==========
    -- Channel 1: MISS rising at pin 4 triggers GOAL / GOALn.
    -- R49 (47k) and C19 (5uF) set the goal pulse duration.
    J9: entity work.IC9602
        generic map(
            PIN_ACCURATE     => true,
            PULSE_WIDTH_CLKS => clocks(GOAL_US)
        )
        port map(
            CLK       => CLOCK_7,
            -- Channel 1: miss sound
            P1_CEXT1  => '1',
            P2_REXT1  => '1',
            P3_CLR1n  => '1',          -- P2 (+5V)
            P4_B1     => MISS,
            P5_A1     => '1',          -- P2 (+5V)
            P6_Q1     => goal_i,       -- -> L8 pin 13 and GOAL
            P7_Q1n    => GOALn,
            -- Channel 2: player circuit (separate instance)
            P9_Q2n    => open,
            P10_Q2    => open,
            P11_A2    => '1',
            P12_B2    => '0',
            P13_CLR2n => '0',
            P14_REXT2 => '0',
            P15_CEXT2 => '0'
        );

    -- ========== M9 (IC9602) - Hit sound one-shot ==========
    -- Channel 1: L8 pin 6 falling triggers the hit envelope.
    -- SLOW controls the duration through the R47/R44/C28 timing network.
    M9: entity work.IC9602
        generic map(
            PIN_ACCURATE     => true,
            PULSE_WIDTH_CLKS => slow_clks
        )
        port map(
            CLK         => CLOCK_7,
            WIDTH1_CLKS => hit_width,
            -- Channel 1: hit sound
            P1_CEXT1    => '1',
            P2_REXT1    => '1',
            P3_CLR1n    => '1',
            P4_B1       => '0',
            P5_A1       => hit_trigger_n,  -- from L8 pin 6
            P6_Q1       => hit_window,     -- -> L8 pin 1
            P7_Q1n      => open,
            -- Channel 2: player circuit (separate instance)
            P9_Q2n      => open,
            P10_Q2      => open,
            P11_A2      => '1',
            P12_B2      => '0',
            P13_CLR2n   => '0',
            P14_REXT2   => '0',
            P15_CEXT2   => '0'
        );

    -- ========== E5 (IC9602) - Bounce sound one-shots ==========
    -- Channel 2: BOUNCEn falling triggers Q2n at pin 9 (R67/C31).
    -- Channel 1: the falling leading edge of Q2n triggers Q1n (R68/C32).
    -- Channel 1 starts at that leading edge, not at channel 2 expiry.
    E5: entity work.IC9602
        generic map(
            PIN_ACCURATE      => true,
            PULSE_WIDTH_CLKS  => clocks(BOUNCE_PULSE_US),
            PULSE_WIDTH_CLKS2 => clocks(BOUNCE_DELAY_US)
        )
        port map(
            CLK       => CLOCK_7,
            -- Channel 1: bounce sound pulse
            P1_CEXT1  => '1',
            P2_REXT1  => '1',
            P3_CLR1n  => '1',
            P4_B1     => '0',
            P5_A1     => bounce_delay_n,  -- from E5 pin 9
            P6_Q1     => open,
            P7_Q1n    => bounce_sound_n,  -- -> E7 pin 5
            -- Channel 2: bounce trigger
            P9_Q2n    => bounce_delay_n,  -- -> E5 pin 5
            P10_Q2    => open,
            P11_A2    => BOUNCEn,
            P12_B2    => '0',
            P13_CLR2n => '1',
            P14_REXT2 => '1',
            P15_CEXT2 => '1'
        );

    -- ========== L8 (LS00) - Hit trigger and tone gating ==========
    -- Gate 1: NAND(hit envelope, HIT_TONE) -> hit sound
    -- Gate 2: NAND(STOPn, HIT) -> M9 trigger
    -- Gate 4: NAND(32V, GOAL) -> SCORE_SOUNDn
    L8: entity work.LS00
        port map(
            P1_A1  => hit_window,     -- gate 1: from M9 pin 6
            P2_B1  => HIT_TONE,
            P3_Y1  => hit_sound_n,    -- -> E7 pin 1
            P4_A2  => STOPn,          -- gate 2: hit trigger
            P5_B2  => HIT,
            P6_Y2  => hit_trigger_n,  -- -> M9 pin 5
            P9_A3  => '1', P10_B3 => '1', P8_Y3 => open,  -- gate 3: player circuit
            P12_A4 => V32,            -- gate 4: score tone
            P13_B4 => goal_i,
            P11_Y4 => score_n         -- -> E7 pin 4 and SCORE_SOUNDn
        );

    -- ========== E7 (LS20) - Sound summing and attract mute ==========
    -- Gate 1: four-input NAND, drawn as a negative-true OR in Figure 20.
    -- ATRCn low forces a constant high output to mute the monitor audio.
    E7: entity work.LS20
        port map(
            P1_A1  => hit_sound_n,    -- from L8 pin 3
            P2_B1  => ATRCn,
            P4_C1  => score_n,        -- from L8 pin 11
            P5_D1  => bounce_sound_n, -- from E5 pin 7
            P6_Y1  => SOUND_OUT,
            -- Gate 2: unused
            P9_D2  => '1',
            P10_C2 => '1',
            P12_B2 => '1',
            P13_A2 => '1',
            P8_Y2  => open
        );

end Structural;
