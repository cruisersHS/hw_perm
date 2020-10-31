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
	reg pushout_d;
	reg firstout_d;
	reg [63:0] dout_d;

	
	enum [3:0] {
	IDLE,
	INPUT_D,
	THETA_1,
	THETA_2,
	BUFFER,
	THETA_3,
	RHO_PI,
	CHI,
	IOTA
	} cs, ns;
	
	reg [2:0] x, y, cx, cy;
	reg write_rdy, write_rdy_d;		//write ready
	reg [1:0] buffer;
	reg buffer1;
	
	reg [63:0] temp_c, temp_c_acc, temp_c2;
	
	//pushin: data input to m1
	//stopin: x4y4 stop input
	
	//update cx, cy 5 by 5, y0-5 then x+1
	task cxy55;
		if(cx >= 4 && cy >= 4) begin
			cx = 0;
			cy = 0;
		end else if (cy >= 4) begin
			cx = x + 1;
			cy = 0;
		end else begin
			cy = y + 1;
		end
	endtask
	
	//update cx, cy 5 by 5, x0-5 then y+1
	task cyx55;
		if(cx >= 4 && cy >= 4) begin
			cx = 0;
			cy = 0;
		end else if (cx >= 4) begin
			cy = y + 1;
			cx = 0;
		end else begin
			cx = x + 1;
		end
	endtask
	
	//state logic
	always @(*) begin
		ns = cs;
		case(cs)
			IDLE: begin
				if(write_rdy) begin
					ns = INPUT_D;
				end else begin
					ns = IDLE;
				end
			end
			
			INPUT_D: begin
				if(x == 4 && y == 4) begin
					ns = THETA_1;
				end else begin
					ns = INPUT_D;
				end
			end
			
			THETA_1: begin
				if(x == 4 && y == 4) begin
					$display("\nFINISHED THETA_1 %t\n", $time);
					ns = THETA_2;
				end else begin
					ns = THETA_1;
				end
			end
			
			THETA_2: begin		//stored in m2(y=0)
				if(x == 4 && y == 0 && !buffer1) begin
					$display("\nFINISHED THETA_2 %t\n", $time);
					ns = BUFFER;
				end else begin
					ns = THETA_2;
				end
			end
			
			BUFFER: begin
				$display("\nBUFFER%t\n", $time);
				ns = THETA_3;
			end
			
			THETA_3: begin
				if(x == 4 && y == 4) begin
					$display("\nFINISHED THETA_3 %t\n", $time);
					ns = RHO_PI;
				end else begin
					ns = THETA_3;
				end
			end
			
			RHO_PI: begin
				if(x == 4 && y == 4) begin
					$display("\nFINISHED RHO_PI %t\n", $time);
					ns = CHI;
				end else begin
					ns = RHO_PI;
				end
			end
			
			CHI: begin
				if(x == 4 && y == 4 && buffer == 3) begin
					$display("\nFINISHED CHI %t\n", $time);
					ns = IOTA;
				end else begin
					ns = CHI;
				end
			end
			
			IOTA: begin
				#20 $finish;
			end
			
			default: begin
				ns = IDLE;
			end
		endcase
	end
	
	//_d
	always @(*) begin
		pushout_d = pushout;
		dout_d = dout;
		firstout_d = firstout;
		stopin_d = stopin;
	end
	
	//data in m1 write
	always @(*) begin
		case(cs)
			IDLE: begin
				if(pushin) begin
					$display("INPUT(pushin),x%dy%d,din=%h, %t", x, y, din, $time);
					m1wx = x;
					m1wy = y;
					m1wr = 1;
					m1wd = din;
				end
			end
			INPUT_D: begin
				$display("INPUT,x%dy%d,din=%h, %t", x, y, din, $time);
				m1wx = x;
				m1wy = y;
				m1wr = 1;
				m1wd = din;
			end
			
			default: begin
				m1wx = 0;
				m1wy = 0;
				m1wd = 0;
				m1wr = 0;
			end
		endcase
	end
	
	//m1, read
	always @(*) begin
		case(cs)
			THETA_1: begin
				m1rx = x;
				m1ry = y;
			end
			
			THETA_3: begin
				m1rx = x;
				m1ry = y;
			end
			
			default: begin
				m1rx = 0;
				m1ry = 0;
			end
		endcase
	end
	
	//m2, write
	always @(*) begin
		case(cs)
			THETA_1: begin
				m2wx = x;
				m2wy = 0;
				m2wd = temp_c_acc;
				m2wr = 1;
				$display("THETA_1, m2wd(%d) = %h, cx%dcy%d, %t", m2wx, m2wd, cx, cy, $time);
			end
			
			THETA_2: begin
				m2wy = 1;
				m2wx = x;
				m2wd = temp_c;
				m2wr = 1;
				if(cx > 4) begin
					m2wy = 0;
					m2wx = 0;
					m2wd = 0;
					m2wr = 0;
				end
			end
			
			RHO_PI: begin
				m2wr = 1;
				
				//m2wy
				case({1'b0,x,1'b0,y})
					8'h00: begin
						m2wx = 0;
						m2wy = 0;
						m2wd = m3rd;
					end
					8'h10: begin
						m2wx = 0;
						m2wy = 2;
						m2wd = `sub64(m3rd);
					end
					8'h20: begin
						m2wx = 0;
						m2wy = 4;
						m2wd = `sub64_n(m3rd, 62);
					end
					8'h30: begin
						m2wx = 0;
						m2wy = 1;
						m2wd = `sub64_n(m3rd, 28);
					end
					8'h40: begin
						m2wx = 0;
						m2wy = 3;
						m2wd = `sub64_n(m3rd, 27);
					end
					
					8'h01: begin
						m2wx = 1;
						m2wy = 3;
						m2wd = `sub64_n(m3rd, 36);
					end
					8'h11: begin
						m2wx = 1;
						m2wy = 0;
						m2wd = `sub64_n(m3rd, 44);
					end
					8'h21: begin
						m2wx = 1;
						m2wy = 2;
						m2wd = `sub64_n(m3rd, 6);
					end
					8'h31: begin
						m2wx = 1;
						m2wy = 4;
						m2wd = `sub64_n(m3rd, 55);
					end
					8'h41: begin
						m2wx = 1;
						m2wy = 1;
						m2wd = `sub64_n(m3rd, 20);
					end
					
					8'h02: begin
						m2wx = 2;
						m2wy = 1;
						m2wd = `sub64_n(m3rd, 3);
					end
					8'h12: begin
						m2wx = 2;
						m2wy = 3;
						m2wd = `sub64_n(m3rd, 10);
					end
					8'h22: begin
						m2wx = 2;
						m2wy = 0;
						m2wd = `sub64_n(m3rd, 43);
					end
					8'h32: begin
						m2wx = 2;
						m2wy = 2;
						m2wd = `sub64_n(m3rd, 25);
					end
					8'h42: begin
						m2wx = 2;
						m2wy = 4;
						m2wd = `sub64_n(m3rd, 39);
					end
					
					8'h03: begin
						m2wx = 3;
						m2wy = 4;
						m2wd = `sub64_n(m3rd, 41);
					end
					8'h13: begin
						m2wx = 3;
						m2wy = 1;
						m2wd = `sub64_n(m3rd, 45);
					end
					8'h23: begin
						m2wx = 3;
						m2wy = 3;
						m2wd = `sub64_n(m3rd, 15);
					end
					8'h33: begin
						m2wx = 3;
						m2wy = 0;
						m2wd = `sub64_n(m3rd, 21);
					end
					8'h43: begin
						m2wx = 3;
						m2wy = 2;
						m2wd = `sub64_n(m3rd, 8);
					end
					
					8'h04: begin
						m2wx = 4;
						m2wy = 2;
						m2wd = `sub64_n(m3rd, 18);
					end
					8'h14: begin
						m2wx = 4;
						m2wy = 4;
						m2wd = `sub64_n(m3rd, 2);
					end
					8'h24: begin
						m2wx = 4;
						m2wy = 1;
						m2wd = `sub64_n(m3rd, 61);
					end
					8'h34: begin
						m2wx = 4;
						m2wy = 3;
						m2wd = `sub64_n(m3rd, 56);
					end
					8'h44: begin
						m2wx = 4;
						m2wy = 0;
						m2wd = `sub64_n(m3rd, 14);
					end
					
					default: begin
						m2wx = 0;
						m2wy = 0;
						m2wd = 0;
					end
				endcase
			end
			
			default: begin
				m2wx = 0;
				m2wy = 0;
				m2wd = 0;
				m2wr = 0;
			end
		endcase
	end
	
	//m2 read
	always @(*) begin
		case(cs)
			THETA_2: begin
				m2rx = `sub_1(x);
				m2ry = 0;
			end
			
			THETA_3: begin
				m2rx = x;
				m2ry = 1;
			end
			
			CHI: begin
				m2ry = y;
				case(buffer)
					0: m2rx = `add_1(x);
					1: m2rx = `add_2(x);
					2: m2rx = x;
					3: m2rx = x;
					default: begin
						m2rx = 0;
					end
				endcase
			end
			
			default: begin
				m2rx = 0;
				m2ry = 0;
			end
		endcase
	end
	
	//m3 write
	always @(*) begin
		case(cs)
			THETA_1: begin
				m3wx = x;
				m3wy = 0;
				m3wd = temp_c_acc;
				m3wr = 1;
			end
			
			THETA_3: begin
				m3wx = x;
				m3wy = y;
				m3wd = m1rd ^ m2rd;
				m3wr = 1;
			end
			
			CHI: begin
				m3wx = x;
				m3wy = y;
				m3wr = 1;
				m3wd = temp_c2;
			end
			
			default: begin
				m3wx = 0;
				m3wy = 0;
				m3wd = 0;
				m3wr = 0;
			end
		endcase
	end
	
	//m3 read
	always @(*) begin
		case(cs)
			THETA_2: begin
				m3rx = `add_1(x);
				m3ry = 0;
			end
			
			RHO_PI: begin
				m3rx = x;
				m3ry = y;
			end
			
			default: begin
				m3rx = 0;
				m3ry = 0;
			end
		endcase
	end
	
	
	//cx, cy, always use x, y for assignment
	always @(*) begin
		cx = x;
		cy = y;
		case(cs)
			IDLE: begin
				if(pushin) begin
					cx = x + 1;
				end
			end

			INPUT_D: begin			//5x5
				//$display("cx = %d, cy = %d, %t", cx, cy, $time);
				cyx55();
			end
			
			THETA_1: begin			//5x5
				cxy55();
			end
			
			THETA_2: begin
				cy = 0;
				if(x < 4 && (buffer == 0 && buffer1)) begin
					cx = x + 1;
				end else if (x == 4) begin
					if(y == 4) cx = 0;
				end
			end
			
			THETA_3: begin
				cxy55();
			end
			
			RHO_PI: begin
				cyx55();
			end
			
			CHI: begin		//x then y
				if(buffer == 3) cyx55();
				else begin
					cx = x;
					cy = y;
				end
			end
			
			default: begin
				cx = 0;
				cy = 0;
			end
		endcase
	end
	
	//buffer1
	always_ff @(posedge clk or posedge rst) begin
		if(rst) begin
			buffer1 <= #1 0;
		end else begin
			case(cs)
				THETA_2: begin
					if(x < 4) begin
						if(buffer) buffer1 <= #1 1;
					end else begin
						if(y == 0) buffer1 <= #1 0;
						else buffer1 <= #1 1;
					end
				end

				default: buffer1 <= #1 0;
			endcase
		end
	end

	//buffer (not now)
	always_ff @(posedge clk or posedge rst) begin
		if(!rst) begin
			case(cs)
				THETA_2: begin
					if(buffer == 0) buffer <= #1 1;
					else buffer <= #1 0;
				end
				
				CHI: begin
					case(buffer)
						0: buffer <= #1 1;
						1: buffer <= #1 2;
						2: buffer <= #1 3;
						3: buffer <= #1 0;
						default: buffer <= #1 0;
					endcase
				end
				
				default: buffer <= #1 0;
			endcase
		end else buffer <= #1 0;
	end
	
	//temp_c2
	always_ff @(posedge clk or posedge rst) begin
		if(rst) begin
			temp_c2 <= #1 0;
		end else begin
			case(cs)
				CHI: begin
					case(buffer)
						0: temp_c2 <= #1 m2rd ^ 64'hffffffffffffffff;
						1: temp_c2 <= #1 temp_c2 & m2rd;
						2: temp_c2 <= #1 temp_c2 ^ m2rd;
						default: temp_c2 <= #1 0;
					endcase
				end
				
				
				default: temp_c2 <= #1 0;
			endcase
		end
	end
	
	//temp_c
	always_ff @(posedge clk or posedge rst) begin
		if(!rst) begin
			case(cs)
				THETA_1: begin
					if(y == 0) temp_c <= #1 m1rd;
					else if (y < 4) temp_c <= #1 temp_c ^ m1rd;
					else begin 
						$display("x%dy%d, temp_c%h, rd%h, acc%h,", x, y, temp_c, m1rd, temp_c_acc);
						temp_c <= #1 0;
					end
				end
				
				THETA_2: begin
					if(buffer == 1 && y == 0) begin
						temp_c <= #1 (m2rd ^ `sub64(m3rd));
						$monitor("temp_c calc:x%dy%dwr%d m2rd:%h, m3rd:%h, tempc:%h, %t", x, y, m2wr, m2rd, m3rd, temp_c, $time);
					end
				end
				
				default: temp_c <= #1 0;
			endcase
		end else begin
			temp_c <= #1 0;
		end
	end
	
	//temp_c_acc
	always_ff @(posedge clk or posedge rst) begin
		if(!rst) begin
			if (y < 4) temp_c_acc <= #1 m1rd ^ temp_c;
			else temp_c_acc <= #1 0;
		end else begin
			temp_c_acc <= #1 0;
		end
	end
	
	//rdy
	always_ff @(posedge clk or posedge rst) begin
		if(!rst) begin
			if(pushin && !stopin) begin
				$display("pushin received!! push data is %h %t", din, $time);
				write_rdy <= #1 1;
			end else begin
				write_rdy <= #1 0;
			end
		end else begin
			write_rdy <= #1 0;
		end
	end
	
	//cs, ns, rst
	always_ff @(posedge clk or posedge rst) begin
		if(rst) begin
			cs <=#1 IDLE;
		end else begin
			cs <=#1 ns;
		end
	end
	
	//stopin, change all !rst to rst
	always_ff @(posedge clk or posedge rst) begin
		if(!rst) begin
			if(cs == INPUT_D && (cx == 4 && cy == 4)) stopin <= #1 0;
			else if(pushin && (x == 4 && y == 4)) stopin <= #1 1;
		end else begin
			stopin <= #1 0;
		end
	end
	
	//ds
	always_ff @(posedge clk or posedge rst) begin
		if(rst) begin
			x <= #1 0;
			y <= #1 0;
			pushout <= #1 0;
			firstout <= #1 0;
			dout <= #1 0;
		end else begin
			x <= #1 cx;
			y <= #1 cy;
			pushout <= #1 pushout_d;
			firstout <= #1 firstout_d;
			dout <= #1 dout_d;
		end
	end
	
endmodule



















