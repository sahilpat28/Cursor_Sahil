## Xilinx Vivado constraints for the 500 MHz 8-PSK modem top level.
##
## Target flow:
##   Part: xcvu9p-flga2104-3-e
##   RTL clock: 500 MHz
##   Converter throughput: 4 GSPS via 8 complex samples per clock

create_clock -name clk_500mhz -period 2.000 [get_ports clk]

## These are conservative placeholder I/O budgets for top-level timing runs.
## Replace them with board/converter-specific interface constraints during
## product integration.
set_input_delay  -clock clk_500mhz 0.250 [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay -clock clk_500mhz 0.250 [all_outputs]

## The reset is treated as an asynchronous control input in the RTL.
set_false_path -from [get_ports rst]

