# Quartus Prime Pro 26.1 compile and timing flow for the 500 MHz 8-PSK modem.
#
# Target board:
#   Agilex 7 FPGA I-Series Transceiver-SoC Development Kit (4x F-Tile)
#   Ordering code: DK-SI-AGI027FD
#   Device OPN: AGIB027R31B1E1VC
#
# Usage from repository root on a machine with Quartus Prime Pro 26.1 installed:
#   quartus_sh -t hdl/synth/quartus/run_quartus_compile.tcl
#
# Do not manually set psk8_modem_top as the Quartus top-level entity for a
# standalone compile. This script intentionally uses psk8_modem_quartus_top so
# the wide sample buses remain internal and do not consume package I/O pins.
#
# Reports are written under:
#   hdl/reports/quartus/

package require ::quartus::project
package require ::quartus::flow
package require ::quartus::report

set script_dir [file dirname [file normalize [info script]]]
set repo_root [file normalize [file join $script_dir ../../..]]
set work_dir [file join $repo_root hdl reports quartus work]
set report_dir [file join $repo_root hdl reports quartus]
file mkdir $work_dir
file mkdir $report_dir

set project_name psk8_modem_agilex7
set revision_name psk8_modem_quartus_top
set top_name psk8_modem_quartus_top
set device_opn AGIB027R31B1E1VC

cd $work_dir

# Always create a clean project. This prevents stale assignments from a
# manually-created or previous project, such as a Cyclone 10 GX DEVICE setting,
# from surviving into the timing run.
if {[project_exists $project_name]} {
    file delete -force ${project_name}.qpf ${revision_name}.qsf \
        db incremental_db output_files
}
project_new -revision $revision_name $project_name

set_global_assignment -name FAMILY "Agilex 7"
set_global_assignment -name DEVICE $device_opn
set_global_assignment -name TOP_LEVEL_ENTITY $top_name
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files

set_global_assignment -name VERILOG_FILE [file join $repo_root hdl rtl psk8_mapper.v]
set_global_assignment -name VERILOG_FILE [file join $repo_root hdl rtl psk8_demapper.v]
set_global_assignment -name VERILOG_FILE [file join $repo_root hdl rtl srrc_fir_8x.v]
set_global_assignment -name VERILOG_FILE [file join $repo_root hdl rtl nco_rotator_8x.v]
set_global_assignment -name VERILOG_FILE [file join $repo_root hdl rtl psk8_tx.v]
set_global_assignment -name VERILOG_FILE [file join $repo_root hdl rtl psk8_rx.v]
set_global_assignment -name VERILOG_FILE [file join $repo_root hdl rtl psk8_modem_top.v]
set_global_assignment -name VERILOG_FILE [file join $repo_root hdl rtl psk8_modem_quartus_top.v]
set_global_assignment -name SDC_FILE [file join $script_dir psk8_modem_500mhz.sdc]

# Keep the flow performance-oriented for the 2 ns clock target. These are
# standard Quartus assignment names; board projects may add placement,
# partitioning, or clock-resource assignments for final closure.
set_global_assignment -name OPTIMIZATION_MODE "AGGRESSIVE PERFORMANCE"
set_global_assignment -name AUTO_DSP_RECOGNITION ON
set_global_assignment -name PHYSICAL_SYNTHESIS_COMBO_LOGIC ON
set_global_assignment -name PHYSICAL_SYNTHESIS_REGISTER_DUPLICATION ON
set_global_assignment -name PHYSICAL_SYNTHESIS_REGISTER_RETIMING ON

# Standalone core timing build: keep all wrapper ports virtual so the fitter
# does not try to consume package pins or require board I/O standards. Remove
# or replace these assignments in the final board-level project.
set_instance_assignment -name VIRTUAL_PIN ON -to clk
set_instance_assignment -name VIRTUAL_PIN ON -to rst
set_instance_assignment -name VIRTUAL_PIN ON -to block_valid
set_instance_assignment -name VIRTUAL_PIN ON -to seed_load
set_instance_assignment -name VIRTUAL_PIN ON -to "prbs_seed[*]"
set_instance_assignment -name VIRTUAL_PIN ON -to "rx_phase_inc[*]"
set_instance_assignment -name VIRTUAL_PIN ON -to rx_phase_clear
set_instance_assignment -name VIRTUAL_PIN ON -to "tx_bits[*]"
set_instance_assignment -name VIRTUAL_PIN ON -to "tx_symbol_valid[*]"
set_instance_assignment -name VIRTUAL_PIN ON -to "rx_bits[*]"
set_instance_assignment -name VIRTUAL_PIN ON -to "rx_bits_valid[*]"

export_assignments

execute_flow -compile

load_report
write_report_panel -file [file join $report_dir flow_summary.rpt] "Flow Summary"
write_report_panel -file [file join $report_dir fitter_resource_usage_summary.rpt] "Fitter||Resource Section||Fitter Resource Usage Summary"
write_report_panel -file [file join $report_dir timing_analyzer_summary.rpt] "Timing Analyzer||Timing Analyzer Summary"

project_close

puts "Quartus compile complete for $top_name on $device_opn."
puts "Review reports under $report_dir, especially timing_analyzer_summary.rpt."

