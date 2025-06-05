/*
    --- simple systolic array --- 
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
    func    : A * B         fetch data / calculate / load data
*/

`include "E:/Desktop/Zynq_Spikformer/Zynq_Spikformer.srcs/sources_1/hyper_para.v"
module SystolicArray (
    input                                             s_clk               ,
    input                                             s_rst               ,   
    input                                             i_Init_PrepareData  ,
    output wire                                       o_Finish_Calc       ,
    // -- get A Matrix Data Slices
    input                                             MtrxA_slice_valid   ,
    input       [`DATA_WIDTH - 1 : 0]                 MtrxA_slice_data    ,
    input                                             MtrxA_slice_done    ,
    output reg                                        MtrxA_slice_ready=0 ,
    // -- get B Matrix Data Slices
    input                                             MtrxB_slice_valid   ,
    input       [`DATA_WIDTH - 1 : 0]                 MtrxB_slice_data    ,
    input                                             MtrxB_slice_done    ,
    output reg                                        MtrxB_slice_ready=0 ,
    // -- PsumFIFO Data Slices
    input       [`SYSTOLIC_UNIT_NUM - 1 : 0]          i_PsumFIFO_Grant    ,
    input                                             i_PsumFIFO_Valid    ,
    output reg  [`SYSTOLIC_PSUM_WIDTH - 1 : 0]        o_PsumFIFO_Data=0   
);

// --- wire ---  
wire  [`SYSTOLIC_UNIT_NUM - 1 : 0]                               w00_fifo_full                  ;
wire  [`SYSTOLIC_UNIT_NUM - 1 : 0]                               w00_fifo_empty                 ;
wire  [`SYSTOLIC_UNIT_NUM - 1 : 0]                               w01_fifo_full                  ;
wire  [`SYSTOLIC_UNIT_NUM - 1 : 0]                               w01_fifo_empty                 ;
wire  [`SYSTOLIC_UNIT_NUM - 1 : 0]                               w_psum_fifo_full               ;
wire  [`SYSTOLIC_UNIT_NUM - 1 : 0]                               w_psum_fifo_empty              ;

wire  [`SYSTOLIC_DATA_WIDTH - 1 : 0]                             w00_Systolic_fifo_out    [`SYSTOLIC_UNIT_NUM - 1 : 0]                      ;
wire  [`SYSTOLIC_DATA_WIDTH - 1 : 0]                             w01_Systolic_fifo_out    [`SYSTOLIC_UNIT_NUM - 1 : 0]                      ;

wire  [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0]          w_in_data_valid                                                            ;
wire  [`SYSTOLIC_DATA_WIDTH - 1 : 0]                             w_in_raw_data            [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0] ; 
wire  [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0]          w_out_data_valid                                                           ;   
wire  [`SYSTOLIC_DATA_WIDTH - 1 : 0]                             w_out_raw_data           [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0] ;
wire  [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                             w_in_psum_data           [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0] ;  
wire  [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                             w_out_psum_data          [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0] ;  
wire  [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0]          w_out_psum_valid                                                           ;   

wire signed [`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS - 1 : 0]         w_PsumData_T0            [`SYSTOLIC_UNIT_NUM - 1 : 0]                      ;
wire signed [`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS - 1 : 0]         w_PsumData_T1            [`SYSTOLIC_UNIT_NUM - 1 : 0]                      ;
wire signed [`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS - 1 : 0]         w_PsumData_T2            [`SYSTOLIC_UNIT_NUM - 1 : 0]                      ;
wire signed [`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS - 1 : 0]         w_PsumData_T3            [`SYSTOLIC_UNIT_NUM - 1 : 0]                      ;

wire  [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                             w_Cal_MM_rlst            [`SYSTOLIC_UNIT_NUM - 1 : 0]                      ;  
wire                                                             w_Cal_MM_rlst_valid      [`SYSTOLIC_UNIT_NUM - 1 : 0]                      ;  

wire  [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                             w_Psumfifo_out           [`SYSTOLIC_UNIT_NUM - 1 : 0]                      ;  
wire  [`SYSTOLIC_UNIT_NUM - 1 : 0]                               w_Psumfifo_valid               ;
wire                                                             w_MtrxB_Empty                  ;
wire                                                             w_MtrxB_Full                   ;

wire                                                             w_MtrxA_Empty                  ;
wire                                                             w_MtrxA_Full                   ;

// --- reg ---
reg  [`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1 : 0]           Systolic_weight_valid='d0      ;     
reg  [`SYSTOLIC_UNIT_NUM - 1 : 0]                                Systolic_fifoin_valid='d0      ;
reg  [`DATA_WIDTH - 1 : 0]                                       Systolic_fifoindata='d0        ;  
reg  [$clog2(`SYSTOLIC_UNIT_NUM) - 1 : 0]                        r_fifoin_cnt                   ;
reg  [`SYSTOLIC_UNIT_NUM - 1 : 0]                                r_Systolic_fifo_out_valid='d0  ;
reg  [`SYSTOLIC_UNIT_NUM - 1 : 0]                                r_Psumfifo_out_valid=0         ;  
reg                                                              r_PsumAdd_Flag                 ;

reg                                                              r_MM_Calc_done                 ;
reg                                                              r_MM_Calc_done_delay           ;
reg                                                              r_MM_Calc_valid_delay=0        ;
reg  [`SYSTOLIC_UNIT_NUM - 1 : 0]                                r_Cal_MM_rlst_valid_d0=0       ;  
reg  [`SYSTOLIC_UNIT_NUM - 1 : 0]                                r_Cal_MM_rlst_valid_d1=0       ;  
reg                                                              r_Calc_MM_Busy                 ;
reg  [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                              r_Cal_MM_rlst_d0         [`SYSTOLIC_UNIT_NUM - 1 : 0]                      ;  
reg  [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                              r_Cal_MM_rlst_d1         [`SYSTOLIC_UNIT_NUM - 1 : 0]                      ;  

// -- MtrxB register signal -- 
reg  [1:0]                                                       r_LoadMtrxB_Pointer=2'b00      ;
reg  [1:0]                                                       r_CalcMtrxB_Pointer=2'b00      ;
reg  [`SYSTOLIC_UNIT_NUM - 1 : 0]                                r_Systolic_Col_valid='d0       ;
reg  [`SYSTOLIC_UNIT_NUM - 1 : 0]                                r_Systolic_Row_valid='d0       ;
reg                                                              r_MtrxB_slice_done_d0=0        ;
reg  [`SYSTOLIC_WEIGHT_WIDTH - 1 : 0]                            r_Systolic_Weights       [`SYSTOLIC_UNIT_NUM - 1 : 0]                      ; 

// -- MtrxA register signal --
reg  [$clog2((`SYSTOLIC_UNIT_NUM*8) / `DATA_WIDTH) - 1 : 0]      r_MtrxAin_cnt                  ;
reg  [1:0]                                                       r_LoadMtrxA_Pointer=2'b00      ;
reg  [1:0]                                                       r_CalcMtrxA_Pointer=2'b00      ;
reg                                                              r_MtrxA_slice_done_d0=0        ;

// --------------- MTRXB proc --------------- \\ 
assign w_MtrxB_Empty  = r_LoadMtrxB_Pointer == r_CalcMtrxB_Pointer;
assign w_MtrxB_Full   = (r_LoadMtrxB_Pointer[1] ^ r_CalcMtrxB_Pointer[1]) && (r_LoadMtrxB_Pointer[0] == r_CalcMtrxB_Pointer[0]);

// MtrxB_slice_ready
always@(posedge s_clk) begin
    if (MtrxB_slice_ready && MtrxB_slice_valid && MtrxB_slice_done)
        MtrxB_slice_ready <= 1'b0;
    else if (~w_MtrxB_Full && ~r_MtrxB_slice_done_d0)
        MtrxB_slice_ready <= 1'b1;
    else 
        MtrxB_slice_ready <= 1'b0;
end

// r_LoadMtrxB_Pointer
always@(posedge s_clk) begin
    r_MtrxB_slice_done_d0 <= MtrxB_slice_done;

    if (r_MtrxB_slice_done_d0)
        r_LoadMtrxB_Pointer <= r_LoadMtrxB_Pointer + 1'b1;
    else 
        r_LoadMtrxB_Pointer <= r_LoadMtrxB_Pointer;
end

// r_CalcMtrxB_Pointer
always@(posedge s_clk) begin
    if (r_MM_Calc_done)
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
    if (s_rst)
        r_Systolic_Col_valid <= {{(`SYSTOLIC_UNIT_NUM - 1){1'b0}}, 1'b1};
    else if (MtrxB_slice_ready && MtrxB_slice_valid && r_Systolic_Row_valid[`SYSTOLIC_UNIT_NUM - 1] && r_Systolic_Col_valid[`SYSTOLIC_UNIT_NUM - 1])
        r_Systolic_Col_valid <= {{(`SYSTOLIC_UNIT_NUM - 1){1'b0}}, 1'b1};
    else if (MtrxB_slice_ready && MtrxB_slice_valid && r_Systolic_Row_valid[`SYSTOLIC_UNIT_NUM - 1])
        r_Systolic_Col_valid <= r_Systolic_Col_valid << 1;
end

// r_Systolic_Row_valid
always@(posedge s_clk) begin
    if (s_rst)
        r_Systolic_Row_valid <= {{(`SYSTOLIC_UNIT_NUM - 8){1'b0}}, 8'hff};
    else if (r_Systolic_Row_valid[`SYSTOLIC_UNIT_NUM - 1])
        r_Systolic_Row_valid <= {{(`SYSTOLIC_UNIT_NUM - 8){1'b0}}, 8'hff};
    else if (MtrxB_slice_ready && MtrxB_slice_valid)
        r_Systolic_Row_valid <= r_Systolic_Row_valid << 8;
end

genvar nn;
generate
    for (nn = 0; nn < `SYSTOLIC_UNIT_NUM / 8; nn = nn + 1) begin

        // r_Systolic_Weights
        always@(posedge s_clk) begin
            if (MtrxB_slice_ready && MtrxB_slice_valid) begin
                r_Systolic_Weights[8 * nn + 0] <= MtrxB_slice_data[7 : 0];
                r_Systolic_Weights[8 * nn + 1] <= MtrxB_slice_data[15: 8];
                r_Systolic_Weights[8 * nn + 2] <= MtrxB_slice_data[23:16];
                r_Systolic_Weights[8 * nn + 3] <= MtrxB_slice_data[31:24];
                r_Systolic_Weights[8 * nn + 4] <= MtrxB_slice_data[39:32];
                r_Systolic_Weights[8 * nn + 5] <= MtrxB_slice_data[47:40];
                r_Systolic_Weights[8 * nn + 6] <= MtrxB_slice_data[55:48];
                r_Systolic_Weights[8 * nn + 7] <= MtrxB_slice_data[63:56];
            end
            else begin
                r_Systolic_Weights[8 * nn + 0] <= r_Systolic_Weights[8 * nn + 0];
                r_Systolic_Weights[8 * nn + 1] <= r_Systolic_Weights[8 * nn + 1];
                r_Systolic_Weights[8 * nn + 2] <= r_Systolic_Weights[8 * nn + 2];
                r_Systolic_Weights[8 * nn + 3] <= r_Systolic_Weights[8 * nn + 3];
                r_Systolic_Weights[8 * nn + 4] <= r_Systolic_Weights[8 * nn + 4];
                r_Systolic_Weights[8 * nn + 5] <= r_Systolic_Weights[8 * nn + 5];
                r_Systolic_Weights[8 * nn + 6] <= r_Systolic_Weights[8 * nn + 6];
                r_Systolic_Weights[8 * nn + 7] <= r_Systolic_Weights[8 * nn + 7];
            end
        end

    end
endgenerate

// --------------- MTRXA proc --------------- \\ 
assign w_MtrxA_Empty  = r_LoadMtrxA_Pointer == r_CalcMtrxA_Pointer;
assign w_MtrxA_Full   = (r_LoadMtrxA_Pointer[1] ^ r_CalcMtrxA_Pointer[1]) && (r_LoadMtrxA_Pointer[0] == r_CalcMtrxA_Pointer[0]);

// Systolic_fifoindata
always@(posedge s_clk) begin
    Systolic_fifoindata <= MtrxA_slice_data;
    r_MtrxA_slice_done_d0 <= MtrxA_slice_done;
end

// r_LoadMtrxA_Pointer
always@(posedge s_clk) begin
    if (r_MtrxA_slice_done_d0)
        r_LoadMtrxA_Pointer <= r_LoadMtrxA_Pointer + 1'b1;
    else 
        r_LoadMtrxA_Pointer <= r_LoadMtrxA_Pointer;
end

// r_CalcMtrxA_Pointer
always@(posedge s_clk) begin
    if (r_MM_Calc_done)
        r_CalcMtrxA_Pointer <= r_CalcMtrxA_Pointer + 1'b1;
    else 
        r_CalcMtrxA_Pointer <= r_CalcMtrxA_Pointer;
end

// MtrxA_slice_ready 
always@(posedge s_clk) begin
    if (MtrxA_slice_ready && MtrxA_slice_valid && MtrxA_slice_done)
        MtrxA_slice_ready <= 1'b0;
    else if (~w_MtrxA_Full && ~r_MtrxA_slice_done_d0)
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
    else if (MtrxA_slice_ready && MtrxA_slice_valid && r_MtrxAin_cnt == 'd1)
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
// r_Calc_MM_Busy
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_Calc_MM_Busy <= 1'b0;
    else if (r_MM_Calc_done)
        r_Calc_MM_Busy <= 1'b0;
    else if (r_Systolic_fifo_out_valid[0])
        r_Calc_MM_Busy <= 1'b1;
end

// r_Systolic_fifo_out_valid
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_Systolic_fifo_out_valid[0] <= 1'b0;
    else if (r_Systolic_fifo_out_valid[`SYSTOLIC_UNIT_NUM - 1])
        r_Systolic_fifo_out_valid[0] <= 1'b0;
    else if (~w_MtrxA_Empty && ~w_MtrxB_Empty && ~r_Calc_MM_Busy)
        r_Systolic_fifo_out_valid[0] <= 1'b1;
end

// -----> debug dot 
wire signed [`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS - 1 : 0] debug_PsumData_T0     [`SYSTOLIC_UNIT_NUM - 1 : 0]  ;
wire signed [`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS - 1 : 0] debug_PsumData_T1     [`SYSTOLIC_UNIT_NUM - 1 : 0]  ;
wire signed [`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS - 1 : 0] debug_PsumData_T2     [`SYSTOLIC_UNIT_NUM - 1 : 0]  ;
wire signed [`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS - 1 : 0] debug_PsumData_T3     [`SYSTOLIC_UNIT_NUM - 1 : 0]  ;
// end debug dot <-----

genvar mm;
generate

    for (mm = 0; mm < `SYSTOLIC_UNIT_NUM; mm = mm + 1) begin: psum_fifo

        assign w_PsumData_T0[mm] = $signed(r_Cal_MM_rlst_d0[mm][(`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*1 - 1 : (`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*0]) 
                                 + $signed(w_Psumfifo_out[mm][(`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*1 - 1 : (`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*0])     ;
        assign w_PsumData_T1[mm] = $signed(r_Cal_MM_rlst_d0[mm][(`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*2 - 1 : (`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*1]) 
                                 + $signed(w_Psumfifo_out[mm][(`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*2 - 1 : (`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*1])     ;
        assign w_PsumData_T2[mm] = $signed(r_Cal_MM_rlst_d0[mm][(`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*3 - 1 : (`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*2]) 
                                 + $signed(w_Psumfifo_out[mm][(`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*3 - 1 : (`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*2])     ;
        assign w_PsumData_T3[mm] = $signed(r_Cal_MM_rlst_d0[mm][(`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*4 - 1 : (`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*3]) 
                                 + $signed(w_Psumfifo_out[mm][(`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*4 - 1 : (`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*3])     ;

// -----> debug dot 
        assign debug_PsumData_T0[mm] = r_Cal_MM_rlst_d1[mm][(`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*1 - 1 : (`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*0];
        assign debug_PsumData_T1[mm] = r_Cal_MM_rlst_d1[mm][(`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*2 - 1 : (`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*1];
        assign debug_PsumData_T2[mm] = r_Cal_MM_rlst_d1[mm][(`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*3 - 1 : (`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*2];
        assign debug_PsumData_T3[mm] = r_Cal_MM_rlst_d1[mm][(`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*4 - 1 : (`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*3];
// end debug dot <-----

        if (mm > 0) begin

            always@(posedge s_clk) begin
                r_Systolic_fifo_out_valid[mm] <= r_Systolic_fifo_out_valid[mm - 1];
            end

        end
        
        // r_Cal_MM_rlst r_Cal_MM_rlst_valid
        always@(posedge s_clk) begin
            r_Cal_MM_rlst_d0[mm]       <= w_Cal_MM_rlst[mm]       ;
            r_Cal_MM_rlst_valid_d0[mm] <= w_Cal_MM_rlst_valid[mm] ;

            r_Cal_MM_rlst_d1[mm]       <= r_PsumAdd_Flag ? {w_PsumData_T3[mm], w_PsumData_T2[mm], w_PsumData_T1[mm], w_PsumData_T0[mm]}
                                        : r_Cal_MM_rlst_d0[mm] ;
            r_Cal_MM_rlst_valid_d1[mm] <= r_Cal_MM_rlst_valid_d0[mm] ;
        end

        // r_Psumfifo_out_valid
        always@(posedge s_clk) begin
            r_Psumfifo_out_valid[mm] <= w_Cal_MM_rlst_valid[mm];
        end

        assign w_Psumfifo_valid[mm] =  (r_Psumfifo_out_valid[mm] & r_PsumAdd_Flag) 
                                    || (i_PsumFIFO_Grant[mm] ? i_PsumFIFO_Valid : 1'b0);

        Psum_slice_fifo u_Psum_slice_fifo (
            .clk        ( s_clk                                ),
            .srst       ( s_rst                                ),
            .din        ( r_Cal_MM_rlst_d1[mm]                 ),  // [79 : 0]
            .wr_en      ( r_Cal_MM_rlst_valid_d1[mm]           ),  
            
            .rd_en      ( w_Psumfifo_valid[mm]                 ), 
            .dout       ( w_Psumfifo_out[mm]                   ),  // [79 : 0]
            .full       ( w_psum_fifo_full[mm]                 ),
            .empty      ( w_psum_fifo_empty[mm]                )
        );

    end

endgenerate

// -- Psum fetch o_PsumFIFO_Data
integer d;
always@(*) begin
    for (d = 0; d < `SYSTOLIC_UNIT_NUM; d = d + 1) begin
        if (i_PsumFIFO_Grant[d])
            o_PsumFIFO_Data <= w_Psumfifo_out[d];
    end
end

// r_PsumAdd_Flag
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst || i_Init_PrepareData)
        r_PsumAdd_Flag <= 1'b0;
    else if (r_MM_Calc_done)
        r_PsumAdd_Flag <= 1'b1;
end

// --------------- Systolic Array Main Code --------------- \\ 
always@(posedge s_clk) begin
    r_MM_Calc_valid_delay <= r_Cal_MM_rlst_valid_d1[`SYSTOLIC_UNIT_NUM - 1];
end

// r_MM_Calc_done
always@(posedge s_clk) begin
    r_MM_Calc_done_delay <= r_MM_Calc_done;

    if (r_MM_Calc_valid_delay && ~r_Cal_MM_rlst_valid_d1[`SYSTOLIC_UNIT_NUM - 1])
        r_MM_Calc_done <= 1'b1;
    else
        r_MM_Calc_done <= 1'b0;
end

genvar row, col;
generate
    
    for (col = 0; col < `SYSTOLIC_UNIT_NUM; col = col + 1) begin: PE_col
        
        assign w_in_data_valid[col*`SYSTOLIC_UNIT_NUM] = r_Systolic_fifo_out_valid[col];
        assign w_in_raw_data[col*`SYSTOLIC_UNIT_NUM]   = r_CalcMtrxA_Pointer[0] ? w01_Systolic_fifo_out[col] : w00_Systolic_fifo_out[col];

        for (row = 0; row < `SYSTOLIC_UNIT_NUM; row = row + 1) begin: PE_row

            Systolic_pe u_Systolic_pe(
                .s_clk           ( s_clk                                                              ),
                .s_rst           ( s_rst                                                              ),

                .weight_LoadPtr  ( r_LoadMtrxB_Pointer[0]                                             ),
                .weight_CalcPtr  ( r_CalcMtrxB_Pointer[0]                                             ),
                .weight_valid    ( Systolic_weight_valid[col*`SYSTOLIC_UNIT_NUM + row] & ~w_MtrxB_Full),
                .weights         ( r_Systolic_Weights[row]                                            ),

                .in_data_valid   ( w_in_data_valid[col*`SYSTOLIC_UNIT_NUM + row]                      ),
                .in_raw_data     ( w_in_raw_data[col*`SYSTOLIC_UNIT_NUM + row]                        ),
                .out_data_valid  ( w_out_data_valid[col*`SYSTOLIC_UNIT_NUM + row]                     ),
                .out_raw_data    ( w_out_raw_data[col*`SYSTOLIC_UNIT_NUM + row]                       ),

                .in_psum_data    ( w_in_psum_data[col*`SYSTOLIC_UNIT_NUM + row]                       ),
                .out_psum_valid  ( w_out_psum_valid[col*`SYSTOLIC_UNIT_NUM + row]                     ),
                .out_psum_data   ( w_out_psum_data[col*`SYSTOLIC_UNIT_NUM + row]                      )
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

        assign w_Cal_MM_rlst_valid[col]  =   w_out_psum_valid[(`SYSTOLIC_UNIT_NUM - 1) * `SYSTOLIC_UNIT_NUM + col] ;
        assign w_Cal_MM_rlst[col]        =   w_out_psum_data[(`SYSTOLIC_UNIT_NUM - 1) * `SYSTOLIC_UNIT_NUM + col]  ;

    end

endgenerate

assign o_Finish_Calc = r_MM_Calc_done_delay && w_MtrxA_Empty;
// --------------- Finite-State-Machine --------------- \\
// Not Use

endmodule // SystolicArray


