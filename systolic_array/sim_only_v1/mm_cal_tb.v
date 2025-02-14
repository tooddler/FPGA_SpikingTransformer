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

wire [15 : 0]                               w_MtrxA_cnt       ;
wire [15 : 0]                               w_MtrxB_cnt       ;

wire [`ADDR_SIZE - 1 : 0]                   w_MtrxA_addr      ;
wire [`ADDR_SIZE - 1 : 0]                   w_MtrxB_addr      ;

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

assign w_MtrxA_cnt  = u_data_gen.r_MtrxA_cnt ;
assign w_MtrxB_cnt  = u_data_gen.r_MtrxB_cnt ;

assign w_MtrxA_addr = u_data_gen.r_MtrxA_addr;
assign w_MtrxB_addr = u_data_gen.r_MtrxB_addr;

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
    .MtrxC_slice_ready  ( )
);

endmodule //mm_cal_tb

