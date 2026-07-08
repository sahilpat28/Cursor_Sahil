# Run synthesis, place, route, and timing reports for the 500 MHz 8-PSK modem.
#
# Usage from repository root:
#   vivado -mode batch -source hdl/synth/vivado/run_vivado_pnr.tcl

set script_dir [file dirname [file normalize [info script]]]
set repo_root [file normalize [file join $script_dir ../../..]]
set report_dir [file join $repo_root hdl reports vivado]
file mkdir $report_dir

set part_name xcvu9p-flga2104-3-e
set top_name psk8_modem_top

read_verilog [file join $repo_root hdl rtl psk8_mapper.v]
read_verilog [file join $repo_root hdl rtl psk8_demapper.v]
read_verilog [file join $repo_root hdl rtl srrc_fir_8x.v]
read_verilog [file join $repo_root hdl rtl nco_rotator_8x.v]
read_verilog [file join $repo_root hdl rtl psk8_tx.v]
read_verilog [file join $repo_root hdl rtl psk8_rx.v]
read_verilog [file join $repo_root hdl rtl psk8_modem_top.v]
read_xdc [file join $script_dir psk8_modem_500mhz.xdc]

synth_design -top $top_name -part $part_name -retiming
write_checkpoint -force [file join $report_dir post_synth.dcp]
report_utilization -file [file join $report_dir post_synth_utilization.rpt]
report_timing_summary -file [file join $report_dir post_synth_timing_summary.rpt]

opt_design
place_design
phys_opt_design
route_design
phys_opt_design

write_checkpoint -force [file join $report_dir post_route.dcp]
report_timing_summary -delay_type max -report_unconstrained -check_timing_verbose \
    -file [file join $report_dir post_route_timing_summary.rpt]
report_timing -delay_type max -max_paths 25 -sort_by group \
    -file [file join $report_dir post_route_worst_paths.rpt]
report_utilization -hierarchical -file [file join $report_dir post_route_utilization.rpt]
report_clock_utilization -file [file join $report_dir post_route_clock_utilization.rpt]
report_drc -file [file join $report_dir post_route_drc.rpt]

set timing_ok [expr {[get_property SLACK [get_timing_paths -delay_type max -max_paths 1]] >= 0.0}]
if {!$timing_ok} {
    puts "ERROR: 500 MHz timing was not met. See post_route_timing_summary.rpt."
    exit 1
}

puts "PASS: 500 MHz post-route timing met for $top_name on $part_name."

