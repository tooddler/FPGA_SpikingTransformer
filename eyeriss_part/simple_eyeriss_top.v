/*
    --- Simple Eyeriss Top --- 
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "../hyper_para.v"
module simple_eyeriss_top (
    input                                           s_clk                     ,
    input                                           s_rst                     ,
    // calculate done
    input                                           SPS_part_done             , // global rst
    // interact with weights RAM
    input         [`DATA_WIDTH - 1 : 0]             weight_in                 ,
    input                                           weight_valid              ,
    output wire                                     o_weight_ready            ,
    // get spikes from SpikingEncoder module
    input                                           SpikingEncoder_out_done   ,
    input         [`TIME_STEPS - 1 : 0]             SpikingEncoder_out        ,
    input                                           SpikingEncoder_out_valid  , 
    // send fmaps and patch
    output reg                                      o_data_valid              ,
    output reg    [`PATCH_EMBED_WIDTH - 1 : 0]      o_fmap                    ,
    output reg    [`PATCH_EMBED_WIDTH - 1 : 0]      o_patchdata               
);

localparam P_MAXADDR = `FINAL_FMAPS_CHNNLS * 8 ;  // FIXME: ofmap_size = 384 x 8 x 8

wire                                                 w_line_data_valid       ;
wire [`IMG_WIDTH*`TIME_STEPS - 1 : 0]                w_line_data             ;
wire [12:0]                                          w_TmpRam00_wraddr       ;
wire                                                 w_TmpRam00_valid        ;
wire [`IMG_WIDTH*`TIME_STEPS - 1 : 0]                w_TmpRam00_data         ;

wire                                                 fetch_code_done         ;
wire                                                 code_valid              ;    
wire [15:0]                                          conv_in_ch              ;
wire [15:0]                                          conv_out_ch             ;
wire [15:0]                                          conv_img_size           ;
wire [15:0]                                          conv_lif_thrd           ;
wire [15:0]                                          conv_bias_scale         ;
wire                                                 conv_or_maxpool         ;

wire                                                 ifmap_spikes_valid      ; 
wire [`IMG_WIDTH*`TIME_STEPS - 1 : 0]                ifmap_spikes            ; 
wire                                                 ifmap_spikes_done       ;
wire                                                 ifmap_spikes_ready      ; 

wire                                                 Control_spikes_valid    ; 
wire [`IMG_WIDTH*`TIME_STEPS - 1 : 0]                Control_spikes          ; 
wire                                                 Control_spikes_done     ;
wire                                                 Control_spikes_ready    ; 

wire                                                 pool_spikes_valid       ;
wire [`IMG_WIDTH*`TIME_STEPS - 1 : 0]                pool_spikes             ;
wire                                                 pool_spikes_ready       ;

wire                                                 Array_out_valid         ;  
wire [`IMG_WIDTH*`TIME_STEPS - 1 : 0]                Array_out_spikes        ;  
wire                                                 Array_out_done          ;  
wire                                                 Array_out_ready         ;  

wire                                                 Control_out_valid       ;  
wire [`IMG_WIDTH*`TIME_STEPS - 1 : 0]                Control_out_spikes      ;  
wire                                                 Control_out_done        ;  
wire                                                 Control_out_ready       ; 

wire                                                 Pooling_out_valid       ;  
wire [`IMG_WIDTH*`TIME_STEPS - 1 : 0]                Pooling_out_spikes      ;  
wire                                                 Pooling_out_done        ;  
wire                                                 Pooling_out_ready       ; 

wire                                                 Control_TmpRam00_wea    ; 
wire  [12 : 0]                                       Control_TmpRam00_addra  ; 
wire  [`IMG_WIDTH*`TIME_STEPS - 1 : 0]               Control_TmpRam00_dina   ;
wire  [12 : 0]                                       Control_TmpRam00_addrb  ; 
reg   [`IMG_WIDTH*`TIME_STEPS - 1 : 0]               Control_TmpRam00_doutb  ;

wire                                                 Control_TmpRam01_wea    ; 
wire  [12 : 0]                                       Control_TmpRam01_addra  ; 
wire  [`IMG_WIDTH*`TIME_STEPS - 1 : 0]               Control_TmpRam01_dina   ;
wire  [12 : 0]                                       Control_TmpRam01_addrb  ; 
reg   [`IMG_WIDTH*`TIME_STEPS - 1 : 0]               Control_TmpRam01_doutb  ;

wire  [`IMG_WIDTH*`TIME_STEPS - 1 : 0]               w_spikes_TmpRam00_doutb ;
wire  [`IMG_WIDTH*`TIME_STEPS - 1 : 0]               w_spikes_TmpRam01_doutb ;

wire                                                 w_sps_DataGetReady      ;
wire  [12 : 0]                                       w_Final_TmpRam00_addrb  ; 
wire  [12 : 0]                                       w_Final_TmpRam01_addrb  ; 

reg  [12:0]                                          r_TmpRam00_wraddr       ;
reg                                                  r_TmpRam00_mode         ;
reg  [12:0]                                          r_GetData2Attnpart_addr ;
reg                                                  r_sps_DataGetReady      ;
reg                                                  r_data_valid_d0         ;
reg                                                  r_data_valid_d1         ;
reg                                                  r_data_valid_d2         ;

assign w_TmpRam00_wraddr    = r_TmpRam00_mode ? Control_TmpRam00_addra : r_TmpRam00_wraddr ;
assign w_TmpRam00_valid     = r_TmpRam00_mode ? Control_TmpRam00_wea   : w_line_data_valid ;
assign w_TmpRam00_data      = r_TmpRam00_mode ? Control_TmpRam00_dina  : w_line_data       ;

assign ifmap_spikes_valid   = conv_or_maxpool ? 'd0 : Control_spikes_valid                 ;
assign ifmap_spikes         = conv_or_maxpool ? 'd0 : Control_spikes                       ;
assign ifmap_spikes_done    = conv_or_maxpool ? 'd0 : Control_spikes_done                  ;

assign Control_spikes_ready = conv_or_maxpool ? pool_spikes_ready : ifmap_spikes_ready     ;

assign pool_spikes_valid    = conv_or_maxpool ? Control_spikes_valid : 'd0                 ;
assign pool_spikes          = conv_or_maxpool ? Control_spikes       : 'd0                 ; 

assign Control_out_valid    = conv_or_maxpool ? Pooling_out_valid  : Array_out_valid       ;
assign Control_out_spikes   = conv_or_maxpool ? Pooling_out_spikes : Array_out_spikes      ;
assign Control_out_done     = conv_or_maxpool ? Pooling_out_done   : Array_out_done        ;

assign Pooling_out_ready    = conv_or_maxpool ? Control_out_ready : 1'b0                   ;
assign Array_out_ready      = conv_or_maxpool ? 1'b0 : Control_out_ready                   ;

assign w_Final_TmpRam00_addrb = r_sps_DataGetReady ? r_GetData2Attnpart_addr : Control_TmpRam00_addrb ;
assign w_Final_TmpRam01_addrb = r_sps_DataGetReady ? r_GetData2Attnpart_addr : Control_TmpRam01_addrb ;

// r_TmpRam00_mode
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_TmpRam00_mode <= 1'b0;
    else if (SPS_part_done)
        r_TmpRam00_mode <= 1'b0;
    else if (SpikingEncoder_out_done)
        r_TmpRam00_mode <= 1'b1;
end

// r_TmpRam00_wraddr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_TmpRam00_wraddr <= 'd0;
    else if (SpikingEncoder_out_done)
        r_TmpRam00_wraddr <= 'd0;
    else if (w_line_data_valid)
        r_TmpRam00_wraddr <= r_TmpRam00_wraddr + 1'b1;
end

always@(posedge s_clk) begin
    r_sps_DataGetReady <= w_sps_DataGetReady;
    r_data_valid_d1    <= r_data_valid_d0   ;
    r_data_valid_d2    <= r_data_valid_d1   ;
    o_data_valid       <= r_data_valid_d2   ;

    Control_TmpRam00_doutb <= w_spikes_TmpRam00_doutb ;
    Control_TmpRam01_doutb <= w_spikes_TmpRam01_doutb ;
end

// o_fmap     
always@(posedge s_clk) begin
    if (r_sps_DataGetReady)
        o_fmap <= Control_TmpRam00_doutb[`PATCH_EMBED_WIDTH - 1 : 0];
    else   
        o_fmap <= 'd0;
end

// o_patchdata
always@(posedge s_clk) begin
    if (r_sps_DataGetReady)
        o_patchdata <= Control_TmpRam01_doutb[`PATCH_EMBED_WIDTH - 1 : 0];
    else   
        o_patchdata <= 'd0;
end

// r_GetData2Attnpart_addr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_GetData2Attnpart_addr <= 'd0;
    else if (r_data_valid_d0)
        r_GetData2Attnpart_addr <= r_GetData2Attnpart_addr + 1'b1;
end

// r_data_valid
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst || r_GetData2Attnpart_addr == P_MAXADDR - 1)
        r_data_valid_d0 <= 1'b0;
    else if (w_sps_DataGetReady && ~r_sps_DataGetReady)
        r_data_valid_d0 <= 1'b1;
end

// --------------- instantiation --------------- \\ 
Organize_data_unit u_Organize_data_unit (
    .s_clk                     ( s_clk                     ),
    .s_rst                     ( s_rst                     ),
    .SpikingEncoder_out_done   ( SpikingEncoder_out_done   ),
    .SpikingEncoder_out        ( SpikingEncoder_out        ),
    .SpikingEncoder_out_valid  ( SpikingEncoder_out_valid  ),
    .o_line_data_valid         ( w_line_data_valid         ),
    .o_line_data               ( w_line_data               )
);

simple_eyeriss_Controller u_simple_eyeriss_Controller(
    .s_clk                     ( s_clk                    ),
    .s_rst                     ( s_rst                    ),

    .SpikingEncoder_out_done   ( SpikingEncoder_out_done  ),
    .SPS_part_done             ( SPS_part_done            ), 
    .o_fetch_code_done         ( fetch_code_done          ),
    .o_sps_DataGetReady        ( w_sps_DataGetReady       ),

    .o_code_valid              ( code_valid               ),
    .o_conv_in_ch              ( conv_in_ch               ),
    .o_conv_out_ch             ( conv_out_ch              ),
    .o_conv_img_size           ( conv_img_size            ),
    .o_conv_lif_thrd           ( conv_lif_thrd            ),
    .o_conv_bias_scale         ( conv_bias_scale          ),
    .o_conv_or_maxpool         ( conv_or_maxpool          ),

    .TmpRam00_wea              ( Control_TmpRam00_wea     ),
    .TmpRam00_addra            ( Control_TmpRam00_addra   ),
    .TmpRam00_dina             ( Control_TmpRam00_dina    ),
    .TmpRam00_addrb            ( Control_TmpRam00_addrb   ),
    .TmpRam00_doutb            ( Control_TmpRam00_doutb   ),

    .TmpRam01_wea              ( Control_TmpRam01_wea     ),
    .TmpRam01_addra            ( Control_TmpRam01_addra   ),
    .TmpRam01_dina             ( Control_TmpRam01_dina    ),
    .TmpRam01_addrb            ( Control_TmpRam01_addrb   ),
    .TmpRam01_doutb            ( Control_TmpRam01_doutb   ),
    
    .ifmap_spikes_valid        ( Control_spikes_valid     ),
    .ifmap_spikes              ( Control_spikes           ),
    .ifmap_spikes_done         ( Control_spikes_done      ),
    .ifmap_spikes_ready        ( Control_spikes_ready     ),
    
    .Array_out_valid           ( Control_out_valid        ),
    .Array_out_spikes          ( Control_out_spikes       ),
    .Array_out_done            ( Control_out_done         ),
    .Array_out_ready           ( Control_out_ready        )
);

simple_eyeriss_array u_simple_eyeriss_array(
    .s_clk                     ( s_clk                 ),
    .s_rst                     ( s_rst                 ),

    .fetch_code_done           ( fetch_code_done       ),
    .SPS_part_done             ( SPS_part_done         ),

    .code_valid                ( code_valid            ),
    .conv_in_ch                ( conv_in_ch            ),
    .conv_out_ch               ( conv_out_ch           ),
    .conv_img_size             ( conv_img_size         ),
    .conv_lif_thrd             ( conv_lif_thrd         ),
    .conv_bias_scale           ( conv_bias_scale       ),
    .conv_or_maxpool           ( conv_or_maxpool       ),

    .weight_in                 ( weight_in             ),
    .weight_valid              ( weight_valid          ),
    .o_weight_ready            ( o_weight_ready        ),

    .i_spikes_valid            ( ifmap_spikes_valid    ),
    .i_spikes                  ( ifmap_spikes          ),
    .i_spikes_done             ( ifmap_spikes_done     ),
    .o_spikes_ready            ( ifmap_spikes_ready    ),

    .Array_out_valid           ( Array_out_valid       ),
    .Array_out_spikes          ( Array_out_spikes      ),
    .Array_out_done            ( Array_out_done        ),
    .Array_out_ready           ( Array_out_ready       )
);

simple_maxpool_unit u_simple_maxpool_unit(
    .s_clk                     ( s_clk                ),
    .s_rst                     ( s_rst                ),

    .code_valid                ( code_valid           ),
    .conv_in_ch                ( conv_in_ch           ),
    .conv_img_size             ( conv_img_size        ),
    .conv_or_maxpool           ( conv_or_maxpool      ),

    .i_spikes_valid            ( pool_spikes_valid    ),
    .i_spikes                  ( pool_spikes          ),
    .o_spikes_ready            ( pool_spikes_ready    ),

    .Pooling_out_valid         ( Pooling_out_valid    ),
    .Pooling_out_spikes        ( Pooling_out_spikes   ),
    .Pooling_out_done          ( Pooling_out_done     ),
    .Pooling_out_ready         ( Pooling_out_ready    )
);


SpikesTmpRam SpikesTmpRam_m00 (
    .clka                      ( s_clk                     ),  // input wire clka
    .wea                       ( w_TmpRam00_valid          ),  // input wire [0 : 0] wea
    .addra                     ( w_TmpRam00_wraddr         ),  // input wire [12 : 0] addra
    .dina                      ( w_TmpRam00_data           ),  // input wire [127 : 0] dina

    .clkb                      ( s_clk                     ),  // input wire clkb
    .addrb                     ( w_Final_TmpRam00_addrb    ),  // input wire [12 : 0] addrb
    .doutb                     ( w_spikes_TmpRam00_doutb   )   // output wire [127 : 0] doutb
);

SpikesTmpRam SpikesTmpRam_m01 (
    .clka                      ( s_clk                     ),  // input wire clka
    .wea                       ( Control_TmpRam01_wea      ),  // input wire [0 : 0] wea
    .addra                     ( Control_TmpRam01_addra    ),  // input wire [12 : 0] addra
    .dina                      ( Control_TmpRam01_dina     ),  // input wire [127 : 0] dina

    .clkb                      ( s_clk                     ),  // input wire clkb
    .addrb                     ( w_Final_TmpRam01_addrb    ),  // input wire [12 : 0] addrb
    .doutb                     ( w_spikes_TmpRam01_doutb   )   // output wire [127 : 0] doutb
);

endmodule // simple_eyeriss_top
