// Design example: GTS AXI-Stream -> MPU bus -> user register map.
//
// Hook rx_* / tx_* to the Agilex 3 GTS AXI Streaming IP:
//   rx_tvalid  <- p0_ss_app_st_rx_tvalid
//   rx_tready  -> p0_app_ss_st_rx_tready
//   rx_tdata   <- p0_ss_app_st_rx_tdata
//   rx_tkeep   <- p0_ss_app_st_rx_tkeep
//   rx_tlast   <- p0_ss_app_st_rx_tlast
//   tx_tvalid  -> p0_app_ss_st_tx_tvalid
//   tx_tready  <- p0_ss_app_st_tx_tready
//   tx_tdata   -> p0_app_ss_st_tx_tdata
//   tx_tkeep   -> p0_app_ss_st_tx_tkeep
//   tx_tlast   -> p0_app_ss_st_tx_tlast
//
// Replace mpu_regmap_example with the SAT / Ethernet CSR block. The MPU
// signals are the entire slave contract: address, data, chip select, r/w.

`timescale 1ns/1ps

module gts_axis_mpu_example_top #(
    parameter integer AXIS_DATA_W = 256,
    parameter integer MPU_ADDR_W  = 32
) (
    input  wire                         clk,
    input  wire                         rst,

    input  wire                         rx_tvalid,
    output wire                         rx_tready,
    input  wire [AXIS_DATA_W-1:0]       rx_tdata,
    input  wire [AXIS_DATA_W/8-1:0]     rx_tkeep,
    input  wire                         rx_tlast,
    output wire [2:0]                   rx_tuser_halt,

    output wire                         tx_tvalid,
    input  wire                         tx_tready,
    output wire [AXIS_DATA_W-1:0]       tx_tdata,
    output wire [AXIS_DATA_W/8-1:0]     tx_tkeep,
    output wire                         tx_tlast,

    output wire                         busy,
    output wire [7:0]                   unsupported_count,
    output wire [3:0]                   last_bar,

    output wire                         mpu_cs,
    output wire                         mpu_we,
    output wire                         mpu_re,
    output wire [MPU_ADDR_W-1:0]        mpu_addr,
    output wire [3:0]                   mpu_be,
    output wire [31:0]                  mpu_wdata,
    output wire [31:0]                  mpu_rdata,
    output wire                         mpu_ack
);
    gts_axis_to_mpu #(
        .AXIS_DATA_W(AXIS_DATA_W),
        .MPU_ADDR_W(MPU_ADDR_W)
    ) u_adapter (
        .clk(clk),
        .rst(rst),
        .rx_tvalid(rx_tvalid),
        .rx_tready(rx_tready),
        .rx_tdata(rx_tdata),
        .rx_tkeep(rx_tkeep),
        .rx_tlast(rx_tlast),
        .rx_tuser_halt(rx_tuser_halt),
        .tx_tvalid(tx_tvalid),
        .tx_tready(tx_tready),
        .tx_tdata(tx_tdata),
        .tx_tkeep(tx_tkeep),
        .tx_tlast(tx_tlast),
        .mpu_cs(mpu_cs),
        .mpu_we(mpu_we),
        .mpu_re(mpu_re),
        .mpu_addr(mpu_addr),
        .mpu_be(mpu_be),
        .mpu_wdata(mpu_wdata),
        .mpu_rdata(mpu_rdata),
        .mpu_ack(mpu_ack),
        .busy(busy),
        .unsupported_count(unsupported_count),
        .last_bar(last_bar)
    );

    mpu_regmap_example #(
        .MPU_ADDR_W(MPU_ADDR_W)
    ) u_regmap (
        .clk(clk),
        .rst(rst),
        .mpu_cs(mpu_cs),
        .mpu_we(mpu_we),
        .mpu_re(mpu_re),
        .mpu_addr(mpu_addr),
        .mpu_be(mpu_be),
        .mpu_wdata(mpu_wdata),
        .mpu_rdata(mpu_rdata),
        .mpu_ack(mpu_ack)
    );
endmodule
