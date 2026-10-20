# Timing-annotated board: real horizontal raster and B4/C4 counters.
# Force vertical ball window and VRESET inactive to isolate horizontal STOP=9.
# No horizontal counter, phase, carry, collision or score outputs are forced.
onerror {quit -code 1 -f}
onbreak {quit -code 1 -f}
proc net {name} {return "sim:/atari_wcc_board/\\${name}\\"}
proc drive {name value} {force -freeze [net $name] $value}
proc bit {name} {
    set value [string trim [examine -radix binary [net $name]] "'\" "]
    if {$value ne "0" && $value ne "1"} {error "Unknown net $name: $value"}
    return $value
}
set miss {U_CORE|miss_one_shot~regout}
set side {U_CORE|U_HSYNC|B2|edge_slaves:JKFF1|nxt_state~regout}
set start {U_CORE|U_START|IC_B9|DFF1|JKFF|nxt_state~regout}
foreach port {Clk_50_I ControlsMISO_I} {force -freeze sim:/atari_wcc_board/$port 0}
foreach port {Coin1_I GameSelect_I Start1_I KickChecks_I KickSolids_I Reset_I} {force -freeze sim:/atari_wcc_board/$port 1}


drive $start 1
run 1 us
drive $start 0
run 1 us
proc score {ic ff} {
    set value 0
    foreach {stage weight} {A 1 B 2 C 4 D 8} {
        incr value [expr {$weight * [bit "U_CORE|U_SCORE|ic_${ic}|FF_${stage}|nxt_state~regout"]}]
    }
    incr value [expr {10 * [bit "U_CORE|U_SCORE|ic_N2|edge_slaves:JKFF${ff}|nxt_state~regout"]}]
    return $value
}
proc check {solid checks} {
    set actual [list [score K3 1] [score L3 2]]
    if {$actual ne [list $solid $checks]} {error "Score expected $solid/$checks, got $actual"}
    puts "POSTFIT score $actual"
}

force -freeze [net {U_CORE|U_CLOCK|E2|DFF2|JKFF|nxt_state~regout}] 0 0 ns, 1 70 ns -repeat 140 ns
# Paid two-player, fixed V=160; keep the real horizontal ripple raster.
drive {U_CORE|U_START|IC_B9|DFF2|JKFF|nxt_state~2_combout} 0
drive {U_CORE|U_MODE_INPUT|settled~regout} 0
foreach {ic stage value} {D1 0 0 D1 1 0 D1 2 0 D1 3 0 C1 0 0 C1 1 1 C1 2 0 C1 3 1} {
    drive "U_CORE|U_VSYNC|${ic}|Q${stage}_JKFF|nxt_state~regout" $value
}
drive {U_CORE|U_BALL_MOTION|D4|count} 1111
drive {U_CORE|U_BALL_MOTION|B3|edge_slaves:JKFF1|nxt_state~regout} 1
set ballsource {U_CORE|U_BALL_MOTION|A3|P8_Y3~0_combout}
drive {U_CORE|U_BALL_MOTION|A4|count} 1000
drive {U_CORE|U_VSYNC|D2|DFF2|JKFF|nxt_state~regout} 1
drive {U_CORE|U_VSYNC|F3|P10_Y3~0_combout} 0
drive {U_CORE|U_SERVE|U_L5|DFF2|JKFF|nxt_state~regout} 0
run 1 us
drive {U_CORE|U_SERVE|U_L5|DFF2|JKFF|nxt_state~regout} 1
set hnames {}
foreach ic {F1 E1} {for {set i 0} {$i < 4} {incr i} {lappend hnames "U_CORE|U_HSYNC|${ic}|Q${i}_JKFF|nxt_state~regout"}}
lappend hnames $side
proc hpos {} {
 global hnames
 set x 0; set w 1
 foreach n $hnames {incr x [expr {$w*[bit $n]}]; set w [expr {$w*2}]}
 return $x
}
vcd file ball_carry.vcd
foreach n [concat $hnames [list $ballsource {U_CORE|U_WINDOW_MISS_BOUNCE|IC_F4|P10_Y3~combout} {U_CORE|U_WINDOW_MISS_BOUNCE|IC_F5|P8_Y3~combout} {U_CORE|miss_one_shot~regout} {U_CORE|U_PLAYERS_SUM|IC_K6|P11_Y4~combout} {U_CORE|U_CATCH_KICK|U_D8|DFF2|JKFF|nxt_state~2_combout} {U_CORE|U_SERVE|U_J5|active1~regout}]] {vcd add [net $n]}
foreach n {{U_CORE|U_BALL_MOTION|B4|count} {U_CORE|U_BALL_MOTION|C4|count} {U_CORE|U_BALL_MOTION|B3|edge_slaves:JKFF2|nxt_state~regout} {U_CORE|U_HSYNC|C3|P3_Y1~1_combout} {U_CORE|U_CLOCK|E2|DFF2|JKFF|nxt_state~clkctrl_outclk} {U_CORE|U_BALL_MOTION|A4|count}} {vcd add [net $n]}
run 150 us
vcd flush
quit -code 0 -f
