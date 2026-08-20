// MPU master to AXI4-Lite master bridge.
//
// One outstanding transaction. Use this when a CSR block already speaks
// AXI4-Lite instead of the simple MPU bus.

`timescale 1ns/1ps

module mpu_to_axi4lite #(
    parameter integer ADDR_W = 32
) (
    input  wire                clk,
    input  wire                rst,

    input  wire                mpu_cs,
    input  wire                mpu_we,
    input  wire                mpu_re,
    input  wire [ADDR_W-1:0]   mpu_addr,
    input  wire [3:0]          mpu_be,
    input  wire [31:0]         mpu_wdata,
    output reg  [31:0]         mpu_rdata,
    output wire                mpu_ack,

    output reg  [ADDR_W-1:0]   awaddr,
    output reg                 awvalid,
    input  wire                awready,
    output reg  [31:0]         wdata,
    output reg  [3:0]          wstrb,
    output reg                 wvalid,
    input  wire                wready,
    input  wire [1:0]          bresp,
    input  wire                bvalid,
    output reg                 bready,

    output reg  [ADDR_W-1:0]   araddr,
    output reg                 arvalid,
    input  wire                arready,
    input  wire [31:0]         rdata,
    input  wire [1:0]          rresp,
    input  wire                rvalid,
    output reg                 rready
);
    localparam [1:0] S_IDLE  = 2'd0;
    localparam [1:0] S_WRITE = 2'd1;
    localparam [1:0] S_WRESP = 2'd2;
    localparam [1:0] S_READ  = 2'd3;

    reg [1:0] state;
    reg       ack_r;
    reg       saw_cs_low;
    wire      aw_fire = awvalid && awready;
    wire      w_fire  = wvalid && wready;
    wire      ar_fire = arvalid && arready;
    wire      new_wr  = mpu_cs && mpu_we && saw_cs_low && !ack_r;
    wire      new_rd  = mpu_cs && mpu_re && saw_cs_low && !ack_r;

    assign mpu_ack = ack_r;

    always @(posedge clk) begin
        if (rst) begin
            state      <= S_IDLE;
            ack_r      <= 1'b0;
            saw_cs_low <= 1'b1;
            awaddr     <= {ADDR_W{1'b0}};
            awvalid    <= 1'b0;
            wdata      <= 32'b0;
            wstrb      <= 4'b0;
            wvalid     <= 1'b0;
            bready     <= 1'b0;
            araddr     <= {ADDR_W{1'b0}};
            arvalid    <= 1'b0;
            rready     <= 1'b0;
            mpu_rdata  <= 32'b0;
        end else begin
            ack_r <= 1'b0;
            if (!mpu_cs)
                saw_cs_low <= 1'b1;

            case (state)
                S_IDLE: begin
                    bready <= 1'b0;
                    rready <= 1'b0;
                    if (new_wr) begin
                        awaddr     <= mpu_addr;
                        awvalid    <= 1'b1;
                        wdata      <= mpu_wdata;
                        wstrb      <= mpu_be;
                        wvalid     <= 1'b1;
                        saw_cs_low <= 1'b0;
                        state      <= S_WRITE;
                    end else if (new_rd) begin
                        araddr     <= mpu_addr;
                        arvalid    <= 1'b1;
                        rready     <= 1'b1;
                        saw_cs_low <= 1'b0;
                        state      <= S_READ;
                    end
                end

                S_WRITE: begin
                    if (aw_fire)
                        awvalid <= 1'b0;
                    if (w_fire)
                        wvalid <= 1'b0;
                    if ((aw_fire || !awvalid) && (w_fire || !wvalid)) begin
                        bready <= 1'b1;
                        state  <= S_WRESP;
                    end
                end

                S_WRESP: begin
                    if (bvalid && bready) begin
                        bready <= 1'b0;
                        ack_r  <= 1'b1;
                        state  <= S_IDLE;
                    end
                end

                S_READ: begin
                    if (ar_fire)
                        arvalid <= 1'b0;
                    if (rvalid && rready) begin
                        rready    <= 1'b0;
                        mpu_rdata <= rdata;
                        ack_r     <= 1'b1;
                        state     <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
