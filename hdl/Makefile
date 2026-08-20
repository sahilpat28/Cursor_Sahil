IVERILOG ?= iverilog
VVP ?= vvp
IVERILOG_WARNINGS ?= -Wall -Wno-sensitivity-entire-array

RTL_MODEM = \
	rtl/psk8_mapper.v \
	rtl/psk8_demapper.v \
	rtl/srrc_fir_8x.v \
	rtl/nco_rotator_8x.v \
	rtl/psk8_tx.v \
	rtl/psk8_rx.v \
	rtl/psk8_modem_top.v \
	rtl/psk8_modem_quartus_top.v

RTL_MPU = \
	rtl/axis_mpu/gts_axis_to_mpu.v \
	rtl/axis_mpu/mpu_regmap_example.v \
	rtl/axis_mpu/mpu_to_axi4lite.v \
	rtl/axis_mpu/axi4lite_regmap_example.v \
	rtl/axis_mpu/gts_axis_mpu_example_top.v \
	rtl/axis_mpu/gts_axis_axi4lite_example_top.v

TB_MODEM = tb/tb_psk8_modem.v
TB_MPU = tb/tb_gts_axis_mpu.v
BUILD_DIR = build
SIM_MODEM = $(BUILD_DIR)/tb_psk8_modem.vvp
SIM_MPU = $(BUILD_DIR)/tb_gts_axis_mpu.vvp

.PHONY: all sim sim-modem sim-mpu clean

all: sim

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(SIM_MODEM): $(RTL_MODEM) $(TB_MODEM) | $(BUILD_DIR)
	$(IVERILOG) $(IVERILOG_WARNINGS) -o $@ $(RTL_MODEM) $(TB_MODEM)

$(SIM_MPU): $(RTL_MPU) $(TB_MPU) | $(BUILD_DIR)
	$(IVERILOG) $(IVERILOG_WARNINGS) -s tb_gts_axis_mpu -o $@ $(RTL_MPU) $(TB_MPU)

sim-modem: $(SIM_MODEM)
	$(VVP) $(SIM_MODEM)

sim-mpu: $(SIM_MPU)
	$(VVP) $(SIM_MPU)

sim: sim-modem sim-mpu

clean:
	rm -rf $(BUILD_DIR) tb_psk8_modem.vcd

