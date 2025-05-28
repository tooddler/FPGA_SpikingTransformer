/*
    --- simple systolic pe unit --- 
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
    FUNC    : Din[1:0] * Weight[7:0] + Psum[19:0]
    ps      : DSP - free
*/

`include "E:/Desktop/spiking_transformer/spiking_transformer/spiking_transformer.srcs/sources_1/imports/FPGA_SpikingTransformer/hyper_para.v"
module Systolic_pe (
    input                                                    s_clk               ,
    input                                                    s_rst               ,    
    // B Matrix Data Slices as Weights
    input                                                    weight_LoadPtr      , // 1 : r_weight_T0_tmp1 / 0 : r_weight_T0_tmp0
    input                                                    weight_CalcPtr      ,
    input                                                    weight_valid        ,
    input       [`SYSTOLIC_WEIGHT_WIDTH - 1 : 0]             weights             ,
    // A Matrix data-in
    input                                                    in_data_valid       ,
    input       [`SYSTOLIC_DATA_WIDTH - 1 : 0]               in_raw_data         ,
    // A Matrix data-in -> right-out
    output reg                                               out_data_valid=0    ,
    output reg  [`SYSTOLIC_DATA_WIDTH - 1 : 0]               out_raw_data='d0    ,
    // psum-in
    input       [`SYSTOLIC_PSUM_WIDTH - 1 : 0]               in_psum_data        ,
    // psum-out  -- delay 2 clk -- 
    output reg                                               out_psum_valid=0    ,
    output reg  [`SYSTOLIC_PSUM_WIDTH - 1 : 0]               out_psum_data       
);

wire signed [`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS - 1 : 0]     w_psum_data_T0      ;
wire signed [`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS - 1 : 0]     w_psum_data_T1      ;
wire signed [`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS - 1 : 0]     w_psum_data_T2      ;
wire signed [`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS - 1 : 0]     w_psum_data_T3      ;

wire signed [7:0]                                            w_weight_T0         ;
wire signed [7:0]                                            w_weight_T1         ;
wire signed [7:0]                                            w_weight_T2         ;
wire signed [7:0]                                            w_weight_T3         ;

reg  signed [`SYSTOLIC_WEIGHT_WIDTH + 1 : 0]                 r_multidata_T0='d0  ;
reg  signed [`SYSTOLIC_WEIGHT_WIDTH + 1 : 0]                 r_multidata_T1='d0  ;
reg  signed [`SYSTOLIC_WEIGHT_WIDTH + 1 : 0]                 r_multidata_T2='d0  ;
reg  signed [`SYSTOLIC_WEIGHT_WIDTH + 1 : 0]                 r_multidata_T3='d0  ;

reg  signed [7:0]                                            r_weight_T0_tmp0    ;
reg  signed [7:0]                                            r_weight_T1_tmp0    ;
reg  signed [7:0]                                            r_weight_T2_tmp0    ;
reg  signed [7:0]                                            r_weight_T3_tmp0    ;

reg  signed [7:0]                                            r_weight_T0_tmp1    ; // pingpong
reg  signed [7:0]                                            r_weight_T1_tmp1    ;
reg  signed [7:0]                                            r_weight_T2_tmp1    ;
reg  signed [7:0]                                            r_weight_T3_tmp1    ;

assign w_psum_data_T0 = $signed(in_psum_data[(`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*1 - 1 : (`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*0]) + $signed(r_multidata_T0);
assign w_psum_data_T1 = $signed(in_psum_data[(`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*2 - 1 : (`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*1]) + $signed(r_multidata_T1);
assign w_psum_data_T2 = $signed(in_psum_data[(`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*3 - 1 : (`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*2]) + $signed(r_multidata_T2);
assign w_psum_data_T3 = $signed(in_psum_data[(`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*4 - 1 : (`SYSTOLIC_PSUM_WIDTH / `TIME_STEPS)*3]) + $signed(r_multidata_T3);

assign w_weight_T0    = weight_CalcPtr ? r_weight_T0_tmp1 : r_weight_T0_tmp0;
assign w_weight_T1    = weight_CalcPtr ? r_weight_T1_tmp1 : r_weight_T1_tmp0;
assign w_weight_T2    = weight_CalcPtr ? r_weight_T2_tmp1 : r_weight_T2_tmp0;
assign w_weight_T3    = weight_CalcPtr ? r_weight_T3_tmp1 : r_weight_T3_tmp0;

// r_weight_T_tmp0
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) begin
        r_weight_T0_tmp0 <= 'd0;
        r_weight_T1_tmp0 <= 'd0;
        r_weight_T2_tmp0 <= 'd0;
        r_weight_T3_tmp0 <= 'd0;
    end
    else if (~weight_LoadPtr && weight_valid) begin
        r_weight_T0_tmp0 <= weights[7:0];
        r_weight_T1_tmp0 <= weights[7:0];
        r_weight_T2_tmp0 <= weights[7:0];
        r_weight_T3_tmp0 <= weights[7:0];
    end
end

// r_weight_T_tmp1
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) begin
        r_weight_T0_tmp1 <= 'd0;
        r_weight_T1_tmp1 <= 'd0;
        r_weight_T2_tmp1 <= 'd0;
        r_weight_T3_tmp1 <= 'd0;
    end
    else if (weight_LoadPtr && weight_valid) begin
        r_weight_T0_tmp1 <= weights[7:0];
        r_weight_T1_tmp1 <= weights[7:0];
        r_weight_T2_tmp1 <= weights[7:0];
        r_weight_T3_tmp1 <= weights[7:0];
    end
end

//out_data_valid out_raw_data  
always@(posedge s_clk) begin
    out_data_valid <= in_data_valid ;
    out_raw_data   <= in_raw_data ;
end

// out_psum_data
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        out_psum_data <= 'd0;
    else if (out_data_valid)
        out_psum_data <= {w_psum_data_T3, w_psum_data_T2, w_psum_data_T1, w_psum_data_T0}; 
end

// out_psum_valid
always@(posedge s_clk) begin
    out_psum_valid <= out_data_valid;
end

// ---- as multiplier unit ---- \\
// SYSTOLIC_DATA_WIDTH == 2
// r_multidata_T0
always@(posedge s_clk) begin
    if (in_data_valid)
        case(in_raw_data[1:0])
            'd0:        r_multidata_T0 <= 'd0;
            'd1:        r_multidata_T0 <= w_weight_T0;
            'd2:        r_multidata_T0 <= w_weight_T0 <<< 1;
            'd3:        r_multidata_T0 <= $signed({w_weight_T0, 1'b0}) + $signed({{2{w_weight_T0[`SYSTOLIC_WEIGHT_WIDTH - 1]}}, w_weight_T0});// $signed(w_weight_T0 <<< 1) + $signed(w_weight_T0);
            default:    r_multidata_T0 <= r_multidata_T0;
        endcase
    else
        r_multidata_T0 <= r_multidata_T0;
end

// r_multidata_T1
always@(posedge s_clk) begin
    if (in_data_valid)
        case(in_raw_data[3:2])
            'd0:        r_multidata_T1 <= 'd0;
            'd1:        r_multidata_T1 <= w_weight_T1;
            'd2:        r_multidata_T1 <= w_weight_T1 <<< 1;
            'd3:        r_multidata_T1 <= $signed({w_weight_T1, 1'b0}) + $signed({{2{w_weight_T1[`SYSTOLIC_WEIGHT_WIDTH - 1]}}, w_weight_T1});
            default:    r_multidata_T1 <= r_multidata_T1;
        endcase
    else
        r_multidata_T1 <= r_multidata_T1;
end

// r_multidata_T2
always@(posedge s_clk) begin
    if (in_data_valid)
        case(in_raw_data[5:4])
            'd0:        r_multidata_T2 <= 'd0;
            'd1:        r_multidata_T2 <= w_weight_T2;
            'd2:        r_multidata_T2 <= w_weight_T2 <<< 1;
            'd3:        r_multidata_T2 <= $signed({w_weight_T2, 1'b0}) + $signed({{2{w_weight_T2[`SYSTOLIC_WEIGHT_WIDTH - 1]}}, w_weight_T2});
            default:    r_multidata_T2 <= r_multidata_T2;
        endcase
    else
        r_multidata_T2 <= r_multidata_T2;
end

// r_multidata_T3
always@(posedge s_clk) begin
    if (in_data_valid)
        case(in_raw_data[7:6])
            'd0:        r_multidata_T3 <= 'd0;
            'd1:        r_multidata_T3 <= w_weight_T3;
            'd2:        r_multidata_T3 <= w_weight_T3 <<< 1;
            'd3:        r_multidata_T3 <= $signed({w_weight_T3, 1'b0}) + $signed({{2{w_weight_T3[`SYSTOLIC_WEIGHT_WIDTH - 1]}}, w_weight_T3});
            default:    r_multidata_T3 <= r_multidata_T3;
        endcase
    else
        r_multidata_T3 <= r_multidata_T3;
end

endmodule // Systolic_pe


