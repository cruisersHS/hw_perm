`timescale 1ns / 1ps

`define add_1(x)            (x == 4 ? 0 : x + 1)
`define add_2(x)            (x == 3 ? 0 : x == 4 ? 1 : x + 2)
`define sub_1(x)            (x == 0 ? 4 : x - 1)
`define sub64(x)            {x[62:0], x[63]}
`define sub64_n(x, n)       {x[63-n:0], x[63:63-n+1]}

module perm_blk(input clk, input rst, input pushin, output reg stopin,
	input firstin, input [63:0] din,
	output reg [2:0] m1rx, output reg [2:0] m1ry,
	input [63:0] m1rd,
	output reg [2:0] m1wx, output reg [2:0] m1wy,output reg m1wr,
	output reg [63:0] m1wd,
	output reg [2:0] m2rx, output reg [2:0] m2ry,
	input [63:0] m2rd,
	output reg [2:0] m2wx, output reg [2:0] m2wy,output reg m2wr,
	output reg [63:0] m2wd,
	output reg [2:0] m3rx, output reg [2:0] m3ry,
	input [63:0] m3rd,
	output reg [2:0] m3wx, output reg [2:0] m3wy,output reg m3wr,
	output reg [63:0] m3wd,
	output reg [2:0] m4rx, output reg [2:0] m4ry,
	input [63:0] m4rd,
	output reg [2:0] m4wx, output reg [2:0] m4wy,output reg m4wr,
	output reg [63:0] m4wd,
	output reg pushout, output reg firstout, output reg [63:0] dout
	);
	
	enum [3:0] {
	IDLE,
	INPUT,
	THETA_1,
	THETA_2,
	THETA_3,
	RHO,
	PI,
	CHI
	} cs, ns;
	
	reg [2:0] x, y, cx, cy;
	
	//pushin: data input to m1
	//stopin: x4y4 stop input
	
	//state logic
	always_ff @(posedge clk) begin
		ns <= cs;
		case(cs)
			IDLE: begin
				$display("in IDLE %t", $time);
				#100 $finish;
			end
			
			
			default: begin
			end
		endcase
	end
	
	
	
	
	
	//cs, ns
	always_ff @(posedge clk) begin
		if(rst) begin
			cs <= 0;
		end else begin
			cs <= ns;
		end
	end
	
	//ds
	always_ff @(posedge clk) begin
		if(rst) begin
			x <=#1 0;
			y <=#1 0;
		end else begin
			x <=#1 cx;
			y <=#1 cy;
		end
	end
	
endmodule



















