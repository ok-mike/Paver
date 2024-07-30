
//////////////////////////////////////////////////////////////////////////////
// Paver microcontroller CPU FPGA core NOV 2018
// Author: Michael Mangelsdorf (mim@ok-schalter.de)
//////////////////////////////////////////////////////////////////////////////


// Define parts of instruction word

`define G   iw[15:12]
`define L   iw[11:8]
`define R2  iw[7:4]
`define R1  iw[3:0]

`define R2_MSB  iw[7:7]
`define R2_LOR  iw[6:4]

`define SEVEN  iw[6:0]
`define OFFS   fq_b + iw[6:4]
`define SXOFFS fq_b + {{13{iw[6]}},iw[6:4]}

`define READ_A( X ) faddr_a = X
`define READ_B( X ) faddr_b = X
`define READ_RAM( X ) gaddr = X

module Paver_CORE (

  input reset,
  input clk,
  input irq1,
  input irq2,

  // Core frame stack RAM interconnect

  output reg [FRAM_ADDR_WIDTH-1:0] faddr_a,
  output reg [FRAM_ADDR_WIDTH-1:0] faddr_b,
  output reg [15:0] fdata_a,
  output reg [15:0] fdata_b,
  output reg        fwren_a,
  output reg        fwren_b,
  input      [15:0] fq_a,
  input      [15:0] fq_b,

  // Common RAM interconnect

  output     [3:0] overlay_sel, // Selects 8k overlay region from E000 to FFFF

  output reg [GRAM_ADDR_WIDTH-1:0] gaddr,
  output reg [15:0] gdata,
  output reg        gwren,
  input      [15:0] gq,

  // font RAM interconnect

  output reg [11:0] font_addr,
  output reg [31:0] font_data,
  output reg        font_wren,
  input      [31:0] font_q,

  // txt RAM interconnect

  output reg [12:0] txt_addr,
  output reg [31:0] txt_data,
  output reg        txt_wren,
  input      [31:0] txt_q,

  output reg [12:0] txt_base,

  output reg        cursor_vis,
  output reg [6:0]  cursor_x,
  output reg [4:0]  cursor_y,

  output reg [16:0] gfx_addr,
  output reg [8:0]  gfx_data,
  output reg        gfx_wren,
  input      [8:0]  gfx_q,

  output reg [16:0] gfx_base,

  output reg [9:0]  H_GFX_offs,
  output reg [9:0]  V_GFX_offs,

  input             blanking,
  output reg [15:0] bgcol,

  // PS/2 Keyboard interconnect

  input [7:0] keycode,
  output reg  kbreset,
  output reg  pickup,
  input		  ctrl_pressed,

  // SD/SPI interconnect

  output reg sd_clk,
  output reg sd_mosi,
  output reg sd_cs,
  input      sd_miso,

  input  [31:0] gpio,
  output reg [31:0] gpio_out,

  output reg [13:0] seg7hex01,
  output reg [13:0] seg7hex23,
  output reg [13:0] seg7hex45,
  output reg [9:0] led,
  input [13:0] keysw,

	input [31:0] cycles,
	input [15:0] microsecs,
	output reg fetch
);

parameter GRAM_TOPADDR		= 98303; // 96k
parameter GRAM_ADDR_WIDTH	= 17;
parameter FRAM_ADDR_WIDTH	= 13;
parameter ISMASTER = 1;

localparam zop_INIT         = 0;
localparam zop_NEXT         = 1;
localparam zop_LIT          = 2;
localparam zop_TXT_SHOWCUR  = 3;
localparam zop_TXT_HIDECUR  = 4;
localparam zop_JUMP         = 10;
localparam zop_KB_reset     = 12;
localparam zop_TXT_flip     = 13;
localparam zop_GFX_flip     = 14;
localparam zop_VM_IDLE      = 15;
localparam zop_SYNC		 	 = 17;
localparam zop_NOP          = 20;
localparam zop_GOTKEY		 = 21;

localparam dop_REF          = 1;
localparam dop_GFX_LDFG     = 2;
localparam dop_GFX_STBG     = 3;
localparam dop_BRA          = 4;
localparam dop_PAR          = 6;
localparam dop_PUSH         = 9;
localparam dop_RET          = 10;

localparam sop_SETL         = 59;
localparam sop_IRQ_vec	 	 = 60;
localparam sop_WARM         = 61;
localparam sop_W_get        = 62;
localparam sop_POP          = 63;
localparam sop_DROP         = 64;
localparam sop_PULL         = 65;
localparam sop_LODS         = 66;
localparam sop_STOS         = 67;
localparam sop_ASR          = 68;
localparam sop_W_set        = 69;
localparam sop_TXT_fg       = 70;
localparam sop_TXT_bg       = 71;
localparam sop_PER          = 73;
localparam sop_NYBL         = 77;
localparam sop_PC_set       = 81;
localparam sop_PC_get       = 82;
localparam sop_BYTE         = 83;
localparam sop_SERVICE      = 84;
localparam sop_MSB          = 85;
localparam sop_LSB          = 86;
localparam sop_NOT          = 87;
localparam sop_NEG          = 88;
localparam sop_OVERLAY      = 90;
localparam sop_BLANKING     = 91;
localparam sop_IRQ_self     = 92;
localparam sop_GFX_H		    = 93;
localparam sop_GFX_V        = 94;
localparam sop_CYCLES       = 95;
localparam sop_MICROSECS    = 96;
localparam sop_LED_set      = 97;
localparam sop_KEYSW_get    = 98;
localparam sop_CORE_id      = 99;
localparam sop_TXT_colors   = 100;
localparam sop_TXT_colorg   = 101;
localparam sop_TXT_setpos   = 102;
localparam sop_TXT_glyphs   = 103;
localparam sop_TXT_glyphg   = 104;
localparam sop_TXT_curset   = 105;
localparam sop_KB_keyc      = 106;
localparam sop_KB_ctrl      = 107;
localparam sop_RETI         = 108;
localparam sop_BGCOL_set    = 109;
localparam sop_SD_SET_MOSI  = 110;
localparam sop_SD_GET_MISO  = 111;
localparam sop_SD_SET_SCLK  = 112;
localparam sop_SD_SET_CS    = 113;
localparam sop_CPU_speed    = 114;
localparam sop_CPU_id       = 115;
localparam sop_FONT_ld      = 116;
localparam sop_FONT_st      = 117;
localparam sop_GPIO_rd_a    = 118;
localparam sop_GPIO_rd_b    = 119;
localparam sop_GPIO_rd_c    = 120;
localparam sop_GPIO_rd_d    = 121;
localparam sop_GPIO_wr_c    = 122;
localparam sop_GPIO_wr_d    = 123;
localparam sop_SEG7_set01   = 124;
localparam sop_SEG7_set23   = 125;
localparam sop_SEG7_set45   = 126;

localparam YES = 1'b1;
localparam NO = 1'b0;

localparam SFRAMESIZE = 11;


reg [12:0] addrbuf;
reg [2:0]  fsm_state;

reg [15:0] pc;
reg [FRAM_ADDR_WIDTH-1:0] sfp = (1'b1 << FRAM_ADDR_WIDTH) - 1 - SFRAMESIZE;
reg [FRAM_ADDR_WIDTH-1:0] fbp = 2; // Frame base pointer
reg [15:0] cfk;
reg [15:0] iw;

assign overlay_sel = cfk[15:12];

reg [3:0]  tmp4;
reg [7:0]  tmp8;
reg [15:0] tmp16;
reg [16:0] carry;


`define PTR 0
`define RV  1
`define TOS	fbp + 1    // Top of stack - 1st
`define SEC fbp        // Second on stack - 2nd
`define DR  sfp + 0
`define R   sfp + 8
`define W   sfp + 9
`define FK  sfp + 10 

function [15:0] selector;
input [3:0] i;
if (i[3:3] == 1) selector = sfp + i[2:0];
else
  case(i[2:0])
  'b000: selector = `PTR;
  'b001: selector = `RV;
  'b010: selector = `TOS;
  'b011: selector = `SEC;
  'b100: selector = sfp + SFRAMESIZE + cfk[11:9];
  'b101: selector = sfp + SFRAMESIZE + cfk[8:6];
  'b110: selector = sfp + SFRAMESIZE + cfk[5:3];
  'b111: selector = sfp + SFRAMESIZE + cfk[2:0];
  endcase
endfunction


task write_a;
input [FRAM_ADDR_WIDTH-1:0] addr;
input [15:0] val;
begin
  fwren_a = 1;
  faddr_a = addr;
  fdata_a = val;
end
endtask


task write_b;
input [FRAM_ADDR_WIDTH-1:0] addr;
input [15:0] val;
begin
  fwren_b = 1;
  faddr_b = addr;
  fdata_b = val;
end
endtask

task write_ram;
input [15:0] addr;
input [15:0] val;
begin
  gwren = 1;
  gaddr = addr;
  gdata = val;
end
endtask


task seq_fetch;
begin
	pc = pc + 16'd1;
	`READ_RAM( pc );
	fetch = YES;
end
endtask


task op_ZOP;
case ((`L<<4) | `R1)

		zop_INIT:
			case (fsm_state)
				0: begin
						sfp = (1'b1 << FRAM_ADDR_WIDTH) - 1 - SFRAMESIZE;
						fbp = 2; // Also change in WARM
						cfk = 0;
						pc = 16'h0000;
						cursor_vis = 0;
					end
				1: begin
						cursor_x = 0;
						cursor_y = 0;
						bgcol = 0; // 16'd15;
						irq_cmd = 1;					// Disable interrupts
						irq_par = 32'hFFFF_FFFF;
					end
				2: begin 								// Interrupt service processing
						V_GFX_offs = 524;
						H_GFX_offs = 720;
						`READ_RAM(pc);
					end
				3: begin
						irq_cmd = 0;					// Finish service processing
						fetch = YES;
					end
				default:;
			endcase

		zop_NEXT:
			case (fsm_state)
			0: begin 
				`READ_A( `R );
			    `READ_B( `FK);
				tmp16 = cfk;
			   end	
			1:  begin
			      write_a( `R, fq_a + 1 ); // Skip the retrieved literal
				  cfk = fq_b;
                 `READ_RAM( fq_a );
				end
			2: begin
			        cfk = tmp16;
					  write_a( selector(`W), gq );
					  pc = gq;
					seq_fetch;
				end
			default:;
			endcase
			

		zop_JUMP:
			case (fsm_state)
				0: `READ_RAM( pc + 1 );
				1:	begin
						pc = gq;
						`READ_RAM(pc);
						fetch = YES;
					end
				default:;
			endcase


	 zop_KB_reset:
			case (fsm_state)
				0: kbreset = 1;
			//1: wait
				2: begin
						kbreset = 0;
						seq_fetch;
					end
				default:;
			endcase

		zop_TXT_SHOWCUR:
			case (fsm_state)
				0: begin
						cursor_vis = YES;
						seq_fetch;
					end
				default:;
			endcase					

		zop_TXT_HIDECUR:
			case (fsm_state)
				0: begin
						cursor_vis = NO;
						seq_fetch;
					end
				default:;
			endcase					
			
		zop_TXT_flip:
			case (fsm_state)
				0: begin
						txt_base = 12'd4096 - txt_base;
						seq_fetch;
					end
				default:;
			endcase

		zop_GFX_flip:
			case (fsm_state)
				0: begin
						gfx_base = 17'd65536 - gfx_base;
						seq_fetch;
					end
				default:;
			endcase

		zop_SYNC: case (fsm_state) default: seq_fetch; endcase

	   zop_LIT:
		case (fsm_state)
			0: `READ_RAM( pc + 1 );
			1: begin
			      fbp = fbp + 1;
					write_a( selector(`TOS), gq );
					pc = pc + 16'd2;
					`READ_RAM(pc);
					fetch = YES;
				end
			default:;
		endcase
			
		zop_NOP:
			case (fsm_state)
				0: seq_fetch;
				default:;
			endcase
 
		zop_GOTKEY:
			case (fsm_state)
				0: pickup = 1;
				1: ; //PS2 wait
				2: begin
						pickup = 0;
						seq_fetch;
					end
				default:;
			endcase 

			
		default:
			case (fsm_state)
				0: seq_fetch;
				default:;
			endcase

endcase
endtask


task op_SOP;
case( `SEVEN )
		
	sop_CPU_id:
			case (fsm_state)
				0: begin
						write_a( selector(`L), 2 ); // 1=Hen, 2=Paver
						seq_fetch;
					end
				default:;
			endcase
	
	sop_CPU_speed:
			case (fsm_state)
				0: begin
						write_a( selector(`L), 12_048 ); // Cycle time in picoseconds
						write_b( `DR, 83_0 ); // Frequency code
						seq_fetch;
					end
				default:;
			endcase	

	// This is the main method for controlling the interrupt system.
	// The programmer requests a command (set timer, enable interrupt etc) in the L register
	// with a corresponding parameter (concatenate RV after DR) and this request is
	// picked up during the next instruction fetch

	sop_SERVICE:
			case (fsm_state)
				0: begin
						`READ_A(`DR);
						`READ_B(`RV);						
					end
				1: begin
						irq_cmd = `L;
						irq_par = {fq_a,fq_b};
					end
			// 2:	Process command
				3: begin
						irq_cmd = 0;
						seq_fetch;
					end
				default:;
			endcase


	// Store value in L operand register into address
	// given by literal following current instruction

	sop_PER:
		case (fsm_state)
			0: begin
					`READ_A( selector(`L) );
					`READ_RAM( pc + 1 );
				end
			1: begin
					write_ram( gq, fq_a );
					pc = pc + 16'd2;
				end
			2: begin		
					`READ_RAM(pc);
					fetch = YES;
				end
			default:;
		endcase

		// Write w register into L operand register

	sop_W_get:
		case (fsm_state)
			0: `READ_A( `W );
			1: begin
					write_a( selector(`L), fq_a );
					seq_fetch;
				end
			default:;
		endcase

	sop_W_set:
		case (fsm_state)
			0: `READ_A( selector(`L) );
			1: begin
					write_a( selector(`W), fq_a );
					seq_fetch;
				end
			default:;
		endcase
		
	// Store literal following current instruction word
	// into L operand register

	sop_SETL:
		case (fsm_state)
			0: `READ_RAM( pc + 1 );
			1: begin
					write_a( selector(`L), gq );
					pc = pc + 16'd2;
					`READ_RAM(pc);
					fetch = YES;
				end
			default:;
		endcase

	// Jump to L operand register value

	sop_PC_set:
		case (fsm_state)
			0: `READ_A( selector(`L) );
			1: begin
					pc = fq_a;
					`READ_RAM(pc);
					fetch = YES;
				end
			default:;
		endcase

	// Store PC value into L operand register

	sop_PC_get:
		case (fsm_state)
			0: begin
					write_a( selector(`L), pc );
					seq_fetch;
				end
			default:;
		endcase


    // Pull a literal value from the cell following the
    // return address of the current subroutine frame.
    // Increment the return address to skip the literal, respect different overlays

	sop_PULL:
		case (fsm_state)
			0: begin 
				`READ_A( `R );
			    `READ_B( `FK);
				tmp16 = cfk;
			   end	
			1:  begin
			      write_a( `R, fq_a + 1 ); // Skip the retrieved literal
				  cfk = fq_b;
                 `READ_RAM( fq_a );
				end
			2: begin
			        cfk = tmp16;
					write_a( selector(`L), gq );
					seq_fetch;
				end
			default:;
		endcase

	sop_CYCLES:
		case (fsm_state)
			0: begin
					write_a( selector(`L), cycles[15:0] );
					write_b( selector(`DR), cycles[31:16] );
					seq_fetch;
				end
			default:;
		endcase

	sop_MICROSECS:
		case (fsm_state)
			0: begin
					write_a( selector(`L), microsecs );
					seq_fetch;
				end
			default:;
		endcase
		
	sop_IRQ_self:
		case (fsm_state)
			0: begin
					irq_self = YES;
					irq_index_self = `L;
				end
		// 1: Process
			2: begin
					irq_self = NO;
					seq_fetch;
				end
			default:;
		endcase

	sop_LODS:
		case (fsm_state)
			0: begin
					`READ_A( selector(`L) );
				end
			1:	begin
					`READ_RAM( fq_a );
					write_a( selector(`L), fq_a + 1);
				end
			2: begin
					write_a( `RV , gq );
					seq_fetch;
				end
			default:;
		endcase

	sop_STOS:
		case (fsm_state)
			0: begin
					`READ_A( selector(`L) );
					`READ_B( `RV );
				end
			1:	begin
					write_a( selector(`L), fq_a + 1);
					write_ram( fq_a, fq_b );
				end
			2: begin
					seq_fetch;
				end
			default:;
		endcase


	sop_IRQ_vec:
		case (fsm_state)
			0:	begin
					pc = pc + 1;
					`READ_RAM(pc);
				end
			1: begin
					irqvec[`L] = gq;
					seq_fetch;
				 end
			default:;
		endcase

	sop_MSB:
		case (fsm_state)
		   0: `READ_A( selector(`L) );
			1: begin
			      write_a( `DR, fq_a & 16'h8000 );
			      seq_fetch;
				end
			default:;
		endcase

	sop_LSB:
		case (fsm_state)
		   0: `READ_A( selector(`L) );
			1: begin
					write_a( `DR, fq_a & 16'd1 );
					seq_fetch;
			   end
			default:;
		endcase

	sop_NOT:
		case (fsm_state)
		   0: `READ_A( selector(`L) );
			1: begin
			        write_a( `DR, fq_a ^ 16'hFFFF );
			        seq_fetch;
				end
			default:;
		endcase

	sop_NEG:
		case (fsm_state)
		   0: `READ_A( selector(`L) );
			1: begin
					write_a( `DR, (fq_a ^ 16'hFFFF) + 1 );
					seq_fetch;
				end
			default:;
		endcase

	sop_BYTE:
		case (fsm_state)
		   0: `READ_A( selector(`L) );
			1: begin
			        write_a( `DR, fq_a & 16'hFF );
			        seq_fetch;
				end
			default:;
		endcase

	sop_NYBL:
		case (fsm_state)
		   0: `READ_A( selector(`L) );
    		1: begin
			        write_a( `DR, fq_a & 16'hF );
			        seq_fetch;
				end
			default:;
		endcase

	sop_OVERLAY:
		case (fsm_state)
		   0: begin
					cfk[15:12] = `L;
					seq_fetch;
				end
			default:;
		endcase

	sop_DROP:
		case (fsm_state)
		   0: begin
					fbp = fbp - `L; // Drop n stack elements
					seq_fetch;
				end
			default:;
		endcase

	sop_POP:
		case (fsm_state)
		   0: `READ_A( `TOS );
			1: begin
			      fbp = fbp - 1;
					write_a( selector(`L), fq_a );
					seq_fetch;
				end
			default:;
		endcase
		
	sop_ASR:
		case( fsm_state )
			0: `READ_A( selector(`L) );
			1: begin
				write_a( selector(`L), fq_a >>> 1 );
				seq_fetch;
				end
		default: ;
		endcase	
		
	sop_CORE_id:
		case (fsm_state)
			0: begin
					write_a( selector(`L), ISMASTER );
					seq_fetch;
				end
			default:;
		endcase

	sop_RETI:
		case (fsm_state)
			0:	begin
					`READ_A( `FK );
					`READ_B( `R );
					sfp = sfp + (SFRAMESIZE<<1); // Skip PAR frame too
				end
			1: begin
					cfk = fq_a;
					pc = fq_b;
					`READ_RAM( pc );
					fetch=YES;
				end
			default:;
		endcase

	sop_TXT_fg:
		case (fsm_state)
			0: begin
					write_a( selector(`L), txt_base );
					seq_fetch;
				end
			default:;
		endcase

	sop_TXT_bg:
		case (fsm_state)
			0: begin
					write_a( selector(`L), 4096 - txt_base );
					seq_fetch;
				end
			default:;
		endcase


	sop_GPIO_rd_a:
		case (fsm_state)
			0: begin
				 write_a( selector(`L), gpio[15:0] );
				 seq_fetch;
				end
			default:;
		endcase

	sop_GPIO_rd_b:
		case (fsm_state)
			0: begin
				 write_a( selector(`L), gpio[31:16] );
				 seq_fetch;
				end
			default:;
		endcase

	sop_GPIO_rd_c:
		case (fsm_state)
			0: begin
				 write_a( selector(`L), gpio_out[15:0] );
				  seq_fetch;
				 end
			default:;
		endcase

	sop_GPIO_rd_d:
		case (fsm_state)
			0: begin
				 write_a( selector(`L), gpio_out[31:16] );
				 seq_fetch;
				end
			default:;
		endcase

	sop_GPIO_wr_c:
		case (fsm_state)
			0: `READ_A( selector(`L) );
			1: begin
					gpio_out[15:0] = fq_a;
					seq_fetch;
				end
			default:;
		endcase

	sop_GPIO_wr_d:
		case (fsm_state)
			0: `READ_A( selector(`L) );
			1: begin
					gpio_out[31:16] = fq_a;
					seq_fetch;
				end
			default:;
		endcase

	sop_LED_set:
		case (fsm_state)
			0: `READ_A( selector(`L) );
			1: begin
					led = fq_a[9:0];
					seq_fetch;
				end
			default:;
		endcase

	sop_KEYSW_get:
		case (fsm_state)
			0: begin
				 write_a( selector(`L), keysw );
				 seq_fetch;
				end
			default:;
		endcase

	sop_SEG7_set01:
		case (fsm_state)
			0: `READ_A( selector(`L) );
			1: begin
					seg7hex01 = fq_a[13:0];
					seq_fetch;
				end
			default:;
		endcase

	sop_SEG7_set23:
		case (fsm_state)
			0: `READ_A( selector(`L) );
			1: begin
					seg7hex23 = fq_a[13:0];
					seq_fetch;
				end
			default:;
		endcase

	sop_SEG7_set45:
		case (fsm_state)
			0: `READ_A( selector(`L) );
			1: begin
					seg7hex45 = fq_a[13:0];
					seq_fetch;
				end
			default:;
		endcase

	sop_KB_keyc:
		case (fsm_state)
			0: begin
					write_a( selector(`L), keycode);
					seq_fetch;
				end
			default:;
		endcase

	sop_TXT_setpos:
		case (fsm_state)
			0: `READ_A( selector(`L) );
			1: begin
					addrbuf = fq_a & 8191;
					seq_fetch;
				end
			default:;
		endcase

	sop_TXT_colors:
		case (fsm_state)
			0: begin
					txt_wren = 0;
					txt_addr = addrbuf;
					`READ_A( selector(`L) );
				end
			1: begin
				  txt_addr = addrbuf;
				  txt_wren = 1;
				  txt_data = {txt_q[31:16], 16'd0 | fq_a};
				end
			2: begin
					txt_wren = 0;
					seq_fetch;
				end
			default:;
		endcase

	sop_TXT_colorg:
		case (fsm_state)
			0: begin
					txt_addr = addrbuf;
					txt_wren = 0;
				end
			1: begin
					write_a( selector(`L), txt_q[15:0] );
					seq_fetch;
				end
			default:;
		endcase

	sop_TXT_glyphs:
		case (fsm_state)
			0: begin
					txt_wren = 0;
					txt_addr = addrbuf;
					`READ_A( selector(`L) );
				end
			1: begin
				  txt_addr = addrbuf;
				  txt_wren = 1;
				  txt_data = {16'd0 | fq_a, txt_q[15:0] };
				end
			2: begin
					txt_wren = 0;
					seq_fetch;
				end
			default:;
		endcase

	sop_TXT_glyphg:
		case (fsm_state)
			0: begin
					txt_addr = addrbuf;
					txt_wren = 0;
				end
			1: begin
					write_a( selector(`L), txt_q[31:16] );
					seq_fetch;
				end
			default:;
		endcase

	sop_TXT_curset:
		case (fsm_state)
			0: `READ_A( selector(`L) );
			1: begin
					cursor_x = fq_a[6:0];
					cursor_y = fq_a[11:7];
					seq_fetch;
				end
			default:;
		endcase

	sop_SD_SET_MOSI:
		case (fsm_state)
			0: `READ_A( selector(`L) );
			1: begin
					sd_mosi = fq_a ? 1'd1 : 1'd0;
					seq_fetch;
				end
			default:;
		endcase

	sop_SD_SET_SCLK:
		case (fsm_state)
			0: `READ_A( selector(`L) );
			1: begin
					sd_clk = fq_a ? 1'd1 : 1'd0;
					seq_fetch;
				end
			default:;
		endcase

	sop_SD_SET_CS:
		case (fsm_state)
			0: `READ_A( selector(`L) );
			1: begin
					sd_cs = fq_a ? 1'd1 : 1'd0;
					seq_fetch;
				end
			default:;
		endcase

	sop_SD_GET_MISO:
		case (fsm_state)
			0: write_a( selector(`L), sd_miso );
			1: seq_fetch;
			default:;
		endcase

	sop_BGCOL_set:
		case (fsm_state)
			0: `READ_A( selector(`L) );
			1: begin
					bgcol = fq_a;
					seq_fetch;
				end
			default:;
		endcase

	sop_GFX_H:
		case (fsm_state)
			0: `READ_A( selector(`L) );
			1: begin
					H_GFX_offs = fq_a;
					seq_fetch;
				end
			default:;
		endcase

	sop_GFX_V:
		case (fsm_state)
			0: `READ_A( selector(`L) );
			1: begin
					V_GFX_offs = fq_a;
					seq_fetch;
				end
			default:;
		endcase

	sop_BLANKING:
		case (fsm_state)
			0: begin
					write_a( selector(`L), {16{blanking}} );
					seq_fetch;
				end
			default:;
		endcase

	sop_KB_ctrl:
		case (fsm_state)
			0: begin
					write_a( selector(`L), ctrl_pressed );
					seq_fetch;
				end
			default:;
		endcase


	sop_WARM:
		case (fsm_state)
			0: `READ_A( selector(`L) );
			1: begin
					sfp = (1'b1 << FRAM_ADDR_WIDTH) - 1 - SFRAMESIZE;
					fbp = 2;
					cfk = 0;
					pc = fq_a;
					seq_fetch;
				end
			default:;
		endcase
	
	sop_FONT_ld:
		case( fsm_state )
			0: `READ_B( selector(`L) );
			1: font_addr = fq_b;
			2: begin
					write_b( selector(`DR), font_q );
					seq_fetch;
				end
			default: ;
		endcase

	sop_FONT_st:
		case( fsm_state )
			0: begin
					`READ_B( selector(`DR) );
					`READ_A( selector(`L) );
				end
			1: begin
					font_addr = fq_a;
					font_data = fq_b;
					font_wren = 1;
				end
			2: begin
					font_wren = 0;
					seq_fetch;
				end
			default: ;
		endcase
	
	default:
		case (fsm_state)
			0: seq_fetch; // This is for NOPs like VM_rdblk etc (!)
			default : ;
		endcase

endcase
endtask

task op_REP;
case( fsm_state )

  0:	`READ_A( selector(`L) );

  1:	begin
            write_a( selector(`L), fq_a - 1 );
			if (fq_a - 1) pc = pc + { {9{iw[6]}},`SEVEN };
			else pc = pc + 16'd1;
			`READ_RAM(pc);
			fetch = YES;
		end

  default: ;

endcase
endtask

task op_ELS;
case( fsm_state )

  0: `READ_A( selector(`L) );

  1: begin
			if (fq_a == 0) pc = pc + { {9{iw[6]}},`SEVEN };
			else pc = pc + 16'd1;
			`READ_RAM(pc);
			fetch = YES;
		end

  default: ;

endcase
endtask

task op_THN;
case( fsm_state )

  0: `READ_A( selector(`L) );

  1: begin
			if (fq_a != 0) pc = pc + { {9{iw[6]}},`SEVEN };
			else pc = pc + 16'd1;
			`READ_RAM(pc);
			fetch = YES;
		end

    default: ;

endcase
endtask


task op_LTL;
case( fsm_state )

  0: `READ_A( selector(`L) );

  1: begin
			write_a( `DR, (fq_a < `SEVEN) ? 1 : 0);
			seq_fetch;
	  end

  default: ;

endcase
endtask

task op_EQL;
case( fsm_state )

  0: `READ_A( selector(`L) );

  1: begin
		write_a( `DR, (fq_a == `SEVEN) ? 1 : 0);
		seq_fetch;
	  end

  default: ;

endcase
endtask

task op_GTL;
case( fsm_state )

  0: `READ_A( selector(`L) );

  1: begin
			write_a( `DR, (fq_a > `SEVEN) ? 1 : 0);
			seq_fetch;
	  end

  default: ;

endcase
endtask

task op_SET;
case( fsm_state )

  0:	begin
			write_a( selector(`L), (`R2_LOR<<4) + `R1 );
			seq_fetch;
		end

  default: ;

endcase
endtask

task op_LTR;
case( fsm_state )

  0: begin
       `READ_A( selector(`L) );
       `READ_B( selector(`R1) );
	  end

  1: begin
			write_a( `DR, (fq_a < `SXOFFS) ? 1 : 0);
			seq_fetch;
	  end

  default: ;

endcase
endtask

task op_EQR;
case( fsm_state )

  0: begin
       `READ_A( selector(`L) );
       `READ_B( selector(`R1) );
	  end

  1: begin
			write_a( `DR, (fq_a == `SXOFFS) ? 1 : 0);
			seq_fetch;
		end

  default: ;

endcase
endtask

task op_GTR;
case( fsm_state )

  0: begin
       `READ_A( selector(`L) );
       `READ_B( selector(`R1) );
	  end

  1: begin
			write_a( `DR, (fq_a > `SXOFFS) ? 1 : 0);
			seq_fetch;
	  end

  default: ;

endcase
endtask

task op_LOD;
case( fsm_state )
  0: `READ_B( selector(`R1) );
  1:   `READ_RAM( `OFFS );
  2: begin
			write_b( selector(`L), gq );
			seq_fetch;
		end
  default: ;
endcase
endtask

task op_STO;
case( fsm_state )
  0: begin
	   `READ_A( selector(`L) );
	   `READ_B( selector(`R1) );
	  end
  1: write_ram( `OFFS, fq_a );
  2: begin
			seq_fetch;
		end
  default: ;
endcase
endtask


task op_SHL;
case( fsm_state )

  0: `READ_A( selector(`R1) );

  1: begin
			write_a( selector(`L), fq_a << (`R2_LOR+1) );
			seq_fetch;
	 end

  default: ;

endcase
endtask


task op_SHR;
case( fsm_state )

  0: `READ_A( selector(`R1) );

  1: begin
			write_a( selector(`L), fq_a >> (`R2_LOR+1) );
			seq_fetch;
	 end

  default: ;

endcase
endtask

task op_GET;
case( fsm_state )

  0: `READ_A( selector(`R1) );

  1: begin
			write_a( selector(`L), fq_a + {{13{`R2_MSB}},`R2_LOR} );
			seq_fetch;
	  end

  default: ;

endcase
endtask

task op_JSR;
case( fsm_state )

  0: begin
		`READ_A( `DR );
		sfp = sfp - SFRAMESIZE;
		write_b( `FK, cfk );
		`READ_RAM( pc + 1 );
	 end

  1: begin
			write_a( `R, pc + 2 );
			cfk[11:0] = iw[11:0]; // Includes overlay sel
			if (gq != 0) pc = gq;
			else pc = fq_a;
			`READ_RAM(pc);
			fetch = YES;
	  end

default: ;

endcase
endtask


task op_DOP;
case (`R2)

	dop_REF:
		case (fsm_state)
			0:	begin
					`READ_RAM( pc + 1 );
					pc = pc + 16'd2;
				end
			1:  begin
					`READ_RAM( gq );
					write_a( selector(`R1), gq );
				end
			2:  begin
					write_b( selector(`L), gq );
					`READ_RAM(pc);
					fetch = YES;
				end
			default:;
		endcase

	dop_BRA:
		case (fsm_state)
		    0:  begin
		            tmp8 = (`L<<4) + `R1;
		            pc = pc + { {8{tmp8[7]}}, tmp8 };
						`READ_RAM(pc);
						fetch = YES;
			    end
			default:;
		endcase


	dop_GFX_LDFG: // Transparently convert VGA 9 bit (RGB333) to RGB565?
		case (fsm_state)
			0:	`READ_B( selector(`R1) );
			1:	gfx_addr = gfx_base + fq_b;
			2: begin
					write_a( selector(`L), gfx_q );
					seq_fetch;
				end
			default:;
		endcase

	dop_GFX_STBG: // Transparently convert RGB565 to VGA 9 bit (RGB333)?
		case (fsm_state)
			0:	begin
				  `READ_A( selector(`L) );
				  `READ_B( selector(`R1) );
				end
			1: begin
					gfx_addr = (65536 - gfx_base) + fq_b;
					gfx_data = fq_a;
					gfx_wren = 1;
				end
			2: begin
					gfx_wren = 0;
					seq_fetch;
				end
			default:;
		endcase

	
	dop_PAR:
		case (fsm_state)
			0: `READ_A( selector(`R1) );
			1: begin
					write_a( (sfp - SFRAMESIZE + `L) & 16'hFFFF, fq_a );
					seq_fetch;
				end
			default:;
		endcase	

	dop_PUSH:
		case (fsm_state)
			0: `READ_A( selector(`L) );
			1: begin
			      fbp = fbp + 1;
					write_a( `TOS, fq_a + {{12{iw[3]}},iw[3:0]} ); // Sign extended `R1 (4 bits!)
					seq_fetch;
				end
			default:;
		endcase	

	dop_RET:
			case (fsm_state)
				0: begin
					  `READ_A( `R );
					  `READ_B( `FK );
						sfp = sfp + SFRAMESIZE;
 				   end
				1: begin
					  cfk = fq_b;
					  pc = fq_a;
  					  `READ_A( selector(`L) );
					end
				2: begin
				      write_a( selector(`RV), fq_a + {{12{iw[3]}},iw[3:0]} ); // Sign extended `R1 (4 bits!)
					  `READ_RAM(pc);
						fetch = YES;
					end
				default:;
			endcase
	
   default:
		case (fsm_state)
			0: seq_fetch;
			default : ;
		endcase

   endcase
endtask


task op_AND;
case( fsm_state )

  0: begin
	    `READ_A( selector(`R2) );
       `READ_B( selector(`R1) );
	end

  1: begin
       write_a( selector(`L), fq_a & fq_b );
	    seq_fetch;
	  end
  default: ;

endcase
endtask

task op_IOR;
case( fsm_state )

  0: begin
	   `READ_A( selector(`R2) );
	   `READ_B( selector(`R1) );
	 end

  1: begin
       write_a( selector(`L), fq_a | fq_b );
       seq_fetch;
	  end
  default: ;

endcase
endtask

task op_EOR;
case( fsm_state )

  0: begin
	   `READ_A( selector(`R2) );
	   `READ_B( selector(`R1) );
 	  end

  1: begin
       write_a( selector(`L), fq_a ^ fq_b );
       seq_fetch;
		end
  default: ;

endcase
endtask

task op_ADD;
case( fsm_state )

  0: begin
	   `READ_A( selector(`R2) );
	   `READ_B( selector(`R1) );
	 end

  1: begin
	   carry = fq_a + fq_b;
	   write_a( selector(`L), carry[15:0] );
	   if (selector(`L) != `DR) write_b( `DR, carry[16] );
		seq_fetch;
		end
  default: ;

endcase
endtask


task op_SUB;
case( fsm_state )

  0: begin
	   `READ_A( selector(`R2) );
	   `READ_B( selector(`R1) );
	 end

  1: begin
      tmp16 = (16'hFFFF ^ fq_b) + 16'd1;
	   carry = fq_a + tmp16;
	   write_a( selector(`L), carry[15:0] );
  	   if (selector(`L) != `DR) write_b( `DR, carry[16] );
		seq_fetch;
		end
  default: ;

endcase
endtask

// Interrupt and Control System

reg [15:0] irqvec [3:0];
reg [31:0] timer1;
reg [31:0] timer2;
reg [15:0] brkpoint;
reg [31:0] irq_up;
reg [31:0] irq_enabled;
reg irq;
reg irq_self;
reg irq_ack;
reg [3:0] irq_index;
reg [3:0] irq_index_self;
reg [4:0] irq_cmd;
reg [31:0] irq_par;

always @( posedge clk ) // Handle interrupt service command and update state
begin
	if (fsm_state == 2) begin // Constant must match sop_SERVICE and zop_INIT
		case (irq_cmd)
			1: irq_enabled = irq_enabled & ~irq_par; // Disable bits
			2: irq_enabled = irq_enabled | irq_par; // Enable bits
			3: brkpoint = irq_par;
			4: timer1 = irq_par;
			5: timer2 = irq_par;
			default:;
		endcase
	end
	timer1 = timer1 - 1;
	timer2 = timer2 - 1;
end

// Not all interrupt events can be checked/generated in one cycle
// Use an FSM to do round-robin processing across several cycles
reg [1:0] event_fsm_state;
always @( posedge clk ) event_fsm_state = event_fsm_state + 1'd1;
always @( posedge clk ) // Compute events and handle acknowledge
begin
	if (irq_ack) irq = NO;
	if (irq_self) begin irq = YES; irq_index = irq_index_self; end
	if ((timer1==0) & irq_enabled[1]) begin irq=YES; irq_index=0; end
	if ((timer2==0) & irq_enabled[2]) begin irq=YES; irq_index=1; end
	if ((pc==brkpoint) & irq_enabled[8]) begin irq=YES; irq_index=7; end
	case (event_fsm_state)
		0:	begin
				if (irq1) begin
					if (!irq_up[1] & irq_enabled[3]) begin irq_up[1]=YES; irq=YES; irq_index=2; end
				end else irq_up[1]=NO;
				if (irq2) begin
					if (!irq_up[2] & irq_enabled[4]) begin irq_up[2]=YES; irq=YES; irq_index=3; end
				end else irq_up[2]=NO;
			end
		1: if (!keysw[13]) begin
				if (!irq_up[3] & irq_enabled[5]) begin irq_up[3]=YES; irq=YES; irq_index=4; end
			end else irq_up[3]=NO;
		2: if (blanking) begin
				if (!irq_up[4] & irq_enabled[6]) begin irq_up[4]=YES; irq=YES; irq_index=5; end
			end else irq_up[4]=NO;
		3: if (keycode) begin
				if (!irq_up[5] & irq_enabled[7]) begin irq_up[5]=YES; irq=YES; irq_index=6; end
			end else irq_up[5]=NO;
		default:;
	endcase
end

always @( posedge clk ) // FSM dispatcher
begin
	if (!irq) irq_ack = 0;
	if (fetch) begin
		if (irq) begin fsm_state = 7; irq_ack = 1; end
		else fsm_state = 0;
	end
	else begin
		case (fsm_state)
			0: fsm_state = 1; // Regular fetch
			1: fsm_state = 2;
			2: fsm_state = 3;
			3: fsm_state = 4;
			4: fsm_state = 5;
			5: fsm_state = 6;		
			6: fsm_state = 0;
			
			7: fsm_state = 0; // If interrupt
		endcase
	end
end

always @( posedge clk ) // Main processing loop
begin
	if (fetch) fetch = NO;
	gwren = 0;
	fwren_a = 0;
	fwren_b = 0;
	if (fsm_state==7) // Interrupt - see RETI instruction which undoes this
	begin // Essentially a fake JSR
		sfp = sfp - (SFRAMESIZE<<1); 	// Protect PAR frame owned by subroutine
		write_a( `R, pc );
		pc = irqvec[irq_index];
		write_b( `FK, cfk );
		cfk = 12'b000_001_010_011; // overlay 0, signature DR L1 L2 L3
		`READ_RAM( pc );				// State modulo rollover, implicit fetch
	end
	else begin
		if (fsm_state==0) iw = gq; // Don't use _a channel elsewhere
		case( {`G,`R2_MSB} )
			 0: op_ZOP;		 1: op_SOP;	 	 2: op_ELS;		 3: op_THN;
			 4: op_REP;		 5: op_LTL;		 6: op_EQL;		 7: op_GTL;
			 8: op_SET;		 9: op_LTR;		10: op_EQR;		11: op_GTR;
			12: op_LOD;		13: op_STO;		14: op_SHL;		15: op_SHR;
			16: op_JSR;		17: op_JSR;		18: op_DOP;		19: op_DOP;
			20: op_GET;		21: op_GET;		22: op_AND;		23: op_AND;
			24: op_IOR;		25: op_IOR;		26: op_EOR;		27: op_EOR;
			28: op_ADD;		29: op_ADD;		30: op_SUB;		31: op_SUB;
			default: ;
		endcase
	end
end


endmodule



