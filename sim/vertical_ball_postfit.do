# Full fitted board with SDF. Isolate vertical motion by driving HSYNC's source,
# serve, STOP and Figure 14 segment/direction state. Never force A4/D4,
# their carry/load signals, or B3.
# Accelerated line stimulus keeps this independent of unrelated raster logic.
onerror {quit -code 1 -f}
onbreak {quit -code 1 -f}
proc net {name} {return "sim:/atari_wcc_board/\\${name}\\"}
proc drive {name value} {force -freeze [net $name] $value}
proc number {name} {
    set value [string trim [examine -radix binary [net $name]] "'\" "]
    if {![regexp {^[01]+$} $value]} {error "Unknown net $name: $value"}
    set result 0
    foreach digit [split $value ""] {set result [expr {2*$result + $digit}]}
    return $result
}
foreach port {Clk_50_I ControlsMISO_I} {force -freeze sim:/atari_wcc_board/$port 0}
foreach port {Coin1_I GameSelect_I Start1_I KickChecks_I KickSolids_I Reset_I} {
    force -freeze sim:/atari_wcc_board/$port 1
}
set hs {U_CORE|U_HSYNC|E2|DFF1|JKFF|nxt_state~regout}
set serve {U_CORE|U_SERVE|U_L5|DFF2|JKFF|nxt_state~regout}
set stop {U_CORE|U_SERVE|U_J5|active1~regout}
set phase {U_CORE|U_BALL_MOTION|B3|edge_slaves:JKFF1|nxt_state~regout}
proc measure {label preset filename} {
global hs serve stop phase
drive $hs 1
drive $serve 0
run 1 us
drive $serve 1
run 1 us
set trace [open $filename w]
puts $trace "line,a4,d4,phase,window,expected_a4,expected_d4,expected_phase"
set a 0
set d 0
set p 0
set failures 0
set starts {}
set previous_window 0
for {set line 1} {$line <= 1200} {incr line} {
    set old_a $a
    set old_d $d
    if {$p && $d == 15 && $a == 15} {
        set a $preset
        set d 12
    } else {
        set a [expr {($a + 1) % 16}]
        if {$old_a == 15} {set d [expr {($d + 1) % 16}]}
    }
    if {$old_a == 15 && $old_d == 15} {set p [expr {1 - $p}]}
    drive $hs 0
    run 1 us
    set actual_a [number {U_CORE|U_BALL_MOTION|A4|count}]
    set actual_d [number {U_CORE|U_BALL_MOTION|D4|count}]
    set actual_p [number $phase]
    set window [expr {$actual_p && $actual_d == 15 && $actual_a >= 8}]
    puts $trace "$line,$actual_a,$actual_d,$actual_p,$window,$a,$d,$p"
    if {$window && !$previous_window} {lappend starts $line}
    set previous_window $window
    if {[list $actual_a $actual_d $actual_p] ne [list $a $d $p]} {
        if {$failures < 5} {
            puts "FAIL line $line: A4/D4/B3=$actual_a/$actual_d/$actual_p expected $a/$d/$p"
        }
        incr failures
    }
    drive $hs 1
    run 1 us
}
close $trace
puts "POSTFIT $label vertical window starts: $starts"
if {$failures} {error "$failures vertical counter/phase mismatches"}
if {[llength $starts] < 3} {error "Missing vertical ball windows"}
for {set i 1} {$i < [llength $starts]} {incr i} {
    if {[expr {[lindex $starts $i] - [lindex $starts [expr {$i-1}]]}] != 320-$preset} {
        error "$label window does not recur every [expr {320-$preset}] lines"
    }
}
puts "PASS: $label 1200 fitted scanline transitions; period is [expr {320-$preset}] lines"
}
drive $stop 1
measure STOP 7 vertical_ball_postfit.csv
# Serve's reset data selects code 10 (maximum upward motion).
drive $stop 0
drive {U_CORE|U_VERT_SPEED|D7|latch} 0000
drive {U_CORE|U_VERT_SPEED|D6|DFF1|JKFF|nxt_state~regout} 0
measure UP 10 vertical_ball_up.csv
drive {U_CORE|U_VERT_SPEED|D7|latch} 0111
measure DOWN 4 vertical_ball_down.csv
quit -code 0 -f
