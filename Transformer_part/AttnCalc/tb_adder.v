/*
    --- Full Adder Group TB --- 
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "E:/Desktop/spiking_transformer/spiking_transformer/spiking_transformer.srcs/sources_1/imports/FPGA_SpikingTransformer/hyper_para.v"
module tb_adder ();
reg                 s_clk  ;
reg                 s_rst  ;
reg [32 - 1 : 0]    i_Spikesdata ;
reg                 i_Spikesdata_valid;

wire  [5 - 1 : 0]   o_SpikeSum        ;
wire                o_SpikeSum_valid  ;

initial s_clk = 1'b1;
always #(`CLK_PERIOD/2) s_clk = ~s_clk;

initial begin
    s_rst = 1'b1;
    i_Spikesdata = 0;
    i_Spikesdata_valid = 0;
    # 201;
    s_rst = 1'b0;
    # `CLK_PERIOD
    i_Spikesdata_valid = 1;
    i_Spikesdata = 32'b0111_1100_0111_1100_0111_1100;
    # `CLK_PERIOD
    i_Spikesdata = 32'b1111_1111_1111_1111_1111_1111;
    # `CLK_PERIOD 
    i_Spikesdata = 32'b0111_0011;
    # `CLK_PERIOD 
    i_Spikesdata = 32'b0000_1111;
    # `CLK_PERIOD
    i_Spikesdata_valid = 0;
    # 200
    $stop; 
end

// FullAdder_Group u_FullAdder_Group(
//     .i_Spikesdata  ( i_Spikesdata  ),
//     .o_Sum         ( o_Sum         )
// );

PipelineAdder u_PipelineAdder(
    .s_clk               ( s_clk               ),
    .s_rst               ( s_rst               ),
    .i_Spikesdata        ( i_Spikesdata        ),
    .i_Spikesdata_valid  ( i_Spikesdata_valid  ),
    .o_SpikeSum          ( o_SpikeSum          ),
    .o_SpikeSum_valid    ( o_SpikeSum_valid    )
);

endmodule // tb_adder


