module top (
		input  wire        clk_clk,                                  
		output wire [0:0]  mem_0_mem_cs,            
		output wire [5:0]  mem_0_mem_ca,            
		output wire [0:0]  mem_0_mem_cke,           
		inout  wire [31:0] mem_0_mem_dq,            
		inout  wire [3:0]  mem_0_mem_dqs_t,         
		inout  wire [3:0]  mem_0_mem_dqs_c,         
		inout  wire [3:0]  mem_0_mem_dmi,           
		output wire [0:0]  mem_ck_0_mem_ck_t,       
		output wire [0:0]  mem_ck_0_mem_ck_c,       
		output wire        mem_reset_n_mem_reset_n, 
		input  wire        oct_0_oct_rzqin,         
		input  wire        ref_clk_clk,             
		input  wire        reset_reset,
		
		inout  wire        intel_agilex_5_soc_0_hps_io_sdmmc_data0,  //  intel_agilex_5_soc_0_hps_io.sdmmc_data0
		inout  wire        intel_agilex_5_soc_0_hps_io_sdmmc_data1,  //                             .sdmmc_data1
		output wire        intel_agilex_5_soc_0_hps_io_sdmmc_cclk,   //                             .sdmmc_cclk
		inout  wire        intel_agilex_5_soc_0_hps_io_sdmmc_data2,  //                             .sdmmc_data2
		inout  wire        intel_agilex_5_soc_0_hps_io_sdmmc_data3,  //                             .sdmmc_data3
		inout  wire        intel_agilex_5_soc_0_hps_io_sdmmc_cmd,    //                             .sdmmc_cmd
		output wire        intel_agilex_5_soc_0_hps_io_emac2_tx_clk, //                             .emac2_tx_clk
		output wire        intel_agilex_5_soc_0_hps_io_emac2_tx_ctl, //                             .emac2_tx_ctl
		input  wire        intel_agilex_5_soc_0_hps_io_emac2_rx_clk, //                             .emac2_rx_clk
		input  wire        intel_agilex_5_soc_0_hps_io_emac2_rx_ctl, //                             .emac2_rx_ctl
		output wire        intel_agilex_5_soc_0_hps_io_emac2_txd0,   //                             .emac2_txd0
		output wire        intel_agilex_5_soc_0_hps_io_emac2_txd1,   //                             .emac2_txd1
		input  wire        intel_agilex_5_soc_0_hps_io_emac2_rxd0,   //                             .emac2_rxd0
		input  wire        intel_agilex_5_soc_0_hps_io_emac2_rxd1,   //                             .emac2_rxd1
		output wire        intel_agilex_5_soc_0_hps_io_emac2_txd2,   //                             .emac2_txd2
		output wire        intel_agilex_5_soc_0_hps_io_emac2_txd3,   //                             .emac2_txd3
		input  wire        intel_agilex_5_soc_0_hps_io_emac2_rxd2,   //                             .emac2_rxd2
		input  wire        intel_agilex_5_soc_0_hps_io_emac2_rxd3,   //                             .emac2_rxd3
		inout  wire        intel_agilex_5_soc_0_hps_io_mdio2_mdio,   //                             .mdio2_mdio
		output wire        intel_agilex_5_soc_0_hps_io_mdio2_mdc,
      // User interface
      
      // SPI interface


	//i2c1
	   inout  wire i2c_sda,
		inout  wire i2c_scl,
	//
	
	//fpga pins
	 //----------------------------------------------------------------------
    // UART
    //----------------------------------------------------------------------
    output wire FPGA_UART_TX,
    input  wire FPGA_UART_RX,

    output wire GPS_UART_TX,
    input  wire GPS_UART_RX,

    //----------------------------------------------------------------------
    // GPS
    //----------------------------------------------------------------------
    output wire GPS_RESET_N,
    input wire GPS_PPS_SYNC_CLK,
	 input wire GPS_1pps,


    //----------------------------------------------------------------------
    // AMBE
    //----------------------------------------------------------------------
    output wire AMBE_RESET,
    output wire AMBE_RST,
    input  wire AMBE_RX,
    output wire AMBE_TX,

    //----------------------------------------------------------------------
    // Digital Microphone / Codec
    //----------------------------------------------------------------------
    output wire KEY_RST,
    output  wire DIS_CD,
    output wire DIS_RES,
    output wire DIS_CS,
    inout wire DIS_SCLK,
    output wire DIS_SDIN,
    input  wire DIS_SDOUT,
    input  wire KEYPAD_INT,

    //----------------------------------------------------------------------
    // Audio Codec
    //----------------------------------------------------------------------
	 input wire AC_IRQ,
    input wire AC_SDINS1,
    input wire AC_BCLK1,
    output  wire AC_SDOUTS1,
    input wire AC_VOLUME,

    //----------------------------------------------------------------------
    // Spare GPIO
    //----------------------------------------------------------------------
    inout  wire SPARE_GPIO5,
    inout  wire SPARE_GPIO4,
    inout  wire SPARE_GPIO3,
    inout  wire SPARE_GPIO2,
    inout  wire SPARE_GPIO1,

    //----------------------------------------------------------------------
    // Test control
    //----------------------------------------------------------------------
    output wire TTR_CTRL1,
    output wire TTR_CTRL2,
	//
	
	
   // ADRV9001 LVDS Interface -- Rx shared dclk (drives both Rx1 and Rx2)
    //=========================================================================
             
             
 
    //=========================================================================
    // ADRV9001 LVDS Interface -- Rx1 data
    //=========================================================================
    input  wire         adrv9001_rx1_idata_in_n,
    input  wire         adrv9001_rx1_idata_in_p,
    input  wire         adrv9001_rx1_qdata_in_n,
    input  wire         adrv9001_rx1_qdata_in_p,
    input  wire         adrv9001_rx1_strobe_in_n,
    input  wire         adrv9001_rx1_strobe_in_p,
    output wire         adrv9001_rx1_enable,
	 input  wire         adrv9001_rx1_dclk_in_n, 
    input  wire         adrv9001_rx1_dclk_in_p, 
    //=========================================================================
    // ADRV9001 LVDS Interface -- Rx2 data
    //=========================================================================
    input  wire         adrv9001_rx2_idata_in_n,
    input  wire         adrv9001_rx2_idata_in_p,
    input  wire         adrv9001_rx2_qdata_in_n,
    input  wire         adrv9001_rx2_qdata_in_p,
    input  wire         adrv9001_rx2_strobe_in_n,
    input  wire         adrv9001_rx2_strobe_in_p,
    output wire         adrv9001_rx2_enable,
	 input  wire         adrv9001_rx2_dclk_in_n, 
    input  wire         adrv9001_rx2_dclk_in_p, 
    //=========================================================================
    // ADRV9001 LVDS Interface -- Tx shared dclk (drives both Tx1 and Tx2)
    //=========================================================================

 
    //=========================================================================
    // ADRV9001 LVDS Interface -- Tx1 data
    //=========================================================================
	 input  wire         adrv9001_tx1_dclk_in_n, 
	 input  wire         adrv9001_tx1_dclk_in_p, 
    output wire         adrv9001_tx1_dclk_out_n,
    output wire         adrv9001_tx1_dclk_out_p,
    output wire         adrv9001_tx1_idata_out_n,
    output wire         adrv9001_tx1_idata_out_p,
    output wire         adrv9001_tx1_qdata_out_n,
    output wire         adrv9001_tx1_qdata_out_p,
    output wire         adrv9001_tx1_enable,
	 output wire         adrv9001_tx1_strobe_out_n,   // <-- add this
    output wire         adrv9001_tx1_strobe_out_p,   // <-- add this
 
    //=========================================================================
    // ADRV9001 LVDS Interface -- Tx2 data
    //=========================================================================
	 input  wire         adrv9001_tx2_dclk_in_n,         
    input  wire         adrv9001_tx2_dclk_in_p,         
    output wire         adrv9001_tx2_dclk_out_n,
    output wire         adrv9001_tx2_dclk_out_p,
    output wire         adrv9001_tx2_idata_out_n,
    output wire         adrv9001_tx2_idata_out_p,
    output wire         adrv9001_tx2_qdata_out_n,
    output wire         adrv9001_tx2_qdata_out_p,
    output wire         adrv9001_tx2_enable,
	 output wire         adrv9001_tx2_strobe_out_n,   // <-- add this
    output wire         adrv9001_tx2_strobe_out_p,   // <-- add this
 
    //=========================================================================
    // ADRV9001 Common control
    //=========================================================================
		output wire       reset_b_1,
		output wire       mode_1,
		output wire       gp_int_1,
		input  wire       aux_dac_3,
		output wire       rzq,
		output wire       dev_clk_in_p,
		output wire       dev_clk_in_n,
		input wire       dev_clk_out,
		output wire       mcs_p_in_p,
		output wire       mcs_p_in_n,
		output wire       dgpio_0,
		output wire       dgpio_1,
		output wire       dgpio_2,
		output wire       dgpio_3,
		output wire       agpio_0,
		output wire       agpio_1,
		output wire       agpio_2,
		output wire       agpio_3,
		input wire       spi_do_1,
		output wire       spi_dio_1,
		output wire       spi_clk_1,
		output wire       spi_en_1
);

//spi
wire                          o_spi_busy;   
wire                          i_wr_en;
wire [7:0]     					i_wr_data;
wire                          o_rd_data_vld;
wire [7:0]     					o_rd_data;
    //=========================================================
    // I2C Signals
    //=========================================================
    wire [31:0] i2c_address;
    wire        i2c_read;
    wire        i2c_write;
    wire [3:0]  i2c_byteenable;
    wire [31:0] i2c_writedata;

    wire        i2c_data_in;
    wire        i2c_clk_in;
    wire        i2c_data_oe;
    wire        i2c_clk_oe;
	 
	 assign i2c_data_in = i2c_sda;
    assign i2c_clk_in  = i2c_scl;

    // Open-drain outputs
    assign i2c_sda = i2c_data_oe ? 1'b0 : 1'bz;
    assign i2c_scl = i2c_clk_oe  ? 1'b0 : 1'bz;

hps_sys h1(
		.clk_clk                      				  (clk_clk),                                  
		.emif_io96b_hps_0_mem_0_mem_cs              (mem_0_mem_cs),            
		.emif_io96b_hps_0_mem_0_mem_ca              (mem_0_mem_ca),            
		.emif_io96b_hps_0_mem_0_mem_cke             (mem_0_mem_cke),           
		.emif_io96b_hps_0_mem_0_mem_dq              (mem_0_mem_dq),            
		.emif_io96b_hps_0_mem_0_mem_dqs_t           (mem_0_mem_dqs_t),         
		.emif_io96b_hps_0_mem_0_mem_dqs_c           (mem_0_mem_dqs_c),         
		.emif_io96b_hps_0_mem_0_mem_dmi             (mem_0_mem_dmi),           
		.emif_io96b_hps_0_mem_ck_0_mem_ck_t         (mem_ck_0_mem_ck_t),       
		.emif_io96b_hps_0_mem_ck_0_mem_ck_c         (mem_ck_0_mem_ck_c),       
		.emif_io96b_hps_0_mem_reset_n_mem_reset_n   (mem_reset_n_mem_reset_n), 
		.emif_io96b_hps_0_oct_0_oct_rzqin           (oct_0_oct_rzqin),         
		.emif_io96b_hps_0_ref_clk_clk               (ref_clk_clk),   

		.intel_agilex_5_soc_0_hps_io_sdmmc_data0           (intel_agilex_5_soc_0_hps_io_sdmmc_data0  ),  
		.intel_agilex_5_soc_0_hps_io_sdmmc_data1           (intel_agilex_5_soc_0_hps_io_sdmmc_data1  ),  
		.intel_agilex_5_soc_0_hps_io_sdmmc_cclk            (intel_agilex_5_soc_0_hps_io_sdmmc_cclk   ),   
		.intel_agilex_5_soc_0_hps_io_sdmmc_data2           (intel_agilex_5_soc_0_hps_io_sdmmc_data2  ),  
		.intel_agilex_5_soc_0_hps_io_sdmmc_data3           (intel_agilex_5_soc_0_hps_io_sdmmc_data3  ),  
		.intel_agilex_5_soc_0_hps_io_sdmmc_cmd             (intel_agilex_5_soc_0_hps_io_sdmmc_cmd    ),    
		.intel_agilex_5_soc_0_hps_io_emac2_tx_clk          (intel_agilex_5_soc_0_hps_io_emac2_tx_clk ), 
		.intel_agilex_5_soc_0_hps_io_emac2_tx_ctl          (intel_agilex_5_soc_0_hps_io_emac2_tx_ctl ), 
		.intel_agilex_5_soc_0_hps_io_emac2_rx_clk          (intel_agilex_5_soc_0_hps_io_emac2_rx_clk ), 
		.intel_agilex_5_soc_0_hps_io_emac2_rx_ctl          (intel_agilex_5_soc_0_hps_io_emac2_rx_ctl ), 
		.intel_agilex_5_soc_0_hps_io_emac2_txd0            (intel_agilex_5_soc_0_hps_io_emac2_txd0   ),   
		.intel_agilex_5_soc_0_hps_io_emac2_txd1            (intel_agilex_5_soc_0_hps_io_emac2_txd1   ),   
		.intel_agilex_5_soc_0_hps_io_emac2_rxd0            (intel_agilex_5_soc_0_hps_io_emac2_rxd0   ),   
		.intel_agilex_5_soc_0_hps_io_emac2_rxd1            (intel_agilex_5_soc_0_hps_io_emac2_rxd1   ),   
		.intel_agilex_5_soc_0_hps_io_emac2_txd2            (intel_agilex_5_soc_0_hps_io_emac2_txd2   ),   
		.intel_agilex_5_soc_0_hps_io_emac2_txd3            (intel_agilex_5_soc_0_hps_io_emac2_txd3   ),   
		.intel_agilex_5_soc_0_hps_io_emac2_rxd2            (intel_agilex_5_soc_0_hps_io_emac2_rxd2   ),   
		.intel_agilex_5_soc_0_hps_io_emac2_rxd3            (intel_agilex_5_soc_0_hps_io_emac2_rxd3   ),   
		.intel_agilex_5_soc_0_hps_io_mdio2_mdio            (intel_agilex_5_soc_0_hps_io_mdio2_mdio   ),   
		.intel_agilex_5_soc_0_hps_io_mdio2_mdc             (intel_agilex_5_soc_0_hps_io_mdio2_mdc    ),		
		.reset_reset    							        (reset_reset)                  
	);
	
i2c1 u_i2c1 (
        .clk            (clk_clk),

        .address        (i2c_address),
        .read           (i2c_read),
        .readdata       (32'h00000000),
        .readdatavalid  (1'b0),
        .waitrequest    (1'b0),
        .write          (i2c_write),
        .byteenable     (i2c_byteenable),
        .writedata      (i2c_writedata),

        .rst_n          (~reset_reset),

        .i2c_data_in    (i2c_data_in),
        .i2c_clk_in     (i2c_clk_in),
        .i2c_data_oe    (i2c_data_oe),
        .i2c_clk_oe     (i2c_clk_oe)
    );

spi_4wire_master spi1(

 .i_clk(clk_clk),
 .i_rst(~reset_reset),
 
 .o_spi_busy      (o_spi_busy   ),
 .i_wr_en			(i_wr_en ),
 .i_wr_data			(i_wr_data ),
 .o_rd_data_vld	(o_rd_data_vld ),
 .o_rd_data			(o_rd_data ),
 
 .o_4wire_spi_cs    (spi_en_1),
 .o_4wire_spi_clk	  (spi_clk_1),
 .o_4wire_spi_mosi  (spi_dio_1),
 .i_4wire_spi_miso  (spi_do_1)
);

//=========================================================================
// GPIO INPUT instance — all extra top-level input pins
//=========================================================================
wire [31:0] gpio_in_dout;
wire [31:0] gpio_in_pad;

assign gpio_in_pad[0]  = FPGA_UART_RX;
assign gpio_in_pad[1]  = GPS_UART_RX;
assign gpio_in_pad[2]  = GPS_PPS_SYNC_CLK;
assign gpio_in_pad[3]  = GPS_1pps;
assign gpio_in_pad[4]  = AMBE_RX;
assign gpio_in_pad[5]  = DIS_SDOUT;
assign gpio_in_pad[6]  = KEYPAD_INT;
assign gpio_in_pad[7]  = AC_IRQ;
assign gpio_in_pad[8]  = AC_SDINS1;
assign gpio_in_pad[9]  = AC_BCLK1;
assign gpio_in_pad[10] = AC_VOLUME;
assign gpio_in_pad[11] = aux_dac_3;
assign gpio_in_pad[12] = dev_clk_out;
assign gpio_in_pad[31:13] = 19'b0;   // unused bits tied low

gpios gpio_in_extra (
	.dout   (gpio_in_dout),  // -> to fabric logic
	.pad_in (gpio_in_pad)
);



//=========================================================================
// GPIO OUTPUT instance #1 — 32 of 34 extra output pins
//=========================================================================
wire [31:0] gpio_out0_din;
wire [31:0] gpio_out0_pad;

assign gpio_out0_din = 32'b0;   // placeholder — drive from fabric logic

gpio2_hsio gpio_out_extra0 (
	.din     (gpio_out0_din),
	.pad_out (gpio_out0_pad)
);

assign FPGA_UART_TX = gpio_out0_pad[0];
assign GPS_UART_TX   = gpio_out0_pad[1];
assign GPS_RESET_N   = gpio_out0_pad[2];
assign AMBE_RESET    = gpio_out0_pad[3];
assign AMBE_RST      = gpio_out0_pad[4];
assign AMBE_TX       = gpio_out0_pad[5];
assign KEY_RST       = gpio_out0_pad[6];
assign DIS_CD        = gpio_out0_pad[7];
assign DIS_RES       = gpio_out0_pad[8];
assign DIS_CS        = gpio_out0_pad[9];
assign DIS_SDIN      = gpio_out0_pad[10];
assign AC_SDOUTS1    = gpio_out0_pad[11];
assign TTR_CTRL1     = gpio_out0_pad[12];
assign TTR_CTRL2     = gpio_out0_pad[13];
assign  gpio_out0_pad[14] = 1'b0;
assign gpio_out0_pad[15]=1'b0;
assign gpio_out0_pad[16]= 1'b0 ;
assign gpio_out0_pad[17]=1'b0 ;
assign reset_b_1     = gpio_out0_pad[18];
assign mode_1        = gpio_out0_pad[19];
assign gp_int_1      = gpio_out0_pad[20];
assign rzq           = gpio_out0_pad[21];
assign dev_clk_in_p  = gpio_out0_pad[22];
assign dev_clk_in_n  = gpio_out0_pad[23];
assign mcs_p_in_p    = gpio_out0_pad[24];
assign mcs_p_in_n    = gpio_out0_pad[25];
assign dgpio_0       = gpio_out0_pad[26];
assign dgpio_1       = gpio_out0_pad[27];
assign dgpio_2       = gpio_out0_pad[28];
assign dgpio_3       = gpio_out0_pad[29];
assign agpio_0       = gpio_out0_pad[30];
assign agpio_1       = gpio_out0_pad[31];

//=========================================================================
// GPIO OUTPUT instance #2 — remaining 2 pins
//=========================================================================
wire [31:0] gpio_out1_din;
wire [31:0] gpio_out1_pad;

assign gpio_out1_din = 32'b0;   // placeholder

gpio2_hsio gpio_out_extra1 (
	.din     (gpio_out1_din),
	.pad_out (gpio_out1_pad)
);

assign agpio_2 = gpio_out1_pad[0];
assign agpio_3 = gpio_out1_pad[1];
// gpio_out1_pad[31:2] unused



endmodule