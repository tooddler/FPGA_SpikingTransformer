/*
    - weights ram - :
        weight_ready : 下级 PE 单元 数据请求信号
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "../hyper_para.v"
module weights_ram (
    input                                        s_clk             , // use ddr_CLK
    input                                        s_rst             ,
    // interact with ddr
    input           [`DATA_WIDTH- 1 : 0]         rd_burst_data     ,
    output reg      [`ADDR_SIZE - 1 : 0]         rd_burst_addr     ,
    output          [`LEN_WIDTH - 1 : 0]         rd_burst_len      ,
    output reg                                   rd_burst_req      ,
    input                                        rd_burst_valid    ,
    input                                        rd_burst_finish   ,
    //  interact with conv_layer1
    output          [`DATA_WIDTH - 1 : 0]        o_weight_out      ,
    output                                       o_weight_valid    ,
    input                                        weight_ready      ,
    input                                        load_w_finish
);

wire                                full                   ;
wire                                empty                  ;
wire                                posedge_rd_burst_vld   ;

reg  [$clog2(`CONV1_BURST_LENS):0]  r_water_level          ;
reg                                 r_weight_valid         ;
reg                                 r_rd_burst_valid_d0=0  ; 
reg                                 r_fifo_rst_flag        ;

assign  rd_burst_len            =  `CONV1_BURST_LENS                        ;
assign  o_weight_valid          =  r_weight_valid                           ;
assign  posedge_rd_burst_vld    =  ~r_rd_burst_valid_d0 && rd_burst_valid   ;

// rd_burst_addr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        rd_burst_addr <= `CONV1_BASEADDR;
    else if (r_fifo_rst_flag)
        rd_burst_addr <= `CONV1_BASEADDR;
    else if (rd_burst_finish)
        rd_burst_addr <= rd_burst_addr + (rd_burst_len << $clog2(`DATA_WIDTH / 8));
end

// rd_burst_req -> hold until finish
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        rd_burst_req <= 1'b0;
    else if (rd_burst_finish)
        rd_burst_req <= 1'b0;
    else if (r_water_level < 'd16 - `CONV1_BURST_LENS)
        rd_burst_req <= 1'b1;
end

always@(posedge s_clk) begin
    r_rd_burst_valid_d0 <= rd_burst_valid;
end

// r_water_level
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_water_level <= 'd0;
    else if (posedge_rd_burst_vld)
        r_water_level <= r_water_level + `CONV1_BURST_LENS;
    else if (r_weight_valid)
        r_water_level <= r_water_level - 1'b1;
end

// r_weight_valid
always@(*) begin
    if (s_rst)
        r_weight_valid <= 1'b0;
    else if (~empty && weight_ready && ~rd_burst_valid)
        r_weight_valid <= 1'b1;
    else 
        r_weight_valid <= 1'b0;
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

conv1_weight_fifo u_conv1_weight_fifo (
    .clk            (s_clk                     ),
    .srst           (s_rst || r_fifo_rst_flag  ),
    .din            (rd_burst_data             ), // [63:0] din
    .wr_en          (rd_burst_valid            ),  
    .rd_en          (r_weight_valid            ),  
    .dout           (o_weight_out              ), // [63:0] dout
    .full           (full                      ), 
    .empty          (empty                     )  
);

endmodule // weights_ram
