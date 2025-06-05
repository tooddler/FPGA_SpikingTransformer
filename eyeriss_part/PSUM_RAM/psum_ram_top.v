/*
    -- psum ram --
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "E:/Desktop/Zynq_Spikformer/Zynq_Spikformer.srcs/sources_1/hyper_para.v"
module psum_ram_top (
    input                                                     s_clk               ,
    input                                                     s_rst               ,

    input                                                     code_valid          ,
    input     [15:0]                                          conv_img_size       ,
    // data write port
    input                                                     i_data_valid        ,
    input      [`PSUM_RAM_DEPTH - 1 : 0]                      i_write_addr        ,  
    input      [`ERS_MAX_WIDTH * `TIME_STEPS - 1 : 0]         i_data_in_line0     ,
    input      [`ERS_MAX_WIDTH * `TIME_STEPS - 1 : 0]         i_data_in_line1     ,
    input      [`ERS_MAX_WIDTH * `TIME_STEPS - 1 : 0]         i_data_in_line2     ,
    // data read port
    input                                                     read_data_mode      , // 1: one line; 0: three lines
    input      [`PSUM_RAM_DEPTH - 1 : 0]                      read_1line_addr     , // 3 clk + 1
    input                                                     read_1line_req      ,
    output reg [`ERS_MAX_WIDTH * `TIME_STEPS - 1 : 0]         read_1line_data='d0 ,

    input                                                     i_data_req          ,
    input      [`PSUM_RAM_DEPTH - 1 : 0]                      read_addr           ,
    output reg [`ERS_MAX_WIDTH * `TIME_STEPS - 1 : 0]         o_data_out_line0    ,
    output reg [`ERS_MAX_WIDTH * `TIME_STEPS - 1 : 0]         o_data_out_line1    ,
    output reg [`ERS_MAX_WIDTH * `TIME_STEPS - 1 : 0]         o_data_out_line2    
);

wire [`PSUM_RAM_DEPTH - 1 : 0]                      w_rd_addr00             ;
wire [`PSUM_RAM_DEPTH - 1 : 0]                      w_rd_addr01             ;
wire [`PSUM_RAM_DEPTH - 1 : 0]                      w_rd_addr02             ;

wire [`ERS_MAX_WIDTH * `TIME_STEPS - 1 : 0]         w_data_out_line0        ;
wire [`ERS_MAX_WIDTH * `TIME_STEPS - 1 : 0]         w_data_out_line1        ;
wire [`ERS_MAX_WIDTH * `TIME_STEPS - 1 : 0]         w_data_out_line2        ;

reg  [15:0]                                         r_conv_img_size         ;
reg  [5:0]                                          r_line_sw_cnt           ;
reg  [1:0]                                          r_channel_sel           ;
reg                                                 r_read_1line_req_d0     ;
reg                                                 r_read_1line_req_d1     ;


assign w_rd_addr00  = read_data_mode ? read_1line_addr : read_addr ;
assign w_rd_addr01  = read_data_mode ? read_1line_addr : read_addr ;
assign w_rd_addr02  = read_data_mode ? read_1line_addr : read_addr ;

always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_conv_img_size <= 'd0;
    else if (code_valid) 
        r_conv_img_size <= conv_img_size;
end

always@(posedge s_clk) begin
    case(r_channel_sel) 
        0: read_1line_data <= o_data_out_line0;
        1: read_1line_data <= o_data_out_line1;
        2: read_1line_data <= o_data_out_line2;
        default: read_1line_data <= 'd0;
    endcase
end

always@(posedge s_clk) begin
    r_read_1line_req_d0 <= read_1line_req;
    r_read_1line_req_d1 <= r_read_1line_req_d0;
    
    o_data_out_line0 <= w_data_out_line0;
    o_data_out_line1 <= w_data_out_line1;
    o_data_out_line2 <= w_data_out_line2;
end

// r_channel_sel
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) 
        r_channel_sel <= 'd0;
    else if (r_channel_sel == 'd2 && r_read_1line_req_d1 && read_data_mode && r_line_sw_cnt == r_conv_img_size - 3)
        r_channel_sel <= 'd0;
    else if (r_read_1line_req_d1 && read_data_mode && r_line_sw_cnt == r_conv_img_size - 3)
        r_channel_sel <= r_channel_sel + 1'b1;
    else if (read_data_mode)
        r_channel_sel <= r_channel_sel;
    else 
        r_channel_sel <= 'd0;
end

// r_line_sw_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) 
        r_line_sw_cnt <= 'd0;
    else if (r_line_sw_cnt == r_conv_img_size - 3 && r_read_1line_req_d1 && read_data_mode)
        r_line_sw_cnt <= 'd0;
    else if (r_read_1line_req_d1 && read_data_mode)
        r_line_sw_cnt <= r_line_sw_cnt + 1'b1;
end

psum_ram psum_ram_m00 (
    .clka       ( s_clk            ),    // input wire clka
    .wea        ( i_data_valid     ),    // input wire [0 : 0] wea
    .addra      ( i_write_addr     ),    // input wire [8 : 0] addra
    .dina       ( i_data_in_line0  ),    // input wire [83 : 0] dina
    
    .clkb       ( s_clk            ),    // input wire clkb
    .addrb      ( w_rd_addr00      ),    // input wire [8 : 0] addrb
    .doutb      ( w_data_out_line0 )     // output wire [83 : 0] doutb
);

psum_ram psum_ram_m01 (
    .clka       ( s_clk            ),    // input wire clka
    .wea        ( i_data_valid     ),    // input wire [0 : 0] wea
    .addra      ( i_write_addr     ),    // input wire [8 : 0] addra
    .dina       ( i_data_in_line1  ),    // input wire [83 : 0] dina
    
    .clkb       ( s_clk            ),    // input wire clkb
    .addrb      ( w_rd_addr01      ),    // input wire [8 : 0] addrb
    .doutb      ( w_data_out_line1 )     // output wire [83 : 0] doutb
);

psum_ram psum_ram_m02 (
    .clka       ( s_clk            ),    // input wire clka
    .wea        ( i_data_valid     ),    // input wire [0 : 0] wea
    .addra      ( i_write_addr     ),    // input wire [8 : 0] addra
    .dina       ( i_data_in_line2  ),    // input wire [83 : 0] dina
       
    .clkb       ( s_clk            ),    // input wire clkb
    .addrb      ( w_rd_addr02      ),    // input wire [8 : 0] addrb
    .doutb      ( w_data_out_line2 )     // output wire [83 : 0] doutb
);


endmodule // psum_ram


