/*
    --- Accumulate one line + LineBuffer --- 
    Author   : Toddler. 
    Email    : 23011211185@stu.xidian.edu.cn
    Encoder  : UTF-8
*/

`include "E:/Desktop/spiking_transformer/spiking_transformer/spiking_transformer.srcs/sources_1/imports/FPGA_SpikingTransformer/hyper_para.v"
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
wire                                                              w_fifo_full            ;
wire                                                              w_fifo_empty           ;
wire [$clog2(2*`SYSTOLIC_UNIT_NUM)*`TIME_STEPS - 1 : 0]           w_ValueSpikes_ext      ;
wire [$clog2(2*`SYSTOLIC_UNIT_NUM)*`TIME_STEPS - 1 : 0]           w_Tmp_fifoin_Result    ;
wire [47 : 0]                                                     w_fifoout_data         ;

wire [12 - 1 : 0]                                                 w_MM_PsumData_T0       ;
wire [12 - 1 : 0]                                                 w_MM_PsumData_T1       ;
wire [12 - 1 : 0]                                                 w_MM_PsumData_T2       ;
wire [12 - 1 : 0]                                                 w_MM_PsumData_T3       ;

// -- reg
reg  [$clog2(2*`SYSTOLIC_UNIT_NUM)*`TIME_STEPS - 1 : 0]           r_Tmp_fifoin_Result=0  ;
reg  [48 - 1 : 0]                                                 r_Tmp_fifoin_Rslt_d0=0 ;
reg                                                               r_SendData_valid       ;
reg                                                               r_SendData_valid_d0    ;
reg                                                               r_MMfifo_PsumFlag      ;

// ------------------ Main Code ------------------ \\
assign o_finalMacData_out     =    w_fifoout_data ;
assign w_ValueSpikes_ext      =    { {($clog2(2*`SYSTOLIC_UNIT_NUM)){i_ValueSpikes[3]}} 
                                   , {($clog2(2*`SYSTOLIC_UNIT_NUM)){i_ValueSpikes[2]}}
                                   , {($clog2(2*`SYSTOLIC_UNIT_NUM)){i_ValueSpikes[1]}}
                                   , {($clog2(2*`SYSTOLIC_UNIT_NUM)){i_ValueSpikes[0]}}};

assign w_Tmp_fifoin_Result    =    w_ValueSpikes_ext & i_AttnRAM_data ;

assign w_MM_PsumData_T0       =    r_MMfifo_PsumFlag ? 
                                   r_Tmp_fifoin_Result[$clog2(2*`SYSTOLIC_UNIT_NUM)*1 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*0] 
                                 + w_fifoout_data[12*1 - 1 : 12*0] 
                                 : r_Tmp_fifoin_Result[$clog2(2*`SYSTOLIC_UNIT_NUM)*1 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*0] ;
assign w_MM_PsumData_T1       =    r_MMfifo_PsumFlag ? 
                                   r_Tmp_fifoin_Result[$clog2(2*`SYSTOLIC_UNIT_NUM)*2 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*1] 
                                 + w_fifoout_data[12*2 - 1 : 12*1]
                                 : r_Tmp_fifoin_Result[$clog2(2*`SYSTOLIC_UNIT_NUM)*2 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*1] ;
assign w_MM_PsumData_T2       =    r_MMfifo_PsumFlag ? 
                                   r_Tmp_fifoin_Result[$clog2(2*`SYSTOLIC_UNIT_NUM)*3 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*2] 
                                 + w_fifoout_data[12*3 - 1 : 12*2] 
                                 : r_Tmp_fifoin_Result[$clog2(2*`SYSTOLIC_UNIT_NUM)*3 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*2] ;
assign w_MM_PsumData_T3       =    r_MMfifo_PsumFlag ? 
                                   r_Tmp_fifoin_Result[$clog2(2*`SYSTOLIC_UNIT_NUM)*4 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*3] 
                                 + w_fifoout_data[12*4 - 1 : 12*3] 
                                 : r_Tmp_fifoin_Result[$clog2(2*`SYSTOLIC_UNIT_NUM)*4 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*3] ;

// --->>> start debug dot
wire [12 - 1 : 0]   w_debug_Data_T0 ;
wire [12 - 1 : 0]   w_debug_Data_T1 ;
wire [12 - 1 : 0]   w_debug_Data_T2 ;
wire [12 - 1 : 0]   w_debug_Data_T3 ;

wire [5 - 1 : 0]   w_debug_inin_T0 ;
wire [5 - 1 : 0]   w_debug_inin_T1 ;
wire [5 - 1 : 0]   w_debug_inin_T2 ;
wire [5 - 1 : 0]   w_debug_inin_T3 ;

wire [12 - 1 : 0]   w_debug_fifoin_T0 ;
wire [12 - 1 : 0]   w_debug_fifoin_T1 ;
wire [12 - 1 : 0]   w_debug_fifoin_T2 ;
wire [12 - 1 : 0]   w_debug_fifoin_T3 ;

assign w_debug_inin_T0 = r_Tmp_fifoin_Result[$clog2(2*`SYSTOLIC_UNIT_NUM)*1 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*0];
assign w_debug_inin_T1 = r_Tmp_fifoin_Result[$clog2(2*`SYSTOLIC_UNIT_NUM)*2 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*1];
assign w_debug_inin_T2 = r_Tmp_fifoin_Result[$clog2(2*`SYSTOLIC_UNIT_NUM)*3 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*2];
assign w_debug_inin_T3 = r_Tmp_fifoin_Result[$clog2(2*`SYSTOLIC_UNIT_NUM)*4 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM)*3];

assign w_debug_Data_T0 = w_fifoout_data[12*1 - 1 : 12*0];
assign w_debug_Data_T1 = w_fifoout_data[12*2 - 1 : 12*1];
assign w_debug_Data_T2 = w_fifoout_data[12*3 - 1 : 12*2];
assign w_debug_Data_T3 = w_fifoout_data[12*4 - 1 : 12*3];

assign w_debug_fifoin_T0 = r_Tmp_fifoin_Rslt_d0[12*1 - 1 : 12*0];
assign w_debug_fifoin_T1 = r_Tmp_fifoin_Rslt_d0[12*2 - 1 : 12*1];
assign w_debug_fifoin_T2 = r_Tmp_fifoin_Rslt_d0[12*3 - 1 : 12*2];
assign w_debug_fifoin_T3 = r_Tmp_fifoin_Rslt_d0[12*4 - 1 : 12*3];

reg [5 : 0]         r_debug_cnt=0;
always@(posedge s_clk) begin
    if (i_SendData_valid)
        r_debug_cnt <= r_debug_cnt + 1'b1;
    else
        r_debug_cnt <= r_debug_cnt; 
end
// end debug dot <<<---

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
    if (s_rst || i_Finish_once)
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


