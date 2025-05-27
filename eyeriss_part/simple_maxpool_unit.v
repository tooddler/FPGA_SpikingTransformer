/*
    - Maxpool2d(k=3, s=2, p=1) - :
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "E:/Desktop/spiking_transformer/spiking_transformer/spiking_transformer.srcs/sources_1/imports/FPGA_SpikingTransformer/hyper_para.v"
module simple_maxpool_unit (
    input                                             s_clk               ,
    input                                             s_rst               ,
    // -- code
    input                                             code_valid          ,
    input       [15:0]                                conv_in_ch          ,
    input       [15:0]                                conv_img_size       ,
    input                                             conv_or_maxpool     ,
    // -- spikes in
    input                                             i_spikes_valid      ,
    input       [`IMG_WIDTH*`TIME_STEPS - 1 : 0]      i_spikes            ,
    output reg                                        o_spikes_ready=0    ,
    // -- spikes out
    output reg                                        Pooling_out_valid   , 
    output reg  [`IMG_WIDTH*`TIME_STEPS - 1 : 0]      Pooling_out_spikes  , 
    output reg                                        Pooling_out_done=0  ,
    input                                             Pooling_out_ready         
);

wire                                                  w_fifo_full                               ;
wire                                                  w_fifo_empty                              ;
wire [`IMG_WIDTH*`TIME_STEPS - 1 : 0]                 w_fifo_rd_data                            ;
wire [`IMG_WIDTH*`TIME_STEPS - 1 : 0]                 w_spikes_in                               ;
wire [`MAXPOOL2D_NUM - 1 : 0]                         w_Pooling_valid                           ; 
wire [`IMG_WIDTH*`TIME_STEPS - 1 : 0]                 w_Pooling_data[`MAXPOOL2D_NUM - 1 : 0]    ;
wire [`MAXPOOL2D_NUM - 1 : 0]                         w_calculating_flag                        ;

reg  [`MAXPOOL2D_NUM - 1 : 0]                         r_calculating_flag                        ;
reg  [`IMG_WIDTH*`TIME_STEPS - 1 : 0]                 r_pre_Pooling_data                        ;  
reg                                                   r_pre_Pooling_valid=0                     ;
reg  [15:0]                                           r_conv_in_ch                              ;
reg  [15:0]                                           r_conv_img_size                           ;
reg                                                   r_conv_or_maxpool                         ;

reg  [`IMG_WIDTH*`TIME_STEPS - 1 : 0]                 r_row_data_tmp0                           ;
reg  [`IMG_WIDTH*`TIME_STEPS - 1 : 0]                 r_row_data_tmp1                           ;
reg  [`IMG_WIDTH*`TIME_STEPS - 1 : 0]                 r_row_data_tmp2                           ;
reg                                                   r_row_data_valid=0                        ;
reg                                                   r_row_data_valid_d0=0                     ;
reg                                                   r_row_data_valid_d1=0                     ;
reg                                                   r_row_data_valid_d2=0                     ;
reg                                                   r_row_data_valid_d3=0                     ;

reg                                                   r_padding_flag=0                          ;
reg  [9:0]                                            r_row_cnt                                 ;
reg  [9:0]                                            r_chnnl_cnt                               ;
reg  [1:0]                                            r_pooling_pre_cnt                         ;

reg  [`MAXPOOL2D_NUM - 1 : 0]                         r_demux_valid='d0                         ;                                                
reg  [`MAXPOOL2D_NUM - 1 : 0]                         r_mux_valid='d0                           ;   

reg                                                   r_spikes_in_valid=0                       ;
reg                                                   r_spikes_in_valid_d0=0                    ;

assign w_spikes_in = r_padding_flag ? 'd0 : w_fifo_rd_data ;

// --------------- code fetch --------------- \\ 
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) begin
        r_conv_in_ch      <= 'd0  ;
        r_conv_img_size   <= 'd0  ;
        r_conv_or_maxpool <= 1'b0 ;
    end
    else if ((r_chnnl_cnt == r_conv_in_ch - 1) && (r_row_cnt == r_conv_img_size - 2)) begin
        r_conv_in_ch      <= r_conv_in_ch   ;
        r_conv_img_size   <= r_conv_img_size;
        r_conv_or_maxpool <= 1'b0;
    end
    else if (code_valid) begin
        r_conv_in_ch      <= conv_in_ch      ;
        r_conv_img_size   <= conv_img_size   ;
        r_conv_or_maxpool <= conv_or_maxpool ;
    end
end

// r_spikes_in_valid
always@(posedge s_clk) begin
    r_spikes_in_valid_d0 <= r_spikes_in_valid;

    if (o_spikes_ready && i_spikes_valid)
        r_spikes_in_valid <= 1'b1;
    else
        r_spikes_in_valid <= 1'b0;
end

// o_spikes_ready
always@(posedge s_clk) begin
    if (r_conv_or_maxpool && Pooling_out_ready)
        o_spikes_ready <= 1'b1;
    else
        o_spikes_ready <= 1'b0;
end

// r_row_data
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) begin
        r_row_data_tmp0 <= 'd0;
        r_row_data_tmp1 <= 'd0;
        r_row_data_tmp2 <= 'd0;
    end
    else if (r_row_data_valid) begin
        r_row_data_tmp0 <= w_spikes_in    ;
        r_row_data_tmp1 <= r_row_data_tmp0;
        r_row_data_tmp2 <= r_row_data_tmp1;
    end
end

// r_chnnl_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_chnnl_cnt <= 'd0;
    else if (r_chnnl_cnt == r_conv_in_ch - 1 && r_row_cnt == r_conv_img_size - 1)
        r_chnnl_cnt <= 'd0;
    else if (r_row_cnt == r_conv_img_size - 1)
        r_chnnl_cnt <= r_chnnl_cnt + 1'b1;
end

// r_row_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_row_cnt <= 'd0;
    else if (r_row_cnt == r_conv_img_size - 1)
        r_row_cnt <= 'd0;
    else if (r_row_data_valid)
        r_row_cnt <= r_row_cnt + 1'b1;
end

// r_row_data_valid 
always@(posedge s_clk) begin
    if (~w_fifo_empty && r_conv_or_maxpool)
        r_row_data_valid <= 1'b1;
    else 
        r_row_data_valid <= 1'b0;
end

always@(posedge s_clk) begin
    r_row_data_valid_d0 <= r_row_data_valid   ;
    r_row_data_valid_d1 <= r_row_data_valid_d0;
    r_row_data_valid_d2 <= r_row_data_valid_d1;
    r_row_data_valid_d3 <= r_row_data_valid_d2;
end

// r_pooling_pre_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_pooling_pre_cnt <= 'd0;
    else if (r_pooling_pre_cnt == 'd1 && r_row_data_valid)
        r_pooling_pre_cnt <= 'd0;
    else if (r_row_data_valid)
        r_pooling_pre_cnt <= r_pooling_pre_cnt + 1'b1;
end

// r_padding_flag 
always@(posedge s_clk) begin
    if ((~w_fifo_empty && ~r_row_data_valid) || r_row_cnt >= r_conv_img_size - 2)
        r_padding_flag <= 1'b1;
    else
        r_padding_flag <= 1'b0;
end

// r_pre_Pooling_data 
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) 
        r_pre_Pooling_data <= 'd0;
    else if (r_pooling_pre_cnt == 'd1 && r_row_data_valid)
        r_pre_Pooling_data <= r_row_data_tmp0 | r_row_data_tmp1 | r_row_data_tmp2;
end

// r_pre_Pooling_valid
always@(posedge s_clk) begin
    if (r_pooling_pre_cnt == 'd1 && r_row_data_valid && r_row_cnt != 'd1)
        r_pre_Pooling_valid <= 1'b1;
    else 
        r_pre_Pooling_valid <= 1'b0;
end

// Pooling_out_done
always@(posedge s_clk) begin
    if (~r_conv_or_maxpool && ((|r_calculating_flag) && ~(|w_calculating_flag)))
        Pooling_out_done <= 1'b1;
    else
        Pooling_out_done <= 1'b0;
end

// --------------- DeMux / Mux --------------- \\ 
// r_demux_valid 
always@(posedge s_clk) begin
    if (code_valid)
        r_demux_valid <= {{(`MAXPOOL2D_NUM - 1){1'b0}}, 1'b1};
    else if (r_pre_Pooling_valid)
        r_demux_valid <= {r_demux_valid[`MAXPOOL2D_NUM - 2 : 0], r_demux_valid[`MAXPOOL2D_NUM - 1]};
end

// r_mux_valid
always@(posedge s_clk) begin
    if (code_valid) 
        r_mux_valid <= 'd0;
    else if (r_mux_valid == `MAXPOOL2D_NUM - 1 && |w_Pooling_valid)
        r_mux_valid <= 'd0;
    else if (|w_Pooling_valid)
        r_mux_valid <= r_mux_valid + 1'b1;
end

// r_calculating_flag
always@(posedge s_clk) begin
    r_calculating_flag <= w_calculating_flag;
end

// Pooling_out_valid 
always@(*) begin
    case(r_mux_valid) 
        'd0 : Pooling_out_valid <= w_Pooling_valid[0];
        'd1 : Pooling_out_valid <= w_Pooling_valid[1];
        'd2 : Pooling_out_valid <= w_Pooling_valid[2];
        'd3 : Pooling_out_valid <= w_Pooling_valid[3];
        'd4 : Pooling_out_valid <= w_Pooling_valid[4];
        'd5 : Pooling_out_valid <= w_Pooling_valid[5];
        'd6 : Pooling_out_valid <= w_Pooling_valid[6];
        'd7 : Pooling_out_valid <= w_Pooling_valid[7];
        'd8 : Pooling_out_valid <= w_Pooling_valid[8];
        'd9 : Pooling_out_valid <= w_Pooling_valid[9];
        'd10: Pooling_out_valid <= w_Pooling_valid[10];
        'd11: Pooling_out_valid <= w_Pooling_valid[11];
        'd12: Pooling_out_valid <= w_Pooling_valid[12];
        'd13: Pooling_out_valid <= w_Pooling_valid[13];
        'd14: Pooling_out_valid <= w_Pooling_valid[14];
        'd15: Pooling_out_valid <= w_Pooling_valid[15];
        default: Pooling_out_valid <= 1'b0;
    endcase        
end

// Pooling_out_spikes
always@(*) begin
    case(r_mux_valid) 
        'd0 : Pooling_out_spikes <= w_Pooling_data[0];
        'd1 : Pooling_out_spikes <= w_Pooling_data[1];
        'd2 : Pooling_out_spikes <= w_Pooling_data[2];
        'd3 : Pooling_out_spikes <= w_Pooling_data[3];
        'd4 : Pooling_out_spikes <= w_Pooling_data[4];
        'd5 : Pooling_out_spikes <= w_Pooling_data[5];
        'd6 : Pooling_out_spikes <= w_Pooling_data[6];
        'd7 : Pooling_out_spikes <= w_Pooling_data[7];
        'd8 : Pooling_out_spikes <= w_Pooling_data[8];
        'd9 : Pooling_out_spikes <= w_Pooling_data[9];
        'd10: Pooling_out_spikes <= w_Pooling_data[10];
        'd11: Pooling_out_spikes <= w_Pooling_data[11];
        'd12: Pooling_out_spikes <= w_Pooling_data[12];
        'd13: Pooling_out_spikes <= w_Pooling_data[13];
        'd14: Pooling_out_spikes <= w_Pooling_data[14];
        'd15: Pooling_out_spikes <= w_Pooling_data[15];
        default: Pooling_out_spikes <= 'd0;
    endcase        
end

genvar i;
generate

    for (i = 0; i < `MAXPOOL2D_NUM; i = i + 1) begin
        
        simple_maxpool_row_unit u_simple_maxpool_row_unit(
            .s_clk              ( s_clk             ),
            .s_rst              ( s_rst             ),

            .code_valid         ( code_valid        ),
            .conv_in_ch         ( conv_in_ch        ),
            .conv_img_size      ( conv_img_size     ),

            .i_row_data_valid   ( r_demux_valid[i] && r_pre_Pooling_valid),
            .i_row_data         ( r_pre_Pooling_data                     ),

            .o_calculating_flag ( w_calculating_flag[i]                  ),
            .o_pooling_valid    ( w_Pooling_valid[i]                     ),
            .o_pooling_data     ( w_Pooling_data[i]                      )
        );

    end

endgenerate

MaxPool_fifo u_MaxPool_fifo (
    .clk        ( s_clk                               ),
    .srst       ( s_rst || Pooling_out_done           ),
    .din        ( i_spikes                            ),  // input wire [127 : 0] din
    .wr_en      ( r_spikes_in_valid_d0                ),  // input wire wr_en
    
    .rd_en      ( r_row_data_valid && ~r_padding_flag ),  // input wire rd_en
    .dout       ( w_fifo_rd_data                      ),  // output wire [127 : 0] dout
    .full       ( w_fifo_full                         ),
    .empty      ( w_fifo_empty                        )
);

endmodule // simple_maxpool_unit


