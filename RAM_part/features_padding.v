/*
    - features padding -
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "E:/Desktop/Zynq_Spikformer/Zynq_Spikformer.srcs/sources_1/hyper_para.v"
module features_padding (
    input                                          s_clk                    ,
    input                                          s_rst                    ,

    input                                          ready4data               , // pe unit need data

    output reg                                     o_data_in_req            ,
    input                                          data_in_valid            ,
    input       [`QUAN_BITS*3 - 1 : 0]             data_in                  ,

    output wire [`QUAN_BITS*3 - 1 : 0]             padding_data_out         ,
    output wire                                    padding_data_out_valid      
);

reg [9:0]                                          r_pos_x                  ;
reg [9:0]                                          r_pos_y                  ;
reg                                                r_padding_data_out_valid ;
reg  [1:0]                                         r_cnt                    ;

wire                                               w_padding_flag           ;

assign w_padding_flag           = (r_pos_x > 'd0 && r_pos_x <= `IMG_WIDTH) && (r_pos_y > 'd0 && r_pos_y <= `IMG_WIDTH)  ;
assign padding_data_out         = w_padding_flag ? data_in                       : `PADDING_PARAM                       ;
assign padding_data_out_valid   = w_padding_flag ? data_in_valid & o_data_in_req : r_padding_data_out_valid & (|r_cnt)  ;

// r_pos_x
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_pos_x <= 'd0;
    else if (ready4data && padding_data_out_valid && r_pos_x == `IMG_WIDTH + 2 - 1)
        r_pos_x <= 'd0;
    else if (ready4data && padding_data_out_valid)
        r_pos_x <= r_pos_x + 1'b1;
end

// r_pos_y
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_pos_y <= 'd0;
    else if (ready4data && r_pos_y == `IMG_HIGH + 2 - 1 && r_pos_x == `IMG_WIDTH + 2 - 1 && padding_data_out_valid)
        r_pos_y <= 'd0;
    else if (ready4data && padding_data_out_valid && r_pos_x == `IMG_WIDTH + 2 - 1)
        r_pos_y <= r_pos_y + 1'b1;
end

// r_padding_data_out_valid
always@(posedge s_clk) begin
    if (ready4data && ~w_padding_flag)
        r_padding_data_out_valid <= 1'b1;
    else
        r_padding_data_out_valid <= 1'b0;
end

// r_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_cnt <= 'd0;
    else if (r_padding_data_out_valid && r_cnt == 'd2)
        r_cnt <= 'd0;
    else if (r_padding_data_out_valid)
        r_cnt <= r_cnt + 1'b1;
end

// o_data_in_req
always@(posedge s_clk) begin
    if (w_padding_flag)
        o_data_in_req <= 1'b1;
    else
        o_data_in_req <= 1'b0;
end

endmodule //features_padding


