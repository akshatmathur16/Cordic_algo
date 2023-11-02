// Cordic Algorithm
// Author: Akshat Mathur

`include "defines.svh"
module cordic # (parameter DATA_WIDTH=8)

(
    input clk, rst,
    input signed [DATA_WIDTH-1:0] angle,  // in Radians, 1 sign bit 7 frac bits
    output bit signed [DATA_WIDTH-1:0] cos_val, sin_val // final cos(theta), sin(theta)
);

localparam MEM_SIZE=12;
localparam ITER_COUNT = MEM_SIZE; //iteration count 
localparam DATA_WIDTH_TEMP = 14;

// assuming max iterations of 12 right now
bit signed [DATA_WIDTH_TEMP-1:0]lut[MEM_SIZE-1:0];
bit [3:0] flag_count;
bit flag;

bit signed [DATA_WIDTH_TEMP-1:0] x[MEM_SIZE-1:0]; // var holding interim cos(thta) values
bit signed [DATA_WIDTH_TEMP-1:0] y[MEM_SIZE-1:0]; // var holding interim sin(theta) values
bit signed [DATA_WIDTH_TEMP-1:0] z[MEM_SIZE-1:0]; // variable holding rotated angle
bit signed [DATA_WIDTH_TEMP-1:0] ext_angle;
bit signed [DATA_WIDTH_TEMP-1:0] two_s_compl_angle; // var to hold if angle is negative
bit neg_flag;
bit neg_flag_new[MEM_SIZE-1:0];
bit int_cos_val, int_sin_val;

//variables for Rounding off 
bit [11:0] sin_fracpart_temp0, cos_fracpart_temp0;
bit [10:0] sin_fracpart_temp0_temp, cos_fracpart_temp0_temp;
bit [9:0] sin_fracpart_temp1, cos_fracpart_temp1;
bit [8:0] sin_fracpart_temp2, cos_fracpart_temp2; 
bit [7:0] sin_fracpart_temp3, cos_fracpart_temp3;
bit [6:0] sin_fracpart, cos_fracpart;
bit [7:0] carry_sin_fracpart, carry_cos_fracpart;
bit carry;


// storing tan-1 values of angles taken in radians tan-1(2**-i) 
initial begin
    lut[0]  = 'b00_110010010000;// tan-1(1)
    lut[1]  = 'b00_011101101011;// tan-1(1/2)
    lut[2]  = 'b00_001111101011;// tan-1(1/4)
    lut[3]  = 'b00_000111111101;// tan-1(1/8)
    lut[4]  = 'b00_000011111111;// tan-1(1/16)
    lut[5]  = 'b00_000001111111;// tan-1(1/32)
    lut[6]  = 'b00_000000111111;// tan-1(1/64)
    lut[7]  = 'b00_000000100000;// tan-1(1/128)
    lut[8]  = 'b00_000000010000;// tan-1(1/256)
    lut[9]  = 'b00_000000001000;// tan-1(1/512)
    lut[10] = 'b00_000000000100;// tan-1(1/1024)
    lut[11] = 'b00_000000000010;// tan-1(1/2048)

end


assign ext_angle = {angle, 6'b0};
assign flag =  (ext_angle^ z[0])? 1'b1 : 1'b0;
assign neg_flag = ext_angle[DATA_WIDTH_TEMP-1] ? 1'b1: 1'b0;
assign two_s_compl_angle = neg_flag ? {1'b0, ext_angle[DATA_WIDTH_TEMP-2:0]}: ext_angle; // sign mag implementation

initial
begin
    x[0] <= 14'b0_1001101101110;// 1 x 0.6072 (scaling factor)
    y[0] <= 'b0;
end

genvar i;

// Algo for Pipeline architecture

    generate
      for(i=0; i< ITER_COUNT-1; i++)
        begin
          always @(posedge clk)
          begin
              if(~rst)
              begin
                  //x[i+1] <= x[i] - sigma*2**-i*y[i]  +ve angle
                  //x[i+1] <= x[i] + sigma*2**-i*y[i]  -ve angle


                  z[0] <= two_s_compl_angle; 

                  x[i+1] <= (z[i][DATA_WIDTH_TEMP-1] ? (x[i]+ (y[i]>>>i)): (x[i]- (y[i] >>>i )));// shift right for every iteration to divide by 2
                  //y[i+1] = y[i] + (sigma*2**-i*x[i]); //+ve angle
                  //y[i+1] = y[i] - (sigma*2**-i*x[i]); //+ve angle
                  y[i+1] <= (z[i][DATA_WIDTH_TEMP-1] ? (y[i] - (x[i]>>>i)): (y[i] + (x[i]>>>i)));
                  //subtracting tan-1(2**-i) values based on if angle is positive or negative
                  //AM z[i+1] <= (flag_count!='d0 ) ? (z[i][DATA_WIDTH-1] ? z[i] + lut[7*i+:8] : z[i] - lut[7*i+:8]): z[i+1];
                  z[i+1] <= (z[i][DATA_WIDTH_TEMP-1] ? z[i] + lut[i] : z[i] - lut[i]);

              end
          end
      end
    endgenerate


    //Rounding off logic, Rounding off from 12 bits to 8 bits 
    assign cos_fracpart_temp0 = x[MEM_SIZE-1][12:1]+x[MEM_SIZE-1][0];
    assign cos_fracpart_temp0_temp = cos_fracpart_temp0[11:1]+cos_fracpart_temp0[0];
    assign cos_fracpart_temp1 = cos_fracpart_temp0_temp[10:1]+cos_fracpart_temp0_temp[0];

    assign cos_fracpart_temp2 = cos_fracpart_temp1[9:1]+cos_fracpart_temp1[0];

    assign cos_fracpart_temp3 = cos_fracpart_temp2[8:1]+cos_fracpart_temp2[0];

    assign carry_cos_fracpart = cos_fracpart_temp3[7:1]+cos_fracpart_temp3[0];

    assign sin_fracpart_temp0 = y[MEM_SIZE-1][12:1]+y[MEM_SIZE-1][0];
    assign sin_fracpart_temp0_temp = sin_fracpart_temp0[11:1]+sin_fracpart_temp0[0];
    assign sin_fracpart_temp1 = sin_fracpart_temp0_temp[10:1]+sin_fracpart_temp0_temp[0];

    assign sin_fracpart_temp2 = sin_fracpart_temp1[9:1]+sin_fracpart_temp1[0];

    assign sin_fracpart_temp3 = sin_fracpart_temp2[8:1]+sin_fracpart_temp2[0];

    assign carry_sin_fracpart = sin_fracpart_temp3[7:1]+sin_fracpart_temp3[0];



    //preventing 1 clock cycle by assigning as wire
    assign cos_val = (carry_sin_fracpart[6]^carry_cos_fracpart[5]^carry_cos_fracpart[4]^carry_cos_fracpart[3]^carry_cos_fracpart[2]^carry_cos_fracpart[1]^carry_cos_fracpart[0]) ?{1'b0, carry_cos_fracpart[6:0]}: {1'b0, x[MEM_SIZE-1][DATA_WIDTH_TEMP-2:6]};
    assign sin_val = neg_flag_new[MEM_SIZE-1]? ((carry_sin_fracpart[6]^carry_sin_fracpart[5]^carry_sin_fracpart[4]^carry_sin_fracpart[3]^carry_sin_fracpart[2]^carry_sin_fracpart[1]^carry_sin_fracpart[0]) ?{1'b1, carry_sin_fracpart[6:0]}: {1'b1, y[MEM_SIZE-1][DATA_WIDTH_TEMP-2:6]}):((carry_sin_fracpart[6]^carry_sin_fracpart[5]^carry_sin_fracpart[4]^carry_sin_fracpart[3]^carry_sin_fracpart[2]^carry_sin_fracpart[1]^carry_sin_fracpart[0]) ? {1'b0, carry_sin_fracpart[6:0]} :y[MEM_SIZE-1][DATA_WIDTH_TEMP-2:6]);



   // Implementing Negative angle sign propagation
   genvar j;

   generate
    for(j=0; j< ITER_COUNT; j++)
    begin
        always@(posedge clk)
        begin
            neg_flag_new[0] <= neg_flag;
            if(j!=11)
                neg_flag_new[j+1] <= neg_flag_new[j];
        end
    end
   endgenerate



endmodule
