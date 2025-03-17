/*
    --- simple systolic array --- 
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
    func    : A * B         fetch data / calculate / load data
*/

`include "../../hyper_para.v"
module SystolicArray (
    input                                             s_clk               ,
    input                                             s_rst               ,   

    input                                             i_Init_PrepareData  ,
    // -- get A Matrix Data Slices
    input                                             MtrxA_slice_valid   ,
    input       [`DATA_WIDTH - 1 : 0]                 MtrxA_slice_data    ,
    input                                             MtrxA_slice_done    ,
    output reg                                        MtrxA_slice_ready=0 ,
    // -- get B Matrix Data Slices
    input                                             MtrxB_slice_valid   ,
    input       [`DATA_WIDTH - 1 : 0]                 MtrxB_slice_data    , // 64 = 8 x 8
    input                                             MtrxB_slice_done    ,
    output reg                                        MtrxB_slice_ready=0 
);

// --- wire ---  
wire  [`SYSTOLIC_UNIT_NUM - 1 : 0]                       w00_fifo_full                  ;
wire  [`SYSTOLIC_UNIT_NUM - 1 : 0]                       w00_fifo_empty                 ;
wire  [`SYSTOLIC_UNIT_NUM - 1 : 0]                       w01_fifo_full                  ;
wire  [`SYSTOLIC_UNIT_NUM - 1 : 0]                       w01_fifo_empty                 ;
// wire  [`SYSTOLIC_UNIT_NUM - 1 : 0]                       w_psum_fifo_full               ;
// wire  [`SYSTOLIC_UNIT_NUM - 1 : 0]                       w_psum_fifo_empty              ;

wire  [`SYSTOLIC_DATA_WIDTH - 1 : 0]                     w00_Systolic_fifo_out    [`SYSTOLIC_UNIT_NUM - 1 : 0]                      ;
wire  [`SYSTOLIC_DATA_WIDTH - 1 : 0]                     w01_Systolic_fifo_out    [`SYSTOLIC_UNIT_NUM - 1 : 0]                      ;

wire  [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0]  w_in_data_valid                                                            ;
wire  [`SYSTOLIC_DATA_WIDTH - 1 : 0]                     w_in_raw_data            [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0] ; 
wire  [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0]  w_out_data_valid                                                           ;   
wire  [`SYSTOLIC_DATA_WIDTH - 1 : 0]                     w_out_raw_data           [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0] ;
wire  [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                     w_in_psum_data           [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0] ;  
wire  [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                     w_out_psum_data          [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0] ;  

wire  [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                     w_Cal_MM_rlst            [`SYSTOLIC_UNIT_NUM - 1 : 0]                      ;  

wire                                                     w_MtrxB_Empty                  ;
wire                                                     w_MtrxB_Full                   ;

wire                                                     w_MtrxA_Empty                  ;
wire                                                     w_MtrxA_Full                   ;

// --- reg ---
reg                                                      r_weight_switch=0              ;
reg  [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0]   Systolic_weight_valid='d0      ;     
reg  [`SYSTOLIC_UNIT_NUM - 1 : 0]                        Systolic_fifoin_valid='d0      ;
reg  [$clog2(`SYSTOLIC_UNIT_NUM) - 1 : 0]                r_fifoin_cnt                   ;
reg  [`DATA_WIDTH - 1 : 0]                               Systolic_fifoindata='d0        ;  
reg  [`SYSTOLIC_UNIT_NUM - 1 : 0]                        r_Systolic_fifo_out_valid='d0  ;

// -- MtrxB register signal --
reg  [1:0]                                               r_LoadMtrxB_Pointer=2'b00      ;
reg  [1:0]                                               r_CalcMtrxB_Pointer=2'b00      ;
reg  [`SYSTOLIC_UNIT_NUM - 1 : 0]                        r_Systolic_Col_valid='d0       ;
reg  [`SYSTOLIC_UNIT_NUM - 1 : 0]                        r_Systolic_Row_valid='d0       ;
reg  [`SYSTOLIC_WEIGHT_WIDTH - 1 : 0]                    r_Systolic_Weights_Tmp='d0     ;
reg  [`SYSTOLIC_WEIGHT_WIDTH - 1 : 0]                    r_Systolic_Weights       [`SYSTOLIC_UNIT_NUM - 1 : 0]                      ; 

// -- MtrxA register signal --
reg  [2:0]                                               r_MtrxAin_cnt                  ;
reg  [1:0]                                               r_LoadMtrxA_Pointer=2'b00      ;
reg  [1:0]                                               r_CalcMtrxA_Pointer=2'b00      ;

// --------------- MTRXB proc --------------- \\ 
assign w_MtrxB_Empty  = r_LoadMtrxB_Pointer == r_CalcMtrxB_Pointer;
assign w_MtrxB_Full   = (r_LoadMtrxB_Pointer[1] ^ r_CalcMtrxB_Pointer[1]) && (r_LoadMtrxB_Pointer[0] == r_CalcMtrxB_Pointer[0]);

// MtrxB_slice_ready
always@(posedge s_clk) begin
    if (MtrxB_slice_ready && MtrxB_slice_valid && MtrxB_slice_done)
        MtrxB_slice_ready <= 1'b0;
    else if (~w_MtrxB_Full)
        MtrxB_slice_ready <= 1'b1;
    else 
        MtrxB_slice_ready <= 1'b0;
end

// r_LoadMtrxB_Pointer
always@(posedge s_clk) begin
    if (MtrxB_slice_done)
        r_LoadMtrxB_Pointer <= r_LoadMtrxB_Pointer + 1'b1;
    else 
        r_LoadMtrxB_Pointer <= r_LoadMtrxB_Pointer;
end

// r_CalcMtrxB_Pointer
always@(posedge s_clk) begin
    if (MM_Calc_done) // TODO: ARRAY CALC DONE
        r_CalcMtrxB_Pointer <= r_CalcMtrxB_Pointer + 1'b1;
    else 
        r_CalcMtrxB_Pointer <= r_CalcMtrxB_Pointer;
end

// Systolic_weight_valid
genvar kk_c, kk_r;
generate
    for (kk_c = 0; kk_c < `SYSTOLIC_UNIT_NUM; kk_c = kk_c + 1) begin
        for (kk_r = 0; kk_r < `SYSTOLIC_UNIT_NUM; kk_r = kk_r + 1) begin

            always@(posedge s_clk) begin
                Systolic_weight_valid[kk_c*`SYSTOLIC_UNIT_NUM + kk_r] <= r_Systolic_Col_valid[kk_c] & r_Systolic_Row_valid[kk_r];
            end

        end
    end
endgenerate

// r_Systolic_Col_valid
always@(posedge s_clk) begin
    if (i_Init_PrepareData)
        r_Systolic_Col_valid <= {{(`SYSTOLIC_UNIT_NUM - 1){1'b0}}, 1'b1};
    else if (MtrxB_slice_ready && MtrxB_slice_valid && r_Systolic_Row_valid[`SYSTOLIC_UNIT_NUM - 1] && r_Systolic_Col_valid[`SYSTOLIC_UNIT_NUM - 1])
        r_Systolic_Col_valid <= {{(`SYSTOLIC_UNIT_NUM - 1){1'b0}}, 1'b1};
    else if (MtrxB_slice_ready && MtrxB_slice_valid && r_Systolic_Row_valid[`SYSTOLIC_UNIT_NUM - 1])
        r_Systolic_Col_valid <= r_Systolic_Col_valid << 1;
end

// r_Systolic_Row_valid
always@(posedge s_clk) begin
    if (i_Init_PrepareData)
        r_Systolic_Row_valid <= {{(`SYSTOLIC_UNIT_NUM - 8){1'b0}}, 8'hff};
    else if (r_Systolic_Row_valid[`SYSTOLIC_UNIT_NUM - 1])
        r_Systolic_Row_valid <= {{(`SYSTOLIC_UNIT_NUM - 8){1'b0}}, 8'hff};
    else if (MtrxB_slice_ready && MtrxB_slice_valid)
        r_Systolic_Row_valid <= r_Systolic_Row_valid << 8;
end


// r_Systolic_Weights
always@(posedge s_clk) begin
    if (MtrxB_slice_ready && MtrxB_slice_valid)
        r_Systolic_Weights_Tmp <= MtrxB_slice_data;
    else 
        r_Systolic_Weights_Tmp <= r_Systolic_Weights_Tmp;
end

genvar nn;
generate
    for (nn = 0; nn < 8; nn = nn + 1) begin

        always@(posedge s_clk) begin
            r_Systolic_Weights[8 * nn + 0] <= r_Systolic_Weights_Tmp[7 : 0];
            r_Systolic_Weights[8 * nn + 1] <= r_Systolic_Weights_Tmp[15: 8];
            r_Systolic_Weights[8 * nn + 2] <= r_Systolic_Weights_Tmp[23:16];
            r_Systolic_Weights[8 * nn + 3] <= r_Systolic_Weights_Tmp[31:24];
            r_Systolic_Weights[8 * nn + 4] <= r_Systolic_Weights_Tmp[39:32];
            r_Systolic_Weights[8 * nn + 5] <= r_Systolic_Weights_Tmp[47:40];
            r_Systolic_Weights[8 * nn + 6] <= r_Systolic_Weights_Tmp[55:48];
            r_Systolic_Weights[8 * nn + 7] <= r_Systolic_Weights_Tmp[63:56];
        end
 
    end
endgenerate

// --------------- MTRXA proc --------------- \\ 
assign w_MtrxA_Empty  = r_LoadMtrxA_Pointer == r_CalcMtrxA_Pointer;
assign w_MtrxA_Full   = (r_LoadMtrxA_Pointer[1] ^ r_CalcMtrxA_Pointer[1]) && (r_LoadMtrxA_Pointer[0] == r_CalcMtrxA_Pointer[0]);

// Systolic_fifoindata
always@(posedge s_clk) begin
    Systolic_fifoindata <= MtrxA_slice_data;
end

// r_LoadMtrxA_Pointer
always@(posedge s_clk) begin
    if (MtrxA_slice_done)
        r_LoadMtrxA_Pointer <= r_LoadMtrxA_Pointer + 1'b1;
    else 
        r_LoadMtrxA_Pointer <= r_LoadMtrxA_Pointer;
end

// r_CalcMtrxA_Pointer
always@(posedge s_clk) begin
    if (MM_Calc_done) // TODO: ARRAY CALC DONE
        r_CalcMtrxA_Pointer <= r_CalcMtrxA_Pointer + 1'b1;
    else 
        r_CalcMtrxA_Pointer <= r_CalcMtrxA_Pointer;
end

// MtrxA_slice_ready 
always@(posedge s_clk) begin
    if (MtrxA_slice_ready && MtrxA_slice_valid && MtrxA_slice_done)
        MtrxA_slice_ready <= 1'b0;
    else if (~w_MtrxA_Full)
        MtrxA_slice_ready <= 1'b1;
    else 
        MtrxA_slice_ready <= 1'b0;
end

// r_MtrxAin_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_MtrxAin_cnt <= 'd0;
    else if (MtrxA_slice_ready && MtrxA_slice_valid)
        r_MtrxAin_cnt <= r_MtrxAin_cnt + 1'b1;
end

// r_fifoin_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_fifoin_cnt <= 'd0;
    else if (MtrxA_slice_ready && MtrxA_slice_valid && r_MtrxAin_cnt == 'd7) // r_MtrxAin_cnt max = embedded ram width / 8
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

        Mtrx_slice_fifo u00_MtrxA_slice_fifo (
            .clk        ( s_clk                                                  ),
            .srst       ( s_rst                                                  ),
            .din        ( Systolic_fifoindata                                    ),  // [63 : 0] din
            .wr_en      ( Systolic_fifoin_valid[k] & ~r_LoadMtrxA_Pointer[0]     ),

            .rd_en      ( r_Systolic_fifo_out_valid[k] & ~r_CalcMtrxA_Pointer[0] ),
            .dout       ( w00_Systolic_fifo_out[k]                               ),  // [7 : 0] dout
            .full       ( w00_fifo_full[k]                                       ),
            .empty      ( w00_fifo_empty[k]                                      )
        );

        Mtrx_slice_fifo u01_MtrxA_slice_fifo (
            .clk        ( s_clk                                                  ),
            .srst       ( s_rst                                                  ),
            .din        ( Systolic_fifoindata                                    ),  // [63 : 0] din
            .wr_en      ( Systolic_fifoin_valid[k] & r_LoadMtrxA_Pointer[0]      ),
             
            .rd_en      ( r_Systolic_fifo_out_valid[k] & r_CalcMtrxA_Pointer[0]  ),
            .dout       ( w01_Systolic_fifo_out[k]                               ),  // [7 : 0] dout
            .full       ( w01_fifo_full[k]                                       ),
            .empty      ( w01_fifo_empty[k]                                      )
        );

    end
endgenerate

// --------------- CAL MM --------------- \\ 
// r_Systolic_fifo_out_valid
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_Systolic_fifo_out_valid[0] <= 1'b0;
    else if (r_Systolic_fifo_out_valid[`SYSTOLIC_UNIT_NUM - 1])
        r_Systolic_fifo_out_valid[0] <= 1'b0;
    else if (~w_MtrxA_Empty && ~w_MtrxB_Empty)
        r_Systolic_fifo_out_valid[0] <= 1'b1;
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
        assign w_in_raw_data[col*`SYSTOLIC_UNIT_NUM]   = r_CalcMtrxA_Pointer[0] ? w01_Systolic_fifo_out[col] : w00_Systolic_fifo_out[col];

        for (row = 0; row < `SYSTOLIC_UNIT_NUM; row = row + 1) begin: PE_row

            Systolic_pe u_Systolic_pe(
                .s_clk           ( s_clk                                                  ),
                .s_rst           ( s_rst                                                  ),

                .weight_LoadPtr  ( r_LoadMtrxB_Pointer[0]                                 ),
                .weight_CalcPtr  ( r_CalcMtrxB_Pointer[0]                                 ),
                .weight_valid    ( Systolic_weight_valid[col*`SYSTOLIC_UNIT_NUM + row]    ),
                .weights         ( r_Systolic_Weights[row]                                ),

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
// Not Use

endmodule // SystolicArray
