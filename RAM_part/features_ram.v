/*
    - features ram -    -> IMG_RGB565
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "E:/Desktop/spiking_transformer/spiking_transformer/spiking_transformer.srcs/sources_1/imports/FPGA_SpikingTransformer/hyper_para.v"
module features_ram (
    input                                        s_clk               , // use ddr_CLK
    input                                        s_rst               ,
    // interact with ddr
    input           [`DATA_WIDTH- 1 : 0]         rd_burst_data       ,
    output reg      [`ADDR_SIZE - 1 : 0]         rd_burst_addr       ,
    output          [`LEN_WIDTH - 1 : 0]         rd_burst_len        ,
    output reg                                   rd_burst_req        ,
    input                                        rd_burst_valid      ,
    input                                        rd_burst_finish     ,
    //  interact with conv_layer1
    output         [`QUAN_BITS - 1 : 0]          o_feature_data_ch0  , 
    output         [`QUAN_BITS - 1 : 0]          o_feature_data_ch1  , 
    output         [`QUAN_BITS - 1 : 0]          o_feature_data_ch2  , 
    output                                       o_f_data_valid      , 
    input                                        data_ready          ,
    input                                        load_d_once_done    ,
    input                                        data_load_done         
);

wire                                full                     ;
wire                                empty                    ;
wire [15:0]                         w_feature_data           ;
wire [`QUAN_BITS*3 - 1 : 0]         w_bytes_out              ;  
wire                                w_bytes_valid            ;
wire [`DATA_WIDTH- 1 : 0]           w_rd_burst_data_revbyte  ;

reg  [$clog2(`IMG_BURST_LENS) : 0]  r_water_level            ;
reg                                 r_feature_valid          ;
reg  [1:0]                          r_rd_feature_cnt         ;
reg                                 r_rd_burst_valid_d0=0    ; 

assign  rd_burst_len            =  `IMG_BURST_LENS                                  ;

assign  o_f_data_valid          =  w_bytes_valid                                    ;
assign  o_feature_data_ch0      =  w_bytes_out[`QUAN_BITS   - 1 : 0           ]     ;
assign  o_feature_data_ch1      =  w_bytes_out[`QUAN_BITS*2 - 1 : `QUAN_BITS  ]     ;
assign  o_feature_data_ch2      =  w_bytes_out[`QUAN_BITS*3 - 1 : `QUAN_BITS*2]     ;

assign  posedge_rd_burst_vld    =  ~r_rd_burst_valid_d0 && rd_burst_valid           ;
assign  w_rd_burst_data_revbyte =  {rd_burst_data[15:0], rd_burst_data[31:16],
                                    rd_burst_data[47:32], rd_burst_data[63:48]}     ;

// rd_burst_addr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        rd_burst_addr <= `IMG_BASEADDR;
    else if (data_load_done || load_d_once_done)
        rd_burst_addr <= `IMG_BASEADDR;
    else if (rd_burst_finish)
        rd_burst_addr <= rd_burst_addr + (rd_burst_len << $clog2(`DATA_WIDTH / 8));
end

// rd_burst_req -> hold until finish
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        rd_burst_req <= 1'b0;
    else if (rd_burst_finish)
        rd_burst_req <= 1'b0;
    else if (r_water_level < 'd32 - `IMG_BURST_LENS)
        rd_burst_req <= 1'b1;
end

// r_rd_feature_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_rd_feature_cnt <= 'd0;
    else if (r_feature_valid)
        r_rd_feature_cnt <= r_rd_feature_cnt + 1'b1;
end

// r_water_level
always@(posedge s_clk, posedge s_rst) begin
    r_rd_burst_valid_d0 <= rd_burst_valid;

    if (s_rst)
        r_water_level <= 'd0;
    else if (data_load_done || load_d_once_done)
        r_water_level <= 'd0;
    else if (posedge_rd_burst_vld)
        r_water_level <= r_water_level + `IMG_BURST_LENS;
    else if (r_rd_feature_cnt == 2'b11 && r_feature_valid)
        r_water_level <= r_water_level - 1'b1;
end

// r_feature_valid
always@(*) begin
    if (~empty && data_ready && ~rd_burst_valid)
        r_feature_valid <= 1'b1;
    else
        r_feature_valid <= 1'b0;
end

features_in_fifo u_features_in_fifo (
    .clk            (s_clk                                       ),
    .srst           (s_rst || data_load_done || load_d_once_done ),
    .din            (w_rd_burst_data_revbyte                     ), // [63:0] din
    .wr_en          (rd_burst_valid                              ),  
    
    .rd_en          (r_feature_valid                             ),  
    .dout           (w_feature_data                              ), // [15:0] dout
    .full           (full                                        ), 
    .empty          (empty                                       )  
);

width_change u_width_change(
    .s_clk          ( s_clk                                     ),
    .s_rst          ( s_rst                                     ),
    .bytes_in       ( w_feature_data                            ),
    .bytes_valid    ( r_feature_valid                           ),
    .o_bytes_out    ( w_bytes_out                               ),
    .o_bytes_valid  ( w_bytes_valid                             )
);


endmodule // features_ram


