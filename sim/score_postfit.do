# Timing-annotated FULL fitted board netlist; isolate Figure 21 by driving the
# registered goal pulse, H256 and START sources. No counter outputs are forced.
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
drive $miss 0
drive $side 1
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
check 0 0
foreach {side_value expected_other} {1 0 0 1} {
    drive $side $side_value
    run 1 us
    for {set i 1} {$i <= 21} {incr i} {
        drive $miss 1
        run 140 ns
        drive $miss 0
        run 140 ns
        set expected [expr {$i % 20}]
        if {$side_value} {check $expected $expected_other} else {check $expected_other $expected}
    }
}
# Nonzero tens and units, followed by asynchronous START and another goal.
drive $side 1
run 1 us
for {set i 2} {$i <= 12} {incr i} {
    drive $miss 1
    run 140 ns
    drive $miss 0
    run 140 ns
    check $i 1
}
drive $start 1
run 1 us
check 0 0
drive $start 0
run 1 us
drive $miss 1
run 140 ns
drive $miss 0
run 140 ns
check 1 0
puts "PASS: timing-annotated fitted score counters, 8->12, 19->0 and reset"
quit -code 0 -f
