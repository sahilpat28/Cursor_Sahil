// Design example: GTS AXI-Stream -> MPU -> AXI4-Lite -> register map.
//
// Use this when the SAT CSRs are already AXI4-Lite slaves. The adapter still
// produces the simple MPU bus; mpu_to_axi4lite is the second-stage bridge.

`timescale 1ns/1ps

module gts_axis_axi4lite_example_top #(
    parameter integer AXIS_DATA_W = 256,
    parameter integer ADDR_W      = 32
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
    output wire [7:0]                   unsupported_count
);
    wire [3:0] last_bar_unused;
    wire                mpu_cs;
    wire                mpu_we;
    wire                mpu_re;
    wire [ADDR_W-1:0]   mpu_addr;
    wire [3:0]          mpu_be;
    wire [31:0]         mpu_wdata;
    wire [31:0]         mpu_rdata;
    wire                mpu_ack;

    wire [ADDR_W-1:0]   awaddr;
    wire                awvalid;
    wire                awready;
    wire [31:0]         wdata;
    wire [3:0]          wstrb;
    wire                wvalid;
    wire                wready;
    wire [1:0]          bresp;
    wire                bvalid;
    wire                bready;
    wire [ADDR_W-1:0]   araddr;
    wire                arvalid;
    wire                arready;
    wire [31:0]         rdata;
    wire [1:0]          rresp;
    wire                rvalid;
    wire                rready;

    gts_axis_to_mpu #(
        .AXIS_DATA_W(AXIS_DATA_W),
        .MPU_ADDR_W(ADDR_W)
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
        .last_bar(last_bar_unused)
    );

    mpu_to_axi4lite #(
        .ADDR_W(ADDR_W)
    ) u_bridge (
        .clk(clk),
        .rst(rst),
        .mpu_cs(mpu_cs),
        .mpu_we(mpu_we),
        .mpu_re(mpu_re),
        .mpu_addr(mpu_addr),
        .mpu_be(mpu_be),
        .mpu_wdata(mpu_wdata),
        .mpu_rdata(mpu_rdata),
        .mpu_ack(mpu_ack),
        .awaddr(awaddr),
        .awvalid(awvalid),
        .awready(awready),
        .wdata(wdata),
        .wstrb(wstrb),
        .wvalid(wvalid),
        .wready(wready),
        .bresp(bresp),
        .bvalid(bvalid),
        .bready(bready),
        .araddr(araddr),
        .arvalid(arvalid),
        .arready(arready),
        .rdata(rdata),
        .rresp(rresp),
        .rvalid(rvalid),
        .rready(rready)
    );

    axi4lite_regmap_example #(
        .ADDR_W(ADDR_W)
    ) u_regmap (
        .clk(clk),
        .rst(rst),
        .awaddr(awaddr),
        .awvalid(awvalid),
        .awready(awready),
        .wdata(wdata),
        .wstrb(wstrb),
        .wvalid(wvalid),
        .wready(wready),
        .bresp(bresp),
        .bvalid(bvalid),
        .bready(bready),
        .araddr(araddr),
        .arvalid(arvalid),
        .arready(arready),
        .rdata(rdata),
        .rresp(rresp),
        .rvalid(rvalid),
        .rready(rready)
    );
endmodule
