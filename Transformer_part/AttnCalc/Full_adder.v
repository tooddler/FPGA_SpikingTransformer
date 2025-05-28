/*
    --- Full Adder --- 
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "E:/Desktop/spiking_transformer/spiking_transformer/spiking_transformer.srcs/sources_1/imports/FPGA_SpikingTransformer/hyper_para.v"
module Full_adder (
    input                       i_A         ,
    input                       i_B         ,
    input                       i_Cin       ,

    output                      o_Sum       ,
    output                      o_Cout    
);

assign o_Sum  = i_A ^ i_B ^ i_Cin;
assign o_Cout = (i_A & i_B) | (i_Cin & (i_A ^ i_B));

endmodule // Full_adder


