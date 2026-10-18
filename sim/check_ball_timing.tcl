# Check constrained synchronous paths into B4/C4 at both timing corners.
# This does not close the design's separate, unconstrained ripple clocks.
project_open atari_wcc
set failed 0
foreach corner {slow fast} {
    create_timing_netlist -model $corner
    read_sdc
    update_timing_netlist
    set regs [get_registers {*U_BALL_MOTION*IC9316:B4*count* *U_BALL_MOTION*IC9316:C4*count*}]
    if {[get_collection_size $regs] != 8} {error "Expected eight B4/C4 registers"}
    foreach check {setup hold} {
        report_timing -$check -to $regs -npaths 100 -detail full_path -file output_files/ball_${corner}_${check}.rpt
        foreach_in_collection reg $regs {
            set paths [get_timing_paths -$check -to $reg -npaths 1]
            if {[get_collection_size $paths] != 1} {error "Missing ball timing path"}
            foreach_in_collection path $paths {
                set slack [get_path_info -slack $path]
                puts "BALL_TIMING $corner $check [get_node_info -name $reg] $slack ns"
                if {$slack < 0} {set failed 1}
            }
        }
    }
    delete_timing_netlist
}
project_close
if {$failed} {error "Ball setup/hold timing failed"}
puts "PASS: constrained B4/C4 setup/hold paths pass at both timing corners"
