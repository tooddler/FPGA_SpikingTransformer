/*
    - PE unit -
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
    
        data[7:0] and weight[7:0] --> multicast get
        latch weight -> load data -> add_tmp
        latency : 2 clk
        ps: 新一次的计算需复位 PE array 中的 Register Files
*/

`include "E:/Desktop/Zynq_Spikformer/Zynq_Spikformer.srcs/sources_1/hyper_para.v"
module Multi_add_unit (
    input                                        s_clk             ,
    input                                        s_rst             ,

    input                                        k_weight_valid    , // weight
    input      signed [`QUAN_BITS - 1 : 0]       kernel_weight     , 
    input                                        f_data_valid      , // data
    input      signed [`QUAN_BITS - 1 : 0]       feature_data      ,
    input      signed [`ADD9_ALL_BITS - 1 : 0]   shift_data        , // tmp data

    output reg                                   o_mac_rlst_valid=0,
    output reg signed [`ADD9_ALL_BITS - 1 : 0]   o_mac_rlst_out
);

// --- wire ---
wire signed [`QUAN_BITS*2 - 1 : 0]     w_multi_rlst        ;

// --- reg ---
reg  signed [`QUAN_BITS - 1 : 0]       r_kernel_weight     ;
reg                                    r_f_data_valid_d0=0 ;

// o_mac_rlst_out
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        o_mac_rlst_out <= 'd0;
    else if (r_f_data_valid_d0)
        o_mac_rlst_out <= $signed(w_multi_rlst) + $signed(shift_data);
end

// r_kernel_weight
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_kernel_weight <= 'd0;
    else if (k_weight_valid)
        r_kernel_weight <= kernel_weight;
end

// o_mac_rlst_valid
always@(posedge s_clk) begin
    r_f_data_valid_d0 <= f_data_valid;

    if (r_f_data_valid_d0)
        o_mac_rlst_valid <= 1'b1;
    else
        o_mac_rlst_valid <= 1'b0;
end

conv1_multi u_conv1_multi (
    .CLK        (s_clk            ), // input wire CLK
    .A          (feature_data     ), // input wire [7 : 0] A        <- signed
    .B          (r_kernel_weight  ), // input wire [7 : 0] B        <- signed
    .P          (w_multi_rlst     )  // output wire [15 : 0] P
);

endmodule // Multi_add_unit


