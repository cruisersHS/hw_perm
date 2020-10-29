module perm_blk(input clk, input rst, input pushin, output logic stopin,
input firstin, input [63:0] din,
output logic [2:0] m1rx, output logic [2:0] m1ry,
input [63:0] m1rd,
output logic [2:0] m1wx, output logic [2:0] m1wy,output logic m1wr,
output logic [63:0] m1wd,
output logic [2:0] m2rx, output logic [2:0] m2ry,
input [63:0] m2rd,
output logic [2:0] m2wx, output logic [2:0] m2wy,output logic m2wr,
output logic [63:0] m2wd,
output logic [2:0] m3rx, output logic [2:0] m3ry,
input [63:0] m3rd,
output logic [2:0] m3wx, output logic [2:0] m3wy,output logic m3wr,
output logic [63:0] m3wd,
output logic [2:0] m4rx, output logic [2:0] m4ry,
input [63:0] m4rd,
output logic [2:0] m4wx, output logic [2:0] m4wy,output logic m4wr,
output logic [63:0] m4wd,
output logic pushout, input stopout, output logic firstout, output logic [63:0] dout);


function automatic [5:0] mod5(
input signed [5:0] a
);
mod5 = (a%5<0)?(a%5+5):a%5;
endfunction

logic en;
logic [2:0] x,y,c_x,c_y;

logic [63:0] c_init, c_final;
logic [63:0] d;
logic [63:0] theta;
logic [63:0] rho;
logic [63:0] chi;
logic [63:0] rc;
logic [4:0]  perm_num;

logic data_ready_in_w4;


enum [3:0] { IDLE,
       COPY_TO_M1,
       THETA_C,
       THETA_D,
       FINAL_THETA,
       RHO_PI,
       COPY_RHO_PI,
       CHI,
       IOTA,
       PUSH_DOUT
     } curr_state, n_state;

always_ff @(posedge clk or posedge rst) begin
   if(rst)
      en <= #1 0;
   else begin
      if((x==4) && (y==4))
         en <= #1 1'b0;
      else if(pushin)
         en <= #1 1'b1;
   end
end

always_ff @(posedge clk or posedge rst) begin
   if(rst) begin
      x <= #1 0;
      y <= #1 0;
   end
   else if(pushin) begin
      if((x==4) && (y==4)) begin
         x <= #1 0;
         y <= #1 0;
      end else if((firstin | en) & !stopin) begin
         if(x==4) begin
            x <= #1 0;
            y <= #1 y+1;
         end else begin
            x <= #1 x+1;
            y <= #1 y;
         end
      end
   end
end

//always_ff @(posedge clk or posedge rst) begin
//   if(rst)
//      stopin <= #1 0;
//   else begin
//      if((x==4) && (y==4)) begin
//         if(curr_state == PUSH_DOUT)
//            stopin <= #1 0;
//         else if(curr_state == COPY_TO_M1)
//            stopin <= #1 1;
//      end
//   end
//end
always_ff @(posedge clk or posedge rst) begin
   if(rst)
      stopin <= #1 0;
   else if((curr_state == COPY_TO_M1) && (c_x == 4) && (c_y == 4))
      stopin <= #1 0;
   else if(pushin && (x == 4) && (y == 4))
      stopin <= #1 1;
end


always_ff @(posedge clk or posedge rst) begin
   if(rst)
      curr_state <= #1 IDLE;
   else
      curr_state <= #1 n_state;
end

always_comb begin
   n_state = IDLE;
   case(curr_state)
      IDLE: begin
               if(data_ready_in_w4)
                  n_state = COPY_TO_M1;
                else
                  n_state = IDLE;
            end
      COPY_TO_M1: begin
                     if((c_x==4) && (c_y==4))
                        n_state = THETA_C;
                     else
                        n_state = COPY_TO_M1;
                  end
      THETA_C:    begin
                      if((c_x==4) && (c_y==4))
                         n_state = THETA_D;
                      else
                         n_state = THETA_C;
                   end
      THETA_D:     begin
                      if(c_x==4)
                         n_state = FINAL_THETA;
                      else
                         n_state = THETA_D;
                   end
      FINAL_THETA: begin
                      if((c_x==4) && (c_y==4))
                         n_state = RHO_PI;
                      else
                         n_state = FINAL_THETA;
                   end
      RHO_PI:      begin
                      if((c_x==4) && (c_y==4))
                         n_state = COPY_RHO_PI;
                      else
                         n_state = RHO_PI;
                   end
      COPY_RHO_PI: begin
                      if((c_x==4) && (c_y==4))
                         n_state = CHI;
                      else
                         n_state = COPY_RHO_PI;
                   end
      CHI:         begin
                      if((c_x==4) && (c_y==4))
                         n_state = IOTA;
                      else
                         n_state = CHI;
                   end
      IOTA:        begin
                      if(perm_num == 23)
                         n_state = PUSH_DOUT;
                      else
                         n_state = THETA_C;
                   end
      PUSH_DOUT:   begin
                      if(((c_x==4) && (c_y==4)) && !stopout)
                         n_state = IDLE;
                      else
                         n_state = PUSH_DOUT;
                   end
   endcase
end

//always_ff @(posedge clk or posedge rst) begin
//   if(rst) begin
//      c_x <= #1 0;
//      c_y <= #1 0;
//   end else begin
//      if(curr_state != THETA_C) begin
//         c_y <= #1 0;
//         c_x <= #1 0;
//      end else begin
//         if((c_x==4) && (c_y==4)) begin
//            c_y <= #1 0;
//            c_x <= #1 0;
//         end
//         else if(c_y==4) begin
//            c_y <= #1 0;
//            c_x <= #1 c_x+1;
//         end else begin
//            c_y <= #1 c_y+1;
//            c_x <= #1 c_x;
//         end
//      end
//   end
//end
always_ff @(posedge clk or posedge rst) begin
   if(rst) begin
      c_x <= #1 0;
      c_y <= #1 0;
   end else begin
      if((curr_state == COPY_TO_M1) || (curr_state == THETA_C) || (curr_state == FINAL_THETA) || (curr_state == RHO_PI) || (curr_state == COPY_RHO_PI) || (curr_state == CHI)) begin
         if((c_x==4) && (c_y==4)) begin
            c_y <= #1 0;
            c_x <= #1 0;
         end else if(c_y==4) begin
            c_y <= #1 0;
            c_x <= #1 c_x+1;
         end else begin
            c_y <= #1 c_y+1;
            c_x <= #1 c_x;
         end
      end else if(curr_state == THETA_D) begin
         if((c_x==4)) begin
            c_x <= #1 0;
            c_y <= #1 0;
         end else begin
            c_x <= #1 c_x+1;
            c_y <= #1 0;
         end
      end else if((curr_state == PUSH_DOUT) && !stopout)
         if((c_x==4) && (c_y==4)) begin
            c_y <= #1 0;
            c_x <= #1 0;
         end else if(c_x==4) begin
            c_x <= #1 0;
            c_y <= #1 c_y+1;
         end else begin
            c_x <= #1 c_x+1;
            c_y <= #1 c_y;
         end
   end
end


always_ff @(posedge clk or posedge rst) begin
   if(rst) begin
      c_init <= #1 0;
   end
   else begin
      if(curr_state != THETA_C)
         c_init <= #1 0;
      else if(c_y == 0)
         c_init <= #1 m1rd;
      else
         c_init <= #1 c_init ^ m1rd;
   end
end

assign c_final = c_init ^ m1rd;

always_comb begin
   m1rx = 0;
   m1ry = 0;
   if((curr_state == THETA_C) || (curr_state == FINAL_THETA)) begin
      m1rx = c_x;
      m1ry = c_y;
   end else if(curr_state == CHI) begin
      m1ry = c_y;
      m1rx = mod5(c_x+1);
//      case(c_x)
//         0: m1rx = 1;
//         1: m1rx = 2;
//         2: m1rx = 3;
//         3: m1rx = 4;
//         4: m1rx = 0;
//      endcase
   end else if(curr_state == PUSH_DOUT) begin
      m1rx = c_x;
      m1ry = c_y;
   end
end

always_comb begin
   m2rx = 0;
   m2ry = 0;
   if(curr_state == THETA_D) begin
   case(c_x)
      0:   begin
              m2rx = 4;
              m2ry = 0;
           end
      1:   begin
              m2rx = 0;
              m2ry = 0;
           end
      2:   begin
              m2rx = 1;
              m2ry = 0;
           end
      3:   begin
              m2rx = 2;
              m2ry = 0;
           end
      4:   begin
              m2rx = 3;
              m2ry = 0;
           end
   endcase
   end else if(curr_state == RHO_PI) begin // PI is done before rho. PI is just rearranging x,y. e.g. For 0,1 fetch 3,0 and calculate rho and store it in 0,1
      m2ry = c_x;
      case({1'b0,c_x,1'b0,c_y})
         8'h00: m2rx = 0;
         8'h01: m2rx = 3;
         8'h02: m2rx = 1;
         8'h03: m2rx = 4;
         8'h04: m2rx = 2;
         8'h10: m2rx = 1;
         8'h11: m2rx = 4;
         8'h12: m2rx = 2;
         8'h13: m2rx = 0;
         8'h14: m2rx = 3;
         8'h20: m2rx = 2;
         8'h21: m2rx = 0;
         8'h22: m2rx = 3;
         8'h23: m2rx = 1;
         8'h24: m2rx = 4;
         8'h30: m2rx = 3;
         8'h31: m2rx = 1;
         8'h32: m2rx = 4;
         8'h33: m2rx = 2;
         8'h34: m2rx = 0;
         8'h40: m2rx = 4;
         8'h41: m2rx = 2;
         8'h42: m2rx = 0;
         8'h43: m2rx = 3;
         8'h44: m2rx = 1;
      endcase
   end else if(curr_state == CHI) begin
      m2ry = c_y;
      m2rx = mod5(c_x+2);
//      case(c_x)
//         0: m2rx = 2;
//         1: m2rx = 3;
//         2: m2rx = 4;
//         3: m2rx = 0;
//         4: m2rx = 1;
//      endcase
   end
end

always_comb begin
   m3rx = 0;
   m3ry = 0;
   if(curr_state == THETA_D) begin
   case(c_x)
      0:   begin
              m3rx = 1;
              m3ry = 0;
           end
      1:   begin
              m3rx = 2;
              m3ry = 0;
           end
      2:   begin
              m3rx = 3;
              m3ry = 0;
           end
      3:   begin
              m3rx = 4;
              m3ry = 0;
           end
      4:   begin
              m3rx = 0;
              m3ry = 0;
           end
   endcase
   end else if(curr_state == FINAL_THETA) begin
      m3rx = c_x;
      m3ry = 1;
   end else if((curr_state == COPY_RHO_PI) || (curr_state == CHI)) begin
      m3rx = c_x;
      m3ry = c_y;
   end else if(curr_state == IOTA) begin
      m3rx = 0;
      m3ry = 0;
   end
end

always_comb begin
   m4rx = 0;
   m4ry = 0;
   if(curr_state == COPY_TO_M1) begin
      m4rx = c_x;
      m4ry = c_y;
   end
end

assign d = m2rd ^ {m3rd[62:0],m3rd[63]};

assign theta = m1rd ^ m3rd;

assign chi = (m3rd ^ ((m1rd ^ {64{1'b1}}) & m2rd));

always_comb begin
   case({1'b0,m2rx,1'b0,m2ry})
      8'h00: rho = m2rd[63:0];
      8'h01: rho = {m2rd[27:0],m2rd[63:28]};
      8'h02: rho = {m2rd[60:0],m2rd[63:61]};
      8'h03: rho = {m2rd[22:0],m2rd[63:23]};
      8'h04: rho = {m2rd[45:0],m2rd[63:46]};
      8'h10: rho = {m2rd[62:0],m2rd[63]};
      8'h11: rho = {m2rd[19:0],m2rd[63:20]};
      8'h12: rho = {m2rd[53:0],m2rd[63:54]};
      8'h13: rho = {m2rd[20:0],m2rd[63:19]};
      8'h14: rho = {m2rd[61:0],m2rd[63:62]};
      8'h20: rho = {m2rd[1:0],m2rd[63:2]};
      8'h21: rho = {m2rd[57:0],m2rd[63:58]};
      8'h22: rho = {m2rd[20:0],m2rd[63:21]};
      8'h23: rho = {m2rd[48:0],m2rd[63:49]};
      8'h24: rho = {m2rd[2:0],m2rd[63:3]};
      8'h30: rho = {m2rd[35:0],m2rd[63:36]};
      8'h31: rho = {m2rd[8:0],m2rd[63:9]};
      8'h32: rho = {m2rd[38:0],m2rd[63:39]};
      8'h33: rho = {m2rd[42:0],m2rd[63:43]};
      8'h34: rho = {m2rd[7:0],m2rd[63:8]};
      8'h40: rho = {m2rd[36:0],m2rd[63:37]};
      8'h41: rho = {m2rd[43:0],m2rd[63:44]};
      8'h42: rho = {m2rd[24:0],m2rd[63:25]};
      8'h43: rho = {m2rd[55:0],m2rd[63:56]};
      8'h44: rho = {m2rd[49:0],m2rd[63:50]};
      default: rho = 0;
   endcase
end

always_comb begin
if(curr_state == COPY_TO_M1) begin
   m1wx = c_x;
   m1wy = c_y;
   m1wr = 1;
   m1wd = m4rd;
end else if(curr_state == COPY_RHO_PI) begin
   m1wx = c_x;
   m1wy = c_y;
   m1wr = 1;
   m1wd = m3rd;
end else if(curr_state == CHI) begin
   m1wx = c_x;
   m1wy = c_y;
   m1wr = 1;
   m1wd = chi;
end else if(curr_state == IOTA) begin
   m1wx = 0;
   m1wy = 0;
   m1wr = 1;
   m1wd = m1rd ^ rc;
end else begin
   m1wx = 0;
   m1wy = 0;
   m1wr = 0;
   m1wd = 0;
end
end

always_comb begin
if(curr_state == THETA_C) begin
   m2wx = c_x;
   m2wy = 0;
   m2wr = (c_y==4)?1:0;
   m2wd = c_final;
end else if(curr_state == FINAL_THETA) begin
   m2wx = c_x;
   m2wy = c_y;
   m2wr = 1;
   m2wd = theta;
end else if(curr_state == COPY_RHO_PI) begin
   m2wx = c_x;
   m2wy = c_y;
   m2wr = 1;
   m2wd = m3rd;
end else begin
   m2wx = 0;
   m2wy = 0;
   m2wr = 0;
   m2wd = 0;
end
end

always_comb begin
if(curr_state == THETA_C) begin
   m3wx = c_x;
   m3wy = 0;
   m3wr = (c_y==4)?1:0;
   m3wd = c_final;
end else if(curr_state == THETA_D) begin
   m3wx = c_x;
   m3wy = 1;
   m3wr = 1;
   m3wd = d;
end else if(curr_state == RHO_PI) begin
   m3wx = c_x;
   m3wy = c_y;
   m3wr = 1;
   m3wd = rho;
end else begin
   m3wx = 0;
   m3wy = 0;
   m3wr = 0;
   m3wd = 0;
end
end

always_comb begin
if((pushin && !stopin)) begin
   m4wx = x;
   m4wy = y;
   m4wr = pushin & !stopin;
   m4wd = din;
   end else begin
   m4wx = 0;
   m4wy = 0;
   m4wr = 0;
   m4wd = 0;
   end
end

always_ff @(posedge clk or posedge rst) begin
   if(rst)
      data_ready_in_w4 <= #1 0;
   else if((curr_state == COPY_TO_M1) && (c_x == 4) && (c_y == 4))
      data_ready_in_w4 <= #1 0;
   else if(pushin && (x==4) && (y==4))
      data_ready_in_w4 <= #1 1;
end

always_comb begin
case(perm_num)
   32'd0  : rc = 64'h0000000000000001;
   32'd1  : rc = 64'h0000000000008082;
   32'd2  : rc = 64'h800000000000808A;
   32'd3  : rc = 64'h8000000080008000;
   32'd4  : rc = 64'h000000000000808B;
   32'd5  : rc = 64'h0000000080000001;
   32'd6  : rc = 64'h8000000080008081;
   32'd7  : rc = 64'h8000000000008009;
   32'd8  : rc = 64'h000000000000008A;
   32'd9  : rc = 64'h0000000000000088;
   32'd10 : rc = 64'h0000000080008009;
   32'd11 : rc = 64'h000000008000000A;
   32'd12 : rc = 64'h000000008000808B;
   32'd13 : rc = 64'h800000000000008B;
   32'd14 : rc = 64'h8000000000008089;
   32'd15 : rc = 64'h8000000000008003;
   32'd16 : rc = 64'h8000000000008002;
   32'd17 : rc = 64'h8000000000000080;
   32'd18 : rc = 64'h000000000000800A;
   32'd19 : rc = 64'h800000008000000A;
   32'd20 : rc = 64'h8000000080008081;
   32'd21 : rc = 64'h8000000000008080;
   32'd22 : rc = 64'h0000000080000001;
   32'd23 : rc = 64'h8000000080008008;
   default: rc = 64'h0000000000000000;
endcase
end
always_ff @(posedge clk or posedge rst) begin
   if(rst)
      perm_num <= #1 0;
   else begin
      if(curr_state == IOTA) begin
         if(perm_num == 23)
            perm_num <= #1 0;
         else
            perm_num <= #1 perm_num + 1;
      end
   end
end

always_comb begin
 firstout <= #1 ((curr_state == PUSH_DOUT) && (c_x == 0) && (c_y == 0));
 pushout  <= #1 ((curr_state == PUSH_DOUT));
 dout <= m1rd;
end

endmodule
