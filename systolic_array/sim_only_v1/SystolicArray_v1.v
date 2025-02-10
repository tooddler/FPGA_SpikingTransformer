/*
    --- simple systolic array --- 
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
    ** Attn ** : simulation only
*/

`include "../../hyper_para.v"
module SystolicArray_v1 (
    input                                             s_clk               ,
    input                                             s_rst               ,    
    // -- get A Matrix Data Slices
    input                                             MtrxA_slice_valid   ,
    input       [`SYSTOLIC_DATA_WIDTH - 1 : 0]        MtrxA_slice_data    ,
    input                                             MtrxA_slice_done    ,
    output reg                                        MtrxA_slice_ready=0 ,
    // -- get B Matrix Data Slices
    input                                             MtrxB_slice_valid   ,
    input       [`SYSTOLIC_DATA_WIDTH - 1 : 0]        MtrxB_slice_data    ,
    input                                             MtrxB_slice_done    ,
    output reg                                        MtrxB_slice_ready=0 ,
    // -- get C Matrix Data Slices
    input                                             MtrxC_slice_valid   ,
    input       [`SYSTOLIC_DATA_WIDTH - 1 : 0]        MtrxC_slice_data    ,
    input                                             MtrxC_slice_done    ,
    output reg                                        MtrxC_slice_ready=0 
); 



endmodule //SystolicArray_v1
