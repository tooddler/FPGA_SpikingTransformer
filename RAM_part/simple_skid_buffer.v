/*
    -- simple skid buffer --
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "../hyper_para.v"
module simple_skid_buffer (
    input                                               s_clk             ,
    input                                               s_rst             ,

    output reg                                          o_data_in_ready   ,
    input                                               data_in_valid     ,
    input       [`QUAN_BITS*3 - 1 : 0]                  data_in           ,

    input                                               data_out_ready    ,
    output                                              o_data_out_valid  ,
    output      [`QUAN_BITS*3 - 1 : 0]                  o_data_out                 
);

reg                               r_buffer_valid   ;
reg  [`QUAN_BITS*3 - 1 : 0]       r_buffer_data    ;

assign o_data_out_valid = o_data_in_ready ? data_in_valid : r_buffer_valid ;
assign o_data_out       = o_data_in_ready ? data_in       : r_buffer_data  ;

// r_buffer_data
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_buffer_data <= 'd0;
    else if(~data_out_ready && data_in_valid && o_data_in_ready)
        r_buffer_data <= data_in;
end

// r_buffer_valid
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_buffer_valid <= 1'b0;
    else if(data_out_ready)
        r_buffer_valid <= 1'b0;
    else if(~data_out_ready && data_in_valid && o_data_in_ready)
        r_buffer_valid <= 1'b1; 
end

// o_data_in_ready
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        o_data_in_ready <= 1'b1;
    else if(data_out_ready)
        o_data_in_ready <= 1'b1;
    else if(data_in_valid)
        o_data_in_ready <= 1'b0;
end

endmodule //simple_skid_buffer
