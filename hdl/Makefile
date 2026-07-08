IVERILOG ?= iverilog
VVP ?= vvp

RTL = \
	rtl/psk8_mapper.v \
	rtl/psk8_demapper.v \
	rtl/srrc_fir_8x.v \
	rtl/nco_rotator_8x.v \
	rtl/psk8_tx.v \
	rtl/psk8_rx.v \
	rtl/psk8_modem_top.v

TB = tb/tb_psk8_modem.v
BUILD_DIR = build
SIM = $(BUILD_DIR)/tb_psk8_modem.vvp

.PHONY: all sim clean

all: sim

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(SIM): $(RTL) $(TB) | $(BUILD_DIR)
	$(IVERILOG) -Wall -o $@ $(RTL) $(TB)

sim: $(SIM)
	$(VVP) $(SIM)

clean:
	rm -rf $(BUILD_DIR) tb_psk8_modem.vcd

