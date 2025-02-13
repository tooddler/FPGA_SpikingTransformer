`timescale 1ns / 1ps

`include "../../hyper_para.v"
module mm_cal_tb ();

reg         s_clk  ;
reg         s_rst  ;

wire                                        MtrxA_slice_valid ;
wire  [`SYSTOLIC_DATA_WIDTH - 1 : 0]        MtrxA_slice_data  ;
wire                                        MtrxA_slice_done  ;
wire                                        MtrxA_slice_ready ;
wire                                        MtrxB_slice_valid ;
wire  [`SYSTOLIC_DATA_WIDTH - 1 : 0]        MtrxB_slice_data  ;
wire                                        MtrxB_slice_done  ;
wire                                        MtrxB_slice_ready ;

initial s_clk = 1'b1;
always #(`CLK_PERIOD/2) s_clk = ~s_clk;

initial begin
    s_rst = 1'b1;
    # 201;
    s_rst = 1'b0;
    # 400;
    # 4000;
//    $stop;
end

data_gen u_data_gen(
    .s_clk              ( s_clk              ),
    .s_rst              ( s_rst              ),

    .MtrxA_slice_valid  ( MtrxA_slice_valid  ),
    .MtrxA_slice_data   ( MtrxA_slice_data   ),
    .MtrxA_slice_done   ( MtrxA_slice_done   ),
    .MtrxA_slice_ready  ( MtrxA_slice_ready  ),

    .MtrxB_slice_valid  ( MtrxB_slice_valid  ),
    .MtrxB_slice_data   ( MtrxB_slice_data   ),
    .MtrxB_slice_done   ( MtrxB_slice_done   ),
    .MtrxB_slice_ready  ( MtrxB_slice_ready  )
);

SystolicArray_v1 u_SystolicArray_v1(
    .s_clk              ( s_clk              ),
    .s_rst              ( s_rst              ),

    .MtrxA_slice_valid  ( MtrxA_slice_valid  ),
    .MtrxA_slice_data   ( MtrxA_slice_data   ),
    .MtrxA_slice_done   ( MtrxA_slice_done   ),
    .MtrxA_slice_ready  ( MtrxA_slice_ready  ),
    
    .MtrxB_slice_valid  ( MtrxB_slice_valid  ),
    .MtrxB_slice_data   ( MtrxB_slice_data   ),
    .MtrxB_slice_done   ( MtrxB_slice_done   ),
    .MtrxB_slice_ready  ( MtrxB_slice_ready  ),
    
    .MtrxC_slice_valid  ( ),
    .MtrxC_slice_data   ( ),
    .MtrxC_slice_done   ( ),
    .MtrxC_slice_ready  ('d0)
);


endmodule //mm_cal_tb

