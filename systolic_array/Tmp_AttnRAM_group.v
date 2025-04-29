/*
    --- (Q * K^T) MATRIX Store BRAM --- 
    Author   : Toddler. 
    Email    : 23011211185@stu.xidian.edu.cn
    Encoder  : UTF-8
    BRAM-USE : 36 K BRAM * 2.5 * 2
*/

`include "../hyper_para.v"
module Tmp_AttnRAM_group (
    input                                                           s_clk                ,
    input                                                           s_rst                ,
    // interact with SpikesAccumulation
    output wire                                                     o_AttnRAM_Ready      ,
    input       [$clog2(2*`SYSTOLIC_UNIT_NUM)*`TIME_STEPS - 1 : 0]  i_Calc_data          ,
    input                                                           i_Calc_valid         ,
    // Read port
    input                                                           i_AttnRam_Done       ,
    input       [11 : 0]                                            i_AttnRam_rd_addr    ,
    output wire                                                     o_AttnRAM_Empty      ,
    output wire [$clog2(2*`SYSTOLIC_UNIT_NUM)*`TIME_STEPS - 1 : 0]  o_AttnRAM_data       
);

// -- wire
wire                                                        w_AttnRam_Empty          ;
wire                                                        w_AttnRam_Full           ;
wire [$clog2(2*`SYSTOLIC_UNIT_NUM)*`TIME_STEPS - 1 : 0]     w00_AttnRAM_data         ;
wire [$clog2(2*`SYSTOLIC_UNIT_NUM)*`TIME_STEPS - 1 : 0]     w01_AttnRAM_data         ;

// -- reg
reg  [1 : 0]                                                r_LoadAttn_Pointer=2'b00 ;
reg  [1 : 0]                                                r_SendAttn_Pointer=2'b00 ;
reg                                                         r_SendAttn_Switch=0      ;
reg  [11 : 0]                                               r_AttnRam_WR_addr        ;

// ------------------- Main Code ------------------- \\
assign o_AttnRAM_Ready = ~w_AttnRam_Full;
assign o_AttnRAM_data  = r_SendAttn_Switch ? w01_AttnRAM_data : w00_AttnRAM_data;
assign o_AttnRAM_Empty = w_AttnRam_Empty;
assign w_AttnRam_Empty = r_LoadAttn_Pointer == r_SendAttn_Pointer;
assign w_AttnRam_Full  = (r_LoadAttn_Pointer[1] ^ r_SendAttn_Pointer[1]) && (r_LoadAttn_Pointer[0] == r_SendAttn_Pointer[0]);

// r_LoadAttn_Pointer
always@(posedge s_clk) begin
    if (i_Calc_valid && r_AttnRam_WR_addr == `FINAL_FMAPS_WIDTH * `FINAL_FMAPS_WIDTH - 1) // 4096
        r_LoadAttn_Pointer <= r_LoadAttn_Pointer + 1'b1;
    else 
        r_LoadAttn_Pointer <= r_LoadAttn_Pointer;
end

// r_AttnRam_WR_addr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_AttnRam_WR_addr <= 'd0;
    else if (i_Calc_valid)
        r_AttnRam_WR_addr <= r_AttnRam_WR_addr + 1'b1;
end

// r_SendAttn_Pointer
always@(posedge s_clk) begin
    r_SendAttn_Switch <= r_SendAttn_Pointer[0];

    if (i_AttnRam_Done)
        r_SendAttn_Pointer <= r_SendAttn_Pointer + 1'b1;
    else 
        r_SendAttn_Pointer <= r_SendAttn_Pointer;
end

// ------------------- Attn TmpRam ------------------- \\
Attn_TmpRam m00_Attn_TmpRam (
    .clka   ( s_clk                                 ),
    .wea    ( i_Calc_valid & ~r_LoadAttn_Pointer[0] ),
    .addra  ( r_AttnRam_WR_addr                     ), // [11 : 0] 
    .dina   ( i_Calc_data                           ), // [19 : 0] 
    
    .clkb   ( s_clk                                 ),
    .addrb  ( i_AttnRam_rd_addr                     ), // [11 : 0]
    .doutb  ( w00_AttnRAM_data                      )  // [19 : 0]
);

Attn_TmpRam m01_Attn_TmpRam (
    .clka   ( s_clk                                 ), 
    .wea    ( i_Calc_valid & r_LoadAttn_Pointer[0]  ), 
    .addra  ( r_AttnRam_WR_addr                     ), // [11 : 0] 
    .dina   ( i_Calc_data                           ), // [19 : 0]     

    .clkb   ( s_clk                                 ), 
    .addrb  ( i_AttnRam_rd_addr                     ), // [11 : 0] 
    .doutb  ( w01_AttnRAM_data                      )  // [19 : 0] 
);

endmodule // Tmp_AttnRAM_group
