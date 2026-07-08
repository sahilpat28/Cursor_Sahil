// Self-checking 8-PSK modem loopback testbench.
//
// The test injects a carrier frequency offset in the loopback channel and
// programs the receiver with the inverse correction word.

`timescale 1ns/1ps

module tb_psk8_modem;
    localparam signed [15:0] CFO_WORD = 16'sd164;      // ~10.0 MHz at 4 GSPS
    localparam signed [15:0] RX_CORR_WORD = -16'sd164;
    localparam integer TARGET_SYMBOLS = 512;

    reg clk = 1'b0;
    reg rst = 1'b1;
    reg sample_valid = 1'b1;
    reg seed_load = 1'b0;
    reg [30:0] prbs_seed = 31'h7fffffff;
    reg rx_phase_clear = 1'b0;

    wire dac_valid;
    wire signed [15:0] dac_i;
    wire signed [15:0] dac_q;
    wire channel_valid;
    wire signed [15:0] adc_i;
    wire signed [15:0] adc_q;
    wire [2:0] tx_bits;
    wire tx_symbol_valid;
    wire [2:0] rx_bits;
    wire rx_bits_valid;
    wire signed [15:0] corrected_i;
    wire signed [15:0] corrected_q;
    wire signed [15:0] matched_i;
    wire signed [15:0] matched_q;

    reg [2:0] tx_fifo [0:4095];
    integer wr_ptr = 0;
    integer rd_ptr = 0;
    integer checked = 0;
    integer errors = 0;
    integer cycle_count = 0;

    always #5 clk = ~clk;

    psk8_modem_top #(
        .RX_SYMBOL_SAMPLE_PHASE(2'd1),
        .RX_STARTUP_SAMPLES(41)
    ) dut (
        .clk(clk),
        .rst(rst),
        .sample_valid(sample_valid),
        .seed_load(seed_load),
        .prbs_seed(prbs_seed),
        .rx_phase_inc(RX_CORR_WORD),
        .rx_phase_clear(rx_phase_clear),
        .dac_valid(dac_valid),
        .dac_i(dac_i),
        .dac_q(dac_q),
        .adc_valid(channel_valid),
        .adc_i(adc_i),
        .adc_q(adc_q),
        .tx_bits(tx_bits),
        .tx_symbol_valid(tx_symbol_valid),
        .rx_bits(rx_bits),
        .rx_bits_valid(rx_bits_valid),
        .corrected_i(corrected_i),
        .corrected_q(corrected_q),
        .matched_i(matched_i),
        .matched_q(matched_q)
    );

    nco_rotator channel_cfo (
        .clk(clk),
        .rst(rst),
        .in_valid(dac_valid),
        .phase_clear(1'b0),
        .phase_inc(CFO_WORD),
        .i_in(dac_i),
        .q_in(dac_q),
        .out_valid(channel_valid),
        .i_out(adc_i),
        .q_out(adc_q)
    );

    initial begin
        $dumpfile("tb_psk8_modem.vcd");
        $dumpvars(0, tb_psk8_modem);

        repeat (8) @(posedge clk);
        rst <= 1'b0;

        wait (checked == TARGET_SYMBOLS);
        if (errors == 0) begin
            $display("PASS: recovered %0d PRBS31 8-PSK symbols with CFO correction", checked);
            $finish;
        end else begin
            $display("FAIL: %0d errors in %0d recovered symbols", errors, checked);
            $fatal;
        end
    end

    always @(posedge clk) begin
        if (!rst) begin
            cycle_count <= cycle_count + 1;

            if (tx_symbol_valid) begin
                tx_fifo[wr_ptr] <= tx_bits;
                wr_ptr <= wr_ptr + 1;
            end

            if (rx_bits_valid) begin
                if (rd_ptr >= wr_ptr) begin
                    $display("ERROR: RX symbol arrived before TX scoreboard data");
                    errors <= errors + 1;
                end else if (rx_bits !== tx_fifo[rd_ptr]) begin
                    $display(
                        "ERROR: symbol %0d expected %b got %b matched_i=%0d matched_q=%0d",
                        checked,
                        tx_fifo[rd_ptr],
                        rx_bits,
                        matched_i,
                        matched_q
                    );
                    errors <= errors + 1;
                end

                rd_ptr <= rd_ptr + 1;
                checked <= checked + 1;
            end

            if (cycle_count > 20000) begin
                $display("FAIL: timeout checked=%0d errors=%0d wr_ptr=%0d rd_ptr=%0d",
                         checked, errors, wr_ptr, rd_ptr);
                $fatal;
            end
        end
    end
endmodule

