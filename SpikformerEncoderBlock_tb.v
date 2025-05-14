/*
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
    func    : Spikformer Encoder Block testbench
    sim-time: 2600 us + 
*/

`include "hyper_para.v"
module SpikformerEncoderBlock_tb ();

reg                                                  s_clk                   ;
reg                                                  s_rst                   ;

wire [11 : 0]                                        w_rd_addr               ;
wire [`PATCH_EMBED_WIDTH * 2 - 1 : 0]                w_ramout_data           ;
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

wire [`DATA_WIDTH- 1 : 0]                            M_lq_rd_burst_data      ;
wire [`ADDR_SIZE - 1 : 0]                            M_lq_rd_burst_addr      ;
wire [`LEN_WIDTH - 1 : 0]                            M_lq_rd_burst_len       ;
wire                                                 M_lq_rd_burst_req       ;
wire                                                 M_lq_rd_burst_valid     ;
wire                                                 M_lq_rd_burst_finish    ;

wire [`DATA_WIDTH- 1 : 0]                            M_lk_rd_burst_data      ;
wire [`ADDR_SIZE - 1 : 0]                            M_lk_rd_burst_addr      ;
wire [`LEN_WIDTH - 1 : 0]                            M_lk_rd_burst_len       ;
wire                                                 M_lk_rd_burst_req       ;
wire                                                 M_lk_rd_burst_valid     ;
wire                                                 M_lk_rd_burst_finish    ;

wire [`DATA_WIDTH- 1 : 0]                            M_lv_rd_burst_data      ;
wire [`ADDR_SIZE - 1 : 0]                            M_lv_rd_burst_addr      ;
wire [`LEN_WIDTH - 1 : 0]                            M_lv_rd_burst_len       ;
wire                                                 M_lv_rd_burst_req       ;
wire                                                 M_lv_rd_burst_valid     ;
wire                                                 M_lv_rd_burst_finish    ;

wire [`DATA_WIDTH- 1 : 0]                            burst_read_data         ;
wire [`ADDR_SIZE - 1 : 0]                            burst_read_addr         ;
wire [`LEN_WIDTH - 1 : 0]                            burst_read_len          ;
wire                                                 burst_read_req          ;
wire                                                 burst_read_valid        ;
wire                                                 burst_read_finish       ;

wire [`TIME_STEPS - 1 : 0]                           w_lq_spikes_out         ;
wire                                                 w_lq_spikes_valid       ;
wire [`TIME_STEPS - 1 : 0]                           w_lk_spikes_out         ;
wire                                                 w_lk_spikes_valid       ;
wire [`TIME_STEPS - 1 : 0]                           w_lv_spikes_out         ;
wire                                                 w_lv_spikes_valid       ;

wire [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]      w_lq_spikesLine_out     ;
wire                                                 w_lq_spikesLine_valid   ;
wire [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]      w_lk_spikesLine_out     ;
wire                                                 w_lk_spikesLine_valid   ;
wire [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]      w_lv_spikesLine_out     ;
wire                                                 w_lv_spikesLine_valid   ;

initial s_clk = 1'b1;
always #(`CLK_PERIOD/2) s_clk = ~s_clk;

initial begin
    s_rst = 1'b1;
    # 201;
    s_rst = 1'b0;
    # 400;
    # 4000;
end

// --------------- ddr Arbiter --------------- \\ 
ddr_sim_spikformer u_ddr_sim_spikformer(
    .user_clk                ( s_clk                   ),
    .user_rst                ( s_rst                   ),

    .burst_write_data        ( 'd0                     ),
    .burst_write_addr        ( 'd0                     ),
    .burst_write_len         ( 'd0                     ),
    .burst_write_req         ( 1'b0                    ),
    .burst_write_valid       (   ),
    .burst_write_finish      (   ),

    .burst_read_data         ( burst_read_data         ),
    .burst_read_addr         ( burst_read_addr         ),
    .burst_read_len          ( burst_read_len          ),
    .burst_read_req          ( burst_read_req          ),
    .burst_read_valid        ( burst_read_valid        ),
    .burst_read_finish       ( burst_read_finish       )
);

round_robin_arb u_round_robin_arb(
    .ddr_clk                 ( s_clk                   ),
    .ddr_rstn                ( ~s_rst                  ),

    .w00_burst_write_data    ( 'd0   ),
    .w00_burst_write_addr    ( 'd0   ),
    .w00_burst_write_len     ( 'd0   ),
    .w00_burst_write_req     ( 1'b0  ),
    .w00_burst_write_valid   (       ),
    .w00_burst_write_finish  (       ),

    .r00_burst_read_data     ( M_lq_rd_burst_data      ),
    .r00_burst_read_addr     ( M_lq_rd_burst_addr      ),
    .r00_burst_read_len      ( M_lq_rd_burst_len       ),
    .r00_burst_read_req      ( M_lq_rd_burst_req       ),
    .r00_burst_read_valid    ( M_lq_rd_burst_valid     ),
    .r00_burst_read_finish   ( M_lq_rd_burst_finish    ),
    
    .w01_burst_write_data    ( 'd0   ),
    .w01_burst_write_addr    ( 'd0   ),
    .w01_burst_write_len     ( 'd0   ),
    .w01_burst_write_req     ( 1'b0  ),
    .w01_burst_write_valid   (       ),
    .w01_burst_write_finish  (       ),
    
    .r01_burst_read_data     ( M_lk_rd_burst_data      ),
    .r01_burst_read_addr     ( M_lk_rd_burst_addr      ),
    .r01_burst_read_len      ( M_lk_rd_burst_len       ),
    .r01_burst_read_req      ( M_lk_rd_burst_req       ),
    .r01_burst_read_valid    ( M_lk_rd_burst_valid     ),
    .r01_burst_read_finish   ( M_lk_rd_burst_finish    ),
    
    .w02_burst_write_data    ( 'd0  ),
    .w02_burst_write_addr    ( 'd0  ),
    .w02_burst_write_len     ( 'd0  ),
    .w02_burst_write_req     ( 1'b0 ),
    .w02_burst_write_valid   (  ),
    .w02_burst_write_finish  (  ),
    
    .r02_burst_read_data     ( M_lv_rd_burst_data      ),
    .r02_burst_read_addr     ( M_lv_rd_burst_addr      ),
    .r02_burst_read_len      ( M_lv_rd_burst_len       ),
    .r02_burst_read_req      ( M_lv_rd_burst_req       ),
    .r02_burst_read_valid    ( M_lv_rd_burst_valid     ),
    .r02_burst_read_finish   ( M_lv_rd_burst_finish    ),
    
    .w03_burst_write_data    ( 'd0  ),
    .w03_burst_write_addr    ( 'd0  ),
    .w03_burst_write_len     ( 'd0  ),
    .w03_burst_write_req     ( 1'b0 ),
    .w03_burst_write_valid   (  ),
    .w03_burst_write_finish  (  ),
    
    .r03_burst_read_data     (  ),
    .r03_burst_read_addr     ( 'd0  ),
    .r03_burst_read_len      ( 'd0  ),
    .r03_burst_read_req      ( 1'b0 ),
    .r03_burst_read_valid    (  ),
    .r03_burst_read_finish   (  ),

    .wr_burst_data           (    ), 
    .wr_burst_addr           (    ), 
    .wr_burst_len            (    ), 
    .wr_burst_req            (    ), 
    .wr_burst_data_req       ( 'd0), 
    .wr_burst_finish         ( 'd0), 
    
    .rd_burst_data           ( burst_read_data         ), 
    .rd_burst_addr           ( burst_read_addr         ), 
    .rd_burst_len            ( burst_read_len          ), 
    .rd_burst_req            ( burst_read_req          ), 
    .rd_burst_data_valid     ( burst_read_valid        ), 
    .rd_burst_finish         ( burst_read_finish       )  
);

// --------------- Patch Embed --------------- \\ 
PatchEmbed u_PatchEmbed (
    .s_clk                  ( s_clk             ),
    .s_rst                  ( s_rst             ),
    .i_data_valid           ( 'd0               ),
    .i_fmap                 ( 'd0               ),
    .i_patchdata            ( 'd0               ),
    .i_rd_addr              ( w_rd_addr         ),
    .o_ramout_data          ( w_ramout_data     ),
    .o_ramout_ready         ( w_ramout_ready    ),
    .i_switch               ( 'd0 ),
    .i_MLPs_wea             ( 'd0 ),
    .i_MLPs_addra           ( 'd0 ),
    .i_MLPs_dina            ( 'd0 ),
    .i_MLPs_addrb           ( 'd0 ),
    .o_MLPs_doutb           (     )
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
    .load_w_finish          ( 1'b0                 )
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
    .load_w_finish          ( 1'b0                 )
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
    .load_w_finish          ( 1'b0                 )
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

    .o_Psum_Finish       (     ),
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

    .o_Psum_Finish       (     ),
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

    .i_lif_thrd           ( 'd128                   ),
    .i_PsumValid          ( w_lq_PsumValid          ),
    .i_PsumData           ( w_lq_PsumData           ),

    .o_spikes_out         ( w_lq_spikes_out         ),
    .o_spikes_valid       ( w_lq_spikes_valid       )
);

LIF_group u_LIF_group_K(
    .s_clk                ( s_clk                   ),
    .s_rst                ( s_rst                   ),

    .i_lif_thrd           ( 'd128                   ),
    .i_PsumValid          ( w_lk_PsumValid          ),
    .i_PsumData           ( w_lk_PsumData           ),

    .o_spikes_out         ( w_lk_spikes_out         ),
    .o_spikes_valid       ( w_lk_spikes_valid       )
);

LIF_group u_LIF_group_V(
    .s_clk                ( s_clk                   ),
    .s_rst                ( s_rst                   ),

    .i_lif_thrd           ( 'd128                   ),
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

    .o00_spikesLine_out    ( w_lq_spikesLine_out   ),
    .o00_spikesLine_valid  ( w_lq_spikesLine_valid ),
    .o01_spikesLine_out    ( w_lk_spikesLine_out   ),
    .o01_spikesLine_valid  ( w_lk_spikesLine_valid ),
    .o02_spikesLine_out    ( w_lv_spikesLine_out   ),
    .o02_spikesLine_valid  ( w_lv_spikesLine_valid )
);

// GET DATA ----------------------------------------------------------------------------------------------------------------
parameter linear_q_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_q_out_t0.txt";
parameter linear_q_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_q_out_t1.txt";
parameter linear_q_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_q_out_t2.txt";
parameter linear_q_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_q_out_t3.txt";

reg    r_lq_PsumFIFO_Finish_d0;
reg    r_lq_PsumFIFO_Finish_d1;

integer file0, file1, file2, file3;
initial begin
    file0 = $fopen(linear_q_out_t0_path, "w");
    file1 = $fopen(linear_q_out_t1_path, "w");
    file2 = $fopen(linear_q_out_t2_path, "w");
    file3 = $fopen(linear_q_out_t3_path, "w");
end

always@(posedge s_clk) begin
    r_lq_PsumFIFO_Finish_d0 <= w_lq_PsumFIFO_Finish    ;
    r_lq_PsumFIFO_Finish_d1 <= r_lq_PsumFIFO_Finish_d0 ;

    if (r_lq_PsumFIFO_Finish_d1) begin
        $display("linear_q_out cal done");
        $fclose(file0);
        $fclose(file1);
        $fclose(file2);
        $fclose(file3);
    end
    else if (w_lq_PsumValid) begin
        $fwrite(file0, "%d\n", $signed(w_lq_PsumData[1*20 - 1 : 0*20])); 
        $fwrite(file1, "%d\n", $signed(w_lq_PsumData[2*20 - 1 : 1*20])); 
        $fwrite(file2, "%d\n", $signed(w_lq_PsumData[3*20 - 1 : 2*20])); 
        $fwrite(file3, "%d\n", $signed(w_lq_PsumData[4*20 - 1 : 3*20])); 
    end
end

parameter linear_k_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_k_out_t0.txt";
parameter linear_k_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_k_out_t1.txt";
parameter linear_k_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_k_out_t2.txt";
parameter linear_k_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_k_out_t3.txt";

reg [15 : 0]       r_linear_k_cnt=0 ; 

integer kfile0, kfile1, kfile2, kfile3;
initial begin
    kfile0 = $fopen(linear_k_out_t0_path, "w");
    kfile1 = $fopen(linear_k_out_t1_path, "w");
    kfile2 = $fopen(linear_k_out_t2_path, "w");
    kfile3 = $fopen(linear_k_out_t3_path, "w");
end

always@(posedge s_clk) begin
    if (r_linear_k_cnt == 'd24576) begin
        $display("linear_k_out cal done");
        $fclose(kfile0);
        $fclose(kfile1);
        $fclose(kfile2);
        $fclose(kfile3);
    end
    else if (w_lk_PsumValid) begin
        r_linear_k_cnt <= r_linear_k_cnt + 1'b1;
        $fwrite(kfile0, "%d\n", $signed(w_lk_PsumData[1*20 - 1 : 0*20])); 
        $fwrite(kfile1, "%d\n", $signed(w_lk_PsumData[2*20 - 1 : 1*20])); 
        $fwrite(kfile2, "%d\n", $signed(w_lk_PsumData[3*20 - 1 : 2*20])); 
        $fwrite(kfile3, "%d\n", $signed(w_lk_PsumData[4*20 - 1 : 3*20])); 
    end
end

parameter linear_v_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_v_out_t0.txt";
parameter linear_v_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_v_out_t1.txt";
parameter linear_v_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_v_out_t2.txt";
parameter linear_v_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_v_out_t3.txt";

reg [15 : 0]       r_linear_v_cnt=0 ; 

integer vfile0, vfile1, vfile2, vfile3;
initial begin
    vfile0 = $fopen(linear_v_out_t0_path, "w");
    vfile1 = $fopen(linear_v_out_t1_path, "w");
    vfile2 = $fopen(linear_v_out_t2_path, "w");
    vfile3 = $fopen(linear_v_out_t3_path, "w");
end

always@(posedge s_clk) begin
    if (r_linear_v_cnt == 'd24576) begin
        $display("linear_v_out cal done");
        $fclose(vfile0);
        $fclose(vfile1);
        $fclose(vfile2);
        $fclose(vfile3);
    end
    else if (w_lv_PsumValid) begin
        r_linear_v_cnt <= r_linear_v_cnt + 1'b1;
        $fwrite(vfile0, "%d\n", $signed(w_lv_PsumData[1*20 - 1 : 0*20])); 
        $fwrite(vfile1, "%d\n", $signed(w_lv_PsumData[2*20 - 1 : 1*20])); 
        $fwrite(vfile2, "%d\n", $signed(w_lv_PsumData[3*20 - 1 : 2*20])); 
        $fwrite(vfile3, "%d\n", $signed(w_lv_PsumData[4*20 - 1 : 3*20])); 
    end
end

// ======= SPIKES GET =======
parameter attn_lif_q_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_lif_q_out_t0.txt";
parameter attn_lif_q_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_lif_q_out_t1.txt";
parameter attn_lif_q_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_lif_q_out_t2.txt";
parameter attn_lif_q_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_lif_q_out_t3.txt";
reg [15 : 0]       r_lif_q_cnt=0 ; 

integer lq_file0, lq_file1, lq_file2, lq_file3;
initial begin
    lq_file0 = $fopen(attn_lif_q_out_t0_path, "w");
    lq_file1 = $fopen(attn_lif_q_out_t1_path, "w");
    lq_file2 = $fopen(attn_lif_q_out_t2_path, "w");
    lq_file3 = $fopen(attn_lif_q_out_t3_path, "w");
end
  
always@(posedge s_clk) begin
    if (r_lif_q_cnt == 'd24576) begin
        $display("lif_q_out cal done");
        $fclose(lq_file0);
        $fclose(lq_file1);
        $fclose(lq_file2);
        $fclose(lq_file3);
    end
    else if (w_lq_spikes_valid) begin
        r_lif_q_cnt <= r_lif_q_cnt + 1'b1;
        $fwrite(lq_file0, "%b\n", w_lq_spikes_out[0]); 
        $fwrite(lq_file1, "%b\n", w_lq_spikes_out[1]); 
        $fwrite(lq_file2, "%b\n", w_lq_spikes_out[2]); 
        $fwrite(lq_file3, "%b\n", w_lq_spikes_out[3]); 
    end
end

parameter attn_lif_k_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_lif_k_out_t0.txt";
parameter attn_lif_k_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_lif_k_out_t1.txt";
parameter attn_lif_k_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_lif_k_out_t2.txt";
parameter attn_lif_k_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_lif_k_out_t3.txt";
reg [15 : 0]       r_lif_k_cnt=0 ; 

integer lk_file0, lk_file1, lk_file2, lk_file3;
initial begin
    lk_file0 = $fopen(attn_lif_k_out_t0_path, "w");
    lk_file1 = $fopen(attn_lif_k_out_t1_path, "w");
    lk_file2 = $fopen(attn_lif_k_out_t2_path, "w");
    lk_file3 = $fopen(attn_lif_k_out_t3_path, "w");
end
  
always@(posedge s_clk) begin
    if (r_lif_k_cnt == 'd24576) begin
        $display("lif_k_out cal done");
        $fclose(lk_file0);
        $fclose(lk_file1);
        $fclose(lk_file2);
        $fclose(lk_file3);
    end
    else if (w_lk_spikes_valid) begin
        r_lif_k_cnt <= r_lif_k_cnt + 1'b1;
        $fwrite(lk_file0, "%b\n", w_lk_spikes_out[0]); 
        $fwrite(lk_file1, "%b\n", w_lk_spikes_out[1]); 
        $fwrite(lk_file2, "%b\n", w_lk_spikes_out[2]); 
        $fwrite(lk_file3, "%b\n", w_lk_spikes_out[3]); 
    end
end

parameter attn_lif_v_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_lif_v_out_t0.txt";
parameter attn_lif_v_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_lif_v_out_t1.txt";
parameter attn_lif_v_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_lif_v_out_t2.txt";
parameter attn_lif_v_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_lif_v_out_t3.txt";
reg [15 : 0]       r_lif_v_cnt=0 ; 

integer lv_file0, lv_file1, lv_file2, lv_file3;
initial begin
    lv_file0 = $fopen(attn_lif_v_out_t0_path, "w");
    lv_file1 = $fopen(attn_lif_v_out_t1_path, "w");
    lv_file2 = $fopen(attn_lif_v_out_t2_path, "w");
    lv_file3 = $fopen(attn_lif_v_out_t3_path, "w");
end
  
always@(posedge s_clk) begin
    if (r_lif_v_cnt == 'd24576) begin
        $display("lif_k_out cal done");
        $fclose(lv_file0);
        $fclose(lv_file1);
        $fclose(lv_file2);
        $fclose(lv_file3);
    end
    else if (w_lv_spikes_valid) begin
        r_lif_v_cnt <= r_lif_v_cnt + 1'b1;
        $fwrite(lv_file0, "%b\n", w_lv_spikes_out[0]); 
        $fwrite(lv_file1, "%b\n", w_lv_spikes_out[1]); 
        $fwrite(lv_file2, "%b\n", w_lv_spikes_out[2]); 
        $fwrite(lv_file3, "%b\n", w_lv_spikes_out[3]); 
    end
end

// ======= CHECK ALIGN-DATA =======
// -- generate .coe files
parameter align_lif_out_q_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/BRAM_QKV_q.txt";
parameter align_lif_out_k_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/BRAM_QKV_k.txt";
parameter align_lif_out_v_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/BRAM_QKV_v.txt";
// --
parameter align_lif_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/align_lif_out_t0.txt";
parameter align_lif_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/align_lif_out_t1.txt";
parameter align_lif_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/align_lif_out_t2.txt";
parameter align_lif_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/align_lif_out_t3.txt";

wire [`SYSTOLIC_UNIT_NUM*`TIME_STEPS / 2 - 1 : 0]       w_alignSpikes_t0 ;
wire [`SYSTOLIC_UNIT_NUM*`TIME_STEPS / 2 - 1 : 0]       w_alignSpikes_t1 ;
wire [`SYSTOLIC_UNIT_NUM*`TIME_STEPS / 2 - 1 : 0]       w_alignSpikes_t2 ;
wire [`SYSTOLIC_UNIT_NUM*`TIME_STEPS / 2 - 1 : 0]       w_alignSpikes_t3 ;

reg [15 : 0]       r_align_lif_q_cnt=0 ; 
reg [15 : 0]       r_align_lif_k_cnt=0 ; 
reg [15 : 0]       r_align_lif_v_cnt=0 ; 

genvar m;
generate
    for (m = 0; m < `SYSTOLIC_UNIT_NUM*`TIME_STEPS / 2; m = m + 1) begin
        assign w_alignSpikes_t0[m] = w_lq_spikesLine_out[`TIME_STEPS * m + 0]; 
        assign w_alignSpikes_t1[m] = w_lq_spikesLine_out[`TIME_STEPS * m + 1];
        assign w_alignSpikes_t2[m] = w_lq_spikesLine_out[`TIME_STEPS * m + 2];
        assign w_alignSpikes_t3[m] = w_lq_spikesLine_out[`TIME_STEPS * m + 3];
    end
endgenerate

integer align_file0, align_file1, align_file2, align_file3;
integer bram_q_file, bram_k_file, bram_v_file;
initial begin
    bram_q_file = $fopen(align_lif_out_q_path, "w");
    bram_k_file = $fopen(align_lif_out_k_path, "w");
    bram_v_file = $fopen(align_lif_out_v_path, "w");

    align_file0 = $fopen(align_lif_out_t0_path, "w");
    align_file1 = $fopen(align_lif_out_t1_path, "w");
    align_file2 = $fopen(align_lif_out_t2_path, "w");
    align_file3 = $fopen(align_lif_out_t3_path, "w");
end

integer mm;
always@(posedge s_clk) begin
    if (r_align_lif_q_cnt == 'd768) begin
        $display("align lif cal done");
        $fclose(align_file0);
        $fclose(align_file1);
        $fclose(align_file2);
        $fclose(align_file3);
        $fclose(bram_q_file);
    end
    else if (w_lq_spikesLine_valid) begin
        $fwrite(bram_q_file, "%h;\n", w_lq_spikesLine_out); 
        r_align_lif_q_cnt <= r_align_lif_q_cnt + 1'b1;
        for (mm = 0; mm < `SYSTOLIC_UNIT_NUM*`TIME_STEPS / 2; mm = mm + 1) begin
            $fwrite(align_file0, "%b\n", w_alignSpikes_t0[mm]); 
            $fwrite(align_file1, "%b\n", w_alignSpikes_t1[mm]); 
            $fwrite(align_file2, "%b\n", w_alignSpikes_t2[mm]); 
            $fwrite(align_file3, "%b\n", w_alignSpikes_t3[mm]); 
        end
    end
end

always@(posedge s_clk) begin
    if (r_align_lif_k_cnt == 'd768) begin
        $display("bram_k_file write done");
        $fclose(bram_k_file);
    end
    else if (w_lk_spikesLine_valid) begin
        $fwrite(bram_k_file, "%h;\n", w_lk_spikesLine_out); 
        r_align_lif_k_cnt <= r_align_lif_k_cnt + 1'b1;
    end
end

always@(posedge s_clk) begin
    if (r_align_lif_v_cnt == 'd768) begin
        $display("bram_v_file write done");
        $fclose(bram_v_file);
    end
    else if (w_lv_spikesLine_valid) begin
        $fwrite(bram_v_file, "%h;\n", w_lv_spikesLine_out); 
        r_align_lif_v_cnt <= r_align_lif_v_cnt + 1'b1;
    end
end

endmodule // SpikformerEncoderBlock_tb
