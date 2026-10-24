# Onboard 50 MHz oscillator, pin 17.
create_clock -name Clk_50_I -period 20.000 [get_ports {Clk_50_I}]
derive_pll_clocks
# TM-035 Fig. 3: LS04 inverter then LS74 divide-by-two.
create_generated_clock -name CLOCK_7 -source [get_pins {PLL|altpll_component|pll|clk[0]}] -edges {2 4 6} [get_registers {U_CORE|U_CLOCK|E2|DFF2|JKFF|nxt_state}]
# Collision adapter samples halfway through CLOCK_7 low. CLOCK_7 is produced
# at CLOCK_14 falling edges; the gated CLOCK_14 rising edge is 1/4 pixel later.
set sample_shift [expr {[get_clock_info -period [get_clocks CLOCK_7]] / 4.0}]
create_generated_clock -name COLLISION_SAMPLE -source [get_registers {U_CORE|U_CLOCK|E2|DFF2|JKFF|nxt_state}] -edges {2 3 4} -edge_shift [list $sample_shift 0 $sample_shift] [get_pins {U_CORE|U_COLLISION_CLOCK|P3_Y1|combout}]
# Figure 16 local synchronous A4/D4 domain: HSYNC is high for 32 of 455
# pixels; its falling edge clocks both counters through the HSYNCn inverter.
# Model at the registered source to check carry/load setup and hold. This
# does not constrain the upstream ripple raster.
set pixel_period [get_clock_info -period [get_clocks CLOCK_7]]
create_clock -name BALL_HSYNC -period [expr {455 * $pixel_period}] -waveform [list 0 [expr {32 * $pixel_period}]] [get_registers {U_CORE|U_HSYNC|E2|DFF1|JKFF|nxt_state}]
# A4 terminal clocks B3 on its falling edge. Both edges originate at HSYNC
# falling edges. Use a conservative one-line high / one-line low envelope:
# presets shorten the nominal divide-by-16 cycle, but never below this bound.
# This checks the same-edge D4 -> B3 hold race as well as B3 -> preset feedback.
create_generated_clock -name BALL_A4_CARRY -source [get_registers {U_CORE|U_HSYNC|E2|DFF1|JKFF|nxt_state}] -edges {2 4 6} [get_registers {U_CORE|U_BALL_MOTION|A4|terminal}]
# Figure 21 score clocks. J3 emits an active-low, one-CLOCK_7 goal pulse.
# These are EVENT clocks, not free-running dividers of the raster: model a
# conservative 140 ns high / 140 ns low envelope (one event every two pixels).
# Quartus absorbs the LS90 input inverter into J3: the fitted combout is
# active HIGH and FF_A clocks on its rising edge (the schematic J3 falls).
# Real events are much farther apart. This constrains local counter feedback
# and pulse width; it does not prove the upstream MISS/H256 gating glitch-free.
foreach {counter gate} {K3 P3_Y1 L3 P11_Y4} {
    set goal_pin [get_pins U_CORE|U_SCORE|ic_J3|${gate}|combout]
    set q0_pin [get_pins U_CORE|U_SCORE|ic_${counter}|FF_A|nxt_state|regout]
    set q3_pin [get_pins U_CORE|U_SCORE|ic_${counter}|FF_D|nxt_state|regout]
    foreach pin [list $goal_pin $q0_pin $q3_pin] {
        if {[get_collection_size $pin] != 1} {error "Missing/ambiguous Figure 21 clock pin for $counter"}
    }
    create_clock -name SCORE_${counter}_GOAL -period 280.000 -waveform {0.000 140.000} $goal_pin
    # Q0 toggles on each rising fitted J3 edge. B/C/D clock on Q0 falling.
    create_generated_clock -name SCORE_${counter}_Q0 -source $goal_pin -edges {1 3 5} $q0_pin
    # Q3 rises at count 8, falls at count 10, rises again at count 18.
    # Its falling edge clocks the N2 tens flip-flop (20% duty cycle).
    create_generated_clock -name SCORE_${counter}_Q3 -source $q0_pin -edges {8 10 18} $q3_pin
}
# Figure 15 event clock: conservative one-pixel high/low envelope.
# Checks B6 local feedback only; does not prove the upstream catch latch
# and score-sound merge free from glitches or all cross-domain transfers.
set speed_pin [get_pins {U_CORE|U_HORIZ_SPEED|F6|P8_Y3|combout}]
if {[get_collection_size $speed_pin] != 1} {error "Missing Figure 15 speed clock"}
create_clock -name SPEED_HIT -period 280.000 -waveform {0.000 140.000} $speed_pin
derive_clock_uncertainty
