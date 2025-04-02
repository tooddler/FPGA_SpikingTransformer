/*
    --- qkv lienar layer TOP --- 
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "../hyper_para.v"
module TOP_qkv_linearCalc (
    input                                                       s_clk                ,
    input                                                       s_rst                , 
    // get fmaps and patch
    input                                                       i_data_valid         ,
    input       [`PATCH_EMBED_WIDTH - 1 : 0]                    i_fmap               ,
    input       [`PATCH_EMBED_WIDTH - 1 : 0]                    i_patchdata          ,
    // interact with ddr
    // - query
    input           [`DATA_WIDTH- 1 : 0]                        M_lq_rd_burst_data   ,
    output wire     [`ADDR_SIZE - 1 : 0]                        M_lq_rd_burst_addr   ,
    output wire     [`LEN_WIDTH - 1 : 0]                        M_lq_rd_burst_len    ,
    output wire                                                 M_lq_rd_burst_req    ,
    input                                                       M_lq_rd_burst_valid  ,
    input                                                       M_lq_rd_burst_finish ,
    // - key
    input           [`DATA_WIDTH- 1 : 0]                        M_lk_rd_burst_data   ,
    output wire     [`ADDR_SIZE - 1 : 0]                        M_lk_rd_burst_addr   ,
    output wire     [`LEN_WIDTH - 1 : 0]                        M_lk_rd_burst_len    ,
    output wire                                                 M_lk_rd_burst_req    ,
    input                                                       M_lk_rd_burst_valid  ,
    input                                                       M_lk_rd_burst_finish ,
    // - value
    input           [`DATA_WIDTH- 1 : 0]                        M_lv_rd_burst_data   ,
    output wire     [`ADDR_SIZE - 1 : 0]                        M_lv_rd_burst_addr   ,
    output wire     [`LEN_WIDTH - 1 : 0]                        M_lv_rd_burst_len    ,
    output wire                                                 M_lv_rd_burst_req    ,
    input                                                       M_lv_rd_burst_valid  ,
    input                                                       M_lv_rd_burst_finish ,
    // output SpikesArray
    output wire [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]      o00_spikesLine_out   ,
    output wire                                                 o00_spikesLine_valid ,
    output wire [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]      o01_spikesLine_out   ,
    output wire                                                 o01_spikesLine_valid ,
    output wire [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]      o02_spikesLine_out   ,
    output wire                                                 o02_spikesLine_valid  
);

wire     [11 : 0]                                    w_rd_addr               ;
wire     [`PATCH_EMBED_WIDTH * 2 - 1 : 0]            w_ramout_data           ;
wire                                                 w_ramout_ready          ;

wire     [`DATA_WIDTH - 1 : 0]                       w_lq_weight_out         ;
wire                                                 w_lq_weight_valid       ;
wire                                                 w_lq_weight_ready       ;
wire                                                 lq_load_w_finish        ;

wire     [`DATA_WIDTH - 1 : 0]                       w_lk_weight_out         ;
wire                                                 w_lk_weight_valid       ;
wire                                                 w_lk_weight_ready       ;
wire                                                 lk_load_w_finish        ;

wire     [`DATA_WIDTH - 1 : 0]                       w_lv_weight_out         ;
wire                                                 w_lv_weight_valid       ;
wire                                                 w_lv_weight_ready       ;
wire                                                 lv_load_w_finish        ;

wire                                                 m00_MtrxA_slice_valid   ;
wire  [`DATA_WIDTH - 1 : 0]                          m00_MtrxA_slice_data    ;
wire                                                 m00_MtrxA_slice_done    ;
wire                                                 m00_MtrxA_slice_ready   ;
wire                                                 m00_MtrxB_slice_valid   ;
wire  [`DATA_WIDTH - 1 : 0]                          m00_MtrxB_slice_data    ;
wire                                                 m00_MtrxB_slice_done    ;
wire                                                 m00_MtrxB_slice_ready   ;

wire                                                 s00_MtrxA_slice_valid   ;
wire  [`DATA_WIDTH - 1 : 0]                          s00_MtrxA_slice_data    ;
wire                                                 s00_MtrxA_slice_done    ;
wire                                                 s00_MtrxA_slice_ready   ;
wire                                                 s00_MtrxB_slice_valid   ;
wire  [`DATA_WIDTH - 1 : 0]                          s00_MtrxB_slice_data    ;
wire                                                 s00_MtrxB_slice_done    ;
wire                                                 s00_MtrxB_slice_ready   ;

wire                                                 s01_MtrxA_slice_valid   ;
wire  [`DATA_WIDTH - 1 : 0]                          s01_MtrxA_slice_data    ;
wire                                                 s01_MtrxA_slice_done    ;
wire                                                 s01_MtrxA_slice_ready   ;
wire                                                 s01_MtrxB_slice_valid   ;
wire  [`DATA_WIDTH - 1 : 0]                          s01_MtrxB_slice_data    ;
wire                                                 s01_MtrxB_slice_done    ;
wire                                                 s01_MtrxB_slice_ready   ;

wire                                                 w_lq_Init_PrepareData   ;
wire                                                 w_lq_Finish_Calc        ;
wire                                                 w_lk_Init_PrepareData   ;
wire                                                 w_lk_Finish_Calc        ;
wire                                                 w_lv_Init_PrepareData   ;
wire                                                 w_lv_Finish_Calc        ;

wire [`SYSTOLIC_UNIT_NUM - 1 : 0]                    w_lq_PsumFIFO_Grant     ;
wire                                                 w_lq_PsumFIFO_Valid     ;
wire                                                 w_lq_PsumFIFO_Finish    ;
wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                  w_lq_PsumFIFO_Data      ;
wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                  w_lq_PsumData           ;
wire                                                 w_lq_PsumValid          ;
wire [`SYSTOLIC_UNIT_NUM - 1 : 0]                    w_lk_PsumFIFO_Grant     ;
wire                                                 w_lk_PsumFIFO_Valid     ;
wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                  w_lk_PsumFIFO_Data      ;
wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                  w_lk_PsumData           ;
wire                                                 w_lk_PsumValid          ;
wire [`SYSTOLIC_UNIT_NUM - 1 : 0]                    w_lv_PsumFIFO_Grant     ;
wire                                                 w_lv_PsumFIFO_Valid     ;
wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                  w_lv_PsumFIFO_Data      ;
wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                  w_lv_PsumData           ;
wire                                                 w_lv_PsumValid          ;

wire [`TIME_STEPS - 1 : 0]                           w_lq_spikes_out         ;
wire                                                 w_lq_spikes_valid       ;
wire [`TIME_STEPS - 1 : 0]                           w_lk_spikes_out         ;
wire                                                 w_lk_spikes_valid       ;
wire [`TIME_STEPS - 1 : 0]                           w_lv_spikes_out         ;
wire                                                 w_lv_spikes_valid       ;

// --------------- Patch Embed --------------- \\ 
PatchEmbed u_PatchEmbed (
    .s_clk                  ( s_clk             ),
    .s_rst                  ( s_rst             ),
    .i_data_valid           ( i_data_valid      ),
    .i_fmap                 ( i_fmap            ),
    .i_patchdata            ( i_patchdata       ),

    .i_rd_addr              ( w_rd_addr         ),
    .o_ramout_data          ( w_ramout_data     ),
    .o_ramout_ready         ( w_ramout_ready    )
);

// --------------- Weights Loader --------------- \\ 
weight_fifo_v1 #(
    .WEIGHTS_BASEADDR       ( `WEIGHTS_Q_BASEADDR  )
) u_weight_fifo_linear_Q(
    .s_clk                  ( s_clk                ),
    .s_rst                  ( s_rst                ),

    .rd_burst_data          ( M_lq_rd_burst_data   ),
    .rd_burst_addr          ( M_lq_rd_burst_addr   ),
    .rd_burst_len           ( M_lq_rd_burst_len    ),
    .rd_burst_req           ( M_lq_rd_burst_req    ),
    .rd_burst_valid         ( M_lq_rd_burst_valid  ),
    .rd_burst_finish        ( M_lq_rd_burst_finish ),

    .o_weight_out           ( w_lq_weight_out      ),
    .i_weight_valid         ( w_lq_weight_valid    ),
    .o_weight_ready         ( w_lq_weight_ready    ),
    .load_w_finish          ( lq_load_w_finish     )
);

weight_fifo_v1 #(
    .WEIGHTS_BASEADDR       ( `WEIGHTS_K_BASEADDR  )
) u_weight_fifo_linear_K(
    .s_clk                  ( s_clk                ),
    .s_rst                  ( s_rst                ),

    .rd_burst_data          ( M_lk_rd_burst_data   ),
    .rd_burst_addr          ( M_lk_rd_burst_addr   ),
    .rd_burst_len           ( M_lk_rd_burst_len    ),
    .rd_burst_req           ( M_lk_rd_burst_req    ),
    .rd_burst_valid         ( M_lk_rd_burst_valid  ),
    .rd_burst_finish        ( M_lk_rd_burst_finish ),

    .o_weight_out           ( w_lk_weight_out      ),
    .i_weight_valid         ( w_lk_weight_valid    ),
    .o_weight_ready         ( w_lk_weight_ready    ),
    .load_w_finish          ( lk_load_w_finish     )
);

weight_fifo_v1 #(
    .WEIGHTS_BASEADDR       ( `WEIGHTS_V_BASEADDR  )
) u_weight_fifo_linear_V(
    .s_clk                  ( s_clk                ),
    .s_rst                  ( s_rst                ),

    .rd_burst_data          ( M_lv_rd_burst_data   ),
    .rd_burst_addr          ( M_lv_rd_burst_addr   ),
    .rd_burst_len           ( M_lv_rd_burst_len    ),
    .rd_burst_req           ( M_lv_rd_burst_req    ),
    .rd_burst_valid         ( M_lv_rd_burst_valid  ),
    .rd_burst_finish        ( M_lv_rd_burst_finish ),

    .o_weight_out           ( w_lv_weight_out      ),
    .i_weight_valid         ( w_lv_weight_valid    ),
    .o_weight_ready         ( w_lv_weight_ready    ),
    .load_w_finish          ( lv_load_w_finish     )
);

// ---------------  Systolic Controller --------------- \\ 
SystolicController u_SystolicController_Master_Q(
    .s_clk               ( s_clk                    ),
    .s_rst               ( s_rst                    ),

    .o_rd_addr           ( w_rd_addr                ),
    .i_ramout_data       ( w_ramout_data            ),
    .i_ramout_ready      ( w_ramout_ready           ),

    .i_weight_out        ( w_lq_weight_out          ),
    .o_weight_valid      ( w_lq_weight_valid        ),
    .i_weight_ready      ( w_lq_weight_ready        ),
    .load_w_finish       ( lq_load_w_finish         ),

    .o_Init_PrepareData  ( w_lq_Init_PrepareData    ),
    .i_Finish_Calc       ( w_lq_Finish_Calc         ),

    .MtrxA_slice_valid   ( m00_MtrxA_slice_valid    ),
    .MtrxA_slice_data    ( m00_MtrxA_slice_data     ),
    .MtrxA_slice_done    ( m00_MtrxA_slice_done     ),
    .MtrxA_slice_ready   ( m00_MtrxA_slice_ready    ),
    .MtrxB_slice_valid   ( m00_MtrxB_slice_valid    ),
    .MtrxB_slice_data    ( m00_MtrxB_slice_data     ),
    .MtrxB_slice_done    ( m00_MtrxB_slice_done     ),
    .MtrxB_slice_ready   ( m00_MtrxB_slice_ready    ),

    .o_PsumFIFO_Grant    ( w_lq_PsumFIFO_Grant      ),
    .o_PsumFIFO_Valid    ( w_lq_PsumFIFO_Valid      ),
    .i_PsumFIFO_Data     ( w_lq_PsumFIFO_Data       ),

    .o_Psum_Finish       ( w_lq_PsumFIFO_Finish     ),
    .o_PsumData          ( w_lq_PsumData            ),
    .o_PsumValid         ( w_lq_PsumValid           )
);

SystolicController_Slave#(
    .CALC_LINEAR_K       ( 0                       ) // CALC_LINEAR_K == 0 Calc K Mtrx else Calc V Mtrx
) u_SystolicController_Slave_K(
    .s_clk               ( s_clk                   ),
    .s_rst               ( s_rst                   ),

    .i_MasterSend_valid  ( m00_MtrxA_slice_valid   ), // FROM Master-Controller
    .i_MasterSend_data   ( m00_MtrxA_slice_data    ),
    .i_MasterSend_done   ( m00_MtrxA_slice_done    ),

    .i_weight_out        ( w_lk_weight_out         ),
    .o_weight_valid      ( w_lk_weight_valid       ),
    .i_weight_ready      ( w_lk_weight_ready       ),
    .load_w_finish       ( lk_load_w_finish        ),

    .o_Init_PrepareData  ( w_lk_Init_PrepareData   ),
    .i_Finish_Calc       ( w_lk_Finish_Calc        ),

    .MtrxA_slice_valid   ( s00_MtrxA_slice_valid   ),
    .MtrxA_slice_data    ( s00_MtrxA_slice_data    ),
    .MtrxA_slice_done    ( s00_MtrxA_slice_done    ),
    .MtrxA_slice_ready   ( s00_MtrxA_slice_ready   ),
    .MtrxB_slice_valid   ( s00_MtrxB_slice_valid   ),
    .MtrxB_slice_data    ( s00_MtrxB_slice_data    ),
    .MtrxB_slice_done    ( s00_MtrxB_slice_done    ),
    .MtrxB_slice_ready   ( s00_MtrxB_slice_ready   ),

    .o_PsumFIFO_Grant    ( w_lk_PsumFIFO_Grant     ),
    .o_PsumFIFO_Valid    ( w_lk_PsumFIFO_Valid     ),
    .i_PsumFIFO_Data     ( w_lk_PsumFIFO_Data      ),

    .o_PsumData          ( w_lk_PsumData           ),
    .o_PsumValid         ( w_lk_PsumValid          )
);

SystolicController_Slave#(
    .CALC_LINEAR_K       ( 1                       ) // CALC_LINEAR_K == 0 Calc K Mtrx else Calc V Mtrx
) u_SystolicController_Slave_V(
    .s_clk               ( s_clk                   ),
    .s_rst               ( s_rst                   ),

    .i_MasterSend_valid  ( m00_MtrxA_slice_valid   ), // FROM Master-Controller
    .i_MasterSend_data   ( m00_MtrxA_slice_data    ),
    .i_MasterSend_done   ( m00_MtrxA_slice_done    ),

    .i_weight_out        ( w_lv_weight_out         ),
    .o_weight_valid      ( w_lv_weight_valid       ),
    .i_weight_ready      ( w_lv_weight_ready       ),
    .load_w_finish       ( lv_load_w_finish        ),

    .o_Init_PrepareData  ( w_lv_Init_PrepareData   ),
    .i_Finish_Calc       ( w_lv_Finish_Calc        ),

    .MtrxA_slice_valid   ( s01_MtrxA_slice_valid   ),
    .MtrxA_slice_data    ( s01_MtrxA_slice_data    ),
    .MtrxA_slice_done    ( s01_MtrxA_slice_done    ),
    .MtrxA_slice_ready   ( s01_MtrxA_slice_ready   ),
    .MtrxB_slice_valid   ( s01_MtrxB_slice_valid   ),
    .MtrxB_slice_data    ( s01_MtrxB_slice_data    ),
    .MtrxB_slice_done    ( s01_MtrxB_slice_done    ),
    .MtrxB_slice_ready   ( s01_MtrxB_slice_ready   ),

    .o_PsumFIFO_Grant    ( w_lv_PsumFIFO_Grant     ),
    .o_PsumFIFO_Valid    ( w_lv_PsumFIFO_Valid     ),
    .i_PsumFIFO_Data     ( w_lv_PsumFIFO_Data      ),

    .o_PsumData          ( w_lv_PsumData           ),
    .o_PsumValid         ( w_lv_PsumValid          )
);

// ---------------  Systolic Array --------------- \\ 
SystolicArray u_SystolicArray_Q(
    .s_clk                ( s_clk                   ),
    .s_rst                ( s_rst                   ),

    .i_Init_PrepareData   ( w_lq_Init_PrepareData   ),
    .o_Finish_Calc        ( w_lq_Finish_Calc        ),

    .MtrxA_slice_valid    ( m00_MtrxA_slice_valid   ),
    .MtrxA_slice_data     ( m00_MtrxA_slice_data    ),
    .MtrxA_slice_done     ( m00_MtrxA_slice_done    ),
    .MtrxA_slice_ready    ( m00_MtrxA_slice_ready   ),
    .MtrxB_slice_valid    ( m00_MtrxB_slice_valid   ),
    .MtrxB_slice_data     ( m00_MtrxB_slice_data    ),
    .MtrxB_slice_done     ( m00_MtrxB_slice_done    ),
    .MtrxB_slice_ready    ( m00_MtrxB_slice_ready   ),

    .i_PsumFIFO_Grant     ( w_lq_PsumFIFO_Grant     ),
    .i_PsumFIFO_Valid     ( w_lq_PsumFIFO_Valid     ),
    .o_PsumFIFO_Data      ( w_lq_PsumFIFO_Data      )
);

SystolicArray u_SystolicArray_K(
    .s_clk                ( s_clk                   ),
    .s_rst                ( s_rst                   ),

    .i_Init_PrepareData   ( w_lk_Init_PrepareData   ),
    .o_Finish_Calc        ( w_lk_Finish_Calc        ),

    .MtrxA_slice_valid    ( s00_MtrxA_slice_valid   ),
    .MtrxA_slice_data     ( s00_MtrxA_slice_data    ),
    .MtrxA_slice_done     ( s00_MtrxA_slice_done    ),
    .MtrxA_slice_ready    ( s00_MtrxA_slice_ready   ),
    .MtrxB_slice_valid    ( s00_MtrxB_slice_valid   ),
    .MtrxB_slice_data     ( s00_MtrxB_slice_data    ),
    .MtrxB_slice_done     ( s00_MtrxB_slice_done    ),
    .MtrxB_slice_ready    ( s00_MtrxB_slice_ready   ),

    .i_PsumFIFO_Grant     ( w_lk_PsumFIFO_Grant     ),
    .i_PsumFIFO_Valid     ( w_lk_PsumFIFO_Valid     ),
    .o_PsumFIFO_Data      ( w_lk_PsumFIFO_Data      )
);

SystolicArray u_SystolicArray_V(
    .s_clk                ( s_clk                   ),
    .s_rst                ( s_rst                   ),

    .i_Init_PrepareData   ( w_lv_Init_PrepareData   ),
    .o_Finish_Calc        ( w_lv_Finish_Calc        ),

    .MtrxA_slice_valid    ( s01_MtrxA_slice_valid   ),
    .MtrxA_slice_data     ( s01_MtrxA_slice_data    ),
    .MtrxA_slice_done     ( s01_MtrxA_slice_done    ),
    .MtrxA_slice_ready    ( s01_MtrxA_slice_ready   ),
    .MtrxB_slice_valid    ( s01_MtrxB_slice_valid   ),
    .MtrxB_slice_data     ( s01_MtrxB_slice_data    ),
    .MtrxB_slice_done     ( s01_MtrxB_slice_done    ),
    .MtrxB_slice_ready    ( s01_MtrxB_slice_ready   ),

    .i_PsumFIFO_Grant     ( w_lv_PsumFIFO_Grant     ),
    .i_PsumFIFO_Valid     ( w_lv_PsumFIFO_Valid     ),
    .o_PsumFIFO_Data      ( w_lv_PsumFIFO_Data      )
);

// --------------- Lif Group --------------- \\ 
LIF_group u_LIF_group_Q(
    .s_clk                ( s_clk                   ),
    .s_rst                ( s_rst                   ),

    .i_lif_thrd           ( 'd128                   ), // FIXME: 具体阈值看算法
    .i_PsumValid          ( w_lq_PsumValid          ),
    .i_PsumData           ( w_lq_PsumData           ),

    .o_spikes_out         ( w_lq_spikes_out         ),
    .o_spikes_valid       ( w_lq_spikes_valid       )
);

LIF_group u_LIF_group_K(
    .s_clk                ( s_clk                   ),
    .s_rst                ( s_rst                   ),

    .i_lif_thrd           ( 'd128                   ), // FIXME: 具体阈值看算法
    .i_PsumValid          ( w_lk_PsumValid          ),
    .i_PsumData           ( w_lk_PsumData           ),

    .o_spikes_out         ( w_lk_spikes_out         ),
    .o_spikes_valid       ( w_lk_spikes_valid       )
);

LIF_group u_LIF_group_V(
    .s_clk                ( s_clk                   ),
    .s_rst                ( s_rst                   ),

    .i_lif_thrd           ( 'd128                   ), // FIXME: 具体阈值看算法
    .i_PsumValid          ( w_lv_PsumValid          ),
    .i_PsumData           ( w_lv_PsumData           ),

    .o_spikes_out         ( w_lv_spikes_out         ),
    .o_spikes_valid       ( w_lv_spikes_valid       )
);

qkv_Reshape u_qkv_Reshape(
    .s_clk                 ( s_clk                 ),
    .s_rst                 ( s_rst                 ),
    .i00_spikes_out        ( w_lq_spikes_out       ),
    .i00_spikes_valid      ( w_lq_spikes_valid     ),
    .i01_spikes_out        ( w_lk_spikes_out       ),
    .i01_spikes_valid      ( w_lk_spikes_valid     ),
    .i02_spikes_out        ( w_lv_spikes_out       ),
    .i02_spikes_valid      ( w_lv_spikes_valid     ),

    .o00_spikesLine_out    ( o00_spikesLine_out    ),
    .o00_spikesLine_valid  ( o00_spikesLine_valid  ),
    .o01_spikesLine_out    ( o01_spikesLine_out    ),
    .o01_spikesLine_valid  ( o01_spikesLine_valid  ),
    .o02_spikesLine_out    ( o02_spikesLine_out    ),
    .o02_spikesLine_valid  ( o02_spikesLine_valid  )
);

endmodule // TOP_qkv_linearCalc
