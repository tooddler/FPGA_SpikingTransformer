/*
    - width_change - 
        16 bit -> 24 bit
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "E:/Desktop/Zynq_Spikformer/Zynq_Spikformer.srcs/sources_1/hyper_para.v"
module width_change (
    input                                          s_clk               ,
    input                                          s_rst               ,
    // in
    input      [`QUAN_BITS*2 - 1 : 0]              bytes_in            ,
    input                                          bytes_valid         ,
    // out
    output reg [`QUAN_BITS*3 - 1 : 0]              o_bytes_out         ,
    output reg                                     o_bytes_valid         
);

reg  [`QUAN_BITS*2 - 1 : 0]                 r_bytes_in      ;
reg  [1:0]                                  r_cnt           ;

// r_bytes_in
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_bytes_in <= 'd0;
    else if (bytes_valid)
        r_bytes_in <= bytes_in;
end

// r_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_cnt <= 'd0;
    else if (r_cnt == 'd2 && bytes_valid)
        r_cnt <= 'd0;
    else if (bytes_valid)
        r_cnt <= r_cnt + 1'b1;
end

// o_bytes_valid
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        o_bytes_valid <= 1'b0;
    else if ((|r_cnt) && bytes_valid)
        o_bytes_valid <= 1'b1;
    else 
        o_bytes_valid <= 1'b0;
end

// o_bytes_out
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        o_bytes_out <= 'd0;
    else
        case(r_cnt)
            'd1: o_bytes_out <= {bytes_in[`QUAN_BITS - 1 : 0], r_bytes_in}; // {b, g, r}
            'd2: o_bytes_out <= {bytes_in, r_bytes_in[`QUAN_BITS*2 - 1 : `QUAN_BITS]}; 
            default: o_bytes_out <= 'd0;
        endcase
end

endmodule // width_change


