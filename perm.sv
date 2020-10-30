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
	output reg pushout, input stopout, output reg firstout, output reg [63:0] dout
	);
	
	reg stopin_d;
	
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
	reg write_rdy, write_rdy_d;		//write ready
	
	//pushin: data input to m1
	//stopin: x4y4 stop input
	
	//state logic
	always_comb @(posedge clk) begin
		ns = cs;
		case(cs)
			IDLE: begin
				if(write_rdy) begin
					ns = INPUT;
				end else begin
					ns = IDLE;
				end
			end
			
			INPUT: begin
				if(cx == 4 && cy == 4) begin
					//ns = THETA_1
					$finish;
				end else begin
					ns = INPUT;
				end
			end
			
			default: begin
			end
		endcase
	end
	
	//data
	always_comb @(*) begin
		
		case(cs)
			IDLE: begin
				$display("\nIDLE\n, %t", $time);
			end
			
			INPUT: begin
				$display("INPUT,x%dy%d,din=%h, %t", x, y, din, $time);
				m1wx = x;
				m1wy = y;
			end
			
		endcase
	end
	
	//cx, cy
	always_ff @(posedge clk) begin
		cx <= #1 x;
		cy <= #1 y;
		m1wr <= #1 0;
		case(cs)
			IDLE: begin
			end
			
			INPUT: begin
				$display("cx = %d, cy = %d, %t", cx, cy, $time);
				if(cx == 4 && cy == 4) begin
					cx <= #1 0;
					cy <= #1 0;
					m1wr <= #1 1;
				end else if (cy == 4) begin
					cx <= #1 x + 1;
					cy <= #1 0;
					m1wr <= #1 1;
				end else begin
					cx <= #1 x + 1;
					cy <= #1 y + 1;
					m1wr <= #1 1;
				end
			end
			
		endcase
	end
	
	//rdy
	always_ff @(posedge pushin) begin
		//write_rdy_d = #1 write_rdy;
		if(!stopin) begin
			write_rdy_d <= #1 1;
		end else begin
			write_rdy_d <= #1 0;
		end
	end
	
	//cs, ns
	always_ff @(posedge clk or poesdge rst) begin
		if(rst) begin
			cs <=#1 0;
		end else begin
			cs <=#1 ns;
		end
	end
	
	//ds
	always_ff @(posedge clk or poesdge rst) begin
		if(rst) begin
			x <= #1 0;
			y <= #1 0;
			stopin <= #1 0;
			write_rdy <= #1 0;
		end else begin
			x <= #1 cx;
			y <= #1 cy;
			stopin <= #1 stopin_d;
			write_rdy <= #1 write_rdy_d;
		end
	end
	
endmodule



















