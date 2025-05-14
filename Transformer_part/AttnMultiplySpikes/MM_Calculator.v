/*
    --- Attn @ V --- 
    Author   : Toddler. 
    Email    : 23011211185@stu.xidian.edu.cn
    Encoder  : UTF-8
*/

`include "../../hyper_para.v"
module MM_Calculator (
    input                                                            s_clk                  ,
    input                                                            s_rst                  ,  
    // interact with Tmp_AttnRAM_group
    output reg                                                       o_AttnRam_Done         , 
    output reg  [11 : 0]                                             o_AttnRam_rd_addr      ,
    input                                                            i_AttnRAM_Empty        ,
    input       [$clog2(2*`SYSTOLIC_UNIT_NUM)*`TIME_STEPS - 1 : 0]   i_AttnRAM_data         , // delay 1 clk
    // interact with ValueRAM   
    output reg  [9 : 0]                                              o_ValueRam_rdaddr      ,
    input       [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]           i_ValueRam_out         ,  // delay 1 clk
    // spikesdata-out
    output wire [`PATCH_EMBED_WIDTH*2 - 1 : 0]                       o_attn_v_spikes_data   ,
    output wire                                                      o_attn_v_spikes_valid  ,
    output reg                                                       o_attn_v_spikes_done=0     
);

localparam  S_IDLE       =   0 ,
            S_READ_DATA  =   1 ,
            S_FETCH_DATA =   2 ;

// --- wire ---
wire [`TIME_STEPS - 1 : 0]                                              w_spikes_out          ; 
wire [`TIME_STEPS*2 - 1 : 0]                                            w_spikes_out_ext      ; 
wire                                                                    w_spikes_valid        ;
wire [47 : 0]                                                           w_rdfifo_data   [`FINAL_FMAPS_CHNNLS / `MULTI_HEAD_NUMS - 1 : 0]     ;

// --- reg ---
reg  [2 : 0]                                                s_curr_state         ;
reg  [2 : 0]                                                s_next_state         ;
reg                                                         r_read_data_valid=0  ;
reg                                                         r_rd_data_valid_d0=0 ;
reg                                                         r_rd_data_valid_d1=0 ;
reg  [9 : 0]                                                r_InitAddr           ;
reg  [9 : 0]                                                r_ValueRam_baseaddr  ;

reg  [$clog2(2*`SYSTOLIC_UNIT_NUM)*`TIME_STEPS - 1 : 0]     r_AttnRAM_data       ;     
reg  [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]             r_ValueRam_out       ;
reg  [$clog2(`SYSTOLIC_UNIT_NUM) + 1 : 0]                   r_ValueRam_Cnt       ;
reg                                                         r_FinishLine_pre0=0  ;
reg                                                         r_FinishLine_pre1=0  ;
reg                                                         r_FinishLine=0       ;
reg  [`FINAL_FMAPS_CHNNLS / `MULTI_HEAD_NUMS - 1 : 0]       r_rdfifo_valid       ;
reg  [$clog2(`FINAL_FMAPS_WIDTH) - 1 : 0]                   r_rdfifo_Cnt         ;
reg                                                         r_AttnRam_Done_d0    ;
reg                                                         r_AttnRam_Done_d1    ;
reg                                                         r_AttnRam_Done_d2    ;
reg                                                         r_AttnRam_Done_d3    ;
reg  [47 : 0]                                               r4lif_rdfifo_data='d0; 
reg  [15 : 0]                                               r_lif_attnv_cnt      ;

// --------------- state --------------- \\ 
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        s_curr_state <= S_IDLE;
    else
        s_curr_state <= s_next_state;
end

// --------------- Basic logic --------------- \\ 
// r_FinishLine_pre0
always@(posedge s_clk) begin
    r_FinishLine_pre1 <= r_FinishLine_pre0;
    r_FinishLine      <= r_FinishLine_pre1;

    if (o_AttnRam_rd_addr[$clog2(`SYSTOLIC_UNIT_NUM) + 1 : 0] == 6'b111_111)
        r_FinishLine_pre0 <= 1'b1;
    else 
        r_FinishLine_pre0 <= 1'b0;
end

// r_read_data_valid
always@(posedge s_clk) begin
    r_AttnRAM_data <= i_AttnRAM_data;
    r_ValueRam_out <= i_ValueRam_out;

    r_rd_data_valid_d0 <= r_read_data_valid  ;
    r_rd_data_valid_d1 <= r_rd_data_valid_d0 ;

    if (s_curr_state == S_READ_DATA)
        r_read_data_valid <= 1'b1;
    else
        r_read_data_valid <= 1'b0;
end

// r_InitAddr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_InitAddr <= 'd0;
    else if (r_read_data_valid && o_AttnRam_rd_addr[$clog2(`SYSTOLIC_UNIT_NUM) + 1 : 0] == 6'b11_0100 && r_ValueRam_Cnt == 6'b11_1111)
        r_InitAddr <= r_InitAddr + 'd16;
end

// ---- read fifo data ----
// r_rdfifo_Cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) 
        r_rdfifo_Cnt <= 'd0 ;
    else if (| r_rdfifo_valid) 
        r_rdfifo_Cnt <= r_rdfifo_Cnt + 1'b1;
end

// r_rdfifo_valid
genvar ii;
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst || r_rdfifo_Cnt == `FINAL_FMAPS_WIDTH - 1) 
        r_rdfifo_valid[0] <= 1'b0;
    else if (s_curr_state == S_FETCH_DATA && r_AttnRam_Done_d3) 
        r_rdfifo_valid[0] <= 1'b1;
end

generate 
    for (ii = 1; ii < `FINAL_FMAPS_CHNNLS / `MULTI_HEAD_NUMS; ii = ii + 1) begin

        always@(posedge s_clk, posedge s_rst) begin
            if (s_rst) 
                r_rdfifo_valid[ii] <= 1'b0;
            else if (r_rdfifo_Cnt == `FINAL_FMAPS_WIDTH - 1)
                r_rdfifo_valid[ii] <= r_rdfifo_valid[ii - 1];
        end
    
    end
endgenerate

// --------------- READ AttnRAM DATA --------------- \\ 
// o_AttnRam_rd_addr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        o_AttnRam_rd_addr <= 'd0;
    else if (r_read_data_valid)
        o_AttnRam_rd_addr <= o_AttnRam_rd_addr + 1'b1;
end

// o_AttnRam_Done
always@(posedge s_clk) begin
    r_AttnRam_Done_d0 <= o_AttnRam_Done   ;
    r_AttnRam_Done_d1 <= r_AttnRam_Done_d0;
    r_AttnRam_Done_d2 <= r_AttnRam_Done_d1;
    r_AttnRam_Done_d3 <= r_AttnRam_Done_d2;

    if (o_AttnRam_rd_addr == `FINAL_FMAPS_WIDTH * `FINAL_FMAPS_WIDTH - 2) // 4096 - 2
        o_AttnRam_Done <= 1'b1;
    else 
        o_AttnRam_Done <= 1'b0;
end

// --------------- READ ValueRam DATA --------------- \\ 
// o_ValueRam_rdaddr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        o_ValueRam_rdaddr <= 'd0;
    else if (r_read_data_valid && o_AttnRam_rd_addr[$clog2(`SYSTOLIC_UNIT_NUM) + 1 : 0] == 6'b111_111 && r_ValueRam_Cnt[3 : 0] == 4'hF)
        o_ValueRam_rdaddr <= r_ValueRam_baseaddr; 
    else if (r_read_data_valid && o_AttnRam_rd_addr[$clog2(`SYSTOLIC_UNIT_NUM) + 1 : 0] == 6'b111_111)
        o_ValueRam_rdaddr <= o_ValueRam_rdaddr + 1'b1;
end

// r_ValueRam_baseaddr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_ValueRam_baseaddr <= 'd0;
    else if (r_read_data_valid && o_AttnRam_rd_addr[$clog2(`SYSTOLIC_UNIT_NUM) + 1 : 0] == 6'b11_0111 && r_ValueRam_Cnt == 6'b11_1111)
        r_ValueRam_baseaddr <= r_InitAddr;
    else if (r_read_data_valid && o_AttnRam_rd_addr[$clog2(`SYSTOLIC_UNIT_NUM) + 1 : 0] == 6'b111_111 && r_ValueRam_Cnt[3 : 0] == 4'b0111)
        r_ValueRam_baseaddr <= r_ValueRam_baseaddr + `MULTI_HEAD_NUMS*`SYSTOLIC_UNIT_NUM;
end

// r_ValueRam_Cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_ValueRam_Cnt <= 'd0;
    else if (r_read_data_valid && o_AttnRam_rd_addr[$clog2(`SYSTOLIC_UNIT_NUM) + 1 : 0] == 6'b111_111)
        r_ValueRam_Cnt <= r_ValueRam_Cnt + 1'b1;
end

// --------------- LineMac-PE-Group --------------- \\
genvar k, ee;
generate 
    for (k = 0; k < `FINAL_FMAPS_CHNNLS / `MULTI_HEAD_NUMS; k = k + 1) begin : MtrxCalc_Attn_V
        LineMac_PE u_LineMac_PE(
            .s_clk                 ( s_clk                                                       ),
            .s_rst                 ( s_rst                                                       ),

            .i_FirstLine_done      ( r_FinishLine                                                ),
            .i_Finish_once         ( r_AttnRam_Done_d2                                           ),

            .i_SendData_valid      ( r_rd_data_valid_d1                                          ),
            .i_ValueSpikes         ( r_ValueRam_out[`TIME_STEPS * (k + 1) - 1 : `TIME_STEPS * k] ),
            .i_AttnRAM_data        ( r_AttnRAM_data                                              ),
            
            .i_finalMacData_valid  ( r_rdfifo_valid[k]                                           ),
            .o_finalMacData_out    ( w_rdfifo_data[k]                                            )
        );

    end
endgenerate

integer d;
always@(*) begin
    for (d = 0; d < `FINAL_FMAPS_CHNNLS / `MULTI_HEAD_NUMS; d = d + 1) begin
        if (r_rdfifo_valid[d])
            r4lif_rdfifo_data <= w_rdfifo_data[d];
    end
end

LIF_group #(
    .PSUM_WIDTH            ( 48                                                          )
) u_LIF_group(
    .s_clk                 ( s_clk                                                       ),
    .s_rst                 ( s_rst                                                       ),
    .i_lif_thrd            ( `QK_SCALE / 2                                               ),

    .i_PsumValid           ( |r_rdfifo_valid                                             ),
    .i_PsumData            ( r4lif_rdfifo_data                                           ),
    .o_spikes_out          ( w_spikes_out                                                ),
    .o_spikes_valid        ( w_spikes_valid                                              )
);

generate
    for (ee = 0; ee < `TIME_STEPS; ee = ee + 1) begin
        assign w_spikes_out_ext[2*(ee+1) - 1 : 2*ee] = {1'b0, w_spikes_out[ee]};
    end
endgenerate

attn_v_spikes_reshaping u_attn_v_spikes_reshaping(
    .s_clk                      ( s_clk                     ),
    .s_rst                      ( s_rst                     ),

    .i_spikes_out_ext           ( w_spikes_out_ext          ),
    .i_spikes_valid             ( w_spikes_valid            ),

    .o_attn_v_spikes_data       ( o_attn_v_spikes_data      ),
    .o_attn_v_spikes_valid      ( o_attn_v_spikes_valid     )
);

// r_lif_attnv_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_lif_attnv_cnt <= 'd0;
    else if (o_attn_v_spikes_done)
        r_lif_attnv_cnt <= 'd0;
    else if (o_attn_v_spikes_valid)
        r_lif_attnv_cnt <= r_lif_attnv_cnt + 1'b1;
end

// o_attn_v_spikes_done
always@(posedge s_clk) begin
    if (r_lif_attnv_cnt == 'd3070)
        o_attn_v_spikes_done <= 1'b1;
    else
        o_attn_v_spikes_done <= 1'b0;
end

// --------------- Finite-State-Machine --------------- \\
always@(*) begin

    case(s_curr_state)
        S_IDLE:             s_next_state = i_AttnRAM_Empty ? S_IDLE : S_READ_DATA;
        S_READ_DATA:        s_next_state = (o_AttnRam_rd_addr == `FINAL_FMAPS_WIDTH * `FINAL_FMAPS_WIDTH - 2) ? S_FETCH_DATA : S_READ_DATA;
        S_FETCH_DATA:       s_next_state = (r_rdfifo_Cnt == `FINAL_FMAPS_WIDTH - 1 && r_rdfifo_valid[`FINAL_FMAPS_CHNNLS / `MULTI_HEAD_NUMS - 1]) 
                                           ? S_IDLE : S_FETCH_DATA;
        default:            s_next_state = S_IDLE;
    endcase

end

endmodule // MM_Calculator
