`timescale 1ns / 1ps

`include "E:/Desktop/Zynq_Spikformer/Zynq_Spikformer.srcs/sources_1/hyper_para.v"
module fifo_sim ();

reg               s_clk  ;
reg               s_rst  ;   

reg  [63:0]       din    ;
reg               wr_en  ;
reg               rd_en  ;

wire [7:0]        dout   ;

initial s_clk = 1'b1;
always #(`CLK_PERIOD/2) s_clk = ~s_clk;

initial begin
    s_rst = 1'b1;
    din   = 64'h1234_5678;
    wr_en = 'd0;
    rd_en = 'd0;
    # 201;
    s_rst = 1'b0;
    # 400;
    repeat(10) begin
        #(`CLK_PERIOD)
        wr_en = 1'b1;
    end
    #(`CLK_PERIOD)
    wr_en = 'd0;
    #(`CLK_PERIOD)
    repeat(8) begin
        #(`CLK_PERIOD)
        rd_en = 1'b1;
    end
    #(`CLK_PERIOD)
    rd_en = 1'b0;
    # 100
    repeat(16) begin
        #(`CLK_PERIOD)
        rd_en = 1'b1;
    end
    #(`CLK_PERIOD)
    rd_en = 1'b0;
    # 100
    $stop;
end

Mtrx_slice_fifo u_Mtrx_slice_fifo(
    .clk            ( s_clk         ),
    .srst           ( s_rst         ),
    .din            ( din           ),
    .wr_en          ( wr_en         ),
    .rd_en          ( rd_en         ),
    .dout           ( dout          ),
    .full           ( full          ),
    .empty          ( empty         )
);


endmodule


