/*
    -- psum ram callback --
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "E:/Desktop/spiking_transformer/spiking_transformer/spiking_transformer.srcs/sources_1/imports/FPGA_SpikingTransformer/hyper_para.v"
module psum_callback (
    input                                                      s_clk               ,
    input                                                      s_rst               ,
    // conv signal
    input                                                      code_valid          ,
    input     [15:0]                                           conv_in_ch          ,
    input     [15:0]                                           conv_out_ch         ,
    input     [15:0]                                           conv_img_size       ,
    input     [15:0]                                           conv_lif_thrd       ,
    input     [15:0]                                           conv_bias_scale     ,
    input                                                      conv_or_maxpool     ,    
    // interact with psum ram
    input                                                      i_read_data_mode    , // 1: one line; 0: three lines
    output reg [`PSUM_RAM_DEPTH - 1 : 0]                       read_1line_addr     , // 3 clk + 1
    output reg                                                 read_1line_req      ,
    input      [`ERS_MAX_WIDTH * `TIME_STEPS - 1 : 0]          read_1line_data     ,
    // interact with TmpRam
    output wire                                                Array_out_valid     , 
    output wire[`IMG_WIDTH*`TIME_STEPS - 1 : 0]                Array_out_spikes    , 
    output reg                                                 Array_out_done=0      
);

wire signed [`QUAN_BITS - 1 : 0]                              w_bias_rom_out        ;
wire                                                          w_pos_mode_change     ;

reg signed [`ERS_MAX_WIDTH - 1 : 0]                           r_conv_bias_ext       ;
reg  [5:0]                                                    r_bias_scale_cnt      ;

reg                                                           r_read_data_mode_d0   ;
reg  [15:0]                                                   r_conv_in_ch          ;
reg  [15:0]                                                   r_conv_out_ch         ;
reg  [15:0]                                                   r_conv_img_size       ;
reg  [15:0]                                                   r_conv_lif_thrd       ;
reg  [15:0]                                                   r_conv_bias_scale     ;

reg                                                           r_conv_or_maxpool     ;
reg  [1:0]                                                    r_chnnl_cnt           ;
reg  [5:0]                                                    r_ofmap_pos_x         ;
reg  [5:0]                                                    r_ofmap_pos_y         ;

reg  [10:0]                                                   r_bias_addr           ;
reg                                                           r_read_1line_req_d0   ;
reg                                                           r_read_1line_req_d1   ;
reg                                                           r_read_1line_req_d2   ;
reg                                                           r_read_1line_req_d3   ;
reg                                                           r_read_1line_req_d4   ;
reg                                                           r_read_1line_req_d5   ;
reg                                                           r_read_1line_req_d6   ;
reg                                                           r_read_1line_req_d7   ;
reg                                                           r_read_1line_req_d8   ;

reg  [`PSUM_RAM_DEPTH - 1 : 0]                                r_rd_1line_baseaddr   ;

// --------------- code fetch --------------- \\ 
// r_conv
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) begin
        r_conv_in_ch      <= 'd0  ;
        r_conv_out_ch     <= 'd0  ;
        r_conv_img_size   <= 'd0  ;
        r_conv_lif_thrd   <= 'd0  ;
        r_conv_bias_scale <= 'd0  ;
        r_conv_or_maxpool <= 1'b0 ;
    end
    else if (code_valid) begin
        r_conv_in_ch      <= conv_in_ch      ;
        r_conv_out_ch     <= conv_out_ch     ;
        r_conv_img_size   <= conv_img_size   ;
        r_conv_lif_thrd   <= conv_lif_thrd   ;
        r_conv_bias_scale <= conv_bias_scale ;
        r_conv_or_maxpool <= conv_or_maxpool ;
    end
end

// --------------- Psum Ram Read Port --------------- \\ 
assign w_pos_mode_change = ~r_read_data_mode_d0 && i_read_data_mode;

always@(posedge s_clk) begin
    r_read_1line_req_d0 <= read_1line_req      ;
    r_read_1line_req_d1 <= r_read_1line_req_d0 ;
    r_read_1line_req_d2 <= r_read_1line_req_d1 ;
    r_read_1line_req_d3 <= r_read_1line_req_d2 ;
    r_read_1line_req_d4 <= r_read_1line_req_d3 ;
    r_read_1line_req_d5 <= r_read_1line_req_d4 ;
    r_read_1line_req_d6 <= r_read_1line_req_d5 ;
    r_read_1line_req_d7 <= r_read_1line_req_d6 ;
    r_read_1line_req_d8 <= r_read_1line_req_d7 ;

    r_read_data_mode_d0 <= i_read_data_mode;
end

// read_1line_req
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) 
        read_1line_req <= 1'b0;
    else if (r_ofmap_pos_y == r_conv_img_size - 3 && r_ofmap_pos_x == r_conv_img_size - 3)
        read_1line_req <= 1'b0;
    else if (w_pos_mode_change)
        read_1line_req <= 1'b1;
end

// r_chnnl_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) 
        r_chnnl_cnt <= 'd0;
    else if (read_1line_req && r_ofmap_pos_y == r_conv_img_size - 3 && r_ofmap_pos_x == r_conv_img_size - 3)
        r_chnnl_cnt <= 'd0;
    else if (read_1line_req && r_chnnl_cnt == 'd2 && r_ofmap_pos_x == r_conv_img_size - 3)
        r_chnnl_cnt <= 'd0;
    else if (read_1line_req && r_ofmap_pos_x == r_conv_img_size - 3)
        r_chnnl_cnt <= r_chnnl_cnt + 1'b1;
end

// r_ofmap_pos_x
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) 
        r_ofmap_pos_x <= 'd0;
    else if (read_1line_req && r_ofmap_pos_x == r_conv_img_size - 3)
        r_ofmap_pos_x <= 'd0;
    else if (read_1line_req)
        r_ofmap_pos_x <= r_ofmap_pos_x + 1'b1;
end

// r_ofmap_pos_y
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) 
        r_ofmap_pos_y <= 'd0;
    else if (read_1line_req && r_ofmap_pos_y == r_conv_img_size - 3 && r_ofmap_pos_x == r_conv_img_size - 3)
        r_ofmap_pos_y <= 'd0;
    else if (read_1line_req && r_ofmap_pos_x == r_conv_img_size - 3)
        r_ofmap_pos_y <= r_ofmap_pos_y + 1'b1;
end

// r_rd_1line_baseaddr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) 
        r_rd_1line_baseaddr <= 'd0;
    else if (Array_out_done)
        r_rd_1line_baseaddr <= 'd0;
    else if (read_1line_req && r_ofmap_pos_x == r_conv_img_size - 4 && r_chnnl_cnt == 'd2)
        r_rd_1line_baseaddr <= r_rd_1line_baseaddr + r_conv_img_size - 'd2;
end

// read_1line_addr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst || Array_out_done) 
        read_1line_addr <= 'd0;
    else if (read_1line_req && r_ofmap_pos_x == r_conv_img_size - 3)
        read_1line_addr <= r_rd_1line_baseaddr;
    else if (read_1line_req)
        read_1line_addr <= read_1line_addr + 1'b1;
end

// r_bias_addr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) 
        r_bias_addr <= 'd0;
    // TODO: 清零
    else if (read_1line_req && r_ofmap_pos_y == r_conv_img_size - 3 && r_ofmap_pos_x == r_conv_img_size - 3)
        r_bias_addr <= r_bias_addr + 1'b1;
end

// Array_out_done
always@(posedge s_clk) begin
    if (r_read_1line_req_d8 && ~r_read_1line_req_d7)
        Array_out_done <= 1'b1;
    else
        Array_out_done <= 1'b0;
end

// r_conv_bias_ext
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) 
        r_conv_bias_ext <= 'd0;
    else if (r_bias_scale_cnt < r_conv_bias_scale)
        r_conv_bias_ext <= r_conv_bias_ext <<< 1;
    else if ((~r_read_1line_req_d2 && r_read_1line_req_d3) || code_valid)
        r_conv_bias_ext <= w_bias_rom_out;
end

// r_bias_scale_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) 
        r_bias_scale_cnt <= 'd0;
    else if ((~r_read_1line_req_d2 && r_read_1line_req_d3) || code_valid)
        r_bias_scale_cnt <= 'd0;
    else if (r_bias_scale_cnt < r_conv_bias_scale)
        r_bias_scale_cnt <= r_bias_scale_cnt + 1'b1;
end

// --------------- instantiation --------------- \\ 
proj_spikingconv_bias_rom u_proj_spikingconv_bias_rom (
    .a                  ( r_bias_addr      ),   // input wire [10 : 0] a
    .spo                ( w_bias_rom_out   )    // output wire [7 : 0] spo
);

psum_lif_top u_psum_lif_top(
    .s_clk              ( s_clk                 ),
    .s_rst              ( s_rst                 ),

    .code_valid         ( code_valid            ),
    .conv_lif_thrd      ( conv_lif_thrd         ),
    .conv_img_size      ( conv_img_size         ),

    .read_1line_req     ( r_read_1line_req_d2   ),
    .read_1line_data    ( read_1line_data       ),
    .conv_bias_ext      ( r_conv_bias_ext       ),

    .Array_out_valid    ( Array_out_valid       ),
    .Array_out_spikes   ( Array_out_spikes      )
);


endmodule // psum_callback


