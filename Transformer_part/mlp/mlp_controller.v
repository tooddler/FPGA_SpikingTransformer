/*
    --- mlp proc --- 
    Author   : Toddler. 
    Email    : 23011211185@stu.xidian.edu.cn
    Encoder  : UTF-8
*/

`include "E:/Desktop/Zynq_Spikformer/Zynq_Spikformer.srcs/sources_1/hyper_para.v"
module mlp_controller (
    input                                         s_clk                 ,
    input                                         s_rst                 ,
    // triger signal
    input                                         i_multi_linear_start  , 
    // embeded-RAM interface
    output                                        o_Mlp_Ram00_wea       ,
    output  [11 : 0]                              o_Mlp_Ram00_addra     ,
    output  [63 : 0]                              o_Mlp_Ram00_dina      ,
    output  [11 : 0]                              o_Mlp_Ram00_addrb     , // rd
    input   [63 : 0]                              i_Mlp_Ram00_doutb     ,
    // mlp_tmp-RAM interface
    output                                        o_Mlp_Ram01_wea       ,
    output  [13 : 0]                              o_Mlp_Ram01_addra     ,
    output  [63 : 0]                              o_Mlp_Ram01_dina      ,
    output  [13 : 0]                              o_Mlp_Ram01_addrb     , // rd
    input   [63 : 0]                              i_Mlp_Ram01_doutb     ,
    // attn(x)-RAM interface
    output                                        o_Mlp_Ram02_wea       ,
    output  [11 : 0]                              o_Mlp_Ram02_addra     ,
    output  [63 : 0]                              o_Mlp_Ram02_dina      ,
    output  [11 : 0]                              o_Mlp_Ram02_addrb     , // rd
    input   [63 : 0]                              i_Mlp_Ram02_doutb     ,
    // x + attn(x) - RAM interface
    output                                        o_Mlp_Ram03_wea       ,
    output  [11 : 0]                              o_Mlp_Ram03_addra     ,
    output  [63 : 0]                              o_Mlp_Ram03_dina      ,
    // send to systolic array
    output reg                                    o_Init_PrepareData    , // init 
    // - array q
    output wire                                   o_Mtrx00_slice_valid  , // ch - 0
    output wire  [63 : 0]                         o_Mtrx00_slice_data   ,
    output wire                                   o_Mtrx00_slice_done   ,
    input                                         i_Mtrx00_slice_ready  ,
    // - array k
    output wire                                   o_Mtrx01_slice_valid  , // ch - 1
    output wire  [63 : 0]                         o_Mtrx01_slice_data   ,
    output wire                                   o_Mtrx01_slice_done   ,
    input                                         i_Mtrx01_slice_ready  ,
    // - array v
    output wire                                   o_Mtrx02_slice_valid  , // ch - 2
    output wire  [63 : 0]                         o_Mtrx02_slice_data   ,
    output wire                                   o_Mtrx02_slice_done   ,
    input                                         i_Mtrx02_slice_ready  ,
    // get data from array
    // - array q
    output wire [`SYSTOLIC_UNIT_NUM - 1 : 0]      o00_PsumFIFO_Grant    , // ch - 0
    output wire                                   o00_PsumFIFO_Valid    ,
    input       [`SYSTOLIC_PSUM_WIDTH - 1 : 0]    i00_PsumFIFO_Data     ,
    input                                         i00_Finish_Calc       ,
    // - array k
    output wire [`SYSTOLIC_UNIT_NUM - 1 : 0]      o01_PsumFIFO_Grant    , // ch - 1
    output wire                                   o01_PsumFIFO_Valid    ,
    input       [`SYSTOLIC_PSUM_WIDTH - 1 : 0]    i01_PsumFIFO_Data     ,
    input                                         i01_Finish_Calc       ,
    // - array v
    output wire [`SYSTOLIC_UNIT_NUM - 1 : 0]      o02_PsumFIFO_Grant    , // ch - 2
    output wire                                   o02_PsumFIFO_Valid    ,
    input       [`SYSTOLIC_PSUM_WIDTH - 1 : 0]    i02_PsumFIFO_Data     ,
    input                                         i02_Finish_Calc       ,

    output wire                                   o_MLP_Calc_Done      
);

// --- localparam ---
localparam MAX_MTRXB_CNT = (`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM * `QUAN_BITS) / `DATA_WIDTH ; // 32

localparam  P_WEIGHT_PROJ_FC_ROWMAX = `FINAL_FMAPS_CHNNLS / `SYSTOLIC_UNIT_NUM , // 24
            P_WEIGHT_PROJ_FC_COLMAX = `FINAL_FMAPS_CHNNLS / `SYSTOLIC_UNIT_NUM , // 24
            P_WEIGHT_MLP_FC1_ROWMAX = `FINAL_FMAPS_CHNNLS / `SYSTOLIC_UNIT_NUM , // 24
            P_WEIGHT_MLP_FC1_COLMAX = `MLP_HIDDEN_WIDTH   / `SYSTOLIC_UNIT_NUM , // 96
            P_WEIGHT_MLP_FC2_ROWMAX = `MLP_HIDDEN_WIDTH   / `SYSTOLIC_UNIT_NUM , // 96
            P_WEIGHT_MLP_FC2_COLMAX = `FINAL_FMAPS_CHNNLS / `SYSTOLIC_UNIT_NUM ; // 24

localparam  S_IDLE          =   0 ,
            S_INIT          =   1 ,
            S_CAL_PROJ_FC   =   2 ,
            S_CAL_MLP_FC0   =   3 ,
            S_CAL_MLP_FC1   =   4 ,
            S_FETCH_DATA    =   5 ;

// --- wire ---
wire                                                           w_Mtrx_slice_ready      ;
wire [63 : 0]                                                  w_Mlp_Ram_00add02       ;
wire signed [15 : 0]                                           w_ROM_bias_out          ;
wire signed [`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS - 1 : 0]       w_ROM_bias_out_ext      ; // 20
wire [4*`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS + 7 : 0]            w_AddTree_dataout       ;
wire [4*`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS - 1 : 0]            w_AddTree_datain    [`TIME_STEPS - 1 : 0] ;

wire  [`TIME_STEPS - 1 : 0]                                    w_spikes_out            ;
wire                                                           w_spikes_valid          ;
wire  [`TIME_STEPS*2 - 1 : 0]                                  w_spikes_out_ext        ;
wire  [`PATCH_EMBED_WIDTH*2 - 1 : 0]                           w_MLPsSpikesOut_data    ;
wire                                                           w_MLPsSpikesOut_valid   ;
wire                                                           w_LoadDataState_Flag    ;

// --- reg ---
reg  [2 : 0]                                                   s_curr_state            ;
reg  [2 : 0]                                                   s_next_state            ;
// torch.size(linear.weight.data) = torch.tensor([m, n])
reg  [7 : 0]                                                   r_WghtShp_RowCntMax     ; // n
reg  [7 : 0]                                                   r_WghtShp_ColCntMax     ; // m
reg  [7 : 0]                                                   r_WghtShp_RowCnt        ;
reg  [7 : 0]                                                   r_WghtShp_ColCnt        ;
reg  [1 : 0]                                                   r_fcLayer_Cnt           ;
reg  [1 : 0]                                                   r_fcLayer_Cnt_delay     ;

reg  [13 : 0]                                                  r_RamRead_Addr          ;
reg  [13 : 0]                                                  r_RamRead_BaseAddr      ;
reg                                                            r_Mtrx_AddFlag          ;
reg                                                            r_Rd_data_valid_pre0=0  ;
reg                                                            r_Rd_data_valid_pre1=0  ;
reg                                                            r_Rd_data_valid_pre2=0  ;
reg                                                            r_Rd_data_done_pre0=0   ;
reg                                                            r_Rd_data_done_pre1=0   ;
reg                                                            r_Rd_data_done_pre2=0   ;

reg  [63 : 0]                                                  r_Mtrx_slice_data       ;
reg  [2 : 0]                                                   r_Mtrx_slice_ch_Grant   ;
reg                                                            r_Mtrx_slice_valid      ;
reg                                                            r_Mtrx_slice_done       ;
reg  [9 : 0]                                                   r_Mtrx_Cnt              ;

reg  [`SYSTOLIC_UNIT_NUM - 1 : 0]                              r_PsumFIFO_Grant        ;
reg                                                            r_PsumFIFO_Valid        ;
reg  [2 : 0]                                                   r_PsumFIFO_Valid_dly    ;

reg  [2 : 0]                                                   r_Finish_Calc           ;
reg  [$clog2(`SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM) - 1 : 0] r_PsumFIFO_cnt          ;

reg  [11 : 0]                                                  r_ROM_addra             ;
reg  [11 : 0]                                                  r_ROM_BaseAddra         ;
reg  [11 : 0]                                                  r_MLPs_BiasWidth        ;

reg  [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                            r00_PsumFIFO_Data       ;
reg  [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                            r01_PsumFIFO_Data       ;
reg  [`SYSTOLIC_PSUM_WIDTH - 1 : 0]                            r02_PsumFIFO_Data       ;

reg  [`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS + 1 : 0]              r_lif_thrd              ;

reg  [63 : 0]                                                  r_Mlp_Ram00_doutb=0     ;
reg  [63 : 0]                                                  r_Mlp_Ram01_doutb=0     ;
reg  [63 : 0]                                                  r_Mlp_Ram02_doutb=0     ;

reg  [13 : 0]                                                  r_WriteBack2Ram_Addr    ;
reg  [13 : 0]                                                  r_WriteBack2Ram_BaseAddr;
reg  [13 : 0]                                                  r_WriteBack2Ram_BaseAddr_delay;
reg                                                            r_WriteBack2Ram_Flag    ;
reg  [10 : 0]                                                  r_WriteBack2Ram_MaxCnt  ;
reg  [1 : 0]                                                   r_WriteBack2Ram_LayerCnt;

reg  [13 : 0]                                                  r_RamRead_Addr_delay  [2 : 0] ;

reg                                                            r_MLP_Calc_Done         ;

// --------------- state --------------- \\ 
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        s_curr_state <= S_IDLE;
    else
        s_curr_state <= s_next_state;
end

// --------------- Basic Logic Proc --------------- \\ 
assign o_MLP_Calc_Done = r_MLP_Calc_Done;
// r_MLP_Calc_Done
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_MLP_Calc_Done <= 'd0;
    else if (r_fcLayer_Cnt == 'd3 && s_curr_state == S_INIT)
        r_MLP_Calc_Done <= 1'b1;
end

// o_Init_PrepareData
always@(posedge s_clk) begin
    if (s_curr_state == S_INIT)
        o_Init_PrepareData <= 1'b1;
    else 
        o_Init_PrepareData <= 1'b0;
end

// r_WghtShp_RowCntMax  r_WghtShp_ColCntMax
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) begin
        r_WghtShp_RowCntMax <= 'd0;
        r_WghtShp_ColCntMax <= 'd0;
    end
    else begin
        case(s_curr_state)
        S_CAL_PROJ_FC: begin
            r_WghtShp_RowCntMax <= P_WEIGHT_PROJ_FC_ROWMAX;
            r_WghtShp_ColCntMax <= P_WEIGHT_PROJ_FC_COLMAX;
        end
        S_CAL_MLP_FC0: begin
            r_WghtShp_RowCntMax <= P_WEIGHT_MLP_FC1_ROWMAX;
            r_WghtShp_ColCntMax <= P_WEIGHT_MLP_FC1_COLMAX;
        end
        S_CAL_MLP_FC1: begin
            r_WghtShp_RowCntMax <= P_WEIGHT_MLP_FC2_ROWMAX;
            r_WghtShp_ColCntMax <= P_WEIGHT_MLP_FC2_COLMAX;
        end
        S_FETCH_DATA: begin
            r_WghtShp_RowCntMax <= r_WghtShp_RowCntMax;
            r_WghtShp_ColCntMax <= r_WghtShp_ColCntMax;
        end
        default: begin
            r_WghtShp_RowCntMax <= 8'hff;
            r_WghtShp_ColCntMax <= 8'hff;
        end
        endcase
    end
end

// r_lif_thrd
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_lif_thrd <= 'd0;
    else begin
        case(r_WriteBack2Ram_LayerCnt)
            'd0:        r_lif_thrd <= 'd128;
            'd1:        r_lif_thrd <= 'd256;
            'd2:        r_lif_thrd <= 'd128;
            default:    r_lif_thrd <= r_lif_thrd;
        endcase
    end
end

// --------------- RAM-Channels Arbit Proc --------------- \\ 
// -- Read port
assign o_Mlp_Ram00_addrb = (r_fcLayer_Cnt == 'd1) ? r_RamRead_Addr[11 : 0] : 'd0;
assign o_Mlp_Ram01_addrb = (r_fcLayer_Cnt == 'd0 || r_fcLayer_Cnt == 'd2) ? r_RamRead_Addr : 'd0;
assign o_Mlp_Ram02_addrb = (r_fcLayer_Cnt == 'd1) ? r_RamRead_Addr[11 : 0] : 'd0;

always@(posedge s_clk) begin
    r_Mlp_Ram00_doutb <= i_Mlp_Ram00_doutb;
    r_Mlp_Ram01_doutb <= i_Mlp_Ram01_doutb;
    r_Mlp_Ram02_doutb <= i_Mlp_Ram02_doutb;
end

genvar kk;
generate
    for (kk = 0; kk < 32; kk = kk + 1) begin
        assign w_Mlp_Ram_00add02[kk*2 + 1 : kk*2] = r_Mlp_Ram00_doutb[kk*2 + 1 : kk*2] + r_Mlp_Ram02_doutb[kk*2 + 1 : kk*2];
    end
endgenerate

// r_Mtrx_slice_data
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_Mtrx_slice_data <= 'd0;
    else begin
        case(r_fcLayer_Cnt)
            'd0, 'd2:   r_Mtrx_slice_data <= r_Mlp_Ram01_doutb;
            'd1:        r_Mtrx_slice_data <= w_Mlp_Ram_00add02;
            default:    r_Mtrx_slice_data <= r_Mtrx_slice_data;
        endcase
    end
end

// -- Write port
// r_WriteBack2Ram_LayerCnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_WriteBack2Ram_LayerCnt <= 'd0;
    else if (r_WriteBack2Ram_Addr[0] && w_MLPsSpikesOut_valid 
        && r_WriteBack2Ram_Addr[13 : 3] == r_WriteBack2Ram_MaxCnt - 1 
        && r_WriteBack2Ram_BaseAddr_delay == 2 * `FINAL_FMAPS_WIDTH / `SYSTOLIC_UNIT_NUM - 2)
        r_WriteBack2Ram_LayerCnt <= r_WriteBack2Ram_LayerCnt + 1'b1;
end

// r_WriteBack2Ram_MaxCnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_WriteBack2Ram_MaxCnt <= 'd0;
    else begin
        case(r_WriteBack2Ram_LayerCnt)
            'd0, 'd2:    r_WriteBack2Ram_MaxCnt <= `FINAL_FMAPS_CHNNLS;
            'd1:         r_WriteBack2Ram_MaxCnt <= `MLP_HIDDEN_WIDTH;
            default:     r_WriteBack2Ram_MaxCnt <= 14'h3fff;
        endcase
    end
end

// r_WriteBack2Ram_Flag
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_WriteBack2Ram_Flag <= 1'b0;
    else if (w_MLPsSpikesOut_valid)
        r_WriteBack2Ram_Flag <= ~r_WriteBack2Ram_Flag;
end

// r_WriteBack2Ram_Addr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_WriteBack2Ram_Addr <= 'd0;
    else if (w_MLPsSpikesOut_valid && r_WriteBack2Ram_Addr[13 : 3] == r_WriteBack2Ram_MaxCnt - 1 && r_WriteBack2Ram_Addr[0])
        r_WriteBack2Ram_Addr <= r_WriteBack2Ram_BaseAddr;
    else if (w_MLPsSpikesOut_valid && r_WriteBack2Ram_Flag)
        r_WriteBack2Ram_Addr <= r_WriteBack2Ram_Addr + 'd7;
    else if (w_MLPsSpikesOut_valid)
        r_WriteBack2Ram_Addr <= r_WriteBack2Ram_Addr + 1'b1;
end

// r_WriteBack2Ram_BaseAddr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_WriteBack2Ram_BaseAddr <= 'd0;
    else if (~r_WriteBack2Ram_Addr[0] && w_MLPsSpikesOut_valid && r_WriteBack2Ram_Addr[13 : 3] == r_WriteBack2Ram_MaxCnt - 1 && r_WriteBack2Ram_BaseAddr == 2 * `FINAL_FMAPS_WIDTH / `SYSTOLIC_UNIT_NUM - 2)
        r_WriteBack2Ram_BaseAddr <= 'd0;
    else if (~r_WriteBack2Ram_Addr[0] && w_MLPsSpikesOut_valid && r_WriteBack2Ram_Addr[13 : 3] == r_WriteBack2Ram_MaxCnt - 1)
        r_WriteBack2Ram_BaseAddr <= r_WriteBack2Ram_BaseAddr + 'd2;
end

// r_RamRead_Addr_delay
always@(posedge s_clk) begin
    r_RamRead_Addr_delay[0] <= r_RamRead_Addr;
    r_RamRead_Addr_delay[1] <= r_RamRead_Addr_delay[0];
    r_RamRead_Addr_delay[2] <= r_RamRead_Addr_delay[1];

    if (w_MLPsSpikesOut_valid) 
        r_WriteBack2Ram_BaseAddr_delay <= r_WriteBack2Ram_BaseAddr;
    else 
        r_WriteBack2Ram_BaseAddr_delay <= r_WriteBack2Ram_BaseAddr_delay;
end

assign o_Mlp_Ram03_wea   = (r_fcLayer_Cnt_delay == 'd1) ? r_Mtrx_slice_valid      : 'd0;
assign o_Mlp_Ram03_addra = (r_fcLayer_Cnt_delay == 'd1) ? r_RamRead_Addr_delay[2] : 'd0;
assign o_Mlp_Ram03_dina  = (r_fcLayer_Cnt_delay == 'd1) ? r_Mtrx_slice_data       : 'd0;

assign o_Mlp_Ram01_wea   = (r_WriteBack2Ram_LayerCnt == 'd1) ? w_MLPsSpikesOut_valid : 'd0;
assign o_Mlp_Ram01_addra = (r_WriteBack2Ram_LayerCnt == 'd1) ? r_WriteBack2Ram_Addr  : 'd0;
assign o_Mlp_Ram01_dina  = (r_WriteBack2Ram_LayerCnt == 'd1) ? w_MLPsSpikesOut_data  : 'd0;

assign o_Mlp_Ram02_wea   = (r_WriteBack2Ram_LayerCnt == 'd0 ||  r_WriteBack2Ram_LayerCnt == 'd2) ? w_MLPsSpikesOut_valid : 'd0;
assign o_Mlp_Ram02_addra = (r_WriteBack2Ram_LayerCnt == 'd0 ||  r_WriteBack2Ram_LayerCnt == 'd2) ? r_WriteBack2Ram_Addr  : 'd0;
assign o_Mlp_Ram02_dina  = (r_WriteBack2Ram_LayerCnt == 'd0 ||  r_WriteBack2Ram_LayerCnt == 'd2) ? w_MLPsSpikesOut_data  : 'd0;

// --------------- Mtrx Data proc --------------- \\ 
// START ->> Arbiter part
// r_Mtrx_slice_ch_Grant
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst || s_curr_state == S_IDLE)
        r_Mtrx_slice_ch_Grant <= 3'b001;
    else if (r_Mtrx_slice_done)
        r_Mtrx_slice_ch_Grant <= {r_Mtrx_slice_ch_Grant[1 : 0], r_Mtrx_slice_ch_Grant[2]};
end

assign w_Mtrx_slice_ready   = r_Mtrx_slice_ch_Grant[0] ? i_Mtrx00_slice_ready : (
                              r_Mtrx_slice_ch_Grant[1] ? i_Mtrx01_slice_ready : (
                              r_Mtrx_slice_ch_Grant[2] ? i_Mtrx02_slice_ready : 1'b0 ));

assign o_Mtrx00_slice_valid = r_Mtrx_slice_ch_Grant[0] ? r_Mtrx_slice_valid : 'd0 ;
assign o_Mtrx00_slice_data  = r_Mtrx_slice_ch_Grant[0] ? r_Mtrx_slice_data  : 'd0 ;
assign o_Mtrx00_slice_done  = r_Mtrx_slice_ch_Grant[0] ? r_Mtrx_slice_done  : 'd0 ;

assign o_Mtrx01_slice_valid = r_Mtrx_slice_ch_Grant[1] ? r_Mtrx_slice_valid : 'd0 ;
assign o_Mtrx01_slice_data  = r_Mtrx_slice_ch_Grant[1] ? r_Mtrx_slice_data  : 'd0 ;
assign o_Mtrx01_slice_done  = r_Mtrx_slice_ch_Grant[1] ? r_Mtrx_slice_done  : 'd0 ;

assign o_Mtrx02_slice_valid = r_Mtrx_slice_ch_Grant[2] ? r_Mtrx_slice_valid : 'd0 ;
assign o_Mtrx02_slice_data  = r_Mtrx_slice_ch_Grant[2] ? r_Mtrx_slice_data  : 'd0 ;
assign o_Mtrx02_slice_done  = r_Mtrx_slice_ch_Grant[2] ? r_Mtrx_slice_done  : 'd0 ;
// END ->> Arbiter part

assign w_LoadDataState_Flag = s_curr_state == S_CAL_PROJ_FC || s_curr_state == S_CAL_MLP_FC0 || s_curr_state == S_CAL_MLP_FC1;

// r_Mtrx_AddFlag
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_Mtrx_AddFlag <= 1'b0;
    else if (r_Rd_data_valid_pre0)
        r_Mtrx_AddFlag <= ~r_Mtrx_AddFlag;
end

// r_Rd_data_valid_pre0
always@(posedge s_clk) begin
    r_Rd_data_valid_pre1 <= r_Rd_data_valid_pre0 ;
    r_Rd_data_valid_pre2 <= r_Rd_data_valid_pre1 ;
    r_Mtrx_slice_valid   <= r_Rd_data_valid_pre2 ;

    if (r_Rd_data_valid_pre0 && r_Rd_data_done_pre0)
        r_Rd_data_valid_pre0 <= 1'b0;
    else if (w_LoadDataState_Flag && w_Mtrx_slice_ready && ~r_Mtrx_slice_valid)
        r_Rd_data_valid_pre0 <= 1'b1;
end

// r_Mtrx_Cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_Mtrx_Cnt <= 'd0;
    else if (r_Rd_data_done_pre0)
        r_Mtrx_Cnt <= 'd0;
    else if (r_Rd_data_valid_pre0)
        r_Mtrx_Cnt <= r_Mtrx_Cnt + 1'b1;
end

// r_Rd_data_done_pre0 r_Rd_data_done_pre1
always@(posedge s_clk) begin
    r_Rd_data_done_pre1 <= r_Rd_data_done_pre0 ;
    r_Rd_data_done_pre2 <= r_Rd_data_done_pre1 ;
    r_Mtrx_slice_done   <= r_Rd_data_done_pre2 ;

    if (r_Rd_data_valid_pre0 && r_Mtrx_Cnt == MAX_MTRXB_CNT - 2)
        r_Rd_data_done_pre0 <= 1'b1;
    else
        r_Rd_data_done_pre0 <= 1'b0;
end

// r_WghtShp_RowCnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_WghtShp_RowCnt <= 'd0;
    else if (r_WghtShp_RowCnt == r_WghtShp_RowCntMax - 1 && r_Rd_data_done_pre0)
        r_WghtShp_RowCnt <= 'd0;
    else if (r_Rd_data_done_pre0)
        r_WghtShp_RowCnt <= r_WghtShp_RowCnt + 1'b1;
end

// r_WghtShp_ColCnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_WghtShp_ColCnt <= 'd0;
    else if (r_WghtShp_ColCnt == r_WghtShp_ColCntMax - 1 && (&r_PsumFIFO_cnt))
        r_WghtShp_ColCnt <= 'd0;
    else if (&r_PsumFIFO_cnt)
        r_WghtShp_ColCnt <= r_WghtShp_ColCnt + 1'b1;
end

// r_RamRead_BaseAddr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_RamRead_BaseAddr <= 'd0;
    else if ((r_WghtShp_ColCnt == r_WghtShp_ColCntMax - 1 && (&r_PsumFIFO_cnt)) && r_RamRead_BaseAddr == 2 * `FINAL_FMAPS_WIDTH / `SYSTOLIC_UNIT_NUM - 2)
        r_RamRead_BaseAddr <= 'd0;
    else if (r_WghtShp_ColCnt == r_WghtShp_ColCntMax - 1 && (&r_PsumFIFO_cnt))
        r_RamRead_BaseAddr <= r_RamRead_BaseAddr + 'd2;
end

// r_RamRead_Addr    
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_RamRead_Addr <= 'd0;
    else if (s_curr_state == S_INIT)
        r_RamRead_Addr <= r_RamRead_BaseAddr;
    else if (r_Rd_data_valid_pre0 && r_Mtrx_AddFlag)
        r_RamRead_Addr <= r_RamRead_Addr + 'd7;
    else if (r_Rd_data_valid_pre0)
        r_RamRead_Addr <= r_RamRead_Addr + 1'b1;
end

// --------------- Psum Data fetch proc --------------- \\ 
assign o00_PsumFIFO_Grant = r_PsumFIFO_Grant ;
assign o00_PsumFIFO_Valid = r_PsumFIFO_Valid ;
assign o01_PsumFIFO_Grant = r_PsumFIFO_Grant ;
assign o01_PsumFIFO_Valid = r_PsumFIFO_Valid ;
assign o02_PsumFIFO_Grant = r_PsumFIFO_Grant ;
assign o02_PsumFIFO_Valid = r_PsumFIFO_Valid ;
assign w_ROM_bias_out_ext = {{(`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS - 16){w_ROM_bias_out[15]} }, w_ROM_bias_out};

// r_fcLayer_Cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) 
        r_fcLayer_Cnt <= 'd0;
    else if ((r_WghtShp_ColCnt == r_WghtShp_ColCntMax - 1 && (&r_PsumFIFO_cnt)) && r_RamRead_BaseAddr == 2 * `FINAL_FMAPS_WIDTH / `SYSTOLIC_UNIT_NUM - 2) // 6
        r_fcLayer_Cnt <= r_fcLayer_Cnt + 1'b1;
end

// r_fcLayer_Cnt_delay
always@(posedge s_clk) begin
    r_fcLayer_Cnt_delay <= r_fcLayer_Cnt;
end

// r_Finish_Calc
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst || r_Finish_Calc[2])
        r_Finish_Calc <= 3'b000;
    else if (i01_Finish_Calc || i02_Finish_Calc)
        r_Finish_Calc <= r_Finish_Calc << 1;
    else if (i00_Finish_Calc)
        r_Finish_Calc <= 3'b001;
end

// r_PsumFIFO_Grant
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_PsumFIFO_Grant <= 'd0;
    else if (&r_PsumFIFO_cnt)
        r_PsumFIFO_Grant <= 'd0;
    else if (r_PsumFIFO_Valid && (&r_PsumFIFO_cnt[$clog2(`SYSTOLIC_UNIT_NUM) - 1 : 0]))
        r_PsumFIFO_Grant <= {r_PsumFIFO_Grant[`SYSTOLIC_UNIT_NUM - 2 : 0], r_PsumFIFO_Grant[`SYSTOLIC_UNIT_NUM - 1]};
    else if (s_curr_state == S_FETCH_DATA && r_Finish_Calc[2])
        r_PsumFIFO_Grant <= {{(`SYSTOLIC_UNIT_NUM){1'b0}}, 1'b1};
end

// r_PsumFIFO_Valid 
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_PsumFIFO_Valid <= 1'b0;
    else if (r_PsumFIFO_Valid && (&r_PsumFIFO_cnt))
        r_PsumFIFO_Valid <= 1'b0;
    else if (s_curr_state == S_FETCH_DATA && r_Finish_Calc[2])
        r_PsumFIFO_Valid <= 1'b1;
end

// r_PsumFIFO_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_PsumFIFO_cnt <= 'd0;
    else if (r_PsumFIFO_Valid)
        r_PsumFIFO_cnt <= r_PsumFIFO_cnt + 1'b1;
end

always@(posedge s_clk) begin
    r00_PsumFIFO_Data <= i00_PsumFIFO_Data;
    r01_PsumFIFO_Data <= i01_PsumFIFO_Data;
    r02_PsumFIFO_Data <= i02_PsumFIFO_Data;

    r_PsumFIFO_Valid_dly <= {r_PsumFIFO_Valid_dly[1 : 0], r_PsumFIFO_Valid};
end

// --------------- Bias ROM part --------------- \\
// r_MLPs_BiasWidth
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_MLPs_BiasWidth <= 'd0;
    else if (r_WriteBack2Ram_BaseAddr == 2 * `FINAL_FMAPS_WIDTH / `SYSTOLIC_UNIT_NUM - 2
            && r_ROM_BaseAddra[11 : 4] == r_WghtShp_ColCntMax - 1 
            && (&r_PsumFIFO_cnt[$clog2(`SYSTOLIC_UNIT_NUM) - 1 : 0]) 
            && r_ROM_addra[3 : 0] == 4'b0111) begin
        if (r_MLPs_BiasWidth == 'd0)
            r_MLPs_BiasWidth <= `FINAL_FMAPS_CHNNLS;
        else if (r_MLPs_BiasWidth == `FINAL_FMAPS_CHNNLS)
            r_MLPs_BiasWidth <= `FINAL_FMAPS_CHNNLS + `MLP_HIDDEN_WIDTH;
    end
end

// r_ROM_BaseAddra
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_ROM_BaseAddra <= 'd0;
    else if (r_ROM_BaseAddra[11 : 4] == r_WghtShp_ColCntMax - 1 && (&r_PsumFIFO_cnt[$clog2(`SYSTOLIC_UNIT_NUM) - 1 : 0]) && r_ROM_addra[3 : 0] == 4'b0111)
        r_ROM_BaseAddra <= 'd0;
    else if ((&r_PsumFIFO_cnt[$clog2(`SYSTOLIC_UNIT_NUM) - 1 : 0]) && r_ROM_addra[3 : 0] == 4'b0111)
        r_ROM_BaseAddra <= r_ROM_BaseAddra + 'd16;
end

// r_ROM_addra
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_ROM_addra <= 'd0;
    else if (&r_PsumFIFO_cnt)
        r_ROM_addra <= r_ROM_BaseAddra + r_MLPs_BiasWidth;
    else if (&r_PsumFIFO_cnt[$clog2(`SYSTOLIC_UNIT_NUM) - 1 : 0])
        r_ROM_addra <= r_ROM_addra + 1'b1;
end

MLPs_bias_Rom u_MLPs_bias_Rom (
    .clka                   ( s_clk                                 ), 
    .addra                  ( r_ROM_addra                           ),  // [11 : 0] addra
    .douta                  ( w_ROM_bias_out                        )   // [15 : 0] douta
);

// ------------ debug dot
wire [19:0] w_debug_r00_PsumFIFO_Data_t0;
wire [19:0] w_debug_r00_PsumFIFO_Data_t1;
wire [19:0] w_debug_r00_PsumFIFO_Data_t2;
wire [19:0] w_debug_r00_PsumFIFO_Data_t3;

wire [19:0] w_debug_r01_PsumFIFO_Data_t0;
wire [19:0] w_debug_r01_PsumFIFO_Data_t1;
wire [19:0] w_debug_r01_PsumFIFO_Data_t2;
wire [19:0] w_debug_r01_PsumFIFO_Data_t3;

wire [19:0] w_debug_r02_PsumFIFO_Data_t0;
wire [19:0] w_debug_r02_PsumFIFO_Data_t1;
wire [19:0] w_debug_r02_PsumFIFO_Data_t2;
wire [19:0] w_debug_r02_PsumFIFO_Data_t3;

wire [21:0] w_debug_treeout_t0;
wire [21:0] w_debug_treeout_t1;
wire [21:0] w_debug_treeout_t2;
wire [21:0] w_debug_treeout_t3;

wire [21:0] w_debug_add_t0;
wire [21:0] w_debug_add_t1;
wire [21:0] w_debug_add_t2;
wire [21:0] w_debug_add_t3;

wire [1 : 0]   w_debug_spikes_in [31 : 0];

genvar ii;
generate
    for (ii = 0; ii < 32; ii = ii + 1) begin : slice_data
        assign w_debug_spikes_in[ii] = r_Mtrx_slice_data[2*ii+1 : 2*ii];
    end
endgenerate

assign w_debug_r00_PsumFIFO_Data_t0 = r00_PsumFIFO_Data[20*1 - 1 : 20*0] ;
assign w_debug_r00_PsumFIFO_Data_t1 = r00_PsumFIFO_Data[20*2 - 1 : 20*1] ;
assign w_debug_r00_PsumFIFO_Data_t2 = r00_PsumFIFO_Data[20*3 - 1 : 20*2] ;
assign w_debug_r00_PsumFIFO_Data_t3 = r00_PsumFIFO_Data[20*4 - 1 : 20*3] ;

assign w_debug_r01_PsumFIFO_Data_t0 = r01_PsumFIFO_Data[20*1 - 1 : 20*0] ;
assign w_debug_r01_PsumFIFO_Data_t1 = r01_PsumFIFO_Data[20*2 - 1 : 20*1] ;
assign w_debug_r01_PsumFIFO_Data_t2 = r01_PsumFIFO_Data[20*3 - 1 : 20*2] ;
assign w_debug_r01_PsumFIFO_Data_t3 = r01_PsumFIFO_Data[20*4 - 1 : 20*3] ;

assign w_debug_r02_PsumFIFO_Data_t0 = r02_PsumFIFO_Data[20*1 - 1 : 20*0] ;
assign w_debug_r02_PsumFIFO_Data_t1 = r02_PsumFIFO_Data[20*2 - 1 : 20*1] ;
assign w_debug_r02_PsumFIFO_Data_t2 = r02_PsumFIFO_Data[20*3 - 1 : 20*2] ;
assign w_debug_r02_PsumFIFO_Data_t3 = r02_PsumFIFO_Data[20*4 - 1 : 20*3] ;

assign w_debug_add_t0 = $signed(w_debug_r00_PsumFIFO_Data_t0) + $signed(w_debug_r01_PsumFIFO_Data_t0) + $signed(w_debug_r02_PsumFIFO_Data_t0);
assign w_debug_add_t1 = $signed(w_debug_r00_PsumFIFO_Data_t1) + $signed(w_debug_r01_PsumFIFO_Data_t1) + $signed(w_debug_r02_PsumFIFO_Data_t1);
assign w_debug_add_t2 = $signed(w_debug_r00_PsumFIFO_Data_t2) + $signed(w_debug_r01_PsumFIFO_Data_t2) + $signed(w_debug_r02_PsumFIFO_Data_t2);
assign w_debug_add_t3 = $signed(w_debug_r00_PsumFIFO_Data_t3) + $signed(w_debug_r01_PsumFIFO_Data_t3) + $signed(w_debug_r02_PsumFIFO_Data_t3);

assign w_debug_treeout_t0 = w_AddTree_dataout[22*1 - 1 : 22*0] ;
assign w_debug_treeout_t1 = w_AddTree_dataout[22*2 - 1 : 22*1] ;
assign w_debug_treeout_t2 = w_AddTree_dataout[22*3 - 1 : 22*2] ;
assign w_debug_treeout_t3 = w_AddTree_dataout[22*4 - 1 : 22*3] ;

// // ------------ end debug dot

// --------------- AddTree --------------- \\
// AddTree Generator
assign w_AddTree_datain[0] = {r00_PsumFIFO_Data[20*1 - 1 : 20*0], r01_PsumFIFO_Data[20*1 - 1 : 20*0], r02_PsumFIFO_Data[20*1 - 1 : 20*0], w_ROM_bias_out_ext};
assign w_AddTree_datain[1] = {r00_PsumFIFO_Data[20*2 - 1 : 20*1], r01_PsumFIFO_Data[20*2 - 1 : 20*1], r02_PsumFIFO_Data[20*2 - 1 : 20*1], w_ROM_bias_out_ext};
assign w_AddTree_datain[2] = {r00_PsumFIFO_Data[20*3 - 1 : 20*2], r01_PsumFIFO_Data[20*3 - 1 : 20*2], r02_PsumFIFO_Data[20*3 - 1 : 20*2], w_ROM_bias_out_ext};
assign w_AddTree_datain[3] = {r00_PsumFIFO_Data[20*4 - 1 : 20*3], r01_PsumFIFO_Data[20*4 - 1 : 20*3], r02_PsumFIFO_Data[20*4 - 1 : 20*3], w_ROM_bias_out_ext};

genvar t;
generate
    for (t = 0; t < `TIME_STEPS; t = t + 1) begin : multi_timestep

        add_tree #(
            .INPUTS_NUM     ( 4                                     ),
            .IDATA_WIDTH    ( `SYSTOLIC_PSUM_WIDTH / `TIME_STEPS    )
        ) u_add_tree(
            .sclk           ( s_clk                                 ),
            .s_rst_n        ( ~s_rst                                ),
            .idata          ( w_AddTree_datain[t]                   ),
            .data_out       ( w_AddTree_dataout[(`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS + 2)*(t+1) - 1 : (`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS + 2)*t])
        );

    end
endgenerate


// --------------- Active and Reshape Proc --------------- \\
genvar ee;
generate
    for (ee = 0; ee < `TIME_STEPS; ee = ee + 1) begin
        assign w_spikes_out_ext[2*(ee+1) - 1 : 2*ee] = {1'b0, w_spikes_out[ee]};
    end
endgenerate

LIF_group #(
    .PSUM_WIDTH             ( 4*`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS + 8 ) // 88
) u_LIF_group(
    .s_clk                  ( s_clk                                    ),
    .s_rst                  ( s_rst                                    ),

    .i_lif_thrd             ( r_lif_thrd                               ),
    .i_PsumValid            ( r_PsumFIFO_Valid_dly[2]                  ),
    .i_PsumData             ( w_AddTree_dataout                        ),

    .o_spikes_out           ( w_spikes_out                             ),
    .o_spikes_valid         ( w_spikes_valid                           )
);

attn_v_spikes_reshaping u_MLPs_spikes_reshaping (
    .s_clk                  ( s_clk                                    ),
    .s_rst                  ( s_rst                                    ),

    .i_spikes_out_ext       ( w_spikes_out_ext                         ),
    .i_spikes_valid         ( w_spikes_valid                           ),
    .o_attn_v_spikes_data   ( w_MLPsSpikesOut_data                     ),
    .o_attn_v_spikes_valid  ( w_MLPsSpikesOut_valid                    )
);

// --------------- Finite-State-Machine --------------- \\
always@(*) begin

    case(s_curr_state)
        S_IDLE:             s_next_state = i_multi_linear_start ? S_INIT : S_IDLE;
        S_INIT:             s_next_state = (r_fcLayer_Cnt == 'd0) ? S_CAL_PROJ_FC : (
                                           (r_fcLayer_Cnt == 'd1) ? S_CAL_MLP_FC0 : (
                                           (r_fcLayer_Cnt == 'd2) ? S_CAL_MLP_FC1 : S_IDLE));
        S_CAL_PROJ_FC:      s_next_state = (r_WghtShp_RowCnt == r_WghtShp_RowCntMax - 1 && r_Rd_data_done_pre0) ? S_FETCH_DATA : S_CAL_PROJ_FC;
        S_CAL_MLP_FC0:      s_next_state = (r_WghtShp_RowCnt == r_WghtShp_RowCntMax - 1 && r_Rd_data_done_pre0) ? S_FETCH_DATA : S_CAL_MLP_FC0;
        S_CAL_MLP_FC1:      s_next_state = (r_WghtShp_RowCnt == r_WghtShp_RowCntMax - 1 && r_Rd_data_done_pre0) ? S_FETCH_DATA : S_CAL_MLP_FC1;
        S_FETCH_DATA:       s_next_state = (&r_PsumFIFO_cnt) ? S_INIT : S_FETCH_DATA;
        default:            s_next_state = S_IDLE;
    endcase

end


endmodule // mlp_controller


