/*
    --- QKV MATRIX Store BRAM --- 
    Author   : Toddler. 
    Email    : 23011211185@stu.xidian.edu.cn
    Encoder  : UTF-8
    BRAM-USE : 36 K BRAM * 4 * 3 
*/

`include "../hyper_para.v"
module qkv_BRAM_group (
    input                                                       s_clk                ,
    input                                                       s_rst                ,
    // - intercat with qkv linear module -
    input       [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]      i00_spikesLine_in    ,
    input                                                       i00_spikesLine_valid ,
    input       [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]      i01_spikesLine_in    ,
    input                                                       i01_spikesLine_valid ,
    input       [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]      i02_spikesLine_in    ,
    input                                                       i02_spikesLine_valid ,
    // - Read Port -
    output wire                                                 o_SpikesTmpRam_Ready ,
    input       [9 : 0]                                         i_QueryRam_rdaddr    ,
    output wire [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]      o_QueryRam_out       , // 32 * t=4
    input       [9 : 0]                                         i_KeyRam_rdaddr      ,
    output wire [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]      o_KeyRam_out         ,
    input       [9 : 0]                                         i_ValueRam_rdaddr    ,
    output wire [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]      o_ValueRam_out       
);

reg  [9 : 0]                     r_lq_wraddr          ;
reg  [9 : 0]                     r_lk_wraddr          ;
reg  [9 : 0]                     r_lv_wraddr          ;
reg                              r_SpikesTmpRam_Ready ;

assign o_SpikesTmpRam_Ready = r_SpikesTmpRam_Ready ;

// r_SpikesTmpRam_Ready
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_SpikesTmpRam_Ready <= 1'b0;
    else if (r_lv_wraddr == 10'h300) // 768
        r_SpikesTmpRam_Ready <= 1'b1;
end

// r_lq_wraddr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_lq_wraddr <= 'd0;
    else if (i00_spikesLine_valid)
        r_lq_wraddr <= r_lq_wraddr + 1'b1;
end

// r_lk_wraddr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_lk_wraddr <= 'd0;
    else if (i01_spikesLine_valid)
        r_lk_wraddr <= r_lk_wraddr + 1'b1;
end

// r_lv_wraddr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_lv_wraddr <= 'd0;
    else if (i02_spikesLine_valid)
        r_lv_wraddr <= r_lv_wraddr + 1'b1;
end

qkv_SpikesTmpRam Query_SpikesTmpRam (
    .clka   ( s_clk                 ), 
    .wea    ( i00_spikesLine_valid  ), 
    .addra  ( r_lq_wraddr           ), // [9 : 0] addra
    .dina   ( i00_spikesLine_in     ), // [127 : 0] dina
     
    .clkb   ( s_clk                 ), 
    .addrb  ( i_QueryRam_rdaddr     ), // [9 : 0] addrb
    .doutb  ( o_QueryRam_out        )  // [127 : 0] douta
);

qkv_SpikesTmpRam Key_SpikesTmpRam (
    .clka   ( s_clk                 ), 
    .wea    ( i01_spikesLine_valid  ), 
    .addra  ( r_lk_wraddr           ), // [9 : 0] addra
    .dina   ( i01_spikesLine_in     ), // [127 : 0] dina
     
    .clkb   ( s_clk                 ), 
    .addrb  ( i_KeyRam_rdaddr       ), // [9 : 0] addrb
    .doutb  ( o_KeyRam_out          )  // [127 : 0] douta
);

qkv_SpikesTmpRam Value_SpikesTmpRam (
    .clka   ( s_clk                 ), 
    .wea    ( i02_spikesLine_valid  ), 
    .addra  ( r_lv_wraddr           ), // [9 : 0] addra
    .dina   ( i02_spikesLine_in     ), // [127 : 0] dina
     
    .clkb   ( s_clk                 ), 
    .addrb  ( i_ValueRam_rdaddr     ), // [9 : 0] addrb
    .doutb  ( o_ValueRam_out        )  // [127 : 0] douta
);

endmodule // akv_BRAM_group
