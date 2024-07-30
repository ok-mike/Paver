
//////////////////////////////////////////////////////////////////////////////
// Paver FPGA PS2 keyboard interface NOV 2018
// Author: Michael Mangelsdorf (mim@ok-schalter.de)
//////////////////////////////////////////////////////////////////////////////


`define CLOSE 'h0
`define F0 'h1
`define E0 'h2


module Paver_PS2 (
 input reset,
 input coreclk,
 input ps2clk,
 input ps2data,
 output reg [7:0] ps2key,
 input pickup,
 output reg ctrl_pressed
);

reg [1:0] state;
reg [7:0] scancode;
reg rdy;
reg read_char;

reg shift_pressed;
reg altgr_pressed;


//reg [15:0] filter;
reg [7:0] filter;
reg cleanclk;
reg ps2negedge;

always @(posedge coreclk)
begin
	ps2negedge = 0;
   filter = {ps2clk, filter[7:1]};
   if (filter==8'b1111_1111) cleanclk = 1;
   else if (filter==8'b0000_0000 && cleanclk==1) begin
		cleanclk = 0;
		ps2negedge = 1;
	end
end


reg [3:0] incnt;
reg [8:0] shiftin;

always @(posedge coreclk)
begin
	rdy = 0;
	if (ps2negedge==1)
	begin
		if (ps2data==0 && read_char==0) read_char = 1;
		else
		if (read_char == 1)
		begin
			if (incnt < 9)
			begin
				incnt = incnt + 1'b1;
				shiftin = { ps2data, shiftin[8:1]};
			end
			else
			begin
				incnt = 0;
				scancode = shiftin[7:0];
				read_char = 0;
				rdy = 1;
			end
		end
	end
end



task make;
input [7:0] noshift;
input [7:0] shifted;
input [7:0] altgr;
begin
	ps2key = shift_pressed ? shifted : noshift;
end
endtask


always @(posedge coreclk)
begin
		if (pickup) ps2key = 0;
		else if (rdy)
		case (state)

		   `E0:     begin
			            case (scancode)
								'hF0: state = `F0;
								'h70: make(1,1,63);     // INS
								'h71: make(127,29,63);  // DEL
								'h6C: make(2,2,63);     // HOME
								'h69: make(3,3,63);     // END
								'h7D: make(4,4,63);     // PUp
								'h7A: make(5,5,63);     // PDn

								'h75: make(6,6,63);     // U
								'h72: make(11,11,63);   // D
								'h6B: make(12,12,63);   // L
								'h74: make(14,14,63);   // R

								//'h11: altgr_pressed <= 1;
								// AltGr is weird : the break code is E0 F0 11 (!)

								default:;
							endcase
							state = `CLOSE;
						end

			`F0:  	begin
							case (scancode)
								'h12: shift_pressed = 0;
								'h59: shift_pressed = 0;
								'h14: ctrl_pressed = 0;
							//	'h11: altgr_pressed = 0;
								default:;
							endcase
                     state = `CLOSE;
						end


		   `CLOSE:	begin
			         case (scancode)
							'hF0: state = `F0;
							'hE0: state = `E0;
							'h12: shift_pressed = 1; // Left shift key
							'h59: shift_pressed = 1; // Right shift key
							'h14: ctrl_pressed = 1; // Left control key
							'h1C: make(97,65,63); // Aa
							'h32: make(98,66,63);
							'h21: make(99,67,63);
							'h23: make(100,68,63);
							'h24: make(101,69,63);
							'h2B: make(102,70,63);
							'h34: make(103,71,63);
							'h33: make(104,72,63);
							'h43: make(105,73,63);
							'h3B: make(106,74,63);
							'h42: make(107,75,63);
							'h4B: make(108,76,63);
							'h3A: make(109,77,63);
							'h31: make(110,78,63);
							'h44: make(111,79,63);
							'h4D: make(112,80,63);
							'h15: make(113,81,63);
							'h2D: make(114,82,63);
							'h1B: make(115,83,63);
							'h2C: make(116,84,63);
							'h3C: make(117,85,63);
							'h2A: make(118,86,63);
							'h1D: make(119,87,63);
							'h22: make(120,88,63);
							'h35: make(121,89,63);
							'h1A: make(122,90,63); // Zz

							'h45: make(48,41,63);  // 0)
							'h16: make(49,33,63);  // 1!
							'h1E: make(50,64,63);  // 2@
							'h26: make(51,35,63);  // 3#
							'h25: make(52,36,63);  // 4$
							'h2E: make(53,37,63);  // 5%
							'h36: make(54,94,63);  // 6^
							'h3D: make(55,38,63);  // 7&
							'h3E: make(56,42,63);  // 8*
							'h46: make(57,40,63);  // 9(

							'h41: make(60,44,63);  // <,
							'h49: make(62,46,63);  // >.
							'h4A: make(63,47,63);  // ?/

							'h4C: make(58,59,63);  // :;
							'h52: make(34,39,63);  // "'

							'h54: make(91,123,63); // [{
							'h5B: make(93,125,63); // ]}

							'h4E: make(45,95,63);   // -_
							'h55: make(43,61,63);   // +=
							'h5D: make(124,92,92); // |\

							'h5A: make(10,10,63); // ENTER    (code 13 is free!)
							'h76: make(27,27,63); // ESC
							'h66: make(8,8,63);   // BS
							'h0D: make(9,9,63);   // TAB
							'h29: make(32,32,63); // SPACE

							'h05: make(16,16,63); // F1
							'h06: make(17,17,63); // F2
							'h04: make(18,18,63); // F3
							'h0C: make(19,19,63); // F4
							'h03: make(20,20,63); // F5
							'h0B: make(21,21,63); // F6
							'h83: make(22,22,63); // F7
							'h0A: make(23,23,63); // F8
							'h01: make(24,24,63); // F9
							'h09: make(25,25,63); // F10
							'h78: make(26,26,63); // F11  skip 27 (ESC)
							'h07: make(28,28,63); // F12

							 // DE < > Keys not on US keyboard

                     'h61: make(7,15,63);

						   default:;
						endcase
						end
			default:;
		endcase
end




endmodule
