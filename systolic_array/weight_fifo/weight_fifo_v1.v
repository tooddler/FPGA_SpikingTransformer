/*
    Author    : Toddler. 
    Email     : 23011211185@stu.xidian.edu.cn
    Encoder   : UTF-8
    func      : read Weights from DDR
                Order -> Q, K, V, MLP Weights
    ps        : fifo depth --> 512
    New in v1 : Change Weights storage Shape so that facilitate AXI brust read
*/

`include "../../hyper_para.v"
module weight_fifo_v1 #(
    parameter WEIGHTS_BASEADDR = `WEIGHTS_Q_BASEADDR
)(
    input                                        s_clk              ,
    input                                        s_rst              , 
    // interact with ddr
    input           [`DATA_WIDTH- 1 : 0]         rd_burst_data      ,
    output reg      [`ADDR_SIZE - 1 : 0]         rd_burst_addr      ,
    output wire     [`LEN_WIDTH - 1 : 0]         rd_burst_len       ,
    output reg                                   rd_burst_req       ,
    input                                        rd_burst_valid     ,
    input                                        rd_burst_finish    ,
    // interact with Controller
    output wire     [`DATA_WIDTH - 1 : 0]        o_weight_out       ,
    input                                        i_weight_valid     , // input
    output wire                                  o_weight_ready     , // Not for handshake
    input                                        load_w_finish     
);

localparam P_MAX_TIMES = `FINAL_FMAPS_CHNNLS * `FINAL_FMAPS_CHNNLS / (32 << $clog2(`DATA_WIDTH / 8)); // 576
localparam P_MAX_ADDR  = (P_MAX_TIMES - 1) * (32 << $clog2(`DATA_WIDTH / 8));

wire                                full                   ;
wire                                empty                  ;
wire                                w_almost_full          ;
wire                                w_almost_empty         ;
reg                                 r_fifo_rst_flag        ;

// ---> debug dot
wire [7:0]      debug_weight_array [7:0];

genvar k;
generate
    for (k = 0; k < 8; k = k + 1) begin
        assign debug_weight_array[k] = o_weight_out[8*(k+1) - 1 : 8*k];
    end
endgenerate

// ---> end debug dot
assign rd_burst_len         =       'd32                   ;
assign o_weight_ready       =       ~w_almost_empty        ;

// rd_burst_addr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst || r_fifo_rst_flag)
        rd_burst_addr <= WEIGHTS_BASEADDR;
    else if (rd_burst_finish && rd_burst_addr == WEIGHTS_BASEADDR + P_MAX_ADDR)
        rd_burst_addr <= WEIGHTS_BASEADDR;
    else if (rd_burst_finish)
        rd_burst_addr <= rd_burst_addr + (rd_burst_len << $clog2(`DATA_WIDTH / 8));
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

endmodule // weight_fifo_v1
