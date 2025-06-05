/*
    - Maxpool Unit - :
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "E:/Desktop/Zynq_Spikformer/Zynq_Spikformer.srcs/sources_1/hyper_para.v"
module simple_maxpool_row_unit (
    input                                                 s_clk               ,
    input                                                 s_rst               ,
    // -- code
    input                                                 code_valid          ,
    input       [15:0]                                    conv_in_ch          ,
    input       [15:0]                                    conv_img_size       ,
    // -- ifmap in --
    input                                                 i_row_data_valid    ,
    input       [`IMG_WIDTH*`TIME_STEPS - 1 : 0]          i_row_data          ,
    // -- pooling out --
    output reg                                            o_calculating_flag  ,
    output reg                                            o_pooling_valid=0   ,
    output reg  [`IMG_WIDTH*`TIME_STEPS - 1 : 0]          o_pooling_data      
);

wire [`TIME_STEPS - 1 : 0]                                w_and_Tmp_ans       ;

reg  [`TIME_STEPS*(`IMG_WIDTH + 1) - 1 : 0]               r_row_data          ;
reg  [5:0]                                                r_row_cnt           ;
reg  [15:0]                                               r_conv_img_size     ;
reg                                                       r_cal_flag_d0       ;

assign w_and_Tmp_ans = r_row_data[`TIME_STEPS - 1 : 0] | r_row_data[`TIME_STEPS*2 - 1 : `TIME_STEPS] | r_row_data[`TIME_STEPS*3 - 1 : `TIME_STEPS*2];

// --------------- code fetch --------------- \\ 
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_conv_img_size <= 'd0;
    else if (code_valid)
        r_conv_img_size <= conv_img_size;
end

// --------------- main code --------------- \\ 
// r_row_data
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) 
        r_row_data <= 'd0;
    else if ((|r_row_cnt))
        r_row_data <= r_row_data >> (`TIME_STEPS * 2);
    else if (i_row_data_valid)
        r_row_data <= {i_row_data, {(`TIME_STEPS){1'b0}}};
end

// r_row_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) 
        r_row_cnt <= 'd0;
    else if (r_row_cnt == r_conv_img_size - 2)
        r_row_cnt <= 'd0;
    else if (i_row_data_valid || (|r_row_cnt))
        r_row_cnt <= r_row_cnt + 'd2;
end

genvar k;
generate
    // o_pooling_data
    always@(posedge s_clk, posedge s_rst) begin
        if (s_rst)
            o_pooling_data[`TIME_STEPS - 1 : 0] <= 'd0;
        else if (r_row_cnt == 'd2)
            o_pooling_data[`TIME_STEPS - 1 : 0] <= w_and_Tmp_ans;
    end

    for (k = 1; k < `IMG_WIDTH; k = k + 1) begin :  mp_spikes_register_array

        always@(posedge s_clk, posedge s_rst) begin
            if (s_rst)
                o_pooling_data[(k+1)*`TIME_STEPS - 1 : k*`TIME_STEPS] <= 'd0;
            else if (r_cal_flag_d0 && ~o_calculating_flag)
                o_pooling_data[(k+1)*`TIME_STEPS - 1 : k*`TIME_STEPS] <= 'd0;
            else if (r_row_cnt == 2*k+2)
                o_pooling_data[(k+1)*`TIME_STEPS - 1 : k*`TIME_STEPS] <= w_and_Tmp_ans;
        end 

    end

endgenerate

// o_pooling_valid
always@(posedge s_clk) begin
    if (r_row_cnt == r_conv_img_size - 2)
        o_pooling_valid <= 1'b1;
    else
        o_pooling_valid <= 1'b0;
end

// o_calculating_flag
always@(posedge s_clk) begin
    r_cal_flag_d0 <= o_calculating_flag;

    if (|r_row_cnt)
        o_calculating_flag <= 1'b1;
    else
        o_calculating_flag <= 1'b0;
end

endmodule // simple_maxpool_row_unit


