/*
    --- simple systolic pe unit --- 
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
    ** Attn ** : simulation only
*/

`include "../../hyper_para.v"
module Systolic_pe_v1 (
    input                                               s_clk             ,
    input                                               s_rst             ,    
    // B Matrix Data Slices as Weights
    input                                               weight_valid      ,
    input  [`SYSTOLIC_DATA_WIDTH - 1 : 0]               weights           ,
    // Psum data-in
    input                                               data_valid        ,
    input  [`SYSTOLIC_DATA_WIDTH - 1 : 0]               psum_data         ,
    // psum-out
    output                                              o_data_valid      ,
    output  [`SYSTOLIC_DATA_WIDTH - 1 : 0]              o_psum_data       
);



endmodule //Systolic_pe_v1
