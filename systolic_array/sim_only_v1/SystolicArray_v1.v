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

localparam  S_IDLE         =   0   ,
            S_LOAD_MTRX    =   1   ,
            S_CAL_MM       =   2   ,
            S_DATA_WAIT    =   3   ;

// --- wire ---  
wire  [`SYSTOLIC_UNIT_NUM - 1 : 0]                       w_fifo_full                    ;
wire  [`SYSTOLIC_UNIT_NUM - 1 : 0]                       w_fifo_empty                   ;
// wire  [`SYSTOLIC_UNIT_NUM - 1 : 0]                       w_psum_fifo_full               ;
// wire  [`SYSTOLIC_UNIT_NUM - 1 : 0]                       w_psum_fifo_empty              ;

wire  [`SYSTOLIC_DATA_WIDTH - 1 : 0]                     w_Systolic_fifo_out      [`SYSTOLIC_UNIT_NUM - 1 : 0]                      ;

wire  [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0]  w_in_data_valid                                                            ;
wire  [`SYSTOLIC_DATA_WIDTH - 1 : 0]                     w_in_raw_data            [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0] ; 
wire  [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0]  w_out_data_valid                                                           ;   
wire  [`SYSTOLIC_DATA_WIDTH - 1 : 0]                     w_out_raw_data           [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0] ;
wire  [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                     w_in_psum_data           [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0] ;  
wire  [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                     w_out_psum_data          [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0] ;  

wire  [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                     w_Cal_MM_rlst            [`SYSTOLIC_UNIT_NUM - 1 : 0]                      ;  

// --- reg ---
reg  [2:0]                                               s_curr_state                   ;
reg  [2:0]                                               s_next_state                   ;

reg  [1:0]                                               r_loadMtrx_cnt                 ;  
reg  [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0]   Systolic_weight_valid='d0      ;     
reg  [`SYSTOLIC_UNIT_NUM - 1 : 0]                        Systolic_fifoin_valid='d0      ;
reg  [$clog2(`SYSTOLIC_UNIT_NUM) - 1 : 0]                r_fifoin_cnt                   ;
reg  [`SYSTOLIC_DATA_WIDTH - 1 : 0]                      Systolic_fifoindata='d0        ;  
reg  [`SYSTOLIC_UNIT_NUM - 1 : 0]                        r_Systolic_fifo_out_valid='d0  ;

reg                                                      r_loadMtrxA_flag               ;
reg                                                      r_loadMtrxB_flag               ;

// --------------- state --------------- \\ 
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        s_curr_state <= S_IDLE;
    else
        s_curr_state <= s_next_state;
end

// r_loadMtrx_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst || s_curr_state == S_IDLE)
        r_loadMtrx_cnt <= 'd0;
    else if (MtrxA_slice_done && MtrxB_slice_done)
        r_loadMtrx_cnt <= r_loadMtrx_cnt + 'd2;
    else if (MtrxA_slice_done || MtrxB_slice_done)
        r_loadMtrx_cnt <= r_loadMtrx_cnt + 1'b1;
end

// --------------- MTRXB proc --------------- \\ 
// r_loadMtrxB_flag
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst || s_curr_state == S_IDLE)
        r_loadMtrxB_flag <= 1'b0;
    else if (MtrxB_slice_done)
        r_loadMtrxB_flag <= 1'b1;
end

// MtrxB_slice_ready
always@(posedge s_clk) begin
    if (MtrxB_slice_ready && MtrxB_slice_valid && MtrxB_slice_done)
        MtrxB_slice_ready <= 1'b0;
    else if (s_curr_state == S_LOAD_MTRX && ~r_loadMtrxB_flag)
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
end

// --------------- MTRXA proc --------------- \\ 
// r_loadMtrxA_flag
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst || s_curr_state == S_IDLE)
        r_loadMtrxA_flag <= 1'b0;
    else if (MtrxA_slice_done)
        r_loadMtrxA_flag <= 1'b1;
end

// MtrxA_slice_ready Systolic_fifoindata
always@(posedge s_clk) begin
    Systolic_fifoindata <= MtrxA_slice_data;

    if (MtrxA_slice_ready && MtrxA_slice_valid && MtrxA_slice_done)
        MtrxA_slice_ready <= 1'b0;
    else if (s_curr_state == S_LOAD_MTRX && ~r_loadMtrxA_flag)
        MtrxA_slice_ready <= 1'b1;
    else 
        MtrxA_slice_ready <= 1'b0;
end

// r_fifoin_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_fifoin_cnt <= 'd0;
    else if (MtrxA_slice_ready && MtrxA_slice_valid) // Ps : Counter is a power of 2 integer
        r_fifoin_cnt <= r_fifoin_cnt + 1'b1;
end

genvar k;
generate
    for (k = 0; k < `SYSTOLIC_UNIT_NUM; k = k + 1) begin: data_in_fifo
        
        // Systolic_fifoin_valid
        always@(posedge s_clk, posedge s_rst) begin
            if (s_rst)
                Systolic_fifoin_valid[k] <= 'd0;
            else if (MtrxA_slice_ready && MtrxA_slice_valid && r_fifoin_cnt == k)
                Systolic_fifoin_valid[k] <= 1'b1;
            else 
                Systolic_fifoin_valid[k] <= 'd0;
        end

        MtrxA_slice_fifo u_MtrxA_slice_fifo (
            .clk        ( s_clk                               ),
            .srst       ( s_rst                               ),
            .din        ( Systolic_fifoindata                 ),  // input wire [15 : 0] din
            .wr_en      ( Systolic_fifoin_valid[k]            ),  // input wire wr_en
            
            .rd_en      ( r_Systolic_fifo_out_valid[k]        ),  // input wire rd_en
            .dout       ( w_Systolic_fifo_out[k]              ),  // output wire [15 : 0] dout
            .full       ( w_fifo_full[k]                      ),
            .empty      ( w_fifo_empty[k]                     )
        );

    end
endgenerate

// --------------- CAL MM --------------- \\ 
// r_Systolic_fifo_out_valid
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_Systolic_fifo_out_valid[0] = 1'b0;
    else if (r_Systolic_fifo_out_valid[`SYSTOLIC_UNIT_NUM - 1])
        r_Systolic_fifo_out_valid[0] = 1'b0;
    else if (s_curr_state == S_CAL_MM)
        r_Systolic_fifo_out_valid[0] = 1'b1;
end

genvar mm;
generate

    for (mm = 0; mm < `SYSTOLIC_UNIT_NUM; mm = mm + 1) begin: psum_fifo

        if (mm > 0) begin

            always@(posedge s_clk) begin
                r_Systolic_fifo_out_valid[mm] <= r_Systolic_fifo_out_valid[mm - 1];
            end

        end

        // Psum_slice_fifo u_Psum_slice_fifo (
        //     .clk        ( s_clk                                ),
        //     .srst       ( s_rst                                ),
        //     .din        ( psum_fifoindata                      ), 
        //     .wr_en      ( psum_fifoin_valid[mm]                ),
            
        //     .rd_en      ( r_psum_fifo_out_valid[mm]            ),
        //     .dout       ( w_psum_fifo_out[mm]                  ),
        //     .full       ( w_psum_fifo_full[mm]                  ),
        //     .empty      ( w_psum_fifo_empty[mm]                 )
        // );

    end

endgenerate

// --------------- Systolic Array Main Code --------------- \\ 
genvar row, col;

generate
    
    for (col = 0; col < `SYSTOLIC_UNIT_NUM; col = col + 1) begin: PE_col
        
        assign w_in_data_valid[col*`SYSTOLIC_UNIT_NUM] = r_Systolic_fifo_out_valid[col];
        assign w_in_raw_data[col*`SYSTOLIC_UNIT_NUM]   = w_Systolic_fifo_out[col]      ;

        for (row = 0; row < `SYSTOLIC_UNIT_NUM; row = row + 1) begin: PE_row

            Systolic_pe_v1 u_Systolic_pe_v1(
                .s_clk           ( s_clk                                                  ),
                .s_rst           ( s_rst                                                  ),

                .weight_valid    ( Systolic_weight_valid[col*`SYSTOLIC_UNIT_NUM + row]    ),
                .weights         ( MtrxB_slice_data                                       ),

                .in_data_valid   ( w_in_data_valid[col*`SYSTOLIC_UNIT_NUM + row]          ),
                .in_raw_data     ( w_in_raw_data[col*`SYSTOLIC_UNIT_NUM + row]            ),
                .out_data_valid  ( w_out_data_valid[col*`SYSTOLIC_UNIT_NUM + row]         ),
                .out_raw_data    ( w_out_raw_data[col*`SYSTOLIC_UNIT_NUM + row]           ),

                .in_psum_data    ( w_in_psum_data[col*`SYSTOLIC_UNIT_NUM + row]           ),
                .out_psum_data   ( w_out_psum_data[col*`SYSTOLIC_UNIT_NUM + row]          )
            );

            if (row > 0) begin

                assign w_in_data_valid[col*`SYSTOLIC_UNIT_NUM + row] = w_out_data_valid[col*`SYSTOLIC_UNIT_NUM + row - 1];
                assign w_in_raw_data[col*`SYSTOLIC_UNIT_NUM + row]   = w_out_raw_data[col*`SYSTOLIC_UNIT_NUM + row - 1]  ;
         
            end

            if (col == 0) begin

                assign w_in_psum_data[row] = 'd0 ;
            
            end else begin

                assign w_in_psum_data[col*`SYSTOLIC_UNIT_NUM + row] = w_out_psum_data[(col - 1)*`SYSTOLIC_UNIT_NUM + row] ;

            end

        end

        assign w_Cal_MM_rlst[col] = w_out_psum_data[(`SYSTOLIC_UNIT_NUM - 1) * `SYSTOLIC_UNIT_NUM + col] ;

    end

endgenerate

// --------------- Finite-State-Machine --------------- \\

always@(*) begin

    case(s_curr_state)
        S_IDLE:             s_next_state = S_LOAD_MTRX;
        S_LOAD_MTRX:        s_next_state = (r_loadMtrx_cnt == 'd2) ? S_CAL_MM : S_LOAD_MTRX;
        S_CAL_MM:           s_next_state = r_Systolic_fifo_out_valid[`SYSTOLIC_UNIT_NUM - 1] ? S_DATA_WAIT : S_CAL_MM;
        S_DATA_WAIT:        s_next_state = S_DATA_WAIT;
        default:            s_next_state = S_IDLE;
    endcase 

end

endmodule //SystolicArray_v1
