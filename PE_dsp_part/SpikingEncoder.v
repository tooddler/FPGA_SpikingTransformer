/*
    -- Spiking Encoder --
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "../hyper_para.v"
module SpikingEncoder (
    input                                                s_clk                       ,
    input                                                s_rst                       ,
    input                                                network_cal_done            ,
    
    input           [`DATA_WIDTH- 1 : 0]                 burst_read_data             ,
    output wire     [`ADDR_SIZE - 1 : 0]                 burst_read_addr             ,
    output          [`LEN_WIDTH - 1 : 0]                 burst_read_len              ,
    output wire                                          burst_read_req              ,
    input                                                burst_read_valid            ,
    input                                                burst_read_finish           ,

    output  wire    [`DATA_WIDTH - 1 : 0]                Eyeriss_weight_in           ,
    output  wire                                         Eyeriss_weight_valid        ,
    input                                                Eyeriss_weight_ready        ,
    input                                                i_weight_load_done          ,

    output reg                                           o_SpikingEncoder_out_done=0 ,
    output wire     [`TIME_STEPS - 1 : 0]                o_SpikingEncoder_out        ,
    output wire                                          o_SpikingEncoder_out_valid
);

wire [`DATA_WIDTH- 1 : 0]                                r00_burst_read_data   ;
wire [`ADDR_SIZE - 1 : 0]                                r00_burst_read_addr   ;
wire [`LEN_WIDTH - 1 : 0]                                r00_burst_read_len    ;
wire                                                     r00_burst_read_req    ;
wire                                                     r00_burst_read_valid  ;
wire                                                     r00_burst_read_finish ;

wire [`DATA_WIDTH- 1 : 0]                                r01_burst_read_data   ;
wire [`ADDR_SIZE - 1 : 0]                                r01_burst_read_addr   ;
wire [`LEN_WIDTH - 1 : 0]                                r01_burst_read_len    ;
wire                                                     r01_burst_read_req    ;
wire                                                     r01_burst_read_valid  ;
wire                                                     r01_burst_read_finish ;

wire [`DATA_WIDTH - 1 : 0]                               o_weight_out          ;
wire                                                     o_weight_valid        ;
wire                                                     weight_ready          ;
wire                                                     load_w_finish         ;

wire [`DATA_WIDTH - 1 : 0]                               layer1_weight_out     ;
wire                                                     layer1_weight_valid   ;
wire                                                     layer1_weight_ready   ;
wire                                                     layer1_load_w_finish  ;

wire [`QUAN_BITS - 1 : 0]                                o_feature_data_ch0    ;
wire [`QUAN_BITS - 1 : 0]                                o_feature_data_ch1    ;
wire [`QUAN_BITS - 1 : 0]                                o_feature_data_ch2    ;
wire                                                     o_f_data_valid        ;
wire                                                     data_ready            ;
wire                                                     data_load_done        ;
wire                                                     o_load_d_once_done    ;

wire                                                     w_spike_t0            ;
wire                                                     w_spike_t1            ;            
wire                                                     w_spike_t2            ;            
wire                                                     w_spike_t3            ;            

wire                                                     w_spike_valid_t0      ;
wire                                                     w_spike_valid_t1      ;            
wire                                                     w_spike_valid_t2      ;            
wire                                                     w_spike_valid_t3      ;  

wire  [`ADD9_ALL_BITS - 1 : 0]                           w_nxt_mem_t0          ;
wire  [`ADD9_ALL_BITS - 1 : 0]                           w_nxt_mem_t1          ;            
wire  [`ADD9_ALL_BITS - 1 : 0]                           w_nxt_mem_t2          ;            
wire  [`ADD9_ALL_BITS - 1 : 0]                           w_nxt_mem_t3          ;

wire  [`ADD9_ALL_BITS - 1 : 0]                           o_conv1_out           ;
wire                                                     o_conv1_out_valid     ;

reg   [`ADD9_ALL_BITS - 1 : 0]                           r_conv_out_d0='d0     ;
reg   [`ADD9_ALL_BITS - 1 : 0]                           r_conv_out_d1='d0     ;
reg   [`ADD9_ALL_BITS - 1 : 0]                           r_conv_out_d2='d0     ;
reg                                                      r_conv_out_valid_d0=0 ;
reg                                                      r_conv_out_valid_d1=0 ;
reg                                                      r_conv_out_valid_d2=0 ;

reg                                                      r_spike_t0_decay1=0   ;
reg                                                      r_spike_t0_decay2=0   ;
reg                                                      r_spike_t0_decay3=0   ;
reg                                                      r_spike_t1_decay1=0   ;
reg                                                      r_spike_t1_decay2=0   ;
reg                                                      r_spike_t2_decay1=0   ;
reg   [9:0]                                              r_spiking_cal_done    ;

assign o_SpikingEncoder_out         = {w_spike_t3, r_spike_t2_decay1, r_spike_t1_decay2, r_spike_t0_decay3} ;
assign o_SpikingEncoder_out_valid   = w_spike_valid_t3                                                      ;

always@(posedge s_clk) begin
    r_conv_out_d0 <= o_conv1_out   ;
    r_conv_out_d1 <= r_conv_out_d0 ;
    r_conv_out_d2 <= r_conv_out_d1 ;

    r_conv_out_valid_d0 <= o_conv1_out_valid   ;
    r_conv_out_valid_d1 <= r_conv_out_valid_d0 ;
    r_conv_out_valid_d2 <= r_conv_out_valid_d1 ;

    r_spike_t0_decay1 <= w_spike_t0         ;
    r_spike_t0_decay2 <= r_spike_t0_decay1  ;
    r_spike_t0_decay3 <= r_spike_t0_decay2  ;
    
    r_spike_t1_decay1 <= w_spike_t1         ;
    r_spike_t1_decay2 <= r_spike_t1_decay1  ;
    
    r_spike_t2_decay1 <= w_spike_t2         ;
end

// r_spiking_cal_done
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_spiking_cal_done <= 'd0;
    else if (o_load_d_once_done)
        r_spiking_cal_done <= 10'b00_0000_0001;
    else
        r_spiking_cal_done <= r_spiking_cal_done << 1;
end

// o_SpikingEncoder_out_done
always@(posedge s_clk) begin
    if (r_spiking_cal_done[9] && data_load_done)
        o_SpikingEncoder_out_done <= 1'b1;
    else
        o_SpikingEncoder_out_done <= 1'b0;
end

round_robin_arb u_round_robin_arb(
    .ddr_clk                 ( s_clk                   ),
    .ddr_rstn                ( ~s_rst                  ),

    .w00_burst_write_data    ( 'd0   ),
    .w00_burst_write_addr    ( 'd0   ),
    .w00_burst_write_len     ( 'd0   ),
    .w00_burst_write_req     ( 1'b0  ),
    .w00_burst_write_valid   (       ),
    .w00_burst_write_finish  (       ),

    .r00_burst_read_data     ( r00_burst_read_data      ),
    .r00_burst_read_addr     ( r00_burst_read_addr      ),
    .r00_burst_read_len      ( r00_burst_read_len       ),
    .r00_burst_read_req      ( r00_burst_read_req       ),
    .r00_burst_read_valid    ( r00_burst_read_valid     ),
    .r00_burst_read_finish   ( r00_burst_read_finish    ),
    
    .w01_burst_write_data    ( 'd0   ),
    .w01_burst_write_addr    ( 'd0   ),
    .w01_burst_write_len     ( 'd0   ),
    .w01_burst_write_req     ( 1'b0  ),
    .w01_burst_write_valid   (       ),
    .w01_burst_write_finish  (       ),
    
    .r01_burst_read_data     ( r01_burst_read_data     ),
    .r01_burst_read_addr     ( r01_burst_read_addr     ),
    .r01_burst_read_len      ( r01_burst_read_len      ),
    .r01_burst_read_req      ( r01_burst_read_req      ),
    .r01_burst_read_valid    ( r01_burst_read_valid    ),
    .r01_burst_read_finish   ( r01_burst_read_finish   ),
    
    .w02_burst_write_data    ( 'd0  ),
    .w02_burst_write_addr    ( 'd0  ),
    .w02_burst_write_len     ( 'd0  ),
    .w02_burst_write_req     ( 1'b0 ),
    .w02_burst_write_valid   (  ),
    .w02_burst_write_finish  (  ),
    
    .r02_burst_read_data     (  ),
    .r02_burst_read_addr     ( 'd0  ),
    .r02_burst_read_len      ( 'd0  ),
    .r02_burst_read_req      ( 1'b0 ),
    .r02_burst_read_valid    (  ),
    .r02_burst_read_finish   (  ),
    
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

features_ram_v1 u_features_ram_v1 (
    .s_clk               ( s_clk                ),
    .s_rst               ( s_rst                ),

    .rd_burst_data       ( r00_burst_read_data  ),
    .rd_burst_addr       ( r00_burst_read_addr  ),
    .rd_burst_len        ( r00_burst_read_len   ),
    .rd_burst_req        ( r00_burst_read_req   ),
    .rd_burst_valid      ( r00_burst_read_valid ),
    .rd_burst_finish     ( r00_burst_read_finish),

    .o_feature_data_ch0  ( o_feature_data_ch0   ),
    .o_feature_data_ch1  ( o_feature_data_ch1   ),
    .o_feature_data_ch2  ( o_feature_data_ch2   ),
    .o_f_data_valid      ( o_f_data_valid       ),
    .data_ready          ( data_ready           ),
    .load_d_once_done    ( o_load_d_once_done   ),
    .data_load_done      ( data_load_done       )
);

assign Eyeriss_weight_in    = layer1_load_w_finish ? o_weight_out    : 'd0;
assign Eyeriss_weight_valid = layer1_load_w_finish ? o_weight_valid  : 'd0;   
assign layer1_weight_out    = layer1_load_w_finish ? 'd0 : o_weight_out   ;
assign layer1_weight_valid  = layer1_load_w_finish ? 'd0 : o_weight_valid ;

assign weight_ready         = layer1_load_w_finish ? Eyeriss_weight_ready : layer1_weight_ready ;
assign load_w_finish        = i_weight_load_done                                                ;

weights_ram u_weights_ram(
    .s_clk               ( s_clk                 ),
    .s_rst               ( s_rst                 ),

    .rd_burst_data       ( r01_burst_read_data   ),
    .rd_burst_addr       ( r01_burst_read_addr   ),
    .rd_burst_len        ( r01_burst_read_len    ),
    .rd_burst_req        ( r01_burst_read_req    ),
    .rd_burst_valid      ( r01_burst_read_valid  ),
    .rd_burst_finish     ( r01_burst_read_finish ),

    .o_weight_out        ( o_weight_out          ),
    .o_weight_valid      ( o_weight_valid        ),
    .weight_ready        ( weight_ready          ),
    .load_w_finish       ( load_w_finish         )
);

conv_layer1 u_conv_layer1 (
    .s_clk               ( s_clk                 ),
    .s_rst               ( s_rst                 ),
   
    .network_cal_done    ( network_cal_done      ),
   
    .feature_data_ch0    ( o_feature_data_ch0    ),
    .feature_data_ch1    ( o_feature_data_ch1    ),
    .feature_data_ch2    ( o_feature_data_ch2    ),
    .f_data_valid        ( o_f_data_valid        ),
    .o_data_ready        ( data_ready            ),
    .o_load_d_finish     ( data_load_done        ),
    .o_load_d_once_done  ( o_load_d_once_done    ),

    .weight_in           ( layer1_weight_out     ),
    .weight_valid        ( layer1_weight_valid   ),
    .o_weight_ready      ( layer1_weight_ready   ),
    .o_load_w_finish     ( layer1_load_w_finish  ),

    .o_conv1_out         ( o_conv1_out           ),
    .o_conv1_out_valid   ( o_conv1_out_valid     )
);

proj_lif #(
    .ADD9_ALL_BITS      ( `ADD9_ALL_BITS     )
) u_proj_lif_t0 (
    .s_clk              ( s_clk              ),
    .s_rst              ( s_rst              ),

    .THRESHOLD          ( `CONV1_THRESHOLD   ),
    .i_delta_mem        ( o_conv1_out        ),
    .i_delta_mem_valid  ( o_conv1_out_valid  ),
    .i_pre_mem          ( 'd0                ),

    .o_spike            ( w_spike_t0         ),
    .o_delta_mem_valid  ( w_spike_valid_t0   ),
    .o_nxt_mem          ( w_nxt_mem_t0       )
);

proj_lif #(
    .ADD9_ALL_BITS      ( `ADD9_ALL_BITS     )
) u_proj_lif_t1 (
    .s_clk              ( s_clk              ),
    .s_rst              ( s_rst              ),

    .THRESHOLD          ( `CONV1_THRESHOLD   ),
    .i_delta_mem        ( r_conv_out_d0      ),
    .i_delta_mem_valid  ( r_conv_out_valid_d0),
    .i_pre_mem          ( w_nxt_mem_t0       ),

    .o_spike            ( w_spike_t1         ),
    .o_delta_mem_valid  ( w_spike_valid_t1   ),
    .o_nxt_mem          ( w_nxt_mem_t1       )
);

proj_lif #(
    .ADD9_ALL_BITS      ( `ADD9_ALL_BITS     )
) u_proj_lif_t2 (
    .s_clk              ( s_clk              ),
    .s_rst              ( s_rst              ),

    .THRESHOLD          ( `CONV1_THRESHOLD   ),
    .i_delta_mem        ( r_conv_out_d1      ),
    .i_delta_mem_valid  ( r_conv_out_valid_d1),
    .i_pre_mem          ( w_nxt_mem_t1       ),

    .o_spike            ( w_spike_t2         ),
    .o_delta_mem_valid  ( w_spike_valid_t2   ),
    .o_nxt_mem          ( w_nxt_mem_t2       )
);

proj_lif #(
    .ADD9_ALL_BITS      ( `ADD9_ALL_BITS     )
) u_proj_lif_t3 (
    .s_clk              ( s_clk              ),
    .s_rst              ( s_rst              ),

    .THRESHOLD          ( `CONV1_THRESHOLD   ),
    .i_delta_mem        ( r_conv_out_d2      ),
    .i_delta_mem_valid  ( r_conv_out_valid_d2),
    .i_pre_mem          ( w_nxt_mem_t2       ),

    .o_spike            ( w_spike_t3         ),
    .o_delta_mem_valid  ( w_spike_valid_t3   ),
    .o_nxt_mem          ( w_nxt_mem_t3       )
);

endmodule // SpikingEncoder
