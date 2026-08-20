// Self-checking testbench for GTS AXI-Stream to MPU / AXI4-Lite examples.

`timescale 1ns/1ps

module tb_gts_axis_mpu;
    integer errors;
    integer tests;

    tb_axis_mpu_env #(.AXIS_DATA_W(256), .USE_AXIL(0)) u256();
    tb_axis_mpu_env #(.AXIS_DATA_W(128), .USE_AXIL(0)) u128();
    tb_axis_mpu_env #(.AXIS_DATA_W(256), .USE_AXIL(1)) uaxil();

    initial begin
        errors = 0;
        tests  = 0;
        u256.run();
        u128.run();
        uaxil.run();
        $display("");
        if (errors == 0)
            $display("PASS: GTS AXI-Stream to MPU/AXI4-Lite register-map example (%0d tests)", tests);
        else begin
            $display("FAIL: %0d error(s) after %0d tests", errors, tests);
            $fatal(1);
        end
        $finish;
    end
endmodule

module tb_axis_mpu_env #(
    parameter integer AXIS_DATA_W = 256,
    parameter integer USE_AXIL    = 0
);
    localparam integer AXIS_BYTES = AXIS_DATA_W / 8;
    localparam integer AXIS_DWS   = AXIS_DATA_W / 32;

    reg clk;
    reg rst;

    reg                         rx_tvalid;
    wire                        rx_tready;
    reg  [AXIS_DATA_W-1:0]      rx_tdata;
    reg  [AXIS_DATA_W/8-1:0]    rx_tkeep;
    reg                         rx_tlast;
    wire [2:0]                  rx_tuser_halt;

    wire                        tx_tvalid;
    reg                         tx_tready;
    wire [AXIS_DATA_W-1:0]      tx_tdata;
    wire [AXIS_DATA_W/8-1:0]    tx_tkeep;
    wire                        tx_tlast;

    wire                        busy;
    wire [7:0]                  unsupported_count;
    wire [3:0]                  last_bar;
    wire                        mpu_cs;
    wire                        mpu_we;
    wire                        mpu_re;
    wire [31:0]                 mpu_addr;
    wire [3:0]                  mpu_be;
    wire [31:0]                 mpu_wdata;
    wire [31:0]                 mpu_rdata;
    wire                        mpu_ack;

    integer timeout;
    integer collect_done;
    integer collect_n_dw;
    reg [31:0] collect_h0;
    reg [31:0] collect_h1;
    reg [31:0] collect_h2;
    reg [511:0] collect_data;

    initial clk = 1'b0;
    always #5 clk = ~clk;

    generate
        if (USE_AXIL == 0) begin : g_mpu
            gts_axis_mpu_example_top #(
                .AXIS_DATA_W(AXIS_DATA_W)
            ) dut (
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
                .busy(busy),
                .unsupported_count(unsupported_count),
                .last_bar(last_bar),
                .mpu_cs(mpu_cs),
                .mpu_we(mpu_we),
                .mpu_re(mpu_re),
                .mpu_addr(mpu_addr),
                .mpu_be(mpu_be),
                .mpu_wdata(mpu_wdata),
                .mpu_rdata(mpu_rdata),
                .mpu_ack(mpu_ack)
            );
        end else begin : g_axil
            gts_axis_axi4lite_example_top #(
                .AXIS_DATA_W(AXIS_DATA_W)
            ) dut (
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
                .busy(busy),
                .unsupported_count(unsupported_count)
            );
            assign last_bar  = 4'b0;
            assign mpu_cs    = 1'b0;
            assign mpu_we    = 1'b0;
            assign mpu_re    = 1'b0;
            assign mpu_addr  = 32'b0;
            assign mpu_be    = 4'b0;
            assign mpu_wdata = 32'b0;
            assign mpu_rdata = 32'b0;
            assign mpu_ack   = 1'b0;
        end
    endgenerate

    function [255:0] make_mem_hdr;
        input        is_write;
        input        is_4dw;
        input [9:0]  length;
        input [7:0]  tag;
        input [15:0] req_id;
        input [3:0]  fbe;
        input [3:0]  lbe;
        input [63:0] addr;
        input [3:0]  bar;
        reg [2:0]    fmt;
        reg [31:0]   dw0;
        reg [31:0]   dw1;
        reg [31:0]   dw2;
        reg [31:0]   dw3;
        reg [255:0]  h;
        begin
            fmt = 3'b000;
            if (is_write)
                fmt = fmt | 3'b010;
            if (is_4dw)
                fmt = fmt | 3'b001;
            dw0 = {fmt, 5'b00000, 14'b0, length};
            dw1 = {req_id, tag, lbe, fbe};
            if (is_4dw) begin
                dw2 = addr[63:32];
                dw3 = {addr[31:2], 2'b00};
            end else begin
                dw2 = {addr[31:2], 2'b00};
                dw3 = 32'b0;
            end
            h = {128'b0, dw3, dw2, dw1, dw0};
            h[178:175] = bar;
            make_mem_hdr = h;
        end
    endfunction

    task wait_clk;
        begin
            @(posedge clk);
        end
    endtask

    task reset_dut;
        begin
            rst       <= 1'b1;
            rx_tvalid <= 1'b0;
            rx_tdata  <= {AXIS_DATA_W{1'b0}};
            rx_tkeep  <= {AXIS_BYTES{1'b0}};
            rx_tlast  <= 1'b0;
            tx_tready <= 1'b1;
            repeat (4) wait_clk;
            rst <= 1'b0;
            wait_clk;
        end
    endtask

    task wait_idle;
        begin
            timeout = 0;
            begin : wait_idle_loop
                while (busy || tx_tvalid) begin
                    wait_clk;
                    timeout = timeout + 1;
                    if (timeout > 4000) begin
                        $display("ERROR: timeout waiting for idle (width=%0d axil=%0d)",
                                 AXIS_DATA_W, USE_AXIL);
                        tb_gts_axis_mpu.errors = tb_gts_axis_mpu.errors + 1;
                        disable wait_idle_loop;
                    end
                end
            end
        end
    endtask

    task drive_beat;
        input [AXIS_DATA_W-1:0] data;
        input [AXIS_BYTES-1:0]  keep;
        input                   last;
        begin
            rx_tdata  <= data;
            rx_tkeep  <= keep;
            rx_tlast  <= last;
            rx_tvalid <= 1'b1;
            wait_clk;
            while (!(rx_tvalid && rx_tready))
                wait_clk;
            rx_tvalid <= 1'b0;
            rx_tlast  <= 1'b0;
        end
    endtask

    task send_hdr;
        input [255:0] hdr;
        input         last;
        begin
            if (AXIS_DATA_W == 256)
                drive_beat(hdr, {AXIS_BYTES{1'b1}}, last);
            else begin
                drive_beat(hdr[127:0], {AXIS_BYTES{1'b1}}, 1'b0);
                drive_beat(hdr[255:128], {AXIS_BYTES{1'b1}}, last);
            end
        end
    endtask

    task send_payload_dws;
        input [511:0] pdata;
        input integer n_dw;
        integer       sent;
        integer       lane;
        integer       this_n;
        integer       b;
        reg [AXIS_DATA_W-1:0] beat;
        reg [AXIS_BYTES-1:0]  keep;
        begin
            sent = 0;
            while (sent < n_dw) begin
                this_n = n_dw - sent;
                if (this_n > AXIS_DWS)
                    this_n = AXIS_DWS;
                beat = {AXIS_DATA_W{1'b0}};
                keep = {AXIS_BYTES{1'b0}};
                for (lane = 0; lane < this_n; lane = lane + 1) begin
                    beat[32*lane +: 32] = pdata[32*(sent+lane) +: 32];
                    for (b = 0; b < 4; b = b + 1)
                        keep[lane*4 + b] = 1'b1;
                end
                sent = sent + this_n;
                drive_beat(beat, keep, (sent >= n_dw));
            end
        end
    endtask

    task host_write;
        input        is_4dw;
        input [63:0] addr;
        input [9:0]  n_dw;
        input [7:0]  tag;
        input [511:0] pdata;
        begin
            send_hdr(make_mem_hdr(1'b1, is_4dw, n_dw, tag, 16'h0100,
                                  4'hF, 4'hF, addr, 4'd0), 1'b0);
            send_payload_dws(pdata, n_dw);
            wait_idle;
        end
    endtask

    task collect_cpl;
        integer got_hdr_beats;
        integer nbytes;
        integer lane;
        integer b;
        begin
            collect_h0 = 32'b0;
            collect_h1 = 32'b0;
            collect_h2 = 32'b0;
            collect_data = 512'b0;
            collect_n_dw = 0;
            got_hdr_beats = 0;
            collect_done = 0;
            timeout = 0;
            begin : collect_loop
                while (collect_done == 0) begin
                    wait_clk;
                    timeout = timeout + 1;
                    if (timeout > 4000) begin
                        $display("ERROR: timeout waiting for completion");
                        tb_gts_axis_mpu.errors = tb_gts_axis_mpu.errors + 1;
                        collect_done = 1;
                        disable collect_loop;
                    end
                    if (tx_tvalid && tx_tready) begin
                        if (got_hdr_beats < ((AXIS_DATA_W == 256) ? 1 : 2)) begin
                            if (got_hdr_beats == 0) begin
                                collect_h0 = tx_tdata[31:0];
                                collect_h1 = tx_tdata[63:32];
                                collect_h2 = tx_tdata[95:64];
                            end
                            got_hdr_beats = got_hdr_beats + 1;
                        end else begin
                            nbytes = 0;
                            for (b = 0; b < AXIS_BYTES; b = b + 1)
                                if (tx_tkeep[b])
                                    nbytes = nbytes + 1;
                            for (lane = 0; lane < (nbytes/4); lane = lane + 1)
                                collect_data[32*(collect_n_dw+lane) +: 32] = tx_tdata[32*lane +: 32];
                            collect_n_dw = collect_n_dw + (nbytes/4);
                        end
                        if (tx_tlast)
                            collect_done = 1;
                    end
                end
            end
        end
    endtask

    task host_read;
        input        is_4dw;
        input [63:0] addr;
        input [9:0]  n_dw;
        input [7:0]  tag;
        output [511:0] pdata;
        output [2:0]   cpl_status;
        begin
            send_hdr(make_mem_hdr(1'b0, is_4dw, n_dw, tag, 16'h0100,
                                  4'hF, 4'hF, addr, 4'd0), 1'b1);
            collect_cpl;
            pdata = collect_data;
            cpl_status = collect_h1[15:13];
            if (collect_n_dw != n_dw) begin
                $display("ERROR: completion DW count %0d expected %0d (w=%0d axil=%0d)",
                         collect_n_dw, n_dw, AXIS_DATA_W, USE_AXIL);
                tb_gts_axis_mpu.errors = tb_gts_axis_mpu.errors + 1;
            end
            wait_idle;
        end
    endtask

    task check_eq;
        input [255:0] name;
        input [31:0]  got;
        input [31:0]  exp;
        begin
            tb_gts_axis_mpu.tests = tb_gts_axis_mpu.tests + 1;
            if (got !== exp) begin
                $display("ERROR: %0s got 0x%08h expected 0x%08h (w=%0d axil=%0d)",
                         name, got, exp, AXIS_DATA_W, USE_AXIL);
                tb_gts_axis_mpu.errors = tb_gts_axis_mpu.errors + 1;
            end
        end
    endtask

    task run;
        reg [511:0] rdata;
        reg [2:0]   st;
        integer     t;
        begin
            reset_dut;

            host_read(1'b0, 64'h0, 10'd1, 8'h11, rdata, st);
            check_eq("ID", rdata[31:0], 32'h53415401);
            check_eq("Cpl SC", {29'b0, st}, 32'b0);

            host_write(1'b0, 64'h0C, 10'd1, 8'h12, {480'b0, 32'hA5A5_5A5A});
            host_read(1'b0, 64'h0C, 10'd1, 8'h13, rdata, st);
            check_eq("SCRATCH", rdata[31:0], 32'hA5A55A5A);

            host_write(1'b0, 64'h04, 10'd1, 8'h14, {480'b0, 32'h0000_00A3});
            host_read(1'b0, 64'h04, 10'd1, 8'h15, rdata, st);
            check_eq("CTRL", rdata[31:0], 32'h000000A3);

            host_write(1'b0, 64'h20, 10'd4, 8'h16, {
                384'b0, 32'h4444_4444, 32'h3333_3333, 32'h2222_2222, 32'h1111_1111
            });
            host_read(1'b0, 64'h20, 10'd4, 8'h17, rdata, st);
            check_eq("USER0", rdata[31:0], 32'h11111111);
            check_eq("USER1", rdata[63:32], 32'h22222222);
            check_eq("USER2", rdata[95:64], 32'h33333333);
            check_eq("USER3", rdata[127:96], 32'h44444444);

            host_write(1'b1, 64'h0000_0001_0000_000C, 10'd1, 8'h18,
                       {480'b0, 32'hDEADC0DE});
            host_read(1'b1, 64'h0000_0001_0000_000C, 10'd1, 8'h19, rdata, st);
            check_eq("SCRATCH 4DW", rdata[31:0], 32'hDEADC0DE);

            tx_tready <= 1'b0;
            fork
                begin
                    host_read(1'b0, 64'h00, 10'd1, 8'h1A, rdata, st);
                end
                begin
                    repeat (6) wait_clk;
                    for (t = 0; t < 24; t = t + 1) begin
                        tx_tready <= ~tx_tready;
                        wait_clk;
                    end
                    tx_tready <= 1'b1;
                end
            join
            check_eq("ID under backpressure", rdata[31:0], 32'h53415401);

            send_hdr({128'b0, 32'b0, 32'b0, 32'h0100_00FF,
                      {3'b010, 5'b10000, 14'b0, 10'd1}}, 1'b0);
            send_payload_dws(512'h1, 1);
            wait_idle;
            tb_gts_axis_mpu.tests = tb_gts_axis_mpu.tests + 1;
            if (unsupported_count == 8'd0) begin
                $display("ERROR: expected unsupported TLP to be counted");
                tb_gts_axis_mpu.errors = tb_gts_axis_mpu.errors + 1;
            end

            $display("INFO: completed width=%0d axil=%0d", AXIS_DATA_W, USE_AXIL);
        end
    endtask
endmodule
