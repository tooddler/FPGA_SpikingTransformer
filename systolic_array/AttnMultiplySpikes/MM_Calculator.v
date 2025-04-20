/*
    --- Attn @ V --- 
    Author   : Toddler. 
    Email    : 23011211185@stu.xidian.edu.cn
    Encoder  : UTF-8
*/

`include "../../hyper_para.v"
module MM_Calculator (
    input                                                         s_clk                ,
    input                                                         s_rst                ,  
    // interact with Tmp_AttnRAM_group
    output                                                        o_AttnRam_Done       , 
    output     [11 : 0]                                           o_AttnRam_rd_addr    ,
    input                                                         i_AttnRAM_Empty      ,
    input      [$clog2(2*`SYSTOLIC_UNIT_NUM)*`TIME_STEPS - 1 : 0] i_AttnRAM_data       , // delay 1 clk
    // interact with ValueRAM   
    output     [9 : 0]                                            o_ValueRam_rdaddr    ,
    input      [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]         i_ValueRam_out         // delay 1 clk
);



endmodule // MM_Calculator
