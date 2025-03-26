/*
    --- Systolic Array Controller --- 
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "../hyper_para.v"
module SystolicController (
    input                                            s_clk                  ,
    input                                            s_rst                  ,    
    // interact with PatchEmbed module
    output reg  [11 : 0]                             o_rd_addr              ,
    input       [`PATCH_EMBED_WIDTH * 2 - 1 : 0]     i_ramout_data          , // ** Attn : delay 2 clk **      
    input                                            i_ramout_ready         ,
    // interact with weight fifo
    input       [`DATA_WIDTH - 1 : 0]                i_weight_out           ,
    output reg                                       o_weight_valid         , 
    input                                            i_weight_ready         , // Not for handshake
    output wire                                      load_w_finish          , // TODO : rst weights fifo
    // interact with Systolic Array
    output reg                                       o_Init_PrepareData     ,
    input                                            i_Finish_Calc          ,

    output reg                                       MtrxA_slice_valid      , // spikes
    output wire  [`DATA_WIDTH - 1 : 0]               MtrxA_slice_data       ,
    output reg                                       MtrxA_slice_done       ,
    input                                            MtrxA_slice_ready      ,

    output wire                                      MtrxB_slice_valid      , // Weights
    output wire  [`DATA_WIDTH - 1 : 0]               MtrxB_slice_data       ,
    output reg                                       MtrxB_slice_done       ,
    input                                            MtrxB_slice_ready      ,
    // -- fetch data from PsumFIFO
    output reg   [`SYSTOLIC_UNIT_NUM - 1 : 0]        o_PsumFIFO_Grant       ,
    output reg                                       o_PsumFIFO_Valid       ,
    input        [`SYSTOLIC_PSUM_WIDTH - 1 : 0]      i_PsumFIFO_Data      
);

localparam MAX_MTRXB_CNT    = (`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM * `QUAN_BITS) / `DATA_WIDTH ; // 32
localparam MAX_LOAD_ONELINE = `FINAL_FMAPS_CHNNLS / `SYSTOLIC_UNIT_NUM                             ; // 24

localparam  S_IDLE       =   0 ,
            S_LOAD_DATA  =   1 ,
            S_FETCH_DATA =   2 ;

// --- wire ---
assign load_w_finish = 1'b0; // FIXME: ONLY SIM

// --- reg ---
reg  [2 : 0]                    s_curr_state            ;
reg  [2 : 0]                    s_next_state            ;

reg  [9 : 0]                    r_MtrxA_cnt             ;
reg  [9 : 0]                    r_MtrxB_cnt             ;
reg                             r_MtrxA_AddFlag         ;
reg                             r_Rd_data_valid_pre0=0  ;
reg                             r_Rd_data_valid_pre1=0  ;
reg                             r_Rd_data_done_pre0=0   ;
reg                             r_Rd_data_done_pre1=0   ;
reg  [11 : 0]                   r_rd_baseaddr           ;
reg  [9 : 0]                    r_LoadFullLine_cnt      ;
reg  [9 : 0]                    r_PsumFIFO_cnt          ;

// --------------- state --------------- \\ 
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        s_curr_state <= S_IDLE;
    else
        s_curr_state <= s_next_state;
end

// --------------- Weights proc --------------- \\ 
assign MtrxB_slice_data  = i_weight_out   ;
assign MtrxB_slice_valid = o_weight_valid ;

// o_weight_valid
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        o_weight_valid <= 1'b0;
    else if (~i_weight_ready)
        o_weight_valid <= 1'b0;
    else if (o_weight_valid && MtrxB_slice_ready && MtrxB_slice_done)
        o_weight_valid <= 1'b0;
    else if (MtrxB_slice_ready)
        o_weight_valid <= 1'b1;
end

// r_MtrxB_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_MtrxB_cnt <= 'd0;
    else if (MtrxB_slice_done)
        r_MtrxB_cnt <= 'd0;
    else if (MtrxB_slice_ready && MtrxB_slice_valid)
        r_MtrxB_cnt <= r_MtrxB_cnt + 1'b1;
end

// MtrxB_slice_done
always@(posedge s_clk) begin
    if (MtrxB_slice_ready && MtrxB_slice_valid && r_MtrxB_cnt == MAX_MTRXB_CNT - 2)
        MtrxB_slice_done <= 1'b1;
    else
        MtrxB_slice_done <= 1'b0;
end

// --------------- MtrxA Data proc --------------- \\ 
assign MtrxA_slice_data = i_ramout_data;

// r_MtrxA_AddFlag
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_MtrxA_AddFlag <= 1'b0;
    else if (r_Rd_data_valid_pre0)
        r_MtrxA_AddFlag <= ~r_MtrxA_AddFlag;
end

// r_Rd_data_valid_pre0
always@(posedge s_clk) begin
    r_Rd_data_valid_pre1 <= r_Rd_data_valid_pre0 ;
    MtrxA_slice_valid    <= r_Rd_data_valid_pre1 ;

    if (r_Rd_data_valid_pre0 && r_Rd_data_done_pre0)
        r_Rd_data_valid_pre0 <= 1'b0;
    else if (s_curr_state == S_LOAD_DATA && MtrxA_slice_ready && ~MtrxA_slice_valid)
        r_Rd_data_valid_pre0 <= 1'b1;
end

// r_MtrxA_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_MtrxA_cnt <= 'd0;
    else if (r_Rd_data_done_pre0)
        r_MtrxA_cnt <= 'd0;
    else if (r_Rd_data_valid_pre0)
        r_MtrxA_cnt <= r_MtrxA_cnt + 1'b1;
end

// r_Rd_data_done_pre0 r_Rd_data_done_pre1
always@(posedge s_clk) begin
    r_Rd_data_done_pre1 <= r_Rd_data_done_pre0 ;
    MtrxA_slice_done    <= r_Rd_data_done_pre1 ;

    if (r_Rd_data_valid_pre0 && r_MtrxA_cnt == MAX_MTRXB_CNT - 2)
        r_Rd_data_done_pre0 <= 1'b1;
    else
        r_Rd_data_done_pre0 <= 1'b0;
end

// r_LoadFullLine_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_LoadFullLine_cnt <= 'd0;
    else if (r_LoadFullLine_cnt == MAX_LOAD_ONELINE - 1 && r_Rd_data_done_pre0)
        r_LoadFullLine_cnt <= 'd0;
    else if (r_Rd_data_done_pre0)
        r_LoadFullLine_cnt <= r_LoadFullLine_cnt + 1'b1;
end

// r_rd_baseaddr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_rd_baseaddr <= 'd0;
    else if (r_LoadFullLine_cnt == MAX_LOAD_ONELINE - 1 && r_Rd_data_done_pre0) // S_LOAD_DATA -> S_FETCH_DATA
        r_rd_baseaddr <= r_rd_baseaddr + 'd2;
end

// o_rd_addr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        o_rd_addr <= 'd0;
    else if (s_curr_state == S_IDLE)
        o_rd_addr <= r_rd_baseaddr;
    else if (r_Rd_data_valid_pre0 && r_MtrxA_AddFlag)
        o_rd_addr <= o_rd_addr + 'd7;
    else if (r_Rd_data_valid_pre0)
        o_rd_addr <= o_rd_addr + 1'b1;
end

// o_Init_PrepareData
always@(posedge s_clk) begin
    if (s_curr_state == S_IDLE) // FIXME : Psum fifo 一拍能复位成功？
        o_Init_PrepareData <= 1'b1;
    else 
        o_Init_PrepareData <= 1'b0;
end

// --------------- Psum Data fetch proc --------------- \\ 
// o_PsumFIFO_Grant
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        o_PsumFIFO_Grant <= 'd0;
    else if (r_PsumFIFO_cnt == `SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1)
        o_PsumFIFO_Grant <= 'd0;
    else if (o_PsumFIFO_Valid)
        o_PsumFIFO_Grant <= {o_PsumFIFO_Grant[`SYSTOLIC_UNIT_NUM - 2 : 0], o_PsumFIFO_Grant[`SYSTOLIC_UNIT_NUM - 1]};
    else if (s_curr_state == S_FETCH_DATA && i_Finish_Calc)
        o_PsumFIFO_Grant <= {{(`SYSTOLIC_UNIT_NUM){1'b0}}, 1'b1};
end

// r_PsumFIFO_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_PsumFIFO_cnt <= 'd0;
    else if (r_PsumFIFO_cnt == `SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1)
        r_PsumFIFO_cnt <= 'd0;
    else if (o_PsumFIFO_Valid)
        r_PsumFIFO_cnt <= r_PsumFIFO_cnt + 1'b1;
end

// o_PsumFIFO_Valid
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        o_PsumFIFO_Valid <= 1'b0;
    else if (o_PsumFIFO_Valid && r_PsumFIFO_cnt == `SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1)
        o_PsumFIFO_Valid <= 1'b0;
    else if (s_curr_state == S_FETCH_DATA && i_Finish_Calc)
        o_PsumFIFO_Valid <= 1'b1;
end

// i_PsumFIFO_Data 


// --------------- Finite-State-Machine --------------- \\
always@(*) begin

    case(s_curr_state)
        S_IDLE:             s_next_state = i_ramout_ready ? S_LOAD_DATA : S_IDLE;
        S_LOAD_DATA:        s_next_state = (r_LoadFullLine_cnt == MAX_LOAD_ONELINE - 1 && r_Rd_data_done_pre0) ? S_FETCH_DATA : S_LOAD_DATA;
        S_FETCH_DATA:       s_next_state = (r_PsumFIFO_cnt == `SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1) ? S_IDLE : S_FETCH_DATA;
        default:            s_next_state = S_IDLE;
    endcase

end

endmodule // SystolicController
