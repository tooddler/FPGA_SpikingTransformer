/*
    --- simple systolic pe unit --- 
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
    FUNC    : Din * Weight + Psum
    ** Attn ** : simulation only
*/

`include "../../hyper_para.v"
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
    output                                                   out_data_valid      ,
    output      [`SYSTOLIC_DATA_WIDTH - 1 : 0]               out_raw_data        ,
    
    // psum-in
    input                                                    in_psum_data_valid  ,
    input       [`SYSTOLIC_PSUM_WIDTH - 1 : 0]               in_psum_data        ,
    // psum-out
    output                                                   out_psum_data_valid ,
    output      [`SYSTOLIC_PSUM_WIDTH - 1 : 0]               out_psum_data       
);

reg [`SYSTOLIC_DATA_WIDTH - 1 : 0]                           r_weight            ;
reg                                                          r_weight_valid      ;   

always@(posedge s_clk) begin
    r_weight_valid <= weight_valid ;
end

// r_weight
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) begin
        r_weight <= 'd0;
    end
    else if (weight_valid && ~r_weight_valid) begin
        r_weight <= weights;
    end
end


endmodule //Systolic_pe_v1
