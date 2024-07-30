
//////////////////////////////////////////////////////////////////////////////
// Paver microcontroller FPGA top level file NOV 2018
// Author: Michael Mangelsdorf (mim@ok-schalter.de)
//////////////////////////////////////////////////////////////////////////////


module Paver (

	input 		          		CLOCK_50,

	//////////// SEG7 //////////
	output		     [6:0]		HEX0,
	output		     [6:0]		HEX1,
	output		     [6:0]		HEX2,
	output		     [6:0]		HEX3,
	output		     [6:0]		HEX4,
	output		     [6:0]		HEX5,

	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// SW //////////
	input 		     [9:0]		SW,

	//////////// PS2 //////////
	input 		          		PS2_CLK,
	// inout 		          		PS2_CLK2,
	input 		          		PS2_DAT,
	// inout 		          		PS2_DAT2,

	//////////// VGA //////////
	output		          		VGA_BLANK_N,
	output		     [7:0]		VGA_B,
	output		          		VGA_CLK,
	output		     [7:0]		VGA_G,
	output		          		VGA_HS,
	output		     [7:0]		VGA_R,
	output		          		VGA_SYNC_N,
	output		          		VGA_VS,

	input   		     [31:0]		GPIO,
	output           [31:0]    GPIO_OUT,

	output CORE_CLK,
	output FETCH,
	input IRQ1,
	input IRQ2,

	input  SDMISO,
	output SDCLK,
	output SDCS,
	output SDMOSI
);

parameter DWRAM_ADDR_WIDTH = 10;
parameter GRAM_ADDR_WIDTH = 17;
parameter FRAM_ADDR_WIDTH = 13;

reg [31:0] cycles;
reg [15:0] microsecs;
reg [16:0] nanosecs; // Count 1000ns to 2 decimals (000_00) need 17 bits

reg RESET = 0;
wire [15:0] bgcol;

// Keyboard

wire [7:0] keycode;
wire pickup;
wire kbreset;
wire ctrl_pressed;

// DEFINE CLOCKS

wire RAM_CLK; // Why is this required but not for VGA_CLK

pll_core coreclocks (
	.refclk   ( CLOCK_50 ),
	.rst      ( RESET    ),
	.outclk_0 ( RAM_CLK  ),
	.outclk_1 ( CORE_CLK )
);

pll_util utilclocks (
	.refclk   ( CLOCK_50 ),
	.rst      ( RESET    ),
	.outclk_0 ( VGA_CLK  )
);

// INSTANTIATE RAMS

// Common General purpose RAM interconnect

wire [GRAM_ADDR_WIDTH-1:0] gaddr_a;
reg  [GRAM_ADDR_WIDTH-1:0] gaddr_b;
wire [15:0] gdata_a;
wire [15:0] gdata_b;
wire        gwren_a;
reg         gwren_b;
wire [15:0] gq_a;
wire [15:0] gq_b;

wire [3:0] overlay_sel_fg; // Selects 8k overlay region from E000 to FFFF
wire [3:0] overlay_sel_bg; // Selects 8k overlay region from E000 to FFFF for 2nd core

dpRAMmain main_ram (

	.address_a ( (gaddr_a[15:13]==3'b111) ? {3'b111+overlay_sel_fg, gaddr_a[12:0]} : gaddr_a ),
	.address_b ( (gaddr_b[15:13]==3'b111) ? {3'b111+overlay_sel_fg, gaddr_b[12:0]} : gaddr_b ),
	.clock_a   ( RAM_CLK ),
	.clock_b   ( RAM_CLK ),
	.data_a    ( gdata_a  ),
	.data_b    ( gdata_b  ),
	.wren_a    ( gwren_a  ),
	.wren_b    ( gwren_b  ),
	.q_a       ( gq_a     ),
	.q_b       ( gq_b     )

);

// Core frame stack RAM interconnect

wire [FRAM_ADDR_WIDTH-1:0] f1addr_a;
wire [FRAM_ADDR_WIDTH-1:0] f1addr_b;
wire [15:0] f1data_a;
wire [15:0] f1data_b;
wire        f1wren_a;
wire        f1wren_b;
wire [15:0] f1q_a;
wire [15:0] f1q_b;

dpRAMframe frame_ram1 (

	.address_a ( f1addr_a  ),
	.address_b ( f1addr_b  ),
	.clock     ( RAM_CLK  ),
	.data_a    ( f1data_a  ),
	.data_b    ( f1data_b  ),
	.wren_a    ( f1wren_a  ),
	.wren_b    ( f1wren_b  ),
	.q_a       ( f1q_a     ),
	.q_b       ( f1q_b     )

);


// Font RAM interconnect

wire [11:0] font_addr_a;
wire [11:0] font_addr_b;
wire [15:0] font_data_a;
wire [15:0] font_data_b;
wire        font_wren_a;
wire        font_wren_b;
wire [15:0] font_q_a;
wire [15:0] font_q_b;

dpRAMfont font (

	.address_a ( font_addr_a ),
	.address_b ( font_addr_b ),
	.clock_a   ( RAM_CLK    ),
	.clock_b   ( ~VGA_CLK   ),
	.data_a    ( font_data_a ),
	.data_b    ( font_data_b ),
	.wren_a    ( font_wren_a ),
	.wren_b    ( font_wren_b ),
	.q_a       ( font_q_a    ),
	.q_b       ( font_q_b    )
);



// TXT RAM interconnect
// This RAM is IO mapped

wire        cursor_vis;
wire [6:0]  cursor_x;
wire [4:0]  cursor_y;

wire [12:0] txt_addr_a;
wire [12:0] txt_addr_b;
wire [31:0] txt_data_a;
wire [31:0] txt_data_b;
wire        txt_wren_a;
wire        txt_wren_b;
wire [31:0] txt_q_a;
wire [31:0] txt_q_b;

dpRAMtxt txt (

	.address_a ( txt_addr_a ),
	.address_b ( txt_addr_b ),
	.clock_a   ( RAM_CLK    ),
	.clock_b   ( VGA_CLK   ),
	.data_a    ( txt_data_a ),
	.data_b    ( txt_data_b ),
	.wren_a    ( txt_wren_a ),
	.wren_b    ( txt_wren_b ),
	.q_a       ( txt_q_a    ),
	.q_b       ( txt_q_b    )
);

// GFX RAM interconnect
// This RAM is IO mapped

wire [16:0] gfx_base;
wire [12:0] txt_base;

wire [16:0] gfx_addr_a;
wire [16:0] gfx_addr_b;
wire [8:0]	gfx_data_a;
wire [8:0]	gfx_data_b;
wire        gfx_wren_a;
wire        gfx_wren_b;
wire [8:0]	gfx_q_a;
wire [8:0]	gfx_q_b;

dpRAMgfx gfx (

   .address_a ( gfx_addr_a    ),
	.address_b ( gfx_addr_b    ),
	.clock_a   ( RAM_CLK       ),
	.clock_b   ( VGA_CLK      ),
	.data_a    ( gfx_data_a    ),
	.data_b    ( gfx_data_b    ),
	.wren_a    ( gfx_wren_a    ),
	.wren_b    ( gfx_wren_b    ),
	.q_a       ( gfx_q_a       ),
	.q_b       ( gfx_q_b       )

);


// Instantiate CPU core(s)

Paver_CORE #(
	.FRAM_ADDR_WIDTH(FRAM_ADDR_WIDTH),
	.GRAM_ADDR_WIDTH(GRAM_ADDR_WIDTH),
	.GRAM_TOPADDR(98303) )
fgcore (

   .reset ( RESET ),
   .clk ( CORE_CLK ),
	.irq1 ( IRQ1 ),
	.irq2 ( IRQ2 ),

   // Core 1 RAM interconnect

	.faddr_a ( f1addr_a    ),
	.faddr_b ( f1addr_b    ),
	.fdata_a ( f1data_a    ),
	.fdata_b	( f1data_b    ),
	.fwren_a	( f1wren_a    ),
	.fwren_b	( f1wren_b    ),
	.fq_a   	( f1q_a       ),
	.fq_b   	( f1q_b       ),

   // Common RAM interconnect

	.overlay_sel    ( overlay_sel_fg ),

	.gaddr (gaddr_a),
	.gdata (gdata_a),
	.gwren (gwren_a),
  	.gq (gq_a),
	
   // font RAM interconnect

	.font_addr	 ( font_addr_a  ),
   .font_data   ( font_data_a  ),
   .font_wren   ( font_wren_a  ),
	.font_q		 ( font_q_a     ),

   // txt RAM interconnect

	.txt_addr	 ( txt_addr_a  ),
   .txt_data    ( txt_data_a  ),
   .txt_wren    ( txt_wren_a  ),
	.txt_q		 ( txt_q_a     ),

	.txt_base ( txt_base ),

	.cursor_vis			 ( cursor_vis        ), 
	.cursor_x			 ( cursor_x          ),
   .cursor_y          ( cursor_y          ),

	// Graphics RAM interconnect

   .gfx_addr          ( gfx_addr_a        ),
   .gfx_data          ( gfx_data_a        ),
   .gfx_wren          ( gfx_wren_a        ),
   .gfx_q             ( gfx_q_a           ),

	.gfx_base          ( gfx_base          ),

   .H_GFX_offs ( H_GFX_offs ),
	.V_GFX_offs ( V_GFX_offs ),

	.blanking         ( VGA_BLANK_N ),
	.bgcol 				( bgcol ),

	.gpio ( GPIO ),
	.gpio_out ( GPIO_OUT ),

	.seg7hex01 ( {HEX0,HEX1} ),
	.seg7hex23 ( {HEX2,HEX3} ),
	.seg7hex45 ( {HEX4,HEX5} ),

   .led ( LEDR ),

	.keysw ( {KEY,SW} ),

   // PS/2 Keyboard interconnect

	.keycode (keycode),
	.pickup (pickup),
	.ctrl_pressed      ( ctrl_pressed      ),

	// SDCARD

   .sd_clk  ( SDCLK  ),
   .sd_mosi ( SDMOSI ),
   .sd_cs   ( SDCS   ),
   .sd_miso ( SDMISO ),

	.cycles (cycles),
	.microsecs (microsecs),
	.fetch (FETCH)
);


Paver_PS2 keyb (

	.reset      ( kbreset    ),
	.coreclk		( CORE_CLK   ),
   .ps2clk     ( PS2_CLK    ),
	.ps2data    ( PS2_DAT    ),
   .ps2key     ( keycode    ),
	.pickup (pickup),
	.ctrl_pressed ( ctrl_pressed   )

);

wire [9:0] H_GFX_offs; // Changing this to _start did not cause any warning!
wire [9:0] V_GFX_offs;

Paver_VGA vga (

   .clk      ( VGA_CLK ),

   .red      ( VGA_R[7:0] ),
   .green    ( VGA_G[7:0] ),
   .blue     ( VGA_B[7:0] ),
   .hsync    ( VGA_HS     ),
   .vsync    ( VGA_VS     ),
   .blank_n  ( VGA_BLANK_N ),
   .sync_n   ( VGA_SYNC_N  ),
	
	.font_addr (font_addr_b),
	.font_q    (font_q_b),

   .txt_addr ( txt_addr_b ),
   .txt_data ( txt_data_b ),
   .txt_wren ( txt_wren_b ),
   .txt_q    ( txt_q_b    ),

   .gfx_addr ( gfx_addr_b ),
   .gfx_data ( gfx_data_b ),
   .gfx_wren ( gfx_wren_b ),
   .gfx_q    ( gfx_q_b  ),

	.txt_base ( txt_base ),
	.gfx_base ( gfx_base ),

	.bgcol	 ( bgcol ),

	.cursor_vis (cursor_vis ),
   .cursor_x ( cursor_x ),
   .cursor_y ( cursor_y ),

   .H_GFX_offs ( H_GFX_offs ),
	.V_GFX_offs ( V_GFX_offs )
);


always @(posedge CORE_CLK) begin
	cycles = cycles + 1;
	nanosecs = nanosecs + 012_05;
	if (nanosecs > 100000) nanosecs = 0;
	if (nanosecs==0) microsecs = microsecs + 1;
end




endmodule


