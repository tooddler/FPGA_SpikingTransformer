/*
    -- psum LIF --
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "E:/Desktop/Zynq_Spikformer/Zynq_Spikformer.srcs/sources_1/hyper_para.v"
module psum_lif_top (
    input                                                      s_clk               ,
    input                                                      s_rst               ,

    input                                                      code_valid          ,
    input        [15:0]                                        conv_lif_thrd       ,
    input        [15:0]                                        conv_img_size       ,

    input                                                      read_1line_req      ,
    input        [`ERS_MAX_WIDTH * `TIME_STEPS - 1 : 0]        read_1line_data     ,
    input signed [`ERS_MAX_WIDTH - 1 : 0]                      conv_bias_ext       ,   

    output wire                                                Array_out_valid     , 
    output wire[`IMG_WIDTH*`TIME_STEPS - 1 : 0]                Array_out_spikes        
);

wire  [`TIME_STEPS - 1 : 0]                              w_spikes_out          ;
wire                                                     w_spikes_valid        ;

wire                                                     w_spike_t0            ;
wire                                                     w_spike_t1            ;            
wire                                                     w_spike_t2            ;            
wire                                                     w_spike_t3            ;            

wire                                                     w_spike_valid_t0      ;
wire                                                     w_spike_valid_t1      ;            
wire                                                     w_spike_valid_t2      ;            
wire                                                     w_spike_valid_t3      ;

wire signed [`ERS_MAX_WIDTH - 1 : 0]                     w_psum_add_bias_t0    ;
wire signed [`ERS_MAX_WIDTH - 1 : 0]                     w_psum_add_bias_t1    ;            
wire signed [`ERS_MAX_WIDTH - 1 : 0]                     w_psum_add_bias_t2    ;            
wire signed [`ERS_MAX_WIDTH - 1 : 0]                     w_psum_add_bias_t3    ;  

wire  [`ERS_MAX_WIDTH - 1 : 0]                           w_nxt_mem_t0          ;
wire  [`ERS_MAX_WIDTH - 1 : 0]                           w_nxt_mem_t1          ;            
wire  [`ERS_MAX_WIDTH - 1 : 0]                           w_nxt_mem_t2          ;            
wire  [`ERS_MAX_WIDTH - 1 : 0]                           w_nxt_mem_t3          ;

reg [`ERS_MAX_WIDTH * `TIME_STEPS - 1 : 0]               r_read_1line_data_d0  ;
reg [`ERS_MAX_WIDTH * `TIME_STEPS - 1 : 0]               r_read_1line_data_d1  ;
reg [`ERS_MAX_WIDTH * `TIME_STEPS - 1 : 0]               r_read_1line_data_d2  ;
reg [`ERS_MAX_WIDTH * `TIME_STEPS - 1 : 0]               r_read_1line_data_d3  ;
reg [`ERS_MAX_WIDTH * `TIME_STEPS - 1 : 0]               r_read_1line_data_d4  ;

reg                                                      r_read_1line_req_d0   ;
reg                                                      r_read_1line_req_d1   ;

reg [`ERS_MAX_WIDTH - 1 : 0]                             r_conv_lif_thrd       ;

reg                                                      r_spike_t0_decay1=0   ;
reg                                                      r_spike_t0_decay2=0   ;
reg                                                      r_spike_t0_decay3=0   ;
reg                                                      r_spike_t1_decay1=0   ;
reg                                                      r_spike_t1_decay2=0   ;
reg                                                      r_spike_t2_decay1=0   ;

// ------------- debug part -------------

wire signed [`ERS_MAX_WIDTH - 1 : 0]                     w_debugdot_t0    ;
wire signed [`ERS_MAX_WIDTH - 1 : 0]                     w_debugdot_t1    ;
wire signed [`ERS_MAX_WIDTH - 1 : 0]                     w_debugdot_t2    ;
wire signed [`ERS_MAX_WIDTH - 1 : 0]                     w_debugdot_t3    ;

assign w_debugdot_t0 = r_read_1line_data_d0[`ERS_MAX_WIDTH*1 - 1 : `ERS_MAX_WIDTH*0];
assign w_debugdot_t1 = r_read_1line_data_d0[`ERS_MAX_WIDTH*2 - 1 : `ERS_MAX_WIDTH*1];
assign w_debugdot_t2 = r_read_1line_data_d0[`ERS_MAX_WIDTH*3 - 1 : `ERS_MAX_WIDTH*2];
assign w_debugdot_t3 = r_read_1line_data_d0[`ERS_MAX_WIDTH*4 - 1 : `ERS_MAX_WIDTH*3];

// ------------- end debug part -------------

assign w_spikes_out       = {w_spike_t3, r_spike_t2_decay1, r_spike_t1_decay2, r_spike_t0_decay3} ;
assign w_spikes_valid     = w_spike_valid_t3                                                      ;

assign w_psum_add_bias_t0 = $signed(r_read_1line_data_d0[`ERS_MAX_WIDTH*1 - 1 : `ERS_MAX_WIDTH*0]) + $signed(conv_bias_ext);
assign w_psum_add_bias_t1 = $signed(r_read_1line_data_d0[`ERS_MAX_WIDTH*2 - 1 : `ERS_MAX_WIDTH*1]) + $signed(conv_bias_ext);
assign w_psum_add_bias_t2 = $signed(r_read_1line_data_d0[`ERS_MAX_WIDTH*3 - 1 : `ERS_MAX_WIDTH*2]) + $signed(conv_bias_ext);
assign w_psum_add_bias_t3 = $signed(r_read_1line_data_d0[`ERS_MAX_WIDTH*4 - 1 : `ERS_MAX_WIDTH*3]) + $signed(conv_bias_ext);

always@(posedge s_clk) begin
    r_read_1line_data_d0 <= read_1line_data      ;
    r_read_1line_data_d1 <= {w_psum_add_bias_t3, w_psum_add_bias_t2, w_psum_add_bias_t1, w_psum_add_bias_t0};
    r_read_1line_data_d2 <= r_read_1line_data_d1 ;
    r_read_1line_data_d3 <= r_read_1line_data_d2 ;
    r_read_1line_data_d4 <= r_read_1line_data_d3 ;

    r_read_1line_req_d0  <= read_1line_req       ;
    r_read_1line_req_d1  <= r_read_1line_req_d0  ;

    r_spike_t0_decay1    <= w_spike_t0           ;
    r_spike_t0_decay2    <= r_spike_t0_decay1    ;
    r_spike_t0_decay3    <= r_spike_t0_decay2    ;
    
    r_spike_t1_decay1    <= w_spike_t1           ;
    r_spike_t1_decay2    <= r_spike_t1_decay1    ;
    
    r_spike_t2_decay1    <= w_spike_t2           ;
end

// r_conv_lif_thrd
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_conv_lif_thrd <= 'd0;
    else if (code_valid)
        r_conv_lif_thrd <= conv_lif_thrd;
end

proj_lif #(
    .ADD9_ALL_BITS      ( `ERS_MAX_WIDTH     )
) u_proj_lif_t0 (
    .s_clk              ( s_clk              ),
    .s_rst              ( s_rst              ),

    .THRESHOLD          ( r_conv_lif_thrd    ),
    .i_delta_mem        ( r_read_1line_data_d1[`ERS_MAX_WIDTH*1 - 1 : `ERS_MAX_WIDTH*0]  ),
    .i_delta_mem_valid  ( r_read_1line_req_d1),
    .i_pre_mem          ( 'd0                ),

    .o_spike            ( w_spike_t0         ),
    .o_delta_mem_valid  ( w_spike_valid_t0   ),
    .o_nxt_mem          ( w_nxt_mem_t0       )
);

proj_lif #(
    .ADD9_ALL_BITS      ( `ERS_MAX_WIDTH     )
) u_proj_lif_t1 (
    .s_clk              ( s_clk              ),
    .s_rst              ( s_rst              ),
    
    .THRESHOLD          ( r_conv_lif_thrd    ),
    .i_delta_mem        ( r_read_1line_data_d2[`ERS_MAX_WIDTH*2 - 1 : `ERS_MAX_WIDTH*1]  ),
    .i_delta_mem_valid  ( w_spike_valid_t0   ),
    .i_pre_mem          ( w_nxt_mem_t0       ),

    .o_spike            ( w_spike_t1         ),
    .o_delta_mem_valid  ( w_spike_valid_t1   ),
    .o_nxt_mem          ( w_nxt_mem_t1       )
);

proj_lif #(
    .ADD9_ALL_BITS      ( `ERS_MAX_WIDTH     )
) u_proj_lif_t2 (
    .s_clk              ( s_clk              ),
    .s_rst              ( s_rst              ),

    .THRESHOLD          ( r_conv_lif_thrd    ),
    .i_delta_mem        ( r_read_1line_data_d3[`ERS_MAX_WIDTH*3 - 1 : `ERS_MAX_WIDTH*2]  ),
    .i_delta_mem_valid  ( w_spike_valid_t1   ),
    .i_pre_mem          ( w_nxt_mem_t1       ),

    .o_spike            ( w_spike_t2         ),
    .o_delta_mem_valid  ( w_spike_valid_t2   ),
    .o_nxt_mem          ( w_nxt_mem_t2       )
);

proj_lif #(
    .ADD9_ALL_BITS      ( `ERS_MAX_WIDTH     )
) u_proj_lif_t3 (
    .s_clk              ( s_clk              ),
    .s_rst              ( s_rst              ),

    .THRESHOLD          ( r_conv_lif_thrd    ),
    .i_delta_mem        ( r_read_1line_data_d4[`ERS_MAX_WIDTH*4 - 1 : `ERS_MAX_WIDTH*3]  ),
    .i_delta_mem_valid  ( w_spike_valid_t2   ),
    .i_pre_mem          ( w_nxt_mem_t2       ),

    .o_spike            ( w_spike_t3         ),
    .o_delta_mem_valid  ( w_spike_valid_t3   ),
    .o_nxt_mem          ( w_nxt_mem_t3       )
);

Organize_data_unit_v1 u_Organize_data_unit_v1(
    .s_clk              ( s_clk              ),
    .s_rst              ( s_rst              ),

    .code_valid         ( code_valid         ),
    .conv_img_size      ( conv_img_size      ),

    .i_spikes_in        ( w_spikes_out       ),
    .i_spikes_in_valid  ( w_spikes_valid     ),

    .o_line_data_valid  ( Array_out_valid    ),
    .o_line_data        ( Array_out_spikes   )
);


endmodule // psum_lif_top


