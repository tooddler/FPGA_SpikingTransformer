/*
    --- simple eyeriss pe unit --- 
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "E:/Desktop/Zynq_Spikformer/Zynq_Spikformer.srcs/sources_1/hyper_para.v"
module simple_eyeriss_pe_unit (
    input                                                 s_clk               ,
    input                                                 s_rst               ,
    // row weight get
    input                                                 i_weight_valid      ,
    input  [`QUAN_BITS*`ERS_PE_SIZE - 1 : 0]              i_weights           ,
    // line spikes with timestep = `TIME_STEPS
    input                                                 i_spikes_valid      ,
    input  [`IMG_WIDTH*`TIME_STEPS - 1 : 0]               i_spikes            ,
    // run flag -> high valid
    input                                                 i_cal_start         ,
    // - out : data_valid -> i_cal_start - 
    output wire [`QUAN_BITS + 1 : 0]                      o_psum_out_t0       ,
    output wire [`QUAN_BITS + 1 : 0]                      o_psum_out_t1       ,         
    output wire [`QUAN_BITS + 1 : 0]                      o_psum_out_t2       ,         
    output wire [`QUAN_BITS + 1 : 0]                      o_psum_out_t3                
);

wire        [`TIME_STEPS * 3 - 1 : 0]                   w_cal_data      ;
wire signed [`QUAN_BITS - 1 : 0]                        w_cal_tmp00     ;
wire signed [`QUAN_BITS - 1 : 0]                        w_cal_tmp01     ;
wire signed [`QUAN_BITS - 1 : 0]                        w_cal_tmp02     ;
wire signed [`QUAN_BITS - 1 : 0]                        w_cal_tmp10     ;
wire signed [`QUAN_BITS - 1 : 0]                        w_cal_tmp11     ;
wire signed [`QUAN_BITS - 1 : 0]                        w_cal_tmp12     ;
wire signed [`QUAN_BITS - 1 : 0]                        w_cal_tmp20     ;
wire signed [`QUAN_BITS - 1 : 0]                        w_cal_tmp21     ;
wire signed [`QUAN_BITS - 1 : 0]                        w_cal_tmp22     ;
wire signed [`QUAN_BITS - 1 : 0]                        w_cal_tmp30     ;
wire signed [`QUAN_BITS - 1 : 0]                        w_cal_tmp31     ;
wire signed [`QUAN_BITS - 1 : 0]                        w_cal_tmp32     ;

reg                                                     r_weight_valid  ;

reg  signed [`QUAN_BITS - 1 : 0]                        r_weight00      ;
reg  signed [`QUAN_BITS - 1 : 0]                        r_weight01      ;
reg  signed [`QUAN_BITS - 1 : 0]                        r_weight02      ;
reg         [`TIME_STEPS*(`IMG_WIDTH + 1) - 1 : 0]      r_spikes        ;  // padding!

reg  signed [`QUAN_BITS + 1 : 0]                        r_sum_timestep0 ;
reg  signed [`QUAN_BITS + 1 : 0]                        r_sum_timestep1 ;
reg  signed [`QUAN_BITS + 1 : 0]                        r_sum_timestep2 ;
reg  signed [`QUAN_BITS + 1 : 0]                        r_sum_timestep3 ;

assign w_cal_data     =    r_spikes[`TIME_STEPS * `ERS_PE_SIZE - 1 : 0]     ;

assign w_cal_tmp00    =    w_cal_data[0 + `TIME_STEPS*0] ? r_weight00 : 'd0 ;
assign w_cal_tmp10    =    w_cal_data[1 + `TIME_STEPS*0] ? r_weight00 : 'd0 ;
assign w_cal_tmp20    =    w_cal_data[2 + `TIME_STEPS*0] ? r_weight00 : 'd0 ;
assign w_cal_tmp30    =    w_cal_data[3 + `TIME_STEPS*0] ? r_weight00 : 'd0 ;

assign w_cal_tmp01    =    w_cal_data[0 + `TIME_STEPS*1] ? r_weight01 : 'd0 ;
assign w_cal_tmp11    =    w_cal_data[1 + `TIME_STEPS*1] ? r_weight01 : 'd0 ;
assign w_cal_tmp21    =    w_cal_data[2 + `TIME_STEPS*1] ? r_weight01 : 'd0 ;
assign w_cal_tmp31    =    w_cal_data[3 + `TIME_STEPS*1] ? r_weight01 : 'd0 ;

assign w_cal_tmp02    =    w_cal_data[0 + `TIME_STEPS*2] ? r_weight02 : 'd0 ;
assign w_cal_tmp12    =    w_cal_data[1 + `TIME_STEPS*2] ? r_weight02 : 'd0 ;
assign w_cal_tmp22    =    w_cal_data[2 + `TIME_STEPS*2] ? r_weight02 : 'd0 ;
assign w_cal_tmp32    =    w_cal_data[3 + `TIME_STEPS*2] ? r_weight02 : 'd0 ;

assign o_psum_out_t0  =    r_sum_timestep0                                  ;
assign o_psum_out_t1  =    r_sum_timestep1                                  ;
assign o_psum_out_t2  =    r_sum_timestep2                                  ;
assign o_psum_out_t3  =    r_sum_timestep3                                  ;

always@(posedge s_clk) begin
    r_weight_valid <= i_weight_valid ;
end

// r_weight
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) begin
        r_weight00 <= 'd0;
        r_weight01 <= 'd0;
        r_weight02 <= 'd0;
    end
    else if (i_weight_valid && ~r_weight_valid) begin
        r_weight00 <= i_weights[`QUAN_BITS*1 - 1 : `QUAN_BITS*0];
        r_weight01 <= i_weights[`QUAN_BITS*2 - 1 : `QUAN_BITS*1];
        r_weight02 <= i_weights[`QUAN_BITS*3 - 1 : `QUAN_BITS*2];
    end
end

// r_spikes
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_spikes <= 'd0;
    else if (i_cal_start)
        r_spikes <= r_spikes >> `TIME_STEPS;
    else if (i_spikes_valid)
        r_spikes <= {i_spikes, {(`TIME_STEPS){1'b0}}};
end

// r_sum_timestep
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) begin
        r_sum_timestep0 <= 'd0;
        r_sum_timestep1 <= 'd0;
        r_sum_timestep2 <= 'd0;
        r_sum_timestep3 <= 'd0;
    end
    else if (i_cal_start) begin
        r_sum_timestep0 <= $signed(w_cal_tmp00) + $signed(w_cal_tmp01) + $signed(w_cal_tmp02);
        r_sum_timestep1 <= $signed(w_cal_tmp10) + $signed(w_cal_tmp11) + $signed(w_cal_tmp12);
        r_sum_timestep2 <= $signed(w_cal_tmp20) + $signed(w_cal_tmp21) + $signed(w_cal_tmp22);
        r_sum_timestep3 <= $signed(w_cal_tmp30) + $signed(w_cal_tmp31) + $signed(w_cal_tmp32);
    end
end

endmodule // simple_eyeriss_pe_unit


