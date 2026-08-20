// AXI4-Lite slave register map with the same offsets as mpu_regmap_example.
// Used by the optional AXI4-Lite design-example top.

`timescale 1ns/1ps

module axi4lite_regmap_example #(
    parameter integer ADDR_W = 32,
    parameter [31:0]  REG_ID = 32'h5341_5401
) (
    input  wire                clk,
    input  wire                rst,

    input  wire [ADDR_W-1:0]   awaddr,
    input  wire                awvalid,
    output reg                 awready,
    input  wire [31:0]         wdata,
    input  wire [3:0]          wstrb,
    input  wire                wvalid,
    output reg                 wready,
    output reg  [1:0]          bresp,
    output reg                 bvalid,
    input  wire                bready,

    input  wire [ADDR_W-1:0]   araddr,
    input  wire                arvalid,
    output reg                 arready,
    output reg  [31:0]         rdata,
    output reg  [1:0]          rresp,
    output reg                 rvalid,
    input  wire                rready
);
    wire        mpu_cs;
    wire        mpu_we;
    wire        mpu_re;
    wire [31:0] mpu_rdata;
    wire        mpu_ack;
    reg  [ADDR_W-1:0] addr_r;
    reg  [31:0] wdata_r;
    reg  [3:0]  be_r;
    reg         have_addr;
    reg         have_data;
    reg         wr_pend;
    reg         rd_pend;

    mpu_regmap_example #(
        .MPU_ADDR_W(ADDR_W),
        .REG_ID(REG_ID)
    ) regs (
        .clk(clk),
        .rst(rst),
        .mpu_cs(mpu_cs),
        .mpu_we(mpu_we),
        .mpu_re(mpu_re),
        .mpu_addr(addr_r),
        .mpu_be(be_r),
        .mpu_wdata(wdata_r),
        .mpu_rdata(mpu_rdata),
        .mpu_ack(mpu_ack)
    );

    assign mpu_cs = wr_pend || rd_pend;
    assign mpu_we = wr_pend;
    assign mpu_re = rd_pend;

    always @(posedge clk) begin
        if (rst) begin
            awready   <= 1'b1;
            wready    <= 1'b1;
            bvalid    <= 1'b0;
            bresp     <= 2'b00;
            arready   <= 1'b1;
            rvalid    <= 1'b0;
            rresp     <= 2'b00;
            rdata     <= 32'b0;
            addr_r    <= {ADDR_W{1'b0}};
            wdata_r   <= 32'b0;
            be_r      <= 4'h0;
            have_addr <= 1'b0;
            have_data <= 1'b0;
            wr_pend   <= 1'b0;
            rd_pend   <= 1'b0;
        end else begin
            if (wr_pend && mpu_ack)
                wr_pend <= 1'b0;
            if (rd_pend && mpu_ack) begin
                rd_pend <= 1'b0;
                rdata   <= mpu_rdata;
                rresp   <= 2'b00;
                rvalid  <= 1'b1;
                arready <= 1'b0;
            end

            if (awready && awvalid) begin
                addr_r    <= awaddr;
                have_addr <= 1'b1;
                awready   <= 1'b0;
            end
            if (wready && wvalid) begin
                wdata_r   <= wdata;
                be_r      <= wstrb;
                have_data <= 1'b1;
                wready    <= 1'b0;
            end
            if (have_addr && have_data && !wr_pend && !bvalid) begin
                wr_pend   <= 1'b1;
                have_addr <= 1'b0;
                have_data <= 1'b0;
            end
            if (bvalid && bready) begin
                bvalid  <= 1'b0;
                awready <= 1'b1;
                wready  <= 1'b1;
            end else if (wr_pend && mpu_ack) begin
                bresp  <= 2'b00;
                bvalid <= 1'b1;
            end

            if (arready && arvalid && !rd_pend && !rvalid) begin
                addr_r  <= araddr;
                be_r    <= 4'hF;
                rd_pend <= 1'b1;
                arready <= 1'b0;
            end
            if (rvalid && rready) begin
                rvalid  <= 1'b0;
                arready <= 1'b1;
            end
        end
    end
endmodule
