/*
    --- simple systolic pe unit --- 
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
    FUNC    : Din * Weight + Psum
    ** Attn ** : simulation only
*/

`include "E:/Desktop/Zynq_Spikformer/Zynq_Spikformer.srcs/sources_1/hyper_para.v"
module Systolic_pe_v1 (
    input                                                    s_clk               ,
    input                                                    s_rst               ,    
    // B Matrix Data Slices as Weights
    input                                                    weight_valid        ,
    input       [`SYSTOLIC_DATA_WIDTH - 1 : 0]               weights             ,
    // A Matrix data-in
    input                                                    in_data_valid       ,
    input       [`SYSTOLIC_DATA_WIDTH - 1 : 0]               in_raw_data         ,
    // A Matrix data-in -> right-out
    output reg                                               out_data_valid=0    ,
    output reg  [`SYSTOLIC_DATA_WIDTH - 1 : 0]               out_raw_data='d0    ,
    // psum-in
    input       [`SYSTOLIC_PSUM_WIDTH - 1 : 0]               in_psum_data        ,
    // psum-out
    output reg  [`SYSTOLIC_PSUM_WIDTH - 1 : 0]               out_psum_data       
);

wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                          w_rlst              ;
wire                                                         w_rlst_vld          ;

reg [`SYSTOLIC_DATA_WIDTH - 1 : 0]                           r_weight            ;

// r_weight
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) begin
        r_weight <= 'd0;
    end
    else if (weight_valid) begin
        r_weight <= weights;
    end
end

//out_data_valid out_raw_data  
always@(posedge s_clk) begin
    out_data_valid <= in_data_valid ;
    out_raw_data   <= in_raw_data ;
end

// out_psum_data
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        out_psum_data <= 'd0;
    else if (w_rlst_vld)
        out_psum_data <= $signed(in_psum_data) + $signed(w_rlst); 
end

mutil_unit_sim u_mutil_unit_sim(
    .s_clk          ( s_clk         ),
    .s_rst          ( s_rst         ),

    .valid          ( in_data_valid ),
    .a              ( in_raw_data   ),
    .b              ( r_weight      ),

    .rlst           ( w_rlst        ),
    .rlst_vld       ( w_rlst_vld    )
);


endmodule //Systolic_pe_v1


