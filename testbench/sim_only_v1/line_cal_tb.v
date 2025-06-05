`timescale 1ns / 1ps

`include "E:/Desktop/Zynq_Spikformer/Zynq_Spikformer.srcs/sources_1/hyper_para.v"
module line_cal_tb ();

reg         s_clk  ;
reg         s_rst  ;    
reg                                     r_weight_valid ;
reg [`SYSTOLIC_DATA_WIDTH - 1 : 0]      r_weight00     ;
reg [`SYSTOLIC_DATA_WIDTH - 1 : 0]      r_weight01     ;
reg [`SYSTOLIC_DATA_WIDTH - 1 : 0]      r_weight10     ;
reg [`SYSTOLIC_DATA_WIDTH - 1 : 0]      r_weight11     ;

reg                                     in00_data_valid ;
reg [`SYSTOLIC_DATA_WIDTH - 1 : 0]      in00_raw_data   ;
reg                                     in10_data_valid ;
reg [`SYSTOLIC_DATA_WIDTH - 1 : 0]      in10_raw_data   ;

wire                                    out00_data_valid ;
wire                                    out01_data_valid ;
wire                                    out10_data_valid ;
wire                                    out11_data_valid ;

wire [`SYSTOLIC_DATA_WIDTH - 1 : 0]     out00_raw_data   ;
wire [`SYSTOLIC_DATA_WIDTH - 1 : 0]     out01_raw_data   ;
wire [`SYSTOLIC_DATA_WIDTH - 1 : 0]     out10_raw_data   ;
wire [`SYSTOLIC_DATA_WIDTH - 1 : 0]     out11_raw_data   ;

wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]     out00_psum_data  ;   
wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]     out01_psum_data  ;   
wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]     out10_psum_data  ;   
wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]     out11_psum_data  ;   

initial s_clk = 1'b1;
always #(`CLK_PERIOD/2) s_clk = ~s_clk;

initial begin
    r_weight00 = 'd1;
    r_weight01 = 'd2;
    r_weight10 = 'd3;
    r_weight11 = 'd4;
    s_rst = 1'b1;
    r_weight_valid = 1'b0;
    in00_data_valid = 'd0;
    in00_raw_data   = 'd0;
    in10_data_valid = 'd0;
    in10_raw_data   = 'd0;
    # 201;
    s_rst = 1'b0;
    # 400;
    r_weight_valid = 1'b1;
    # (`CLK_PERIOD)
    r_weight_valid = 1'b0;
    # 100;
    in00_data_valid = 1'b1;
    in00_raw_data   = 'd1;
    # (`CLK_PERIOD)
    in00_data_valid = 1'b0;
    in10_data_valid = 1'b1;
    in10_raw_data   = 'd2;
    # (`CLK_PERIOD)
    in00_data_valid = 1'b0;
    in10_data_valid = 1'b0;
    # 300
    $stop;
end

Systolic_pe_v1 pe00(
    .s_clk           ( s_clk           ),
    .s_rst           ( s_rst           ),

    .weight_valid    ( r_weight_valid      ),
    .weights         ( r_weight00          ),

    .in_data_valid   ( in00_data_valid | out00_data_valid ),
    .in_raw_data     ( in00_raw_data       ),
    .out_data_valid  ( out00_data_valid    ),
    .out_raw_data    ( out00_raw_data      ),

    .in_psum_data    ( 'd0                 ),
    .out_psum_data   ( out00_psum_data     )
);

Systolic_pe_v1 pe01(
    .s_clk           ( s_clk           ),
    .s_rst           ( s_rst           ),

    .weight_valid    ( r_weight_valid      ),
    .weights         ( r_weight01          ),

    .in_data_valid   ( out00_data_valid    ),
    .in_raw_data     ( out00_raw_data      ),
    .out_data_valid  ( out01_data_valid    ),
    .out_raw_data    ( out01_raw_data      ),

    .in_psum_data    ( 'd0                 ),
    .out_psum_data   ( out01_psum_data     )
);

Systolic_pe_v1 pe10(
    .s_clk           ( s_clk           ),
    .s_rst           ( s_rst           ),

    .weight_valid    ( r_weight_valid      ),
    .weights         ( r_weight10          ),

    .in_data_valid   ( in10_data_valid | out10_data_valid ),
    .in_raw_data     ( in10_raw_data       ),
    .out_data_valid  ( out10_data_valid    ),
    .out_raw_data    ( out10_raw_data      ),

    .in_psum_data    ( out00_psum_data     ),
    .out_psum_data   ( out10_psum_data     )
);

Systolic_pe_v1 pe11(
    .s_clk           ( s_clk           ),
    .s_rst           ( s_rst           ),

    .weight_valid    ( r_weight_valid      ),
    .weights         ( r_weight11          ),

    .in_data_valid   ( out10_data_valid    ),
    .in_raw_data     ( out10_raw_data      ),
    .out_data_valid  ( out11_data_valid    ),
    .out_raw_data    ( out11_raw_data      ),

    .in_psum_data    ( out01_psum_data     ),
    .out_psum_data   ( out11_psum_data     )
);

endmodule //line_cal_tb


