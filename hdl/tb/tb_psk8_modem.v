// Self-checking 500 MHz 8-PSK modem loopback testbench.
//
// The test injects a carrier frequency offset in the loopback channel and
// programs the receiver with the inverse correction word.

`timescale 1ns/1ps

module tb_psk8_modem;
    localparam signed [15:0] CFO_WORD = 16'sd164;      // ~10.0 MHz at 4 GSPS
    localparam signed [15:0] RX_CORR_WORD = -16'sd164;
    localparam integer TARGET_SYMBOLS = 1024;

    reg clk = 1'b0;
    reg rst = 1'b1;
    reg block_valid = 1'b1;
    reg seed_load = 1'b0;
    reg [30:0] prbs_seed = 31'h7fffffff;
    reg rx_phase_clear = 1'b0;

    wire dac_valid;
    wire signed [127:0] dac_i;
    wire signed [127:0] dac_q;
    wire channel_valid;
    wire signed [127:0] adc_i;
    wire signed [127:0] adc_q;
    wire [5:0] tx_bits;
    wire [1:0] tx_symbol_valid;
    wire [5:0] rx_bits;
    wire [1:0] rx_bits_valid;
    wire signed [127:0] corrected_i;
    wire signed [127:0] corrected_q;
    wire signed [127:0] matched_i;
    wire signed [127:0] matched_q;

    reg [2:0] tx_fifo [0:4095];
    integer wr_ptr = 0;
    integer rd_ptr = 0;
    integer checked = 0;
    integer errors = 0;
    integer cycle_count = 0;

    // 500 MHz RTL clock: 2 ns period.
    always #1 clk = ~clk;

    psk8_modem_top #(
        .RX_SYMBOL_SAMPLE_PHASE(2'd0),
        .RX_STARTUP_BLOCKS(5)
    ) dut (
        .clk(clk),
        .rst(rst),
        .block_valid(block_valid),
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

    nco_rotator_8x channel_cfo (
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
            $display("PASS: recovered %0d PRBS31 8-PSK symbols at 500 MHz RTL clock with CFO correction", checked);
            $finish;
        end else begin
            $display("FAIL: %0d errors in %0d recovered symbols", errors, checked);
            $fatal;
        end
    end

    always @(posedge clk) begin
        if (!rst) begin
            cycle_count <= cycle_count + 1;

            if (tx_symbol_valid[0]) begin
                tx_fifo[wr_ptr] <= tx_bits[2:0];
                wr_ptr <= wr_ptr + 1;
            end
            if (tx_symbol_valid[1]) begin
                tx_fifo[wr_ptr + tx_symbol_valid[0]] <= tx_bits[5:3];
                wr_ptr <= wr_ptr + 1 + tx_symbol_valid[0];
            end

            if (rx_bits_valid[0]) begin
                check_symbol(rx_bits[2:0], rd_ptr, checked, matched_i[15:0], matched_q[15:0]);
                rd_ptr <= rd_ptr + 1;
                checked <= checked + 1;
            end
            if (rx_bits_valid[1]) begin
                check_symbol(rx_bits[5:3], rd_ptr + rx_bits_valid[0], checked + rx_bits_valid[0],
                             matched_i[79:64], matched_q[79:64]);
                rd_ptr <= rd_ptr + 1 + rx_bits_valid[0];
                checked <= checked + 1 + rx_bits_valid[0];
            end

            if (cycle_count > 10000) begin
                $display("FAIL: timeout checked=%0d errors=%0d wr_ptr=%0d rd_ptr=%0d",
                         checked, errors, wr_ptr, rd_ptr);
                $fatal;
            end
        end
    end

    task check_symbol;
        input [2:0] got_bits;
        input integer fifo_index;
        input integer symbol_index;
        input signed [15:0] sym_i;
        input signed [15:0] sym_q;
        begin
            if (fifo_index >= wr_ptr) begin
                $display("ERROR: RX symbol arrived before TX scoreboard data");
                errors <= errors + 1;
            end else if (got_bits !== tx_fifo[fifo_index]) begin
                $display(
                    "ERROR: symbol %0d expected %b got %b matched_i=%0d matched_q=%0d",
                    symbol_index,
                    tx_fifo[fifo_index],
                    got_bits,
                    sym_i,
                    sym_q
                );
                errors <= errors + 1;
            end
        end
    endtask
endmodule

