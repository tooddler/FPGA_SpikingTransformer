/*
    -- Attention-Calculate PE --
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "E:/Desktop/spiking_transformer/spiking_transformer/spiking_transformer.srcs/sources_1/imports/FPGA_SpikingTransformer/hyper_para.v"
module Attention_PE (
    input                                                               s_clk               ,
    input                                                               s_rst               ,
    // Spikes-in
    input                                                               i_Spikesdata_valid  ,
    input      [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]               i_SpikesdataQuery   ,
    input      [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]               i_SpikesdataKey     ,   
    // out
    output wire[$clog2(2*`SYSTOLIC_UNIT_NUM)*`TIME_STEPS - 1 : 0]       o_Calc_data         ,
    output wire                                                         o_Calc_valid  
);

wire [`SYSTOLIC_UNIT_NUM*2 - 1 : 0]                 w_alignSpikes_t0     ;
wire [`SYSTOLIC_UNIT_NUM*2 - 1 : 0]                 w_alignSpikes_t1     ;
wire [`SYSTOLIC_UNIT_NUM*2 - 1 : 0]                 w_alignSpikes_t2     ;
wire [`SYSTOLIC_UNIT_NUM*2 - 1 : 0]                 w_alignSpikes_t3     ;

reg  [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]     r_SpikesMulti=0      ;
reg                                                 r_Spikesdata_valid=0 ;

genvar m;
generate
    for (m = 0; m < `SYSTOLIC_UNIT_NUM*2; m = m + 1) begin
        assign w_alignSpikes_t0[m] = r_SpikesMulti[`TIME_STEPS * m + 0]; 
        assign w_alignSpikes_t1[m] = r_SpikesMulti[`TIME_STEPS * m + 1];
        assign w_alignSpikes_t2[m] = r_SpikesMulti[`TIME_STEPS * m + 2];
        assign w_alignSpikes_t3[m] = r_SpikesMulti[`TIME_STEPS * m + 3];
    end
endgenerate

always@(posedge s_clk) begin
    r_Spikesdata_valid <= i_Spikesdata_valid;

    if (i_Spikesdata_valid)
        r_SpikesMulti <= i_SpikesdataQuery & i_SpikesdataKey;
    else 
        r_SpikesMulti <= r_SpikesMulti;
end

PipelineAdder u_PipelineAdder_m00(
    .s_clk               ( s_clk                                                ),
    .s_rst               ( s_rst                                                ),
    .i_Spikesdata        ( w_alignSpikes_t0                                     ),
    .i_Spikesdata_valid  ( r_Spikesdata_valid                                   ),
    .o_SpikeSum          ( o_Calc_data[$clog2(2*`SYSTOLIC_UNIT_NUM) - 1 : 0]    ),
    .o_SpikeSum_valid    ( o_Calc_valid                                         )
);

PipelineAdder u_PipelineAdder_m01(
    .s_clk               ( s_clk                                                ),
    .s_rst               ( s_rst                                                ),
    .i_Spikesdata        ( w_alignSpikes_t1                                     ),
    .i_Spikesdata_valid  ( r_Spikesdata_valid                                   ),
    .o_SpikeSum          ( o_Calc_data[$clog2(2*`SYSTOLIC_UNIT_NUM)*2 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)] ),
    .o_SpikeSum_valid    ( )
);

PipelineAdder u_PipelineAdder_m02(
    .s_clk               ( s_clk                                                ),
    .s_rst               ( s_rst                                                ),
    .i_Spikesdata        ( w_alignSpikes_t2                                     ),
    .i_Spikesdata_valid  ( r_Spikesdata_valid                                   ),
    .o_SpikeSum          ( o_Calc_data[$clog2(2*`SYSTOLIC_UNIT_NUM)*3 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*2]),
    .o_SpikeSum_valid    ( )
);

PipelineAdder u_PipelineAdder_m03(
    .s_clk               ( s_clk                                                ),
    .s_rst               ( s_rst                                                ),
    .i_Spikesdata        ( w_alignSpikes_t3                                     ),
    .i_Spikesdata_valid  ( r_Spikesdata_valid                                   ),
    .o_SpikeSum          ( o_Calc_data[$clog2(2*`SYSTOLIC_UNIT_NUM)*4 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*3]),
    .o_SpikeSum_valid    ( )
);


endmodule // Attention_PE


