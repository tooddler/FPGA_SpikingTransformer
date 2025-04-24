/*
    --- Accumulate one line + LineBuffer --- 
    Author   : Toddler. 
    Email    : 23011211185@stu.xidian.edu.cn
    Encoder  : UTF-8
*/

`include "../../hyper_para.v"
module LineMac_PE (
    input                                                             s_clk                ,
    input                                                             s_rst                , 
    input                                                             i_FirstLine_done     ,
    input                                                             i_Finish_once        ,
    // data-in
    input                                                             i_SendData_valid     ,
    input       [`TIME_STEPS - 1 : 0]                                 i_ValueSpikes        ,
    input       [$clog2(2*`SYSTOLIC_UNIT_NUM)*`TIME_STEPS - 1 : 0]    i_AttnRAM_data       ,
    // Multi result
    input                                                             i_finalMacData_valid ,
    output wire [48 - 1 : 0]                                          o_finalMacData_out   
);

// -- wire
wire                                                              w_fifo_full          ;
wire                                                              w_fifo_empty         ;
wire [$clog2(2*`SYSTOLIC_UNIT_NUM)*`TIME_STEPS - 1 : 0]           w_ValueSpikes_ext    ;
wire [$clog2(2*`SYSTOLIC_UNIT_NUM)*`TIME_STEPS - 1 : 0]           w_Tmp_fifoin_Result  ;
wire [47 : 0]                                                     w_fifoout_data       ;

wire signed [12 - 1 : 0]                                          w_MM_PsumData_T0     ;
wire signed [12 - 1 : 0]                                          w_MM_PsumData_T1     ;
wire signed [12 - 1 : 0]                                          w_MM_PsumData_T2     ;
wire signed [12 - 1 : 0]                                          w_MM_PsumData_T3     ;

// -- reg
reg  [$clog2(2*`SYSTOLIC_UNIT_NUM)*`TIME_STEPS - 1 : 0]           r_Tmp_fifoin_Result  ;
reg  [48 - 1 : 0]                                                 r_Tmp_fifoin_Rslt_d0 ;
reg                                                               r_SendData_valid     ;
reg                                                               r_SendData_valid_d0  ;
reg                                                               r_MMfifo_PsumFlag    ;

// ------------------ Main Code ------------------ \\
assign o_finalMacData_out     =    w_fifoout_data ;
assign w_ValueSpikes_ext      =    { {($clog2(2*`SYSTOLIC_UNIT_NUM)){i_ValueSpikes[3]}} 
                                   , {($clog2(2*`SYSTOLIC_UNIT_NUM)){i_ValueSpikes[2]}}
                                   , {($clog2(2*`SYSTOLIC_UNIT_NUM)){i_ValueSpikes[1]}}
                                   , {($clog2(2*`SYSTOLIC_UNIT_NUM)){i_ValueSpikes[0]}}};

assign w_Tmp_fifoin_Result    =    w_ValueSpikes_ext & i_AttnRAM_data ;

assign w_MM_PsumData_T0       =    r_MMfifo_PsumFlag ? 
                                   $signed(r_Tmp_fifoin_Result[$clog2(2*`SYSTOLIC_UNIT_NUM)*1 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*0]) 
                                 + $signed(w_fifoout_data[$clog2(2*`SYSTOLIC_UNIT_NUM)*1 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*0]) 
                                 : $signed(r_Tmp_fifoin_Result[$clog2(2*`SYSTOLIC_UNIT_NUM)*1 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*0]) ;
assign w_MM_PsumData_T1       =    r_MMfifo_PsumFlag ? 
                                   $signed(r_Tmp_fifoin_Result[$clog2(2*`SYSTOLIC_UNIT_NUM)*2 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*1]) 
                                 + $signed(w_fifoout_data[$clog2(2*`SYSTOLIC_UNIT_NUM)*2 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*1]) 
                                 : $signed(r_Tmp_fifoin_Result[$clog2(2*`SYSTOLIC_UNIT_NUM)*2 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*1]) ;
assign w_MM_PsumData_T2       =    r_MMfifo_PsumFlag ? 
                                   $signed(r_Tmp_fifoin_Result[$clog2(2*`SYSTOLIC_UNIT_NUM)*3 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*2]) 
                                 + $signed(w_fifoout_data[$clog2(2*`SYSTOLIC_UNIT_NUM)*3 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*2]) 
                                 : $signed(r_Tmp_fifoin_Result[$clog2(2*`SYSTOLIC_UNIT_NUM)*3 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*2]) ;
assign w_MM_PsumData_T3       =    r_MMfifo_PsumFlag ? 
                                   $signed(r_Tmp_fifoin_Result[$clog2(2*`SYSTOLIC_UNIT_NUM)*4 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*3]) 
                                 + $signed(w_fifoout_data[$clog2(2*`SYSTOLIC_UNIT_NUM)*4 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*3]) 
                                 : $signed(r_Tmp_fifoin_Result[$clog2(2*`SYSTOLIC_UNIT_NUM)*4 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*3]) ;

always@(posedge s_clk) begin
    r_SendData_valid    <= i_SendData_valid ;
    r_SendData_valid_d0 <= r_SendData_valid ;
    r_Tmp_fifoin_Rslt_d0 <= {w_MM_PsumData_T3, w_MM_PsumData_T2, w_MM_PsumData_T1, w_MM_PsumData_T0};

    if (i_SendData_valid)
        r_Tmp_fifoin_Result <= w_Tmp_fifoin_Result;
    else 
        r_Tmp_fifoin_Result <= r_Tmp_fifoin_Result;
end

// r_MMfifo_PsumFlag
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst || i_Finish_once) //TODO: FIFO 读空的时候，表示完成一次矩阵乘，开始下一次
        r_MMfifo_PsumFlag <= 1'b0;
    else if (i_FirstLine_done)
        r_MMfifo_PsumFlag <= 1'b1;
end

// ------------------ Line Buffer ------------------ \\
MM_Calc_FIFO u_MM_Calc_FIFO (
    .clk            ( s_clk                                                          ),
    .srst           ( s_rst                                                          ),
    .din            ( r_Tmp_fifoin_Rslt_d0                                           ), // [47 : 0] din
    .wr_en          ( r_SendData_valid_d0                                            ),  
    .rd_en          ( (r_SendData_valid & r_MMfifo_PsumFlag) || i_finalMacData_valid ),  
    .dout           ( w_fifoout_data                                                 ), // [47 : 0] dout
    .full           ( w_fifo_full                                                    ), 
    .empty          ( w_fifo_empty                                                   )  
);

endmodule // LineMac_PE
