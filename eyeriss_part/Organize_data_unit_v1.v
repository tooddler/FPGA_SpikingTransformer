/*
    --- Organize Data --- 
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "E:/Desktop/Zynq_Spikformer/Zynq_Spikformer.srcs/sources_1/hyper_para.v"
module Organize_data_unit_v1 (
    input                                           s_clk                     ,
    input                                           s_rst                     ,

    input                                           code_valid                ,
    input         [15:0]                            conv_img_size             ,
    // get spikes 
    input         [`TIME_STEPS - 1 : 0]             i_spikes_in               ,
    input                                           i_spikes_in_valid         ,
    // interact with Tmp-BRAM
    output  reg                                     o_line_data_valid=0       ,
    output  wire  [`IMG_WIDTH*`TIME_STEPS - 1 : 0]  o_line_data                           
);

reg [`IMG_WIDTH*`TIME_STEPS - 1 : 0]    spikes_register ;
reg [9:0]                               r_ifmap_cnt     ;
reg [15:0]                              r_conv_img_size ;

assign o_line_data = spikes_register;

// r_conv_img_size
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_conv_img_size <= 'd0;
    else if (code_valid)
        r_conv_img_size <= conv_img_size;
end

genvar k;
generate

    // spikes_register
    always@(posedge s_clk, posedge s_rst) begin
        if (s_rst)
            spikes_register[`TIME_STEPS - 1 : 0] <= 'd0;
        else if (i_spikes_in_valid && r_ifmap_cnt == 'd0)
            spikes_register[`TIME_STEPS - 1 : 0] <= i_spikes_in;
    end

    for (k = 1; k < `IMG_WIDTH; k = k + 1) begin :  spikes_register_array

        always@(posedge s_clk, posedge s_rst) begin
            if (s_rst)
                spikes_register[(k+1)*`TIME_STEPS - 1 : k*`TIME_STEPS] <= 'd0;
            else if (i_spikes_in_valid && r_ifmap_cnt == 'd0)
                spikes_register[(k+1)*`TIME_STEPS - 1 : k*`TIME_STEPS] <= 'd0;
            else if (i_spikes_in_valid && r_ifmap_cnt == k)
                spikes_register[(k+1)*`TIME_STEPS - 1 : k*`TIME_STEPS] <= i_spikes_in;
        end

    end

endgenerate


// r_ifmap_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_ifmap_cnt <= 'd0;
    else if (r_ifmap_cnt == r_conv_img_size - 3 && i_spikes_in_valid)
        r_ifmap_cnt <= 'd0;
    else if (i_spikes_in_valid)
        r_ifmap_cnt <= r_ifmap_cnt + 1'b1;
end

// o_line_data_valid
always@(posedge s_clk) begin
    if (r_ifmap_cnt == r_conv_img_size - 3 && i_spikes_in_valid)
        o_line_data_valid <= 1'b1;
    else
        o_line_data_valid <= 1'b0;
end

endmodule // Organize_data_unit_v1


