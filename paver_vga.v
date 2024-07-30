
//////////////////////////////////////////////////////////////////////////////
// Paver FPGA VGA interface NOV 2018
// Author: Michael Mangelsdorf (mim@ok-schalter.de)
//////////////////////////////////////////////////////////////////////////////


module Paver_VGA (

	input             clk,

	// VGA / DAC control signals

	output reg [7:0]  red,
	output reg [7:0]  green,
	output reg [7:0]  blue,
	output reg        hsync,
	output reg        vsync,
	output reg        blank_n,
	output reg        sync_n,
	
	output reg [11:0] font_addr,
	input      [15:0] font_q,

	// txt / gfx RAM

	output reg [12:0] txt_addr,
	output reg [31:0] txt_data,
	output reg        txt_wren,
	input      [31:0] txt_q,

	output reg [16:0] gfx_addr,
	output reg [8:0]  gfx_data,
	output reg        gfx_wren,
	input      [8:0]  gfx_q,


	input [12:0] txt_base,
	input [16:0] gfx_base,

   // Control

	input			[15:0]	bgcol,

	input             cursor_vis,
	input      [6:0]  cursor_x,
	input      [4:0]  cursor_y,

	input [9:0] H_GFX_offs,
	input [9:0] V_GFX_offs
);

`define chars_per_line    128
`define char_width        9
`define char_height       16

// HORIZONTAL TIMING ///////////////////////////////////////////////////

`define H_PULSE_width 128   //1152 x 864 @ 75 Hz
`define H_MAX_pos     1599
`define H_BACK_porch  256
`define H_FRONT_porch 64

`define H_EFFECTIVE   `H_MAX_pos - `H_PULSE_width - `H_BACK_porch - `H_FRONT_porch

`define H_pixels_per_line `chars_per_line * `char_width
localparam H_TXT_OFFS 	=	 (`H_EFFECTIVE - `H_pixels_per_line ) / 2;
`define H_TXT_start      `H_PULSE_width + `H_BACK_porch + H_TXT_OFFS
`define H_TXT_end        `H_TXT_start + `H_pixels_per_line
`define H_GFX_start 		`H_PULSE_width + `H_BACK_porch + H_GFX_offs
`define H_GFX_end        `H_GFX_start + 256


// VERTICAL TIMING ////////////////////////////////////////////////////

`define V_PULSE_width 3 // 1152 x 864 @ 75 Hz     
`define V_MAX_pos     899
`define V_BACK_porch  32
`define V_FRONT_porch 1

// DISPLAY CONTROL ////////////////////////////////////////////////////

localparam V_TXT_OFFS	     =  0;
`define V_TXT_start      `V_PULSE_width + `V_BACK_porch + V_TXT_OFFS
`define V_TXT_end        `V_TXT_start + 512 // Adjust this to n * character height (!)
`define V_GFX_start 		`V_PULSE_width + `V_BACK_porch + V_GFX_offs
`define V_GFX_end        `V_GFX_start + 256


reg [4:0] r;
reg [5:0] g;
reg [4:0] b;

reg [15:0] color;
reg [15:0] lit;

reg [10:0] hcounter;
reg [10:0] vcounter;

reg [7:0] vpos;
reg [8:0] hpos;

reg [6:0] char_x_pos;
reg [3:0] char_x_pix;

reg [4:0] char_y_pos;
reg [4:0] char_y_pix;


task pixel;
input [15:0] pow;
begin
   if ( cursor_vis && char_y_pos==cursor_y && char_x_pos==cursor_x + 1 )
		lit = font_q & pow;
	else lit = (~font_q) & pow;	
   r = lit ? bgcol[15:11] : color[15:11];
   g = lit ? bgcol[10:5]  : color[10:5];
   b = lit ? bgcol[4:0]   : color[4:0];
end
endtask

always @( negedge clk )
begin
	red =   r <<< 3;
   green = g <<< 2;
   blue =  b <<< 3;
end
	
always @( posedge clk )
if ( hcounter > `H_GFX_start && hcounter < `H_GFX_end &&
			vcounter > `V_GFX_start && vcounter < `V_GFX_end )
begin 
 vpos = vcounter - (`V_GFX_start);
 hpos = hcounter - (`H_GFX_start);
	gfx_addr = gfx_base + { vpos, hpos[7:0] };
	gfx_wren = 0;	
end


always @( posedge clk) // Create frame pulses
begin
		 if (hcounter < `H_PULSE_width) hsync <= 0; else hsync <= 1;
		 if (vcounter < `V_PULSE_width) vsync <= 0; else vsync <= 1;

		 if (hcounter==`H_MAX_pos) begin
			  hcounter = 0;
			  if (vcounter==`V_MAX_pos) begin
				  vcounter = 0;
				  //frames = frames + 1'd1;
			  end
			  else begin
					vcounter = vcounter + 1'd1;
			  end
		 end
		 else begin
		    hcounter = hcounter + 1'd1;
		 end
end



always @( posedge clk ) // Create frame data
begin

	 if ( vcounter == `V_TXT_start ) begin
	    char_y_pos = 0;
		 char_y_pix = -5'd1;
	 end

	 if ( hcounter == `H_TXT_start - 1 )
	 begin
			 blank_n <= 1;
			 if ( char_y_pix + 1 == `char_height ) begin
				 char_y_pix = 0;
				 char_y_pos = char_y_pos + 5'd1;
				 char_x_pos = 0;
				 char_x_pix = 0;
			 end
			 else char_y_pix = char_y_pix + 5'd1;
			                                                   // Fill "pipeline" step 1
			 txt_addr = txt_base + {char_y_pos, 7'd0};         // Prefetch first glyph
			 txt_wren = 0;
	 end
    else if ( hcounter == `H_TXT_start ) begin
		 char_x_pos = 1;
		 char_x_pix = 0;

       color = txt_q[15:0];               	  		     // Fill "pipeline" step 2
		 font_addr = {txt_q[22:16], char_y_pix};          // Prefetch first font glyph
       txt_addr = txt_base + {char_y_pos, 7'd1};        // Prefetch second glyph
	 end
    else if ( hcounter > `H_TXT_start && hcounter < `H_TXT_end &&
	           vcounter > `V_TXT_start && vcounter < `V_TXT_end ) begin // text based content

			 pixel( 32768 >> char_x_pix);
			 
		    if ( char_x_pix + 1 == `char_width ) begin
				    char_x_pos = char_x_pos + 7'd1;
				    color = txt_q[15:0];
					 font_addr = {txt_q[22:16], char_y_pix};
				    txt_addr = txt_base + {char_y_pos, char_x_pos};
					 char_x_pix = 0;
			 end
		    else char_x_pix = char_x_pix + 4'd1;		 

	 end
	 else
	 if ( hcounter > `H_MAX_pos -`H_FRONT_porch || hcounter < `H_PULSE_width + `H_BACK_porch ||
			vcounter > `V_MAX_pos - `V_FRONT_porch || vcounter < `V_PULSE_width + `V_BACK_porch )
	 begin // This part outside visible region
       blank_n <= 0;
       r =   0;
       g = 0;
       b =  0;
		 txt_data = 0; // 3x Meaningless, suppress Quartus warning
		 gfx_data = 0;
		 sync_n = 0;
	 end
	 else begin // Remaining part either background or GFX inlays
		 blank_n <= 1;
		 r = bgcol[15:11] & 30;
		 g = bgcol[10:5] & 62;
	    b = bgcol[4:0] & 30;
		 if ( hcounter > `H_GFX_start && hcounter < `H_GFX_end &&
			vcounter > `V_GFX_start && vcounter < `V_GFX_end )
		 begin
		      if ( gfx_q != 0 )
				begin
					r = gfx_q[8:6] <<< 2;
					g = gfx_q[5:3] <<< 3;
					b = gfx_q[2:0] <<< 2;
				end
		 end
	 end	 
end




endmodule







