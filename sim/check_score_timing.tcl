# Run from repository root: quartus_sta -t sim/check_score_timing.tcl
# Intentionally omit a register-only -from filter: Q3 is a generated clock
# AND counter feedback data, so TimeQuest starts that data path at its pin.
project_open atari_wcc
set failed 0
foreach corner {slow fast} {
    create_timing_netlist -model $corner
    read_sdc
    update_timing_netlist
    set regs [get_registers {*U_SCORE*}]
    if {[get_collection_size $regs] != 10} {error "Expected ten Figure 21 score registers"}
    foreach check {setup hold} {
        set report output_files/score_${corner}_${check}.rpt
        report_timing -$check -to $regs -npaths 100 -detail full_path -file $report
        set paths [get_timing_paths -$check -to $regs -npaths 100]
        if {[get_collection_size $paths] < 10} {error "Missing score timing paths"}
        foreach_in_collection path $paths {
            if {[get_path_info -slack $path] < 0} {set failed 1}
        }
        foreach counter {K3 L3} {
            set from [get_pins U_CORE|U_SCORE|ic_${counter}|FF_D|nxt_state|regout]
            set to [get_registers *U_SCORE*ic_${counter}*FF_B*]
            set paths [get_timing_paths -$check -from $from -to $to -npaths 2]
            if {[get_collection_size $paths] == 0} {error "Missing ${counter} Q3 -> Q1 feedback path"}
            foreach_in_collection path $paths {
                puts "SCORE_TIMING $corner $counter Q3_to_Q1 $check [get_path_info -slack $path] ns"
                if {[get_path_info -slack $path] < 0} {set failed 1}
            }
        }
    }
    delete_timing_netlist
}
project_close
if {$failed} {error "Score setup/hold timing failed; see output_files/score_*.rpt"}
puts "PASS: both score counters and tens stages meet setup/hold at slow and fast corners"
