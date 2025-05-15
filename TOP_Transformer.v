/*
    --- Transformer : Attention + MLP --- 
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "hyper_para.v"
module TOP_Transformer (
    input                                                       s_clk                ,
    input                                                       s_rst                ,

    input                                                       i_load_w_finish      , 
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
    input                                                       M_lv_rd_burst_finish     
);

// -- wire -- 
wire  [11 : 0]                                           w_rd_addr                  ;
wire  [`PATCH_EMBED_WIDTH * 2 - 1 : 0]                   w_ramout_data              ;
wire                                                     w_ramout_ready             ;

wire  [`DATA_WIDTH - 1 : 0]                              w_lq_weight_out            ;
wire                                                     w_lq_weight_valid          ;
wire                                                     w_lq_weight_ready          ;

wire  [`DATA_WIDTH - 1 : 0]                              w_lk_weight_out            ;
wire                                                     w_lk_weight_valid          ;
wire                                                     w_lk_weight_ready          ;

wire  [`DATA_WIDTH - 1 : 0]                              w_lv_weight_out            ;
wire                                                     w_lv_weight_valid          ;
wire                                                     w_lv_weight_ready          ;

wire                                                     m00_MtrxA_slice_valid      ;
wire  [`DATA_WIDTH - 1 : 0]                              m00_MtrxA_slice_data       ;
wire                                                     m00_MtrxA_slice_done       ;
wire                                                     m00_MtrxA_slice_ready      ;
wire                                                     m00_MtrxB_slice_valid      ;
wire  [`DATA_WIDTH - 1 : 0]                              m00_MtrxB_slice_data       ;
wire                                                     m00_MtrxB_slice_done       ;
wire                                                     m00_MtrxB_slice_ready      ;

wire                                                     s00_MtrxA_slice_valid      ;
wire  [`DATA_WIDTH - 1 : 0]                              s00_MtrxA_slice_data       ;
wire                                                     s00_MtrxA_slice_done       ;
wire                                                     s00_MtrxA_slice_ready      ;
wire                                                     s00_MtrxB_slice_valid      ;
wire  [`DATA_WIDTH - 1 : 0]                              s00_MtrxB_slice_data       ;
wire                                                     s00_MtrxB_slice_done       ;
wire                                                     s00_MtrxB_slice_ready      ;

wire                                                     s01_MtrxA_slice_valid      ;
wire  [`DATA_WIDTH - 1 : 0]                              s01_MtrxA_slice_data       ;
wire                                                     s01_MtrxA_slice_done       ;
wire                                                     s01_MtrxA_slice_ready      ;
wire                                                     s01_MtrxB_slice_valid      ;
wire  [`DATA_WIDTH - 1 : 0]                              s01_MtrxB_slice_data       ;
wire                                                     s01_MtrxB_slice_done       ;
wire                                                     s01_MtrxB_slice_ready      ;

wire                                                     w_lq_Init_PrepareData      ;
wire                                                     w_lq_Finish_Calc           ;
wire                                                     w_lk_Init_PrepareData      ;
wire                                                     w_lk_Finish_Calc           ;
wire                                                     w_lv_Init_PrepareData      ;
wire                                                     w_lv_Finish_Calc           ;

wire [`SYSTOLIC_UNIT_NUM - 1 : 0]                        w_lq_PsumFIFO_Grant        ;
wire                                                     w_lq_PsumFIFO_Valid        ;
wire                                                     w_lq_PsumFIFO_Finish       ;
wire                                                     w_lk_PsumFIFO_Finish       ;
wire                                                     w_lv_PsumFIFO_Finish       ;

wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                      w_lq_PsumFIFO_Data         ;
wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                      w_lq_PsumData              ;
wire                                                     w_lq_PsumValid             ;
wire [`SYSTOLIC_UNIT_NUM - 1 : 0]                        w_lk_PsumFIFO_Grant        ;
wire                                                     w_lk_PsumFIFO_Valid        ;
wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                      w_lk_PsumFIFO_Data         ;
wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                      w_lk_PsumData              ;
wire                                                     w_lk_PsumValid             ;
wire [`SYSTOLIC_UNIT_NUM - 1 : 0]                        w_lv_PsumFIFO_Grant        ;
wire                                                     w_lv_PsumFIFO_Valid        ;
wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                      w_lv_PsumFIFO_Data         ;
wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                      w_lv_PsumData              ;
wire                                                     w_lv_PsumValid             ;

wire [`TIME_STEPS - 1 : 0]                               w_lq_spikes_out            ;
wire                                                     w_lq_spikes_valid          ;
wire [`TIME_STEPS - 1 : 0]                               w_lk_spikes_out            ;
wire                                                     w_lk_spikes_valid          ;
wire [`TIME_STEPS - 1 : 0]                               w_lv_spikes_out            ;
wire                                                     w_lv_spikes_valid          ;

wire [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]          w00_spikesLine_out         ;
wire                                                     w00_spikesLine_valid       ;
wire [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]          w01_spikesLine_out         ;
wire                                                     w01_spikesLine_valid       ;
wire [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]          w02_spikesLine_out         ;
wire                                                     w02_spikesLine_valid       ;

wire                                                     w_SpikesTmpRam_Ready       ; 
wire [9 : 0]                                             w_QueryRam_rdaddr          ; 
wire [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]          w_QueryRam_out             ; 
wire [9 : 0]                                             w_KeyRam_rdaddr            ; 
wire [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]          w_KeyRam_out               ; 
wire [9 : 0]                                             w_ValueRam_rdaddr          ; 
wire [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]          w_ValueRam_out             ; 

wire                                                     w_AttnRAM_Ready            ;
wire [$clog2(2*`SYSTOLIC_UNIT_NUM)*`TIME_STEPS - 1 : 0]  w_Calc_data                ;
wire                                                     w_Calc_valid               ;

wire                                                     w_AttnRam_Done             ; 
wire [11 : 0]                                            w_AttnRam_rd_addr          ; 
wire                                                     w_AttnRAM_Empty            ; 
wire [$clog2(2*`SYSTOLIC_UNIT_NUM)*`TIME_STEPS - 1 : 0]  w_AttnRAM_data             ; 

wire [`PATCH_EMBED_WIDTH*2 - 1 : 0]                      w_attn_v_spikes_data       ;
wire                                                     w_attn_v_spikes_valid      ;
wire                                                     w_attn_v_spikes_done       ;

wire [0 : 0]                                             w_TmpSpikesRam01_wea       ;
wire [13 : 0]                                            w_TmpSpikesRam01_addra     ;
wire [63 : 0]                                            w_TmpSpikesRam01_dina      ;

wire [0 : 0]                                             w_Mlp_Ram00_wea            ;  
wire [11 : 0]                                            w_Mlp_Ram00_addra          ;  
wire [63 : 0]                                            w_Mlp_Ram00_dina           ;  
wire [11 : 0]                                            w_Mlp_Ram00_addrb          ;  
wire [63 : 0]                                            w_Mlp_Ram00_doutb          ;  

wire [0 : 0]                                             w_Mlp_Ram01_wea            ;  
wire [13 : 0]                                            w_Mlp_Ram01_addra          ;  
wire [63 : 0]                                            w_Mlp_Ram01_dina           ;  
wire [13 : 0]                                            w_Mlp_Ram01_addrb          ;  
wire [63 : 0]                                            w_Mlp_Ram01_doutb          ;  

wire [0 : 0]                                             w_Mlp_Ram02_wea            ;  
wire [11 : 0]                                            w_Mlp_Ram02_addra          ;  
wire [63 : 0]                                            w_Mlp_Ram02_dina           ;  
wire [11 : 0]                                            w_Mlp_Ram02_addrb          ;  
wire [63 : 0]                                            w_Mlp_Ram02_doutb          ;  

wire                                                     w_mlp_Init_PrepareData     ;  

wire                                                     w_mlp_Mtrx00_slice_valid   ;  
wire  [63 : 0]                                           w_mlp_Mtrx00_slice_data    ;  
wire                                                     w_mlp_Mtrx00_slice_done    ;  
wire                                                     w_mlp_Mtrx00_slice_ready   ;  

wire                                                     w_mlp_Mtrx01_slice_valid   ;  
wire  [63 : 0]                                           w_mlp_Mtrx01_slice_data    ;  
wire                                                     w_mlp_Mtrx01_slice_done    ;  
wire                                                     w_mlp_Mtrx01_slice_ready   ;  

wire                                                     w_mlp_Mtrx02_slice_valid   ;  
wire  [63 : 0]                                           w_mlp_Mtrx02_slice_data    ;  
wire                                                     w_mlp_Mtrx02_slice_done    ;  
wire                                                     w_mlp_Mtrx02_slice_ready   ;  

wire [`SYSTOLIC_UNIT_NUM - 1 : 0]                        w00_mlp_PsumFIFO_Grant     ;  
wire                                                     w00_mlp_PsumFIFO_Valid     ;  
wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                      w00_mlp_PsumFIFO_Data      ;  
wire                                                     w00_mlp_Finish_Calc        ;  

wire [`SYSTOLIC_UNIT_NUM - 1 : 0]                        w01_mlp_PsumFIFO_Grant     ;  
wire                                                     w01_mlp_PsumFIFO_Valid     ;  
wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                      w01_mlp_PsumFIFO_Data      ;  
wire                                                     w01_mlp_Finish_Calc        ;  

wire [`SYSTOLIC_UNIT_NUM - 1 : 0]                        w02_mlp_PsumFIFO_Grant     ;  
wire                                                     w02_mlp_PsumFIFO_Valid     ;  
wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                      w02_mlp_PsumFIFO_Data      ;  
wire                                                     w02_mlp_Finish_Calc        ;  

wire                                                     w_Ary00_Init_PrepareData   ; // CH1
wire                                                     w_Ary00_Finish_Calc        ; 
wire                                                     w_Ary00_MtrxA_slice_valid  ; 
wire [`DATA_WIDTH - 1 : 0]                               w_Ary00_MtrxA_slice_data   ; 
wire                                                     w_Ary00_MtrxA_slice_done   ; 
wire                                                     w_Ary00_MtrxA_slice_ready  ;
wire [`SYSTOLIC_UNIT_NUM - 1 : 0]                        w_Ary00_PsumFIFO_Grant     ; 
wire                                                     w_Ary00_PsumFIFO_Valid     ; 
wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                      w_Ary00_PsumFIFO_Data      ;

wire                                                     w_Ary01_Init_PrepareData   ; // CH2 
wire                                                     w_Ary01_Finish_Calc        ; 
wire                                                     w_Ary01_MtrxA_slice_valid  ; 
wire [`DATA_WIDTH - 1 : 0]                               w_Ary01_MtrxA_slice_data   ; 
wire                                                     w_Ary01_MtrxA_slice_done   ; 
wire                                                     w_Ary01_MtrxA_slice_ready  ;
wire [`SYSTOLIC_UNIT_NUM - 1 : 0]                        w_Ary01_PsumFIFO_Grant     ; 
wire                                                     w_Ary01_PsumFIFO_Valid     ; 
wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                      w_Ary01_PsumFIFO_Data      ;

wire                                                     w_Ary02_Init_PrepareData   ; // CH3
wire                                                     w_Ary02_Finish_Calc        ; 
wire                                                     w_Ary02_MtrxA_slice_valid  ; 
wire [`DATA_WIDTH - 1 : 0]                               w_Ary02_MtrxA_slice_data   ; 
wire                                                     w_Ary02_MtrxA_slice_done   ; 
wire                                                     w_Ary02_MtrxA_slice_ready  ;
wire [`SYSTOLIC_UNIT_NUM - 1 : 0]                        w_Ary02_PsumFIFO_Grant     ; 
wire                                                     w_Ary02_PsumFIFO_Valid     ; 
wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                      w_Ary02_PsumFIFO_Data      ;

// -- reg -- 
reg                                                      r_Chnnl_Switch=0           ;
reg  [13 : 0]                                            r_MLP_in_addr              ; 
reg  [7 : 0]                                             r_attn_v_spikes_Finish[2 : 0] ;

reg  [2 : 0]                                             r_attn_v_spikes_done=0     ;

// --------------- Patch Embed --------------- \\ 
// r_Chnnl_Switch
always@(posedge s_clk) begin
    if (w_lv_PsumFIFO_Finish && w_lq_PsumFIFO_Finish)
        r_Chnnl_Switch <= 1'b1;
    else 
        r_Chnnl_Switch <= 1'b0;
end

PatchEmbed u_PatchEmbed (
    .s_clk                  ( s_clk                         ),
    .s_rst                  ( s_rst                         ),
    .i_data_valid           ( i_data_valid                  ),
    .i_fmap                 ( i_fmap                        ),
    .i_patchdata            ( i_patchdata                   ),

    .i_rd_addr              ( w_rd_addr                     ),
    .o_ramout_data          ( w_ramout_data                 ),
    .o_ramout_ready         ( w_ramout_ready                ),

    .i_switch               ( r_Chnnl_Switch                ),
    .i_MLPs_wea             ( w_Mlp_Ram00_wea               ),
    .i_MLPs_addra           ( w_Mlp_Ram00_addra             ),
    .i_MLPs_dina            ( w_Mlp_Ram00_dina              ),
    .i_MLPs_addrb           ( w_Mlp_Ram00_addrb             ),
    .o_MLPs_doutb           ( w_Mlp_Ram00_doutb             )
);

// --------------- Weights Loader --------------- \\ 
weight_fifo_v1 #(
    .WEIGHTS_BASEADDR       ( `WEIGHTS_Q_BASEADDR           )
) u_weight_fifo_linear_Q(
    .s_clk                  ( s_clk                         ),
    .s_rst                  ( s_rst                         ),

    .rd_burst_data          ( M_lq_rd_burst_data            ),
    .rd_burst_addr          ( M_lq_rd_burst_addr            ),
    .rd_burst_len           ( M_lq_rd_burst_len             ),
    .rd_burst_req           ( M_lq_rd_burst_req             ),
    .rd_burst_valid         ( M_lq_rd_burst_valid           ),
    .rd_burst_finish        ( M_lq_rd_burst_finish          ),

    .o_weight_out           ( w_lq_weight_out               ),
    .i_weight_valid         ( w_lq_weight_valid             ),
    .o_weight_ready         ( w_lq_weight_ready             ),
    .load_w_finish          ( i_load_w_finish               )
);

weight_fifo_v1 #(
    .WEIGHTS_BASEADDR       ( `WEIGHTS_K_BASEADDR           )
) u_weight_fifo_linear_K(
    .s_clk                  ( s_clk                         ),
    .s_rst                  ( s_rst                         ),

    .rd_burst_data          ( M_lk_rd_burst_data            ),
    .rd_burst_addr          ( M_lk_rd_burst_addr            ),
    .rd_burst_len           ( M_lk_rd_burst_len             ),
    .rd_burst_req           ( M_lk_rd_burst_req             ),
    .rd_burst_valid         ( M_lk_rd_burst_valid           ),
    .rd_burst_finish        ( M_lk_rd_burst_finish          ),

    .o_weight_out           ( w_lk_weight_out               ),
    .i_weight_valid         ( w_lk_weight_valid             ),
    .o_weight_ready         ( w_lk_weight_ready             ),
    .load_w_finish          ( i_load_w_finish               )
);

weight_fifo_v1 #(
    .WEIGHTS_BASEADDR       ( `WEIGHTS_V_BASEADDR           )
) u_weight_fifo_linear_V(
    .s_clk                  ( s_clk                         ),
    .s_rst                  ( s_rst                         ),

    .rd_burst_data          ( M_lv_rd_burst_data            ),
    .rd_burst_addr          ( M_lv_rd_burst_addr            ),
    .rd_burst_len           ( M_lv_rd_burst_len             ),
    .rd_burst_req           ( M_lv_rd_burst_req             ),
    .rd_burst_valid         ( M_lv_rd_burst_valid           ),
    .rd_burst_finish        ( M_lv_rd_burst_finish          ),

    .o_weight_out           ( w_lv_weight_out               ),
    .i_weight_valid         ( w_lv_weight_valid             ),
    .o_weight_ready         ( w_lv_weight_ready             ),
    .load_w_finish          ( i_load_w_finish               )
);

// ---------------  Systolic Controller --------------- \\ 
SystolicController u_SystolicController_Master_Q(
    .s_clk                  ( s_clk                         ),
    .s_rst                  ( s_rst                         ),

    .o_rd_addr              ( w_rd_addr                     ),
    .i_ramout_data          ( w_ramout_data                 ),
    .i_ramout_ready         ( w_ramout_ready                ),

    .i_weight_out           ( w_lq_weight_out               ),
    .o_weight_valid         ( w_lq_weight_valid             ),
    .i_weight_ready         ( w_lq_weight_ready             ),

    .o_Init_PrepareData     ( w_lq_Init_PrepareData         ),
    .i_Finish_Calc          ( w_lq_Finish_Calc              ),

    .MtrxA_slice_valid      ( m00_MtrxA_slice_valid         ),
    .MtrxA_slice_data       ( m00_MtrxA_slice_data          ),
    .MtrxA_slice_done       ( m00_MtrxA_slice_done          ),
    .MtrxA_slice_ready      ( m00_MtrxA_slice_ready         ),
    .MtrxB_slice_valid      ( m00_MtrxB_slice_valid         ),
    .MtrxB_slice_data       ( m00_MtrxB_slice_data          ),
    .MtrxB_slice_done       ( m00_MtrxB_slice_done          ),
    .MtrxB_slice_ready      ( m00_MtrxB_slice_ready         ),

    .o_PsumFIFO_Grant       ( w_lq_PsumFIFO_Grant           ),
    .o_PsumFIFO_Valid       ( w_lq_PsumFIFO_Valid           ),
    .i_PsumFIFO_Data        ( w_lq_PsumFIFO_Data            ),

    .o_Psum_Finish          ( w_lq_PsumFIFO_Finish          ),
    .o_PsumData             ( w_lq_PsumData                 ),
    .o_PsumValid            ( w_lq_PsumValid                )
);

SystolicController_Slave#(
    .CALC_LINEAR_K          ( 0                             ) // CALC_LINEAR_K == 0 Calc K Mtrx else Calc V Mtrx
) u_SystolicController_Slave_K(
    .s_clk                  ( s_clk                         ),
    .s_rst                  ( s_rst                         ),

    .i_MasterSend_valid     ( m00_MtrxA_slice_valid         ), // FROM Master-Controller
    .i_MasterSend_data      ( m00_MtrxA_slice_data          ),
    .i_MasterSend_done      ( m00_MtrxA_slice_done          ),

    .i_weight_out           ( w_lk_weight_out               ),
    .o_weight_valid         ( w_lk_weight_valid             ),
    .i_weight_ready         ( w_lk_weight_ready             ),

    .o_Init_PrepareData     ( w_lk_Init_PrepareData         ),
    .i_Finish_Calc          ( w_lk_Finish_Calc              ),

    .MtrxA_slice_valid      ( s00_MtrxA_slice_valid         ),
    .MtrxA_slice_data       ( s00_MtrxA_slice_data          ),
    .MtrxA_slice_done       ( s00_MtrxA_slice_done          ),
    .MtrxA_slice_ready      ( s00_MtrxA_slice_ready         ),
    .MtrxB_slice_valid      ( s00_MtrxB_slice_valid         ),
    .MtrxB_slice_data       ( s00_MtrxB_slice_data          ),
    .MtrxB_slice_done       ( s00_MtrxB_slice_done          ),
    .MtrxB_slice_ready      ( s00_MtrxB_slice_ready         ),

    .o_PsumFIFO_Grant       ( w_lk_PsumFIFO_Grant           ),
    .o_PsumFIFO_Valid       ( w_lk_PsumFIFO_Valid           ),
    .i_PsumFIFO_Data        ( w_lk_PsumFIFO_Data            ),

    .o_Psum_Finish          ( w_lk_PsumFIFO_Finish          ),
    .o_PsumData             ( w_lk_PsumData                 ),
    .o_PsumValid            ( w_lk_PsumValid                )
);

SystolicController_Slave#(
    .CALC_LINEAR_K          ( 1                             ) // CALC_LINEAR_K == 0 Calc K Mtrx else Calc V Mtrx
) u_SystolicController_Slave_V(
    .s_clk                  ( s_clk                         ),
    .s_rst                  ( s_rst                         ),

    .i_MasterSend_valid     ( m00_MtrxA_slice_valid         ), // FROM Master-Controller
    .i_MasterSend_data      ( m00_MtrxA_slice_data          ),
    .i_MasterSend_done      ( m00_MtrxA_slice_done          ),

    .i_weight_out           ( w_lv_weight_out               ),
    .o_weight_valid         ( w_lv_weight_valid             ),
    .i_weight_ready         ( w_lv_weight_ready             ),

    .o_Init_PrepareData     ( w_lv_Init_PrepareData         ),
    .i_Finish_Calc          ( w_lv_Finish_Calc              ),

    .MtrxA_slice_valid      ( s01_MtrxA_slice_valid         ),
    .MtrxA_slice_data       ( s01_MtrxA_slice_data          ),
    .MtrxA_slice_done       ( s01_MtrxA_slice_done          ),
    .MtrxA_slice_ready      ( s01_MtrxA_slice_ready         ),
    .MtrxB_slice_valid      ( s01_MtrxB_slice_valid         ),
    .MtrxB_slice_data       ( s01_MtrxB_slice_data          ),
    .MtrxB_slice_done       ( s01_MtrxB_slice_done          ),
    .MtrxB_slice_ready      ( s01_MtrxB_slice_ready         ),

    .o_PsumFIFO_Grant       ( w_lv_PsumFIFO_Grant           ),
    .o_PsumFIFO_Valid       ( w_lv_PsumFIFO_Valid           ),
    .i_PsumFIFO_Data        ( w_lv_PsumFIFO_Data            ),

    .o_Psum_Finish          ( w_lv_PsumFIFO_Finish          ),
    .o_PsumData             ( w_lv_PsumData                 ),
    .o_PsumValid            ( w_lv_PsumValid                )
);

// ---------------  Systolic Array --------------- \\ 
SystolicArray u_SystolicArray_Q(
    .s_clk                  ( s_clk                         ),
    .s_rst                  ( s_rst                         ),

    .i_Init_PrepareData     ( w_Ary00_Init_PrepareData      ), // w_lq_Init_PrepareData
    .o_Finish_Calc          ( w_Ary00_Finish_Calc           ), // w_lq_Finish_Calc     

    .MtrxA_slice_valid      ( w_Ary00_MtrxA_slice_valid     ), // m00_MtrxA_slice_valid
    .MtrxA_slice_data       ( w_Ary00_MtrxA_slice_data      ), // m00_MtrxA_slice_data 
    .MtrxA_slice_done       ( w_Ary00_MtrxA_slice_done      ), // m00_MtrxA_slice_done 
    .MtrxA_slice_ready      ( w_Ary00_MtrxA_slice_ready     ), // m00_MtrxA_slice_ready

    .MtrxB_slice_valid      ( m00_MtrxB_slice_valid         ),
    .MtrxB_slice_data       ( m00_MtrxB_slice_data          ),
    .MtrxB_slice_done       ( m00_MtrxB_slice_done          ),
    .MtrxB_slice_ready      ( m00_MtrxB_slice_ready         ),

    .i_PsumFIFO_Grant       ( w_Ary00_PsumFIFO_Grant        ), // w_lq_PsumFIFO_Grant  
    .i_PsumFIFO_Valid       ( w_Ary00_PsumFIFO_Valid        ), // w_lq_PsumFIFO_Valid  
    .o_PsumFIFO_Data        ( w_Ary00_PsumFIFO_Data         )  // w_lq_PsumFIFO_Data   
);

SystolicArray u_SystolicArray_K(
    .s_clk                  ( s_clk                         ),
    .s_rst                  ( s_rst                         ),

    .i_Init_PrepareData     ( w_Ary01_Init_PrepareData      ), // w_lk_Init_PrepareData  
    .o_Finish_Calc          ( w_Ary01_Finish_Calc           ), // w_lk_Finish_Calc       

    .MtrxA_slice_valid      ( w_Ary01_MtrxA_slice_valid     ), // s00_MtrxA_slice_valid  
    .MtrxA_slice_data       ( w_Ary01_MtrxA_slice_data      ), // s00_MtrxA_slice_data   
    .MtrxA_slice_done       ( w_Ary01_MtrxA_slice_done      ), // s00_MtrxA_slice_done   
    .MtrxA_slice_ready      ( w_Ary01_MtrxA_slice_ready     ), // s00_MtrxA_slice_ready  

    .MtrxB_slice_valid      ( s00_MtrxB_slice_valid         ),   
    .MtrxB_slice_data       ( s00_MtrxB_slice_data          ),   
    .MtrxB_slice_done       ( s00_MtrxB_slice_done          ),   
    .MtrxB_slice_ready      ( s00_MtrxB_slice_ready         ),   

    .i_PsumFIFO_Grant       ( w_Ary01_PsumFIFO_Grant        ), // w_lk_PsumFIFO_Grant    
    .i_PsumFIFO_Valid       ( w_Ary01_PsumFIFO_Valid        ), // w_lk_PsumFIFO_Valid    
    .o_PsumFIFO_Data        ( w_Ary01_PsumFIFO_Data         )  // w_lk_PsumFIFO_Data     
);

SystolicArray u_SystolicArray_V(
    .s_clk                  ( s_clk                         ),
    .s_rst                  ( s_rst                         ),

    .i_Init_PrepareData     ( w_Ary02_Init_PrepareData      ), //w_lv_Init_PrepareData  
    .o_Finish_Calc          ( w_Ary02_Finish_Calc           ), //w_lv_Finish_Calc       

    .MtrxA_slice_valid      ( w_Ary02_MtrxA_slice_valid     ), //s01_MtrxA_slice_valid  
    .MtrxA_slice_data       ( w_Ary02_MtrxA_slice_data      ), //s01_MtrxA_slice_data   
    .MtrxA_slice_done       ( w_Ary02_MtrxA_slice_done      ), //s01_MtrxA_slice_done   
    .MtrxA_slice_ready      ( w_Ary02_MtrxA_slice_ready     ), //s01_MtrxA_slice_ready  

    .MtrxB_slice_valid      ( s01_MtrxB_slice_valid         ), 
    .MtrxB_slice_data       ( s01_MtrxB_slice_data          ), 
    .MtrxB_slice_done       ( s01_MtrxB_slice_done          ), 
    .MtrxB_slice_ready      ( s01_MtrxB_slice_ready         ), 

    .i_PsumFIFO_Grant       ( w_Ary02_PsumFIFO_Grant        ), //w_lv_PsumFIFO_Grant    
    .i_PsumFIFO_Valid       ( w_Ary02_PsumFIFO_Valid        ), //w_lv_PsumFIFO_Valid    
    .o_PsumFIFO_Data        ( w_Ary02_PsumFIFO_Data         )  //w_lv_PsumFIFO_Data     
 );

// --------------- Lif Group --------------- \\ 
LIF_group u_LIF_group_Q(
    .s_clk                  ( s_clk                         ),
    .s_rst                  ( s_rst                         ),

    .i_lif_thrd             ( 'd128                         ), // FIXME: 具体阈值看算法
    .i_PsumValid            ( w_lq_PsumValid                ),
    .i_PsumData             ( w_lq_PsumData                 ),

    .o_spikes_out           ( w_lq_spikes_out               ),
    .o_spikes_valid         ( w_lq_spikes_valid             )
);

LIF_group u_LIF_group_K(
    .s_clk                  ( s_clk                         ),
    .s_rst                  ( s_rst                         ),

    .i_lif_thrd             ( 'd128                         ),
    .i_PsumValid            ( w_lk_PsumValid                ),
    .i_PsumData             ( w_lk_PsumData                 ),

    .o_spikes_out           ( w_lk_spikes_out               ),
    .o_spikes_valid         ( w_lk_spikes_valid             )
);

LIF_group u_LIF_group_V(
    .s_clk                  ( s_clk                         ),
    .s_rst                  ( s_rst                         ),

    .i_lif_thrd             ( 'd128                         ),
    .i_PsumValid            ( w_lv_PsumValid                ),
    .i_PsumData             ( w_lv_PsumData                 ),

    .o_spikes_out           ( w_lv_spikes_out               ),
    .o_spikes_valid         ( w_lv_spikes_valid             )
);

qkv_Reshape u_qkv_Reshape(
    .s_clk                  ( s_clk                         ),
    .s_rst                  ( s_rst                         ),
    .i00_spikes_out         ( w_lq_spikes_out               ),
    .i00_spikes_valid       ( w_lq_spikes_valid             ),
    .i01_spikes_out         ( w_lk_spikes_out               ),
    .i01_spikes_valid       ( w_lk_spikes_valid             ),
    .i02_spikes_out         ( w_lv_spikes_out               ),
    .i02_spikes_valid       ( w_lv_spikes_valid             ),

    .o00_spikesLine_out     ( w00_spikesLine_out            ),
    .o00_spikesLine_valid   ( w00_spikesLine_valid          ),
    .o01_spikesLine_out     ( w01_spikesLine_out            ),
    .o01_spikesLine_valid   ( w01_spikesLine_valid          ),
    .o02_spikesLine_out     ( w02_spikesLine_out            ),
    .o02_spikesLine_valid   ( w02_spikesLine_valid          )
);

// --------------- qkv-BRAM Group --------------- \\ 
qkv_BRAM_group u_qkv_BRAM_group(
    .s_clk                  ( s_clk                         ),
    .s_rst                  ( s_rst                         ),

    .i00_spikesLine_in      ( w00_spikesLine_out            ),
    .i00_spikesLine_valid   ( w00_spikesLine_valid          ),
    .i01_spikesLine_in      ( w01_spikesLine_out            ),
    .i01_spikesLine_valid   ( w01_spikesLine_valid          ),
    .i02_spikesLine_in      ( w02_spikesLine_out            ),
    .i02_spikesLine_valid   ( w02_spikesLine_valid          ),

    .o_SpikesTmpRam_Ready   ( w_SpikesTmpRam_Ready          ),
    .i_QueryRam_rdaddr      ( w_QueryRam_rdaddr             ),
    .o_QueryRam_out         ( w_QueryRam_out                ),
    .i_KeyRam_rdaddr        ( w_KeyRam_rdaddr               ),
    .o_KeyRam_out           ( w_KeyRam_out                  ),

    .i_ValueRam_rdaddr      ( w_ValueRam_rdaddr             ),
    .o_ValueRam_out         ( w_ValueRam_out                )
);

SpikesAccumulation u_SpikesAccumulation(
    .s_clk                 ( s_clk                          ),
    .s_rst                 ( s_rst                          ),

    .i_SpikesTmpRam_Ready  ( w_SpikesTmpRam_Ready           ),
    .o_QueryRam_rdaddr     ( w_QueryRam_rdaddr              ),
    .i_QueryRam_out        ( w_QueryRam_out                 ),
    .o_KeyRam_rdaddr       ( w_KeyRam_rdaddr                ),
    .i_KeyRam_out          ( w_KeyRam_out                   ),

    .i_AttnRAM_Ready       ( w_AttnRAM_Ready                ),
    .o_Calc_data           ( w_Calc_data                    ),
    .o_Calc_valid          ( w_Calc_valid                   )
);

Tmp_AttnRAM_group u_Tmp_AttnRAM_group(
    .s_clk                 ( s_clk                          ),
    .s_rst                 ( s_rst                          ),

    .o_AttnRAM_Ready       ( w_AttnRAM_Ready                ),
    .i_Calc_data           ( w_Calc_data                    ),
    .i_Calc_valid          ( w_Calc_valid                   ),

    .i_AttnRam_Done        ( w_AttnRam_Done                 ),
    .i_AttnRam_rd_addr     ( w_AttnRam_rd_addr              ),
    .o_AttnRAM_Empty       ( w_AttnRAM_Empty                ),
    .o_AttnRAM_data        ( w_AttnRAM_data                 )
);

MM_Calculator u_MM_Calculator(
    .s_clk                 ( s_clk                          ),
    .s_rst                 ( s_rst                          ),

    .o_AttnRam_Done        ( w_AttnRam_Done                 ),
    .o_AttnRam_rd_addr     ( w_AttnRam_rd_addr              ),
    .i_AttnRAM_Empty       ( w_AttnRAM_Empty                ),
    .i_AttnRAM_data        ( w_AttnRAM_data                 ),

    .o_ValueRam_rdaddr     ( w_ValueRam_rdaddr              ),
    .i_ValueRam_out        ( w_ValueRam_out                 ),

    .o_attn_v_spikes_data  ( w_attn_v_spikes_data           ),
    .o_attn_v_spikes_valid ( w_attn_v_spikes_valid          ),
    .o_attn_v_spikes_done  ( w_attn_v_spikes_done           )
);

// --------------- Systolic Signal Arbit Proc --------------- \\ 
assign w_Ary00_Init_PrepareData = r_attn_v_spikes_Finish[2][4] ? w_mlp_Init_PrepareData : w_lq_Init_PrepareData ;
assign w_Ary01_Init_PrepareData = r_attn_v_spikes_Finish[2][4] ? w_mlp_Init_PrepareData : w_lk_Init_PrepareData ;
assign w_Ary02_Init_PrepareData = r_attn_v_spikes_Finish[2][4] ? w_mlp_Init_PrepareData : w_lv_Init_PrepareData ;

assign w_lq_Finish_Calc = r_attn_v_spikes_Finish[2][5] ? 1'b0 : w_Ary00_Finish_Calc;
assign w_lk_Finish_Calc = r_attn_v_spikes_Finish[2][5] ? 1'b0 : w_Ary01_Finish_Calc;
assign w_lv_Finish_Calc = r_attn_v_spikes_Finish[2][5] ? 1'b0 : w_Ary02_Finish_Calc;

assign w00_mlp_Finish_Calc = r_attn_v_spikes_Finish[2][6] ? w_Ary00_Finish_Calc : 1'b0;
assign w01_mlp_Finish_Calc = r_attn_v_spikes_Finish[2][6] ? w_Ary01_Finish_Calc : 1'b0;
assign w02_mlp_Finish_Calc = r_attn_v_spikes_Finish[2][6] ? w_Ary02_Finish_Calc : 1'b0;

assign m00_MtrxA_slice_ready = r_attn_v_spikes_Finish[2][7] ? 1'b0 : w_Ary00_MtrxA_slice_ready;
assign s00_MtrxA_slice_ready = r_attn_v_spikes_Finish[2][7] ? 1'b0 : w_Ary01_MtrxA_slice_ready;
assign s01_MtrxA_slice_ready = r_attn_v_spikes_Finish[2][7] ? 1'b0 : w_Ary02_MtrxA_slice_ready;

assign w_mlp_Mtrx00_slice_ready = r_attn_v_spikes_Finish[2][4] ? w_Ary00_MtrxA_slice_ready : 1'b0;
assign w_mlp_Mtrx01_slice_ready = r_attn_v_spikes_Finish[2][4] ? w_Ary01_MtrxA_slice_ready : 1'b0;
assign w_mlp_Mtrx02_slice_ready = r_attn_v_spikes_Finish[2][4] ? w_Ary02_MtrxA_slice_ready : 1'b0;

assign w_Ary00_MtrxA_slice_valid = r_attn_v_spikes_Finish[2][0] ? w_mlp_Mtrx00_slice_valid : m00_MtrxA_slice_valid;
assign w_Ary00_MtrxA_slice_data  = r_attn_v_spikes_Finish[0][1] ? w_mlp_Mtrx00_slice_data  : m00_MtrxA_slice_data ;
assign w_Ary00_MtrxA_slice_done  = r_attn_v_spikes_Finish[2][0] ? w_mlp_Mtrx00_slice_done  : m00_MtrxA_slice_done ;

assign w_Ary01_MtrxA_slice_valid = r_attn_v_spikes_Finish[2][1] ? w_mlp_Mtrx01_slice_valid : s00_MtrxA_slice_valid;
assign w_Ary01_MtrxA_slice_data  = r_attn_v_spikes_Finish[1][0] ? w_mlp_Mtrx01_slice_data  : s00_MtrxA_slice_data ;
assign w_Ary01_MtrxA_slice_done  = r_attn_v_spikes_Finish[2][1] ? w_mlp_Mtrx01_slice_done  : s00_MtrxA_slice_done ;

assign w_Ary02_MtrxA_slice_valid = r_attn_v_spikes_Finish[2][2] ? w_mlp_Mtrx02_slice_valid : s01_MtrxA_slice_valid;
assign w_Ary02_MtrxA_slice_data  = r_attn_v_spikes_Finish[1][1] ? w_mlp_Mtrx02_slice_data  : s01_MtrxA_slice_data ;
assign w_Ary02_MtrxA_slice_done  = r_attn_v_spikes_Finish[2][2] ? w_mlp_Mtrx02_slice_done  : s01_MtrxA_slice_done ;

assign w_Ary00_PsumFIFO_Grant = r_attn_v_spikes_Finish[1][2] ? w00_mlp_PsumFIFO_Grant : w_lq_PsumFIFO_Grant;
assign w_Ary01_PsumFIFO_Grant = r_attn_v_spikes_Finish[1][3] ? w01_mlp_PsumFIFO_Grant : w_lk_PsumFIFO_Grant;
assign w_Ary02_PsumFIFO_Grant = r_attn_v_spikes_Finish[2][0] ? w02_mlp_PsumFIFO_Grant : w_lv_PsumFIFO_Grant;

assign w_Ary00_PsumFIFO_Valid = r_attn_v_spikes_Finish[2][1] ? w00_mlp_PsumFIFO_Valid : w_lq_PsumFIFO_Valid;
assign w_Ary01_PsumFIFO_Valid = r_attn_v_spikes_Finish[2][2] ? w01_mlp_PsumFIFO_Valid : w_lk_PsumFIFO_Valid;
assign w_Ary02_PsumFIFO_Valid = r_attn_v_spikes_Finish[2][3] ? w02_mlp_PsumFIFO_Valid : w_lv_PsumFIFO_Valid;

assign w00_mlp_PsumFIFO_Data = r_attn_v_spikes_Finish[1][2] ? w_Ary00_PsumFIFO_Data : 'd0;
assign w01_mlp_PsumFIFO_Data = r_attn_v_spikes_Finish[1][3] ? w_Ary01_PsumFIFO_Data : 'd0;
assign w02_mlp_PsumFIFO_Data = r_attn_v_spikes_Finish[2][0] ? w_Ary02_PsumFIFO_Data : 'd0;

assign w_lq_PsumFIFO_Data = r_attn_v_spikes_Finish[2][1] ? 'd0 : w_Ary00_PsumFIFO_Data;
assign w_lk_PsumFIFO_Data = r_attn_v_spikes_Finish[2][2] ? 'd0 : w_Ary01_PsumFIFO_Data;
assign w_lv_PsumFIFO_Data = r_attn_v_spikes_Finish[2][3] ? 'd0 : w_Ary02_PsumFIFO_Data;

// --------------- MLPs --------------- \\ 
mlp_controller u_mlp_controller(
    .s_clk                 ( s_clk                              ),
    .s_rst                 ( s_rst                              ),

    .i_multi_linear_start  ( r_attn_v_spikes_done[2]            ),

    .o_Mlp_Ram00_wea       ( w_Mlp_Ram00_wea                    ),
    .o_Mlp_Ram00_addra     ( w_Mlp_Ram00_addra                  ),
    .o_Mlp_Ram00_dina      ( w_Mlp_Ram00_dina                   ),
    .o_Mlp_Ram00_addrb     ( w_Mlp_Ram00_addrb                  ),
    .i_Mlp_Ram00_doutb     ( w_Mlp_Ram00_doutb                  ),
    
    .o_Mlp_Ram01_wea       ( w_Mlp_Ram01_wea                    ),
    .o_Mlp_Ram01_addra     ( w_Mlp_Ram01_addra                  ),
    .o_Mlp_Ram01_dina      ( w_Mlp_Ram01_dina                   ),
    .o_Mlp_Ram01_addrb     ( w_Mlp_Ram01_addrb                  ),
    .i_Mlp_Ram01_doutb     ( w_Mlp_Ram01_doutb                  ),

    .o_Mlp_Ram02_wea       ( w_Mlp_Ram02_wea                    ),
    .o_Mlp_Ram02_addra     ( w_Mlp_Ram02_addra                  ),
    .o_Mlp_Ram02_dina      ( w_Mlp_Ram02_dina                   ),
    .o_Mlp_Ram02_addrb     ( w_Mlp_Ram02_addrb                  ),
    .i_Mlp_Ram02_doutb     ( w_Mlp_Ram02_doutb                  ),

    .o_Init_PrepareData    ( w_mlp_Init_PrepareData             ),

    .o_Mtrx00_slice_valid  ( w_mlp_Mtrx00_slice_valid           ),
    .o_Mtrx00_slice_data   ( w_mlp_Mtrx00_slice_data            ),
    .o_Mtrx00_slice_done   ( w_mlp_Mtrx00_slice_done            ),
    .i_Mtrx00_slice_ready  ( w_mlp_Mtrx00_slice_ready           ),

    .o_Mtrx01_slice_valid  ( w_mlp_Mtrx01_slice_valid           ),
    .o_Mtrx01_slice_data   ( w_mlp_Mtrx01_slice_data            ),
    .o_Mtrx01_slice_done   ( w_mlp_Mtrx01_slice_done            ),
    .i_Mtrx01_slice_ready  ( w_mlp_Mtrx01_slice_ready           ),

    .o_Mtrx02_slice_valid  ( w_mlp_Mtrx02_slice_valid           ),
    .o_Mtrx02_slice_data   ( w_mlp_Mtrx02_slice_data            ),
    .o_Mtrx02_slice_done   ( w_mlp_Mtrx02_slice_done            ),
    .i_Mtrx02_slice_ready  ( w_mlp_Mtrx02_slice_ready           ),

    .o00_PsumFIFO_Grant    ( w00_mlp_PsumFIFO_Grant             ),
    .o00_PsumFIFO_Valid    ( w00_mlp_PsumFIFO_Valid             ),
    .i00_PsumFIFO_Data     ( w00_mlp_PsumFIFO_Data              ),
    .i00_Finish_Calc       ( w00_mlp_Finish_Calc                ),

    .o01_PsumFIFO_Grant    ( w01_mlp_PsumFIFO_Grant             ),
    .o01_PsumFIFO_Valid    ( w01_mlp_PsumFIFO_Valid             ),
    .i01_PsumFIFO_Data     ( w01_mlp_PsumFIFO_Data              ),
    .i01_Finish_Calc       ( w01_mlp_Finish_Calc                ),

    .o02_PsumFIFO_Grant    ( w02_mlp_PsumFIFO_Grant             ),
    .o02_PsumFIFO_Valid    ( w02_mlp_PsumFIFO_Valid             ),
    .i02_PsumFIFO_Data     ( w02_mlp_PsumFIFO_Data              ),
    .i02_Finish_Calc       ( w02_mlp_Finish_Calc                ) 
);

// r_MLP_in_addr    
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst || w_attn_v_spikes_done) 
        r_MLP_in_addr <= 'd0;
    else if (w_attn_v_spikes_valid)
        r_MLP_in_addr <= r_MLP_in_addr + 1'b1;
end

always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) begin
        r_attn_v_spikes_Finish[0][0] <= 1'b0;
        r_attn_v_spikes_Finish[0][1] <= 1'b0;
    end
    else if (w_attn_v_spikes_done) begin
        r_attn_v_spikes_Finish[0][0] <= 1'b1;
        r_attn_v_spikes_Finish[0][1] <= 1'b1;
    end
end

always@(posedge s_clk) begin
    r_attn_v_spikes_Finish[1][0] <= r_attn_v_spikes_Finish[0][0];
    r_attn_v_spikes_Finish[1][1] <= r_attn_v_spikes_Finish[0][0];

    r_attn_v_spikes_Finish[1][2] <= r_attn_v_spikes_Finish[0][1];
    r_attn_v_spikes_Finish[1][3] <= r_attn_v_spikes_Finish[0][1];

    r_attn_v_spikes_Finish[2][0] <= r_attn_v_spikes_Finish[1][0];
    r_attn_v_spikes_Finish[2][1] <= r_attn_v_spikes_Finish[1][0];
    r_attn_v_spikes_Finish[2][2] <= r_attn_v_spikes_Finish[1][1];
    r_attn_v_spikes_Finish[2][3] <= r_attn_v_spikes_Finish[1][1];

    r_attn_v_spikes_Finish[2][4] <= r_attn_v_spikes_Finish[1][2];
    r_attn_v_spikes_Finish[2][5] <= r_attn_v_spikes_Finish[1][2];
    r_attn_v_spikes_Finish[2][6] <= r_attn_v_spikes_Finish[1][3];
    r_attn_v_spikes_Finish[2][7] <= r_attn_v_spikes_Finish[1][3];

    r_attn_v_spikes_done <= {r_attn_v_spikes_done[1 : 0], w_attn_v_spikes_done};
end

assign w_TmpSpikesRam01_wea   = r_attn_v_spikes_Finish[0][0] ? w_Mlp_Ram01_wea   : w_attn_v_spikes_valid ;
assign w_TmpSpikesRam01_addra = r_attn_v_spikes_Finish[0][0] ? w_Mlp_Ram01_addra : r_MLP_in_addr         ;
assign w_TmpSpikesRam01_dina  = r_attn_v_spikes_Finish[0][0] ? w_Mlp_Ram01_dina  : w_attn_v_spikes_data  ;

MLP_hidden_TmpSpikesRam u_MLP_TmpSpikesRam01 (
    .clka               ( s_clk                         ),
    .wea                ( w_TmpSpikesRam01_wea          ),
    .addra              ( w_TmpSpikesRam01_addra        ),
    .dina               ( w_TmpSpikesRam01_dina         ),

    .clkb               ( s_clk                         ),
    .addrb              ( w_Mlp_Ram01_addrb             ), // [13 : 0]
    .doutb              ( w_Mlp_Ram01_doutb             ) 
);

EmbeddedRAM u_MLP_TmpSpikesRam02 (
    .clka               ( s_clk                         ),
    .wea                ( w_Mlp_Ram02_wea               ), 
    .addra              ( w_Mlp_Ram02_addra             ), 
    .dina               ( w_Mlp_Ram02_dina              ), 

    .clkb               ( s_clk                         ),
    .addrb              ( w_Mlp_Ram02_addrb             ),  // [11 : 0]
    .doutb              ( w_Mlp_Ram02_doutb             )  
);


/*
    todo : r_attn_v_spikes_Finish -> fanout 的问题
*/

endmodule // TOP_Transformer
