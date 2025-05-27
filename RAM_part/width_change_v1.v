/*
    - width_change - 
        16 bit -> 24 bit
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "E:/Desktop/spiking_transformer/spiking_transformer/spiking_transformer.srcs/sources_1/imports/FPGA_SpikingTransformer/hyper_para.v"
module width_change_v1 (
    input                                          s_clk               ,
    input                                          s_rst               ,
    // in
    output reg                                     o_bytes_in_ready=0  ,
    input      [`QUAN_BITS*2 - 1 : 0]              bytes_in            ,
    input                                          bytes_in_valid      ,
    // out
    input                                          bytes_out_ready     ,
    output wire[`QUAN_BITS*3 - 1 : 0]              o_bytes_out         ,
    output wire                                    o_bytes_out_valid         
);

reg  [`QUAN_BITS*3 - 1 : 0]                        r_bytes_out         ;
reg                                                r_bytes_out_valid   ;  
reg  [`QUAN_BITS*2 - 1 : 0]                        r_bytes_in          ;
reg  [1:0]                                         r_cnt               ;
reg                                                r_buffer_valid      ;
reg  [`QUAN_BITS*3 - 1 : 0]                        r_buffer_data       ;

assign o_bytes_out_valid = o_bytes_in_ready ? r_bytes_out_valid : r_buffer_valid ;
assign o_bytes_out       = o_bytes_in_ready ? r_bytes_out       : r_buffer_data  ;

// r_buffer_valid
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_buffer_valid <= 1'b0;
    else if (bytes_out_ready)
        r_buffer_valid <= 1'b0;
    else if (~bytes_out_ready && r_bytes_out_valid && o_bytes_in_ready)
        r_buffer_valid <= 1'b1; 
end

// r_buffer_data
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_buffer_data <= 'd0;
    else if (~bytes_out_ready && r_bytes_out_valid && o_bytes_in_ready)
        r_buffer_data <= r_bytes_out;
end

// r_bytes_in
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_bytes_in <= 'd0;
    else if (bytes_in_valid && o_bytes_in_ready)
        r_bytes_in <= bytes_in;
end

// r_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_cnt <= 'd0;
    else if (r_cnt == 'd2 && r_buffer_valid && bytes_out_ready)
        r_cnt <= 'd0;
    else if (r_cnt == 'd2 && bytes_in_valid && o_bytes_in_ready && bytes_out_ready)
        r_cnt <= 'd0;
    else if (r_buffer_valid && bytes_out_ready)
        r_cnt <= r_cnt + 1'b1;
    else if (bytes_in_valid && o_bytes_in_ready && bytes_out_ready)
        r_cnt <= r_cnt + 1'b1;
end

// o_bytes_out
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_bytes_out <= 'd0;
    else if (bytes_in_valid && o_bytes_in_ready)
        case(r_cnt)
            'd1: r_bytes_out <= {bytes_in[`QUAN_BITS - 1 : 0], r_bytes_in}; // {b, g, r}
            'd2: r_bytes_out <= {bytes_in, r_bytes_in[`QUAN_BITS*2 - 1 : `QUAN_BITS]}; 
            default: r_bytes_out <= r_bytes_out;
        endcase
end

// r_bytes_out_valid
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_bytes_out_valid <= 1'b0;
    else if (r_buffer_valid && bytes_out_ready)
        r_bytes_out_valid <= 1'b1;
    else if ((|r_cnt) && bytes_in_valid && o_bytes_in_ready && bytes_out_ready)
        r_bytes_out_valid <= 1'b1;
    else 
        r_bytes_out_valid <= 1'b0;
end

// o_bytes_in_ready
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        o_bytes_in_ready <= 1'b0;
    else if(bytes_out_ready)
        o_bytes_in_ready <= 1'b1;
    else if(bytes_in_valid)
        o_bytes_in_ready <= 1'b0;
end

endmodule // width_change


