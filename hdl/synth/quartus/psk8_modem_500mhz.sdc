# Quartus Prime Pro timing constraints for the 500 MHz 8-PSK modem.
#
# Target board:
#   Agilex 7 FPGA I-Series Transceiver-SoC Development Kit (4x F-Tile)
#   Ordering code: DK-SI-AGI027FD
#   Device OPN: AGIB027R31B1E1VC
#
# The top-level modem clock is a 500 MHz RTL clock. Each valid clock transfers
# eight complex samples, sustaining the requested 4 GSPS ADC/DAC throughput.

create_clock -name clk_500mhz -period 2.000 [get_ports clk]

# Placeholder top-level I/O timing budgets for standalone timing runs.
# Replace these with board-specific pin and interface timing constraints when
# connecting to the actual ADC/DAC, F-Tile, or board clocking resources.
set_input_delay  -clock clk_500mhz 0.250 [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay -clock clk_500mhz 0.250 [all_outputs]

# Reset is an asynchronous control input in the RTL.
set_false_path -from [get_ports rst]

