# Check constrained synchronous ball counter paths at both timing corners.
# This does not close the design's separate, unconstrained ripple clocks.
project_open atari_wcc
set failed 0
foreach corner {slow fast} {
    create_timing_netlist -model $corner
    read_sdc
    update_timing_netlist
    set regs [get_registers {*U_BALL_MOTION*IC9316:B4*count* *U_BALL_MOTION*IC9316:C4*count* *U_BALL_MOTION*IC9316:C4*terminal}]
    if {[get_collection_size $regs] != 9} {error "Expected eight B4/C4 bits and C4 terminal"}
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
    # HSYNC is modeled independently of the upstream ripple raster. Check
    # counter/carry paths and B3 phase feedback in that local domain.
    set vertical [get_registers {*U_BALL_MOTION*IC9316:A4*count* *U_BALL_MOTION*IC9316:D4*count* *U_BALL_MOTION*IC9316:A4*terminal}]
    if {[get_collection_size $vertical] != 9} {error "Expected eight A4/D4 bits and A4 terminal"}
    set phase [get_registers {*U_BALL_MOTION*B3*JKFF1*nxt_state}]
    if {[get_collection_size $phase] != 1} {error "Missing vertical B3 phase register"}
    set vertical [add_to_collection $vertical $phase]
    foreach check {setup hold} {
        report_timing -$check -from $vertical -to $vertical -npaths 100 -detail full_path -file output_files/ball_vertical_${corner}_${check}.rpt
        foreach_in_collection reg $vertical {
            set paths [get_timing_paths -$check -from $vertical -to $reg -npaths 1]
            if {[get_collection_size $paths] != 1} {error "Missing vertical ball timing path"}
            foreach_in_collection path $paths {
                set slack [get_path_info -slack $path]
                puts "BALL_VERTICAL_TIMING $corner $check [get_node_info -name $reg] $slack ns"
                if {$slack < 0} {set failed 1}
            }
        }
    }
    delete_timing_netlist
}
project_close
if {$failed} {error "Ball setup/hold timing failed"}
puts "PASS: constrained horizontal and vertical ball counter paths pass at both corners"
