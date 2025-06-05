/*
    FullAdder ->|ff |-> AdderTree(pipeline=2)
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
    FUNC    : the nums of "1" in 32 bit data, pipeline = 3
*/

`include "E:/Desktop/Zynq_Spikformer/Zynq_Spikformer.srcs/sources_1/hyper_para.v"
module PipelineAdder (
    input                                                     s_clk               ,
    input                                                     s_rst               ,    
    input        [32 - 1 : 0]                                 i_Spikesdata        ,
    input                                                     i_Spikesdata_valid  ,
    output  wire [5 - 1 : 0]                                  o_SpikeSum          ,
    output  wire                                              o_SpikeSum_valid       
);

wire [15 : 0]               w_TmpSum    ;

reg  [15 : 0]               r_TmpSum=0  ;
reg  [2 : 0]                r_TmpValid  ;

assign o_SpikeSum_valid = r_TmpValid[2];

genvar k;
generate
    for (k = 0; k < 4; k = k + 1) begin: FullAdder_Group
        FullAdder_Group u_FullAdder_Group(
            .i_Spikesdata  ( i_Spikesdata[8*(k+1) - 1 : 8*k]  ),
            .o_Sum         ( w_TmpSum[4*(k+1) - 1 : 4*k]      )
        );
    end
endgenerate

always@(posedge s_clk) begin
    r_TmpSum <= w_TmpSum;

    r_TmpValid <= {r_TmpValid[1 : 0], i_Spikesdata_valid};
end

AddTreeUnsigned #(
    .INPUTS_NUM     ( 4              ),
    .IDATA_WIDTH    ( 4              )
) u_AddTreeUnsigned(
    .sclk           ( s_clk          ),
    .s_rst_n        ( ~s_rst         ),
    .idata          ( r_TmpSum       ),
    .data_out       ( o_SpikeSum     )
);

endmodule // PipelineAdder


