# Onboard 50 MHz oscillator, pin 17.
create_clock -name Clk_50_I -period 20.000 [get_ports {Clk_50_I}]
derive_pll_clocks
# TM-035 Fig. 3: LS04 inverter then LS74 divide-by-two.
create_generated_clock -name CLOCK_7 -source [get_pins {PLL|altpll_component|pll|clk[0]}] -edges {2 4 6} [get_registers {U_CORE|U_CLOCK|E2|DFF2|JKFF|nxt_state}]
derive_clock_uncertainty
