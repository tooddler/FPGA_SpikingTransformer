/*
    --- Organize Data From SpikingEncoder module --- 
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "E:/Desktop/Zynq_Spikformer/Zynq_Spikformer.srcs/sources_1/hyper_para.v"
module Organize_data_unit (
    input                                           s_clk                     ,
    input                                           s_rst                     ,
    // get spikes from SpikingEncoder module
    input                                           SpikingEncoder_out_done   ,
    input         [`TIME_STEPS - 1 : 0]             SpikingEncoder_out        ,
    input                                           SpikingEncoder_out_valid  ,
    // interact with Tmp-BRAM
    output  reg                                     o_line_data_valid=0       ,
    output  wire  [`IMG_WIDTH*`TIME_STEPS - 1 : 0]  o_line_data                           
);

reg [`IMG_WIDTH*`TIME_STEPS - 1 : 0]    spikes_register ;
reg [9:0]                               r_ifmap_cnt     ;

assign o_line_data = spikes_register;

// spikes_register
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        spikes_register <= 'd0;
    else if (SpikingEncoder_out_valid)
        spikes_register <= {SpikingEncoder_out, spikes_register[`TIME_STEPS*`IMG_WIDTH - 1 : `TIME_STEPS]};
end

// r_ifmap_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_ifmap_cnt <= 'd0;
    else if (r_ifmap_cnt == `IMG_WIDTH - 1 && SpikingEncoder_out_valid)
        r_ifmap_cnt <= 'd0;
    else if (SpikingEncoder_out_valid)
        r_ifmap_cnt <= r_ifmap_cnt + 1'b1;
end

// o_line_data_valid
always@(posedge s_clk) begin
    if (r_ifmap_cnt == `IMG_WIDTH - 1 && SpikingEncoder_out_valid)
        o_line_data_valid <= 1'b1;
    else
        o_line_data_valid <= 1'b0;
end

endmodule // Organize_data_unit


