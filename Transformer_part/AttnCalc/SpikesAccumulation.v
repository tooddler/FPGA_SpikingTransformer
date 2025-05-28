/*
    -- Attention-Calculate-Spikes-Accumulation Multi-Head --
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
    PS      : Fix K matrix, iterate over Q matrix
*/

`include "E:/Desktop/spiking_transformer/spiking_transformer/spiking_transformer.srcs/sources_1/imports/FPGA_SpikingTransformer/hyper_para.v"
module SpikesAccumulation (
    input                                                           s_clk                ,
    input                                                           s_rst                , 
    // interact with qkv_BRAM_group
    input                                                           i_SpikesTmpRam_Ready ,
    output reg   [9 : 0]                                            o_QueryRam_rdaddr    ,
    input        [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]         i_QueryRam_out       ,
    output reg   [9 : 0]                                            o_KeyRam_rdaddr      ,
    input        [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]         i_KeyRam_out         ,
    // interact with AttnRAM
    input                                                           i_AttnRAM_Ready      ,
    output wire [$clog2(2*`SYSTOLIC_UNIT_NUM)*`TIME_STEPS - 1 : 0]  o_Calc_data          ,
    output wire                                                     o_Calc_valid         
);

// -- Data-in
reg                                                  r_Spikesdata_valid_d0 ;
reg                                                  r_Spikesdata_valid_d1 ;
reg                                                  r_Spikesdata_valid_d2 ;
reg [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]       r_QueryRam_out        ;
reg [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]       r_KeyRam_out          ;

// -- Jump Addr Registers
reg [$clog2(`SYSTOLIC_UNIT_NUM) + 1 : 0]             r_KeyRam_cnt          ; // 6
reg [$clog2(`SYSTOLIC_UNIT_NUM) + 1 : 0]             r_QueryRam_cnt        ;
reg [9 : 0]                                          r_KeyRam_baseaddr     ;
reg [9 : 0]                                          r_QueryRam_baseaddr   ;
reg [9 : 0]                                          r_InitAddr            ;

// ------------------- Base-Signal Proc ------------------- \\
always@(posedge s_clk) begin
    r_QueryRam_out <= i_QueryRam_out;
    r_KeyRam_out   <= i_KeyRam_out  ;

    r_Spikesdata_valid_d1 <= r_Spikesdata_valid_d0;
    r_Spikesdata_valid_d2 <= r_Spikesdata_valid_d1;
end

// r_InitAddr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_InitAddr <= 'd0;
    else if (r_Spikesdata_valid_d0 && r_QueryRam_cnt == 6'b11_0100 && r_KeyRam_cnt == 6'b11_1111)
        r_InitAddr <= r_InitAddr + 'd16;
end

// r_Spikesdata_valid_d0
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_Spikesdata_valid_d0 <= 1'b0;
    else if (r_Spikesdata_valid_d0 && r_QueryRam_cnt == 6'b11_1111 && r_KeyRam_cnt == 6'b11_1111)
        r_Spikesdata_valid_d0 <= 1'b0;
    else if (r_InitAddr[9 : 4] < `MULTI_HEAD_NUMS && i_AttnRAM_Ready && i_SpikesTmpRam_Ready && ~o_Calc_valid)
        r_Spikesdata_valid_d0 <= 1'b1;
end

// ------------------- Query Ram Proc ------------------- \\
// o_QueryRam_rdaddr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        o_QueryRam_rdaddr <= 'd0;
    else if (r_Spikesdata_valid_d0 && r_QueryRam_cnt[3 : 0] == 4'hF)
        o_QueryRam_rdaddr <= r_QueryRam_baseaddr; 
    else if (r_Spikesdata_valid_d0)
        o_QueryRam_rdaddr <= o_QueryRam_rdaddr + 1'b1;
end

// r_QueryRam_baseaddr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_QueryRam_baseaddr <= 'd0;
    else if (r_Spikesdata_valid_d0 && r_QueryRam_cnt == 6'b11_0111)
        r_QueryRam_baseaddr <= r_InitAddr;
    else if (r_Spikesdata_valid_d0 && r_QueryRam_cnt[3 : 0] == 4'b0111)
        r_QueryRam_baseaddr <= r_QueryRam_baseaddr + `MULTI_HEAD_NUMS*`SYSTOLIC_UNIT_NUM; // 192 
end

// r_QueryRam_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_QueryRam_cnt <= 'd0;
    else if (r_Spikesdata_valid_d0)
        r_QueryRam_cnt <= r_QueryRam_cnt + 1'b1;
end

// ------------------- Key Ram Proc ------------------- \\
// o_KeyRam_rdaddr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        o_KeyRam_rdaddr <= 'd0;
    else if (r_Spikesdata_valid_d0 && r_QueryRam_cnt == 6'b11_1111 && r_KeyRam_cnt[3 : 0] == 4'hF)
        o_KeyRam_rdaddr <= r_KeyRam_baseaddr;
    else if (r_Spikesdata_valid_d0 && r_QueryRam_cnt == 6'b11_1111) // 64
        o_KeyRam_rdaddr <= o_KeyRam_rdaddr + 1'b1;
end

// r_KeyRam_baseaddr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_KeyRam_baseaddr <= 'd0;
    else if (r_Spikesdata_valid_d0 && r_QueryRam_cnt == 6'b11_0111 && r_KeyRam_cnt == 6'b11_1111)
        r_KeyRam_baseaddr <= r_InitAddr;
    else if (r_Spikesdata_valid_d0 && r_QueryRam_cnt == 6'b11_1111 && r_KeyRam_cnt[3 : 0] == 4'b0111)
        r_KeyRam_baseaddr <= r_KeyRam_baseaddr + `MULTI_HEAD_NUMS*`SYSTOLIC_UNIT_NUM;
end

// r_KeyRam_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_KeyRam_cnt <= 'd0;
    else if (r_Spikesdata_valid_d0 && r_QueryRam_cnt == 6'b11_1111)
        r_KeyRam_cnt <= r_KeyRam_cnt + 1'b1;
end

// ------------------- Attention PE ------------------- \\
Attention_PE u_Attention_PE(
    .s_clk               ( s_clk                    ),
    .s_rst               ( s_rst                    ),
    .i_Spikesdata_valid  ( r_Spikesdata_valid_d2    ),
    .i_SpikesdataQuery   ( r_QueryRam_out           ),
    .i_SpikesdataKey     ( r_KeyRam_out             ),

    .o_Calc_data         ( o_Calc_data              ),
    .o_Calc_valid        ( o_Calc_valid             )
);

endmodule // SpikesAccumulation


