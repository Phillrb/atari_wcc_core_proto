project_open atari_wcc
set failed 0
foreach corner {slow fast} {
    create_timing_netlist -model $corner
    read_sdc
    update_timing_netlist
    set regs [get_registers {*U_HORIZ_SPEED*B6*count*}]
    if {[get_collection_size $regs] != 4} {error "Expected four B6 speed registers"}
    foreach check {setup hold} {
        report_timing -$check -from $regs -to $regs -npaths 100 -detail full_path -file output_files/speed_${corner}_${check}.rpt
        set paths [get_timing_paths -$check -from $regs -to $regs -npaths 100]
        if {[get_collection_size $paths] < 4} {error "Missing B6 feedback timing paths"}
        foreach_in_collection path $paths {
            if {[get_path_info -slack $path] < 0} {set failed 1}
        }
    }
    delete_timing_netlist
}
project_close
if {$failed} {error "B6 speed feedback timing failed"}
puts "PASS: B6 local speed feedback setup/hold at slow and fast corners"
