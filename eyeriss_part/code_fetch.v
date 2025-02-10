/*
    - Code Fetch - :
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "../hyper_para.v"
module code_fetch (
    input                             s_clk                     ,
    input                             s_rst                     ,

    input                             SPS_part_done             ,

    output reg                        code_valid=0              ,
    input                             code_ready                , // req signal
    
    output reg                        o_fetch_done              ,
    output   [15:0]                   Conv_lif_thrd             ,
    output   [15:0]                   Conv_bias_scale           ,
    output                            Conv_or_Maxpool           , // 0 : conv ; 1: maxpool
    output   [15:0]                   Conv_in_ch                ,
    output   [15:0]                   Conv_out_ch               ,
    output   [15:0]                   Conv_img_size             
);

wire [95:0]                     w_code      ;
reg  [4:0]                      r_code_addr ;

assign Conv_or_Maxpool = w_code[95:80] == `MAXPOOL_CODE  ;
assign Conv_bias_scale = w_code[79:64]                   ;
assign Conv_lif_thrd   = w_code[63:48]                   ;
assign Conv_in_ch      = w_code[47:32]                   ;
assign Conv_out_ch     = w_code[31:16]                   ;
assign Conv_img_size   = w_code[15: 0]                   ;

// code_valid
always@(posedge s_clk) begin
    if (code_ready)
        code_valid <= 1'b1;
    else 
        code_valid <= 1'b0;
end

// r_code_addr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_code_addr <= 'd0;
    else if (SPS_part_done)
        r_code_addr <= 'd0;
    else if (code_valid && code_ready)
        r_code_addr <= r_code_addr + 1'b1;
end

// o_fetch_done
always@(posedge s_clk) begin
    if (r_code_addr == `LEN_CODE)
        o_fetch_done <= 1'b1;
    else
        o_fetch_done <= 1'b0;
end

cal_code_rom u_cal_code_rom (
    .a      (r_code_addr    ),      // input wire [4 : 0] a
    .spo    (w_code         )       // output wire [96 : 0] spo
);

endmodule // code_fetch
