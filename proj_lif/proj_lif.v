/*
    - proj lif -
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8

        decay_input == True
            V[t] = V[t-1] + 1/tau * (X[t] - (V[t-1] - V_{reset}))
            V_{reset}  =  0
*/

`include "E:/Desktop/spiking_transformer/spiking_transformer/spiking_transformer.srcs/sources_1/imports/FPGA_SpikingTransformer/hyper_para.v"
module proj_lif #(
    parameter  ADD9_ALL_BITS = `ADD9_ALL_BITS   
)(
    input                                        s_clk               ,
    input                                        s_rst               ,

    input      [ADD9_ALL_BITS - 1 : 0]           THRESHOLD           ,
    input      [ADD9_ALL_BITS - 1 : 0]           i_delta_mem         ,
    input                                        i_delta_mem_valid   ,
    input      [ADD9_ALL_BITS - 1 : 0]           i_pre_mem           ,

    output reg                                   o_spike             ,
    output reg                                   o_delta_mem_valid=0 ,
    output reg [ADD9_ALL_BITS - 1 : 0]           o_nxt_mem           
);

wire signed [ADD9_ALL_BITS - 1 : 0]             w_delta_mem         ;

assign  w_delta_mem = ($signed(i_delta_mem) + $signed(i_pre_mem)) >>> 1;

// o_spike
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        o_spike <= 1'b0;
    else if (~w_delta_mem[ADD9_ALL_BITS - 1] && w_delta_mem >= THRESHOLD && i_delta_mem_valid)
        o_spike <= 1'b1;
    else
        o_spike <= 1'b0;
end

// o_delta_mem_valid
always@(posedge s_clk) begin
    o_delta_mem_valid <= i_delta_mem_valid;
end

// o_nxt_mem
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        o_nxt_mem <= 'd0;
    else if ((w_delta_mem[ADD9_ALL_BITS - 1] || w_delta_mem < THRESHOLD) && i_delta_mem_valid)
        o_nxt_mem <= w_delta_mem;
    else 
        // v_reset('d0) or not working state
        o_nxt_mem <= 'd0;
end

endmodule //proj_lif


