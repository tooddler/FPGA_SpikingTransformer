/*
    --- simple systolic array --- 
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
    ** Attn ** : simulation only
*/

`include "../../hyper_para.v"
module SystolicArray_v1 (
    input                                             s_clk               ,
    input                                             s_rst               ,    
    // -- get A Matrix Data Slices
    input                                             MtrxA_slice_valid   ,
    input       [`SYSTOLIC_DATA_WIDTH - 1 : 0]        MtrxA_slice_data    ,
    input                                             MtrxA_slice_done    ,
    output reg                                        MtrxA_slice_ready=0 ,
    // -- get B Matrix Data Slices
    input                                             MtrxB_slice_valid   ,
    input       [`SYSTOLIC_DATA_WIDTH - 1 : 0]        MtrxB_slice_data    ,
    input                                             MtrxB_slice_done    ,
    output reg                                        MtrxB_slice_ready=0 ,
    // -- get C Matrix Data Slices
    input                                             MtrxC_slice_valid   ,
    input       [`SYSTOLIC_DATA_WIDTH - 1 : 0]        MtrxC_slice_data    ,
    input                                             MtrxC_slice_done    ,
    output reg                                        MtrxC_slice_ready=0 
);

localparam  S_IDLE              =   0   ,
            S_LOAD_MTRXB        =   1   ,
            S_LOAD_MTRXA        =   2   ;

// --- wire ---
wire  [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0]  Systolic_rawdata_valid   ;     
wire  [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0]  Systolic_o_rawdata_valid ;    
wire                                                     w_fifo_full              ;
wire                                                     w_fifo_empty             ;

wire  [`SYSTOLIC_DATA_WIDTH - 1 : 0]                     Systolic_rawdata         [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0] ;     
wire  [`SYSTOLIC_DATA_WIDTH - 1 : 0]                     Systolic_o_rawdata       [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0] ; 
wire  [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                     Systolic_psum_in         [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0] ; 
wire  [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                     Systolic_psum_out        [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0] ;

// --- reg ---
reg  [2:0]                                               s_curr_state             ;
reg  [2:0]                                               s_next_state             ;

reg  [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0]   Systolic_weight_valid='d0;     
reg  [`SYSTOLIC_UNIT_NUM - 1 : 0]                        Systolic_fifoin_valid='d0;
reg  [`SYSTOLIC_DATA_WIDTH - 1 : 0]                      Systolic_fifoindata      ;

// --------------- state --------------- \\ 
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        s_curr_state <= S_IDLE;
    else
        s_curr_state <= s_next_state;
end

// --------------- MTRXB proc --------------- \\ 
// MtrxB_slice_ready
always@(posedge s_clk) begin
    if (s_curr_state == S_LOAD_MTRXB)
        MtrxB_slice_ready <= 1'b1;
    else 
        MtrxB_slice_ready <= 1'b0;
end

// Systolic_weight_valid
always@(posedge s_clk) begin
    if (s_curr_state == S_IDLE)
        Systolic_weight_valid <= {{(`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1){1'b0}}, 1'b1};
    else if (MtrxB_slice_ready && MtrxB_slice_valid)
        Systolic_weight_valid <= Systolic_weight_valid << 1;
    else 
        Systolic_weight_valid <= 'd0;
end

// --------------- MTRXA proc --------------- \\ 
// MtrxA_slice_ready
always@(posedge s_clk) begin
    if (s_curr_state == S_LOAD_MTRXA)
        MtrxA_slice_ready <= 1'b1;
    else 
        MtrxA_slice_ready <= 1'b0;
end

genvar k;
generate
    for (k = 0; k < `SYSTOLIC_UNIT_NUM; k = k + 1) begin: data_in_fifo

        MtrxA_slice_fifo u_MtrxA_slice_fifo (
            .clk        ( s_clk                               ),
            .srst       ( s_rst                               ),
            .din        ( Systolic_fifoindata                 ),  // input wire [15 : 0] din
            .wr_en      ( Systolic_fifoin_valid[k]            ),  // input wire wr_en
            
            .rd_en      (                                     ),  // input wire rd_en
            .dout       (                                     ),  // output wire [15 : 0] dout
            .full       ( w_fifo_full                         ),
            .empty      ( w_fifo_empty                        )
        );

    end
endgenerate

// --------------- Systolic Array Main Code --------------- \\ 
genvar row, col;

generate
    for (col = 0; col < `SYSTOLIC_UNIT_NUM; col = col + 1) begin: PE_col
        for (row = 0; row < `SYSTOLIC_UNIT_NUM; row = row + 1) begin: PE_row

            Systolic_pe_v1 u_Systolic_pe_v1(
                .s_clk           ( s_clk           ),
                .s_rst           ( s_rst           ),

                .weight_valid    ( Systolic_weight_valid[col*`SYSTOLIC_UNIT_NUM + row]    ),
                .weights         ( MtrxB_slice_data                                       ),

                .in_data_valid   ( in_data_valid   ),
                .in_raw_data     ( in_raw_data     ),
                .out_data_valid  ( out_data_valid  ),
                .out_raw_data    ( out_raw_data    ),

                .in_psum_data    ( in_psum_data    ),
                .out_psum_data   ( out_psum_data   )
            );

        end
    end
endgenerate

// --------------- Finite-State-Machine --------------- \\

always@(*) begin

    case(s_curr_state)
        S_IDLE:             s_next_state = S_LOAD_MTRXB;
        S_LOAD_MTRXB:       s_next_state = MtrxB_slice_done ? S_LOAD_MTRXA : S_LOAD_MTRXB;
        S_LOAD_MTRXA:       s_next_state = MtrxA_slice_done ?  : S_LOAD_MTRXA;
        default:            s_next_state = S_IDLE;
    endcase 

end

endmodule //SystolicArray_v1
