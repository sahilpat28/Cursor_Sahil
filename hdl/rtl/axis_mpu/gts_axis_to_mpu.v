// GTS AXI-Stream (PCIe TLP) to MPU bus adapter.
//
// Converts inbound Agilex 3 / Agilex 5 GTS AXI4-Stream memory TLPs into a
// simple MPU bus so a user register map can be connected without the Intel PIO
// design example's on-chip memory path.
//
// In-band 32-byte header (AXI-ST Sideband Header disabled), matching the GTS
// AXI Streaming IP User Guide:
//   TDATA[127:0]   PCIe TLP header DW0..DW3
//   TDATA[255:128] prefix / PF / VF / BAR / slot
// Payload DWs follow on later beats.
//
// AXIS_DATA_W: 128 (Agilex 3 Gen3 default) or 256.
// MPU: address, 32-bit data, chip select, write/read, byte enables, ack.

`timescale 1ns/1ps

module gts_axis_to_mpu #(
    parameter integer AXIS_DATA_W = 256,
    parameter integer MPU_ADDR_W  = 32,
    parameter integer MAX_DW      = 16
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

    output wire                         mpu_cs,
    output wire                         mpu_we,
    output wire                         mpu_re,
    output wire [MPU_ADDR_W-1:0]        mpu_addr,
    output wire [3:0]                   mpu_be,
    output wire [31:0]                  mpu_wdata,
    input  wire [31:0]                  mpu_rdata,
    input  wire                         mpu_ack,

    output wire                         busy,
    output wire [7:0]                   unsupported_count,
    output wire [3:0]                   last_bar
);
    localparam integer AXIS_BYTES = AXIS_DATA_W / 8;
    localparam integer AXIS_DWS   = AXIS_DATA_W / 32;
    localparam integer HDR_BEATS  = (AXIS_DATA_W >= 256) ? 1 : 2;
    localparam integer DW_W       = 5;
    localparam integer BEAT_W     = 4;

    localparam [3:0] S_IDLE     = 4'd0;
    localparam [3:0] S_HDR      = 4'd1;
    localparam [3:0] S_DECODE   = 4'd2;
    localparam [3:0] S_MWR      = 4'd3;
    localparam [3:0] S_MRD      = 4'd4;
    localparam [3:0] S_CPL_H0   = 4'd5;
    localparam [3:0] S_CPL_H1   = 4'd6;
    localparam [3:0] S_CPL_DAT  = 4'd7;
    localparam [3:0] S_DRAIN    = 4'd8;
    localparam [3:0] S_UR_H0    = 4'd9;
    localparam [3:0] S_UR_H1    = 4'd10;
    localparam [3:0] S_WAIT_TX  = 4'd11;

    generate
        if ((AXIS_DATA_W != 128) && (AXIS_DATA_W != 256)) begin : g_width_check
            initial begin
                $display("ERROR: gts_axis_to_mpu AXIS_DATA_W must be 128 or 256");
                $finish;
            end
        end
    endgenerate

    reg [3:0]               state;
    reg [1:0]               hdr_beats_got;
    reg [255:0]             hdr;
    reg                     hdr_tlast;

    reg [DW_W-1:0]          dw_len;
    reg [DW_W-1:0]          dw_idx;
    reg [DW_W-1:0]          dw_last;
    reg [7:0]               tag;
    reg [15:0]              req_id;
    reg [3:0]               first_be;
    reg [3:0]               last_be;
    reg [63:0]              cur_addr;
    reg [6:0]               lower_addr;
    reg [3:0]               bar_r;
    reg [7:0]               unsup_r;

    reg [AXIS_DATA_W-1:0]   beat_data;
    reg [BEAT_W-1:0]        beat_dws;

    reg                     mpu_active;
    reg                     mpu_is_write;
    reg [MPU_ADDR_W-1:0]    mpu_addr_r;
    reg [3:0]               mpu_be_r;
    reg [31:0]              mpu_wdata_r;
    reg                     mpu_last_dw;

    reg [31:0]              rd_buf [0:MAX_DW-1];

    reg                     tx_valid_r;
    reg [AXIS_DATA_W-1:0]   tx_data_r;
    reg [AXIS_DATA_W/8-1:0] tx_keep_r;
    reg                     tx_last_r;
    reg [DW_W-1:0]          tx_dw_idx;
    reg [AXIS_DATA_W-1:0]   tx_data_next;
    reg [AXIS_DATA_W/8-1:0] tx_keep_next;

    integer                 i;
    integer                 pack_i;

    wire                    rx_fire = rx_tvalid && rx_tready;
    wire                    tx_fire = tx_valid_r && tx_tready;
    wire                    mpu_fire = mpu_active && mpu_ack;
    wire                    mpu_idle = !mpu_active || mpu_fire;

    wire [31:0]             dwd0 = hdr[31:0];
    wire [31:0]             dwd1 = hdr[63:32];
    wire [31:0]             dwd2 = hdr[95:64];
    wire [31:0]             dwd3 = hdr[127:96];
    wire [2:0]              fmt    = dwd0[31:29];
    wire [4:0]              typ    = dwd0[28:24];
    wire [9:0]              len_dw = dwd0[9:0];
    wire                    dec_has_data = fmt[1];
    wire                    dec_is_4dw   = fmt[0];
    wire                    dec_is_mem   = (typ == 5'b00000);
    wire [63:0]             dec_addr = dec_is_4dw ?
                            {dwd2, dwd3[31:2], 2'b00} :
                            {32'b0, dwd2[31:2], 2'b00};
    wire                    dec_len_ok = (len_dw != 10'd0) && (len_dw <= MAX_DW[9:0]);
    wire [DW_W-1:0]         dec_len = len_dw[DW_W-1:0];
    wire                    dec_mem_ok = dec_is_mem && dec_len_ok;
    wire [3:0]              dec_bar = hdr[178:175];

    function [3:0] dw_be;
        input [DW_W-1:0] idx;
        input [DW_W-1:0] last_idx;
        input [3:0] fbe;
        input [3:0] lbe;
        begin
            if (last_idx == 0)
                dw_be = fbe;
            else if (idx == 0)
                dw_be = fbe;
            else if (idx == last_idx)
                dw_be = lbe;
            else
                dw_be = 4'hF;
        end
    endfunction

    function [255:0] build_cpl_hdr;
        input        ur;
        input [9:0]  length;
        input [11:0] bcnt;
        input [15:0] rid;
        input [7:0]  tg;
        input [6:0]  la;
        begin
            build_cpl_hdr = {
                128'b0,
                {rid, tg, 1'b0, la},
                {16'h0000, (ur ? 3'b001 : 3'b000), 1'b0, bcnt},
                { (ur ? 3'b000 : 3'b010), 5'b01010, 14'b0, (ur ? 10'b0 : length) }
            };
        end
    endfunction

    function [BEAT_W-1:0] keep_to_dws;
        input [AXIS_DATA_W/8-1:0] keep;
        input                     is_last;
        integer                   b;
        integer                   nbytes;
        begin
            if (!is_last)
                keep_to_dws = AXIS_DWS[BEAT_W-1:0];
            else begin
                nbytes = 0;
                for (b = 0; b < AXIS_BYTES; b = b + 1)
                    if (keep[b])
                        nbytes = nbytes + 1;
                keep_to_dws = nbytes[BEAT_W+1:2];
            end
        end
    endfunction

    assign rx_tuser_halt     = 3'b000;
    assign busy              = (state != S_IDLE);
    assign unsupported_count = unsup_r;
    assign last_bar          = bar_r;

    assign mpu_cs    = mpu_active;
    assign mpu_we    = mpu_active && mpu_is_write;
    assign mpu_re    = mpu_active && !mpu_is_write;
    assign mpu_addr  = mpu_addr_r;
    assign mpu_be    = mpu_be_r;
    assign mpu_wdata = mpu_wdata_r;

    assign tx_tvalid = tx_valid_r;
    assign tx_tdata  = tx_data_r;
    assign tx_tkeep  = tx_keep_r;
    assign tx_tlast  = tx_last_r;

    assign rx_tready = (state == S_IDLE) ||
                       ((state == S_HDR) && (hdr_beats_got < HDR_BEATS[1:0])) ||
                       ((state == S_MWR) && (beat_dws == 0) && mpu_idle) ||
                       (state == S_DRAIN);

    always @(posedge clk) begin
        if (rst) begin
            state         <= S_IDLE;
            hdr_beats_got <= 2'd0;
            hdr           <= 256'b0;
            hdr_tlast     <= 1'b0;
            dw_len        <= {DW_W{1'b0}};
            dw_idx        <= {DW_W{1'b0}};
            dw_last       <= {DW_W{1'b0}};
            tag           <= 8'b0;
            req_id        <= 16'b0;
            first_be      <= 4'hF;
            last_be       <= 4'hF;
            cur_addr      <= 64'b0;
            lower_addr    <= 7'b0;
            bar_r         <= 4'b0;
            unsup_r       <= 8'b0;
            beat_data     <= {AXIS_DATA_W{1'b0}};
            beat_dws      <= {BEAT_W{1'b0}};
            mpu_active    <= 1'b0;
            mpu_is_write  <= 1'b0;
            mpu_addr_r    <= {MPU_ADDR_W{1'b0}};
            mpu_be_r      <= 4'h0;
            mpu_wdata_r   <= 32'b0;
            mpu_last_dw   <= 1'b0;
            tx_valid_r    <= 1'b0;
            tx_data_r     <= {AXIS_DATA_W{1'b0}};
            tx_keep_r     <= {AXIS_BYTES{1'b0}};
            tx_last_r     <= 1'b0;
            tx_dw_idx     <= {DW_W{1'b0}};
            for (i = 0; i < MAX_DW; i = i + 1)
                rd_buf[i] <= 32'b0;
        end else begin
            if (mpu_fire)
                mpu_active <= 1'b0;
            if (tx_fire)
                tx_valid_r <= 1'b0;

            case (state)
                S_IDLE: begin
                    hdr_beats_got <= 2'd0;
                    dw_idx        <= {DW_W{1'b0}};
                    beat_dws      <= {BEAT_W{1'b0}};
                    mpu_last_dw   <= 1'b0;
                    if (rx_fire) begin
                        if (AXIS_DATA_W == 256)
                            hdr <= rx_tdata[255:0];
                        else begin
                            hdr[127:0]   <= rx_tdata[127:0];
                            hdr[255:128] <= 128'b0;
                        end
                        hdr_beats_got <= 2'd1;
                        hdr_tlast     <= rx_tlast;
                        state         <= S_HDR;
                    end
                end

                S_HDR: begin
                    if (hdr_beats_got >= HDR_BEATS[1:0])
                        state <= S_DECODE;
                    else if (rx_fire) begin
                        if (AXIS_DATA_W == 128)
                            hdr[255:128] <= rx_tdata[127:0];
                        else
                            hdr <= rx_tdata[255:0];
                        hdr_beats_got <= hdr_beats_got + 2'd1;
                        hdr_tlast     <= rx_tlast;
                        if ((hdr_beats_got + 2'd1) >= HDR_BEATS[1:0])
                            state <= S_DECODE;
                    end
                end

                S_DECODE: begin
                    dw_len     <= dec_len;
                    dw_last    <= (dec_len == 0) ? {DW_W{1'b0}} : (dec_len - 1'b1);
                    dw_idx     <= {DW_W{1'b0}};
                    tag        <= dwd1[15:8];
                    req_id     <= dwd1[31:16];
                    first_be   <= dwd1[3:0];
                    last_be    <= dwd1[7:4];
                    cur_addr   <= dec_addr;
                    lower_addr <= dec_addr[6:0];
                    bar_r      <= dec_bar;
                    beat_dws   <= {BEAT_W{1'b0}};
                    if (dec_mem_ok && dec_has_data) begin
                        if (hdr_tlast) begin
                            unsup_r <= unsup_r + 8'd1;
                            state   <= S_IDLE;
                        end else
                            state <= S_MWR;
                    end else if (dec_mem_ok && !dec_has_data) begin
                        state <= S_MRD;
                    end else begin
                        unsup_r <= unsup_r + 8'd1;
                        if (dec_has_data && !hdr_tlast)
                            state <= S_DRAIN;
                        else if (!dec_has_data)
                            state <= S_UR_H0;
                        else
                            state <= S_IDLE;
                    end
                end

                S_MWR: begin
                    if (mpu_last_dw) begin
                        if (mpu_fire)
                            state <= S_IDLE;
                    end else if ((beat_dws != 0) && !mpu_active) begin
                        mpu_active   <= 1'b1;
                        mpu_is_write <= 1'b1;
                        mpu_addr_r   <= cur_addr[MPU_ADDR_W-1:0];
                        mpu_be_r     <= dw_be(dw_idx, dw_last, first_be, last_be);
                        mpu_wdata_r  <= beat_data[31:0];
                        cur_addr     <= cur_addr + 64'd4;
                        beat_data    <= {{32{1'b0}}, beat_data[AXIS_DATA_W-1:32]};
                        beat_dws     <= beat_dws - 1'b1;
                        if (dw_idx == dw_last)
                            mpu_last_dw <= 1'b1;
                        else
                            dw_idx <= dw_idx + 1'b1;
                    end else if ((beat_dws == 0) && rx_fire) begin
                        beat_data <= rx_tdata;
                        beat_dws  <= keep_to_dws(rx_tkeep, rx_tlast);
                    end
                end

                S_MRD: begin
                    if (mpu_fire) begin
                        rd_buf[dw_idx] <= mpu_rdata;
                        if (dw_idx == dw_last)
                            state <= S_CPL_H0;
                        else begin
                            dw_idx   <= dw_idx + 1'b1;
                            cur_addr <= cur_addr + 64'd4;
                        end
                    end else if (!mpu_active) begin
                        mpu_active   <= 1'b1;
                        mpu_is_write <= 1'b0;
                        mpu_addr_r   <= cur_addr[MPU_ADDR_W-1:0];
                        mpu_be_r     <= dw_be(dw_idx, dw_last, first_be, last_be);
                        mpu_wdata_r  <= 32'b0;
                    end
                end

                S_CPL_H0: begin
                    if (!tx_valid_r || tx_fire) begin
                        tx_valid_r <= 1'b1;
                        tx_keep_r  <= {AXIS_BYTES{1'b1}};
                        tx_last_r  <= 1'b0;
                        tx_dw_idx  <= {DW_W{1'b0}};
                        tx_data_r  <= build_cpl_hdr(
                            1'b0, {5'b0, dw_len}, {5'b0, dw_len, 2'b00},
                            req_id, tag, lower_addr);
                        if (AXIS_DATA_W == 256)
                            state <= S_CPL_DAT;
                        else
                            state <= S_CPL_H1;
                    end
                end

                S_CPL_H1: begin
                    if (!tx_valid_r || tx_fire) begin
                        tx_valid_r <= 1'b1;
                        tx_data_r  <= {AXIS_DATA_W{1'b0}};
                        tx_keep_r  <= {AXIS_BYTES{1'b1}};
                        tx_last_r  <= 1'b0;
                        state      <= S_CPL_DAT;
                    end
                end

                S_CPL_DAT: begin
                    if (!tx_valid_r || tx_fire) begin
                        tx_data_next = {AXIS_DATA_W{1'b0}};
                        tx_keep_next = {AXIS_BYTES{1'b0}};
                        for (pack_i = 0; pack_i < AXIS_DWS; pack_i = pack_i + 1) begin
                            if ((tx_dw_idx + pack_i[DW_W-1:0]) < dw_len) begin
                                tx_data_next[32*pack_i +: 32] = rd_buf[tx_dw_idx + pack_i];
                                tx_keep_next[pack_i*4 + 0]    = 1'b1;
                                tx_keep_next[pack_i*4 + 1]    = 1'b1;
                                tx_keep_next[pack_i*4 + 2]    = 1'b1;
                                tx_keep_next[pack_i*4 + 3]    = 1'b1;
                            end
                        end
                        tx_valid_r <= 1'b1;
                        tx_data_r  <= tx_data_next;
                        tx_keep_r  <= tx_keep_next;
                        if ((tx_dw_idx + AXIS_DWS[DW_W-1:0]) >= dw_len) begin
                            tx_last_r <= 1'b1;
                            state     <= S_WAIT_TX;
                        end else begin
                            tx_last_r <= 1'b0;
                            tx_dw_idx <= tx_dw_idx + AXIS_DWS[DW_W-1:0];
                        end
                    end
                end

                S_DRAIN: begin
                    if (rx_fire && rx_tlast)
                        state <= S_IDLE;
                end

                S_UR_H0: begin
                    if (!tx_valid_r || tx_fire) begin
                        tx_valid_r <= 1'b1;
                        tx_keep_r  <= {AXIS_BYTES{1'b1}};
                        tx_data_r  <= build_cpl_hdr(
                            1'b1, 10'b0, 12'd0, req_id, tag, 7'b0);
                        if (AXIS_DATA_W == 256) begin
                            tx_last_r <= 1'b1;
                            state     <= S_WAIT_TX;
                        end else begin
                            tx_last_r <= 1'b0;
                            state     <= S_UR_H1;
                        end
                    end
                end

                S_UR_H1: begin
                    if (!tx_valid_r || tx_fire) begin
                        tx_valid_r <= 1'b1;
                        tx_data_r  <= {AXIS_DATA_W{1'b0}};
                        tx_keep_r  <= {AXIS_BYTES{1'b1}};
                        tx_last_r  <= 1'b1;
                        state      <= S_WAIT_TX;
                    end
                end

                S_WAIT_TX: begin
                    if (!tx_valid_r || tx_fire)
                        state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
