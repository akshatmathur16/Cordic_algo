module cordic # (parameter DATA_WIDTH=8)

(
    input clk, rst,
    input signed [DATA_WIDTH-1:0] angle,  // in Radians, 1 sign bit 1 integer bit 6 frac bits
    output bit signed [DATA_WIDTH-1:0] cos_val, sin_val
);

localparam MEM_SIZE=10;
localparam ITER_COUNT = MEM_SIZE;
localparam DATA_WIDTH_TEMP = 12;
localparam [11:0] ERROR_RANGE = 'b0_0000001010; //1%
//localparam [6:0] error_prec ; // 1 bit integer, 6 bits frac, no need of sign bit

// implementing LUT in registers instad of memory as per spec 
// assuming max iterations of 6 right now


//AM bit signed [DATA_WIDTH*MEM_SIZE-1:0] lut;
bit signed [DATA_WIDTH_TEMP-1:0]lut[MEM_SIZE-1];
bit [3:0] flag_count;
bit flag;
bit [DATA_WIDTH_TEMP-1:0] frac_part_x;
bit [DATA_WIDTH_TEMP-1:0] frac_part_y;

//TODO change this to register logic later
bit signed [DATA_WIDTH_TEMP-1:0] x[MEM_SIZE-1:0];
bit signed [DATA_WIDTH_TEMP-1:0] y[MEM_SIZE-1:0];
bit signed [DATA_WIDTH_TEMP-1:0] z[MEM_SIZE-1:0];
bit signed [DATA_WIDTH_TEMP-1:0] ext_angle;

// storing tan-1 values of angles taken in radians tan-1(2**-i) 
initial begin

    lut[0]= 'b00_1100100100;// tan-1(1)
    lut[1]= 'b00_0111011010;// tan-1(1/2)
    lut[2]= 'b00_0011111010;// tan-1(1/4)
    lut[3]= 'b00_0001111111;// tan-1(1/8)
    lut[4]= 'b00_0000111111;// tan-1(1/16)
    lut[5]= 'b00_0000011111;// tan-1(1/32)
    lut[6]= 'b00_0000001111;// tan-1(1/64)
    lut[7]= 'b00_0000001000;// tan-1(1/128)
    lut[8]= 'b00_0000000100;// tan-1(1/256)
    lut[9]= 'b00_0000000010;// tan-1(1/512)
end

assign ext_angle = {angle, 4'b0};
assign flag =  (ext_angle^ z[0])? 1'b1 : 1'b0;

initial
begin
    x[0] <= 12'b01_0000000000;
    y[0] <= 'b0;
end

genvar i;

generate

    for(i=0; i< ITER_COUNT-1; i++)
    begin
        always @(posedge clk)
        begin
            if(~rst)
            begin
                //x[i+1] <= x[i] - sigma*2**-i*y[i]  +ve angle
                //x[i+1] <= x[i] + sigma*2**-i*y[i]  -ve angle


                if(flag==1'b1)
                begin
                    flag_count <= 'b1;
                end
                else
                begin
                    //if(flag_count==ITER_COUNT || z[i+1][DATA_WIDTH_TEMP-2:0] < ERROR_RANGE)
                    if(flag_count==ITER_COUNT)
                    begin
                        flag_count <= 'd0;
                        //break;
                    end
                    else if(flag_count!='d0 )
                        flag_count<= flag_count+1;
                end


                z[0] <= ext_angle;
    
                x[i+1] <= (flag_count!='d0 ) ? (z[i][DATA_WIDTH-1] ? (x[i]+ (y[i]>>>i)): (x[i]- (y[i] >>>i ))): x[i+1];// shift right for every iteration to divide by 2
                //AM x[i+1] <= z[i][7] ? (x[i]+ ((2**(~i+1))*y[i])): (x[i]- ((2**(~i+1))*y[i]));// shift right for every iteration to divide by 2
                //y[i+1] = y[i] + (sigma*2**-i*x[i]); //+ve angle
                //y[i+1] = y[i] - (sigma*2**-i*x[i]); //+ve angle
                y[i+1] <= (flag_count!='d0) ? (z[i][DATA_WIDTH-1] ? (y[i] - (x[i]>>>i)): (y[i] + (x[i]>>>i))): y[i+1];
                //AM y[i+1] <= z[i][7] ? (y[i] - ((2**(~i+1))*y[i])): (y[i] + ((2**(~i+1))*y[i]));

                //subtracting tan-1(2**-i) values based on if angle is positive or negative
                //AM z[i+1] <= (flag_count!='d0 ) ? (z[i][DATA_WIDTH-1] ? z[i] + lut[7*i+:8] : z[i] - lut[7*i+:8]): z[i+1];
                z[i+1] <= (flag_count!='d0 ) ? (z[i][DATA_WIDTH-1] ? z[i] + lut[i] : z[i] - lut[i]): z[i+1];


                //TODO implement 1% error check
                //TODO assign cos_val and sin_val outside this for loop

            end
         end
    end
endgenerate

//preventing 1 clock cycle by assigning as wire
//
//always @(*)
//begin
//    for(int i=0; i<3; i++)
//    begin
//        frac_part_x = x[MEM_SIZE-1][i] + x[MEM_SIZE-1][i+1];
//    end
//end
//assign cos_val = {x[MEM_SIZE-1][DATA_WIDTH_TEMP-1],x[MEM_SIZE-1][DATA_WIDTH_TEMP-2], frac_part_x[5:0]}; // assigning final value of x as cos(theta)
//assign sin_val = y[MEM_SIZE-1]; // assigning final value of y as sin(theta)
assign cos_val = x[MEM_SIZE-1]; // assigning final value of x as cos(theta)
assign sin_val = y[MEM_SIZE-1]; // assigning final value of y as sin(theta)


endmodule
