/*
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
    func    : half adder group + Embedded RAM
*/

`include "../../hyper_para.v"
module PatchEmbed (
    input                                            s_clk                  ,
    input                                            s_rst                  ,
    // get fmaps and patch
    input                                            i_data_valid           ,
    input       [`PATCH_EMBED_WIDTH - 1 : 0]         i_fmap                 ,
    input       [`PATCH_EMBED_WIDTH - 1 : 0]         i_patchdata            ,
    // read Embedded RAM
    input       [11 : 0]                             i_rd_addr              ,
    output reg  [`PATCH_EMBED_WIDTH * 2 - 1 : 0]     o_ramout_data          , // ** Attn : delay 2 clk **      
    output reg                                       o_ramout_ready         ,
    // - MLP INTERFACE
    input                                            i_switch               ,
    input       [0 : 0]                              i_MLPs_wea             , 
    input       [11 : 0]                             i_MLPs_addra           ,
    input       [63 : 0]                             i_MLPs_dina            , 
    input       [11 : 0]                             i_MLPs_addrb           , 
    output wire [63 : 0]                             o_MLPs_doutb
);

wire   [`PATCH_EMBED_WIDTH * 2 - 1 : 0]     w_trsfrmrdata           ;
wire   [`PATCH_EMBED_WIDTH * 2 - 1 : 0]     w_ramout_data           ;

wire   [0 : 0]                              w_EmbeddedRAM_wea       ;
wire   [11 : 0]                             w_EmbeddedRAM_addra     ;
wire   [63 : 0]                             w_EmbeddedRAM_dina      ; 
wire   [11 : 0]                             w_EmbeddedRAM_addrb     ;

reg                                         r_trsfrmrdata_valid=0   ;
reg    [`PATCH_EMBED_WIDTH * 2 - 1 : 0]     r_trsfrmrdata=0         ;
reg    [11 : 0]                             r_wr_addr               ;

assign w_EmbeddedRAM_wea   = i_switch ? i_MLPs_wea   : r_trsfrmrdata_valid  ;
assign w_EmbeddedRAM_addra = i_switch ? i_MLPs_addra : r_wr_addr            ;
assign w_EmbeddedRAM_dina  = i_switch ? i_MLPs_dina  : r_trsfrmrdata        ;
assign w_EmbeddedRAM_addrb = i_switch ? i_MLPs_addrb : i_rd_addr            ;
assign o_MLPs_doutb        = w_ramout_data ;

// r_trsfrmrdata_valid
always@(posedge s_clk) begin
    o_ramout_data <= w_ramout_data;

    if (i_data_valid)
        r_trsfrmrdata_valid <= 1'b1;
    else
        r_trsfrmrdata_valid <= 1'b0;
end

// r_trsfrmrdata
always@(posedge s_clk) begin
    if (i_data_valid)
        r_trsfrmrdata <= w_trsfrmrdata;
    else
        r_trsfrmrdata <= r_trsfrmrdata;
end

// r_wr_addr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_wr_addr <= 'd0;
    else if (r_trsfrmrdata_valid)
        r_wr_addr <= r_wr_addr + 1'b1;
end

// o_ramout_ready
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        o_ramout_ready <= 1'b1;  // XXX : JUST FOR SIMULATION
    else if (r_trsfrmrdata_valid && ~i_data_valid)
        o_ramout_ready <= 1'b1;
end

// --------------- instantiation --------------- \\ 
genvar k;
generate
    for (k = 0; k < `PATCH_EMBED_WIDTH; k = k + 1) begin: adder_group

        half_adder u_half_adder(
            .i_data0  ( i_fmap[k]               ),
            .i_data1  ( i_patchdata[k]          ),

            .o_sum    ( w_trsfrmrdata[2*k]      ),
            .o_carry  ( w_trsfrmrdata[2*k + 1]  )  
        );

    end
endgenerate

EmbeddedRAM EmbeddedRAM_m0 (
    .clka       ( s_clk                 ),  // input wire clka
    .wea        ( w_EmbeddedRAM_wea     ),  // input wire [0 : 0] wea
    .addra      ( w_EmbeddedRAM_addra   ),  // input wire [11 : 0] addra
    .dina       ( w_EmbeddedRAM_dina    ),  // input wire [63 : 0] dina

    .clkb       ( s_clk                 ),  // input wire clkb
    .addrb      ( w_EmbeddedRAM_addrb   ),  // input wire [11 : 0] addrb
    .doutb      ( w_ramout_data         )   // output wire [63 : 0] doutb
);

endmodule // PatchEmbed
