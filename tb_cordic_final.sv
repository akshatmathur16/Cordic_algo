module tb_cordic_final();

parameter DATA_WIDTH=8;

bit clk, rst;
bit signed [DATA_WIDTH-1:0] angle;  // in Radians, 1 sign bit 1 integer bit 6 frac bits
bit signed [DATA_WIDTH-1:0] cos_val, sin_val;

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
    #3; rst =0; angle= 'b00_001110;
    #10; rst =0; angle= 'b00_011100;
    #10; rst =0; angle= 'b00_111101;
    //#124; rst =0; angle= 'b00_011100;
    //#124; rst =0; angle= 'b00_110111;


end



initial
begin
    `ifdef FRAC
        $monitor($time, "from tb angle = %f, cos_val=%f, sin_val=%f",$itor(angle*o_SF),$itor(cos_val*o_SF),$itor(sin_val*o_SF));
    `else
        $monitor($time, "from tb angle = %d, cos_val=%d, sin_val=%d",angle, cos_val, sin_val);

    `endif
end








//clock generator
always
    #5 clk = ~clk;


initial begin
    #5000 $stop;
end

endmodule
