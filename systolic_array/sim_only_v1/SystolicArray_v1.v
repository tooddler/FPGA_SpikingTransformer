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
    input                                             spikes_valid        ,
    input       [`IMG_WIDTH*`TIME_STEPS - 1 : 0]      spikes              ,
    input                                             spikes_done         ,
    output reg                                        spikes_ready=0      ,
    // -- get B Matrix Data Slices

    // -- get C Matrix Data Slices

); 

endmodule //SystolicArray_v1
