/*
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
    func    : read Weights from DDR
              Order -> Q, K, V, MLP Weights
    ps      : fifo depth --> 512
*/

`include "../../hyper_para.v"
module weight_fifo (
    input                                        s_clk              ,
    input                                        s_rst              , 
    // interact with ddr
    input           [`DATA_WIDTH- 1 : 0]         rd_burst_data      ,
    output reg      [`ADDR_SIZE - 1 : 0]         rd_burst_addr      ,
    output wire     [`LEN_WIDTH - 1 : 0]         rd_burst_len       ,
    output reg                                   rd_burst_req       ,
    input                                        rd_burst_valid     ,
    input                                        rd_burst_finish    ,
    // interact with Systolic Array
    output wire     [`DATA_WIDTH - 1 : 0]        o_weight_out       ,
    input                                        i_weight_valid     , // input
    output wire                                  o_weight_ready     ,
    input                                        load_w_finish     
);

wire                                full                   ;
wire                                empty                  ;
wire                                w_almost_full          ;
wire                                w_almost_empty         ;

reg     [`ADDR_SIZE - 1 : 0]        r_mtrx_baseaddr00      ;
reg     [`ADDR_SIZE - 1 : 0]        r_mtrx_baseaddr01      ;
reg     [5:0]                       r_base00_cnt           ;
reg     [5:0]                       r_base01_cnt           ;
reg     [5:0]                       r_base02_cnt           ;
reg                                 r_fifo_rst_flag        ;

assign rd_burst_len         =       `SYSTOLIC_UNIT_NUM / 8 ;
assign o_weight_ready       =       ~w_almost_empty        ;

// r_mtrx_baseaddr00
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst || r_fifo_rst_flag)
        r_mtrx_baseaddr00 <= `WEIGHTS_QKV_BASEADDR;
    else if (r_base00_cnt == `FINAL_FMAPS_CHNNLS / `SYSTOLIC_UNIT_NUM)
        r_mtrx_baseaddr00 <= r_mtrx_baseaddr00 
                            + (`FINAL_FMAPS_CHNNLS * `QUAN_BITS * `FINAL_FMAPS_CHNNLS) / `DATA_WIDTH 
                            - (`FINAL_FMAPS_CHNNLS / `SYSTOLIC_UNIT_NUM - 1) * (`QUAN_BITS * `SYSTOLIC_UNIT_NUM) / `DATA_WIDTH; // + 18392
    else if (r_base02_cnt == 'd0 && r_base01_cnt == 'd1 && rd_burst_finish)
        r_mtrx_baseaddr00 <= r_mtrx_baseaddr00 + (`QUAN_BITS * `SYSTOLIC_UNIT_NUM) / `DATA_WIDTH;
end

// r_base00_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst || r_fifo_rst_flag)
        r_base00_cnt <= 'd0;
    else if (r_base00_cnt == `FINAL_FMAPS_CHNNLS / `SYSTOLIC_UNIT_NUM)
        r_base00_cnt <= 'd0;
    else if (r_base02_cnt == 'd0 && r_base01_cnt == 'd1 && rd_burst_finish)
        r_base00_cnt <= r_base00_cnt + 1'b1;
end

// r_mtrx_baseaddr01
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst || r_fifo_rst_flag)
        r_mtrx_baseaddr01 <= `WEIGHTS_QKV_BASEADDR;
    else if (rd_burst_finish && r_base02_cnt == 'd1 && r_base01_cnt == `FINAL_FMAPS_CHNNLS / `SYSTOLIC_UNIT_NUM - 1)
        r_mtrx_baseaddr01 <= r_mtrx_baseaddr00;
    else if (r_base02_cnt == 'd1 && rd_burst_finish)
        r_mtrx_baseaddr01 <= r_mtrx_baseaddr01 + (`FINAL_FMAPS_CHNNLS * `QUAN_BITS * `SYSTOLIC_UNIT_NUM) / `DATA_WIDTH; // 3072 = 48x64 
end

// r_base01_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst || r_fifo_rst_flag)
        r_base01_cnt <= 'd0;
    else if (rd_burst_finish && r_base02_cnt == 'd1 && r_base01_cnt == `FINAL_FMAPS_CHNNLS / `SYSTOLIC_UNIT_NUM - 1) // 0 - 5
        r_base01_cnt <= 'd0;
    else if (r_base02_cnt == 'd1 && rd_burst_finish)
        r_base01_cnt <= r_base01_cnt + 1'b1;
end

// rd_burst_addr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst || r_fifo_rst_flag)
        rd_burst_addr <= `WEIGHTS_QKV_BASEADDR;
    else if (rd_burst_finish && r_base02_cnt == `SYSTOLIC_UNIT_NUM - 1)
        rd_burst_addr <= r_mtrx_baseaddr01;
    else if (rd_burst_finish)
        rd_burst_addr <= rd_burst_addr + (`FINAL_FMAPS_CHNNLS * `QUAN_BITS) / `DATA_WIDTH; // 48
end

// r_base02_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst || r_fifo_rst_flag)
        r_base02_cnt <= 'd0;
    else if (rd_burst_finish && r_base02_cnt == `SYSTOLIC_UNIT_NUM - 1) // 63
        r_base02_cnt <= 'd0;
    else if (rd_burst_finish)
        r_base02_cnt <= r_base02_cnt + 1'b1;
end

// rd_burst_req 
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        rd_burst_req <= 1'b0;
    else if (rd_burst_finish)
        rd_burst_req <= 1'b0;
    else if (~w_almost_full)
        rd_burst_req <= 1'b1;
end

// r_fifo_rst_flag
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) 
        r_fifo_rst_flag <= 1'b0;
    else if (load_w_finish)
        r_fifo_rst_flag <= 1'b1;
    else if (~rd_burst_req)
        r_fifo_rst_flag <= 1'b0;
end

// --------------- instantiation --------------- \\
qkv_linearWeights_fifo qkv_linearWeights_fifo_m0 (
    .clk        ( s_clk                     ),
    .srst       ( s_rst || r_fifo_rst_flag  ),
    .din        ( rd_burst_data             ), // [63 : 0] din
    .wr_en      ( rd_burst_valid            ),
    .rd_en      ( i_weight_valid            ),
    .dout       ( o_weight_out              ), // [63 : 0] dout
    .full       ( full                      ),
    .empty      ( empty                     ),
    .prog_full  ( w_almost_full             ), // prog_full > 448
    .prog_empty ( w_almost_empty            )  // prog_empty < 64
);

endmodule // weight_fifo
