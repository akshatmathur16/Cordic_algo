`include "defines.svh"
module tb_cordic_final();

parameter DATA_WIDTH=8;

bit clk, rst;
bit signed [DATA_WIDTH-1:0] angle;  // in Radians, 1 sign bit 1 integer bit 6 frac bits
bit signed [DATA_WIDTH-1:0] cos_val, sin_val;

localparam i_SF = 2.0**-6.0;
localparam o_SF = 2.0**-6.0;

cordic #(.DATA_WIDTH(DATA_WIDTH)) inst_cordic 
(
    .clk(clk),
    .rst(rst),
    .angle(angle),  
    .cos_val(cos_val),
    .sin_val(sin_val)
);

initial begin

    rst =0;
    `define FRAC

    `ifndef PIPE
        #3; rst =0; angle= 'b01_100000;
        #134; rst =0; angle= 'b00_011100;
        #134; rst =0; angle= 'b11_100000;
        #134; rst =0; angle= 'b01_100101;
        #134; rst =0; angle= 'b01_100000;
    `else
        #3; rst =0; angle= 'b01_100000;
        #10; rst =0; angle= 'b00_011100;
        #10; rst =0; angle= 'b11_100000;
    `endif
    


end



initial
begin
    `ifdef FRAC
        $monitor($time, "from tb angle = %f, cos_val=%f, sin_val=%f, expected cos=%f, expected sin=%f",$itor(angle*i_SF),$itor(cos_val*o_SF),$itor(sin_val*o_SF), $cos($itor(angle*o_SF)), $sin($itor(angle*o_SF)));
    `else
        $monitor($time, "from tb angle = %d, cos_val=%d, sin_val=%d expected cos=%f, expected sin=%f",angle, cos_val, sin_val, $cos(angle), $sin(angle));

    `endif
end








//clock generator
always
    #5 clk = ~clk;


initial begin
    #50000 $stop;
end

endmodule
