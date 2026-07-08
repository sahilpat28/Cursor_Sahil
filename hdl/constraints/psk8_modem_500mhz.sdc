# Generic SDC constraint for the 500 MHz 8-PSK modem RTL clock.
#
# Board-, FPGA-, and converter-specific I/O delays should be added in the
# integration project that instantiates psk8_modem_top.

create_clock -name clk_500mhz -period 2.000 [get_ports clk]

