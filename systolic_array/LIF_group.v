/*
    -- LIF-Group --
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "../hyper_para.v"
module LIF_group (
    input                                                  s_clk               ,
    input                                                  s_rst               ,

    input        [`SYSTOLIC_PSUM_WIDTH / 4 - 1 : 0]        i_lif_thrd          ,
    input                                                  i_PsumValid         ,
    input        [`SYSTOLIC_PSUM_WIDTH - 1 : 0]            i_PsumData          ,

    output wire  [`TIME_STEPS - 1 : 0]                     o_spikes_out        ,
    output wire                                            o_spikes_valid      
);

wire                                          w_spike_t0            ;
wire                                          w_spike_t1            ;            
wire                                          w_spike_t2            ;            
wire                                          w_spike_t3            ;            

wire                                          w_spike_valid_t0      ;
wire                                          w_spike_valid_t1      ;            
wire                                          w_spike_valid_t2      ;            
wire                                          w_spike_valid_t3      ;

wire  [`SYSTOLIC_PSUM_WIDTH / 4 - 1 : 0]      w_nxt_mem_t0          ;
wire  [`SYSTOLIC_PSUM_WIDTH / 4 - 1 : 0]      w_nxt_mem_t1          ;            
wire  [`SYSTOLIC_PSUM_WIDTH / 4 - 1 : 0]      w_nxt_mem_t2          ;            
wire  [`SYSTOLIC_PSUM_WIDTH / 4 - 1 : 0]      w_nxt_mem_t3          ;

reg [`SYSTOLIC_PSUM_WIDTH - 1 : 0]            r_PsumData_d0=0       ;   
reg [`SYSTOLIC_PSUM_WIDTH - 1 : 0]            r_PsumData_d1=0       ;   
reg [`SYSTOLIC_PSUM_WIDTH - 1 : 0]            r_PsumData_d2=0       ;   
reg [`SYSTOLIC_PSUM_WIDTH - 1 : 0]            r_PsumData_d3=0       ;   

reg                                           r_PsumValid_d0=0      ;
reg                                           r_PsumValid_d1=0      ;
reg                                           r_PsumValid_d2=0      ;
reg                                           r_PsumValid_d3=0      ;

reg                                           r_spike_t0_decay1=0   ;
reg                                           r_spike_t0_decay2=0   ;
reg                                           r_spike_t0_decay3=0   ;
reg                                           r_spike_t1_decay1=0   ;
reg                                           r_spike_t1_decay2=0   ;
reg                                           r_spike_t2_decay1=0   ;

assign o_spikes_out   = {w_spike_t3, r_spike_t2_decay1, r_spike_t1_decay2, r_spike_t0_decay3} ;
assign o_spikes_valid = w_spike_valid_t3                                                      ;

always@(posedge s_clk) begin
    r_PsumData_d0     <= i_PsumData        ;
    r_PsumData_d1     <= r_PsumData_d0     ;
    r_PsumData_d2     <= r_PsumData_d1     ;
    r_PsumData_d3     <= r_PsumData_d2     ;

    r_PsumValid_d0    <= i_PsumValid       ;
    r_PsumValid_d1    <= r_PsumValid_d0    ;
    r_PsumValid_d2    <= r_PsumValid_d1    ;
    r_PsumValid_d3    <= r_PsumValid_d2    ;

    r_spike_t0_decay1 <= w_spike_t0        ;
    r_spike_t0_decay2 <= r_spike_t0_decay1 ;
    r_spike_t0_decay3 <= r_spike_t0_decay2 ;
    
    r_spike_t1_decay1 <= w_spike_t1        ;
    r_spike_t1_decay2 <= r_spike_t1_decay1 ;
    
    r_spike_t2_decay1 <= w_spike_t2        ;
end

proj_lif #(
    .ADD9_ALL_BITS      ( `SYSTOLIC_PSUM_WIDTH / 4                        )
) u_proj_lif_t0 (
    .s_clk              ( s_clk                                           ),
    .s_rst              ( s_rst                                           ),
 
    .THRESHOLD          ( i_lif_thrd                                      ),
    .i_delta_mem        ( r_PsumData_d0[`SYSTOLIC_PSUM_WIDTH/4 - 1 : 0]   ),
    .i_delta_mem_valid  ( r_PsumValid_d0                                  ),
    .i_pre_mem          ( 'd0                                             ),

    .o_spike            ( w_spike_t0                                      ),
    .o_delta_mem_valid  ( w_spike_valid_t0                                ),
    .o_nxt_mem          ( w_nxt_mem_t0                                    )
);

proj_lif #(
    .ADD9_ALL_BITS      ( `SYSTOLIC_PSUM_WIDTH / 4                        )
) u_proj_lif_t1 (
    .s_clk              ( s_clk                                           ),
    .s_rst              ( s_rst                                           ),
    
    .THRESHOLD          ( i_lif_thrd                                      ),
    .i_delta_mem        ( r_PsumData_d1[`SYSTOLIC_PSUM_WIDTH*2/4 - 1 : `SYSTOLIC_PSUM_WIDTH/4]),
    .i_delta_mem_valid  ( w_spike_valid_t0                                ),
    .i_pre_mem          ( w_nxt_mem_t0                                    ),

    .o_spike            ( w_spike_t1                                      ),
    .o_delta_mem_valid  ( w_spike_valid_t1                                ),
    .o_nxt_mem          ( w_nxt_mem_t1                                    )
);

proj_lif #(
    .ADD9_ALL_BITS      ( `SYSTOLIC_PSUM_WIDTH / 4                        )
) u_proj_lif_t2 (
    .s_clk              ( s_clk                                           ),
    .s_rst              ( s_rst                                           ),

    .THRESHOLD          ( i_lif_thrd                                      ),
    .i_delta_mem        ( r_PsumData_d2[`SYSTOLIC_PSUM_WIDTH*3/4 - 1 : `SYSTOLIC_PSUM_WIDTH*2/4]),
    .i_delta_mem_valid  ( w_spike_valid_t1                                ),
    .i_pre_mem          ( w_nxt_mem_t1                                    ),

    .o_spike            ( w_spike_t2                                      ),
    .o_delta_mem_valid  ( w_spike_valid_t2                                ),
    .o_nxt_mem          ( w_nxt_mem_t2                                    )
);

proj_lif #(
    .ADD9_ALL_BITS      ( `SYSTOLIC_PSUM_WIDTH / 4                        )
) u_proj_lif_t3 (
    .s_clk              ( s_clk                                           ),
    .s_rst              ( s_rst                                           ),

    .THRESHOLD          ( i_lif_thrd                                      ),
    .i_delta_mem        ( r_PsumData_d3[`SYSTOLIC_PSUM_WIDTH - 1 : `SYSTOLIC_PSUM_WIDTH*3/4]),
    .i_delta_mem_valid  ( w_spike_valid_t2                                ),
    .i_pre_mem          ( w_nxt_mem_t2                                    ),

    .o_spike            ( w_spike_t3                                      ),
    .o_delta_mem_valid  ( w_spike_valid_t3                                ),
    .o_nxt_mem          ( w_nxt_mem_t3                                    )
);


endmodule // LIF_group
