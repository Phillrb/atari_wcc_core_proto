# Onboard 50 MHz oscillator, pin 17.
create_clock -name Clk_50_I -period 20.000 [get_ports {Clk_50_I}]
derive_pll_clocks
# TM-035 Fig. 3: LS04 inverter then LS74 divide-by-two.
create_generated_clock -name CLOCK_7 -source [get_pins {PLL|altpll_component|pll|clk[0]}] -edges {2 4 6} [get_registers {U_CORE|U_CLOCK|E2|DFF2|JKFF|nxt_state}]
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
derive_clock_uncertainty
