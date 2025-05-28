/*
    --- simple eyeriss array --- 
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "E:/Desktop/spiking_transformer/spiking_transformer/spiking_transformer.srcs/sources_1/imports/FPGA_SpikingTransformer/hyper_para.v"
module simple_eyeriss_array (
    input                                             s_clk               ,
    input                                             s_rst               ,

    input                                             fetch_code_done     ,
    input                                             SPS_part_done       , 
    // -- conv signal
    input                                             code_valid          ,
    input       [15:0]                                conv_in_ch          ,
    input       [15:0]                                conv_out_ch         ,
    input       [15:0]                                conv_img_size       ,
    input       [15:0]                                conv_lif_thrd       ,
    input       [15:0]                                conv_bias_scale     ,
    input                                             conv_or_maxpool     ,
    // -- weight
    input       [`DATA_WIDTH - 1 : 0]                 weight_in           ,
    input                                             weight_valid        ,
    output reg                                        o_weight_ready      ,
    // -- ifmap rows
    input                                             i_spikes_valid      ,
    input       [`IMG_WIDTH*`TIME_STEPS - 1 : 0]      i_spikes            ,
    input                                             i_spikes_done       ,
    output reg                                        o_spikes_ready=0    ,
    // -- get ofmaps
    output wire                                       Array_out_valid     , 
    output wire [`IMG_WIDTH*`TIME_STEPS - 1 : 0]      Array_out_spikes    , 
    output wire                                       Array_out_done      ,
    input                                             Array_out_ready           
);

localparam  S_IDLE              =   0   ,
            S_LOAD_WEIGHTS      =   1   ,
            S_PRE_DATA          =   2   ,
            S_CAL               =   3   ,
            S_DONE              =   4   ,
            S_CHECK_FETCH_DATA  =   5   ;

wire [(`QUAN_BITS + 2)*`ERS_PE_SIZE*`ERS_PE_SIZE - 1 : 0]   w_pe_out_t0      [`ERS_PE_NUM - 1 : 0]   ;
wire [(`QUAN_BITS + 2)*`ERS_PE_SIZE*`ERS_PE_SIZE - 1 : 0]   w_pe_out_t1      [`ERS_PE_NUM - 1 : 0]   ;
wire [(`QUAN_BITS + 2)*`ERS_PE_SIZE*`ERS_PE_SIZE - 1 : 0]   w_pe_out_t2      [`ERS_PE_NUM - 1 : 0]   ;
wire [(`QUAN_BITS + 2)*`ERS_PE_SIZE*`ERS_PE_SIZE - 1 : 0]   w_pe_out_t3      [`ERS_PE_NUM - 1 : 0]   ;

wire [(`QUAN_BITS + 4)*`ERS_PE_NUM - 1 : 0]                 w_addtree_in_t0  [`ERS_PE_SIZE - 1 : 0]  ;
wire [(`QUAN_BITS + 4)*`ERS_PE_NUM - 1 : 0]                 w_addtree_in_t1  [`ERS_PE_SIZE - 1 : 0]  ;
wire [(`QUAN_BITS + 4)*`ERS_PE_NUM - 1 : 0]                 w_addtree_in_t2  [`ERS_PE_SIZE - 1 : 0]  ;
wire [(`QUAN_BITS + 4)*`ERS_PE_NUM - 1 : 0]                 w_addtree_in_t3  [`ERS_PE_SIZE - 1 : 0]  ;

wire [(`QUAN_BITS + 7) - 1 : 0]                             w_addtree_out_t0 [`ERS_PE_SIZE - 1 : 0]  ;
wire [(`QUAN_BITS + 7) - 1 : 0]                             w_addtree_out_t1 [`ERS_PE_SIZE - 1 : 0]  ;
wire [(`QUAN_BITS + 7) - 1 : 0]                             w_addtree_out_t2 [`ERS_PE_SIZE - 1 : 0]  ;
wire [(`QUAN_BITS + 7) - 1 : 0]                             w_addtree_out_t3 [`ERS_PE_SIZE - 1 : 0]  ;

wire [`ERS_MAX_WIDTH * `TIME_STEPS - 1 : 0]                 w_psum_tmpdata_line0                     ; // psum_out
wire [`ERS_MAX_WIDTH * `TIME_STEPS - 1 : 0]                 w_psum_tmpdata_line1                     ;
wire [`ERS_MAX_WIDTH * `TIME_STEPS - 1 : 0]                 w_psum_tmpdata_line2                     ;

wire [`ERS_MAX_WIDTH - 1 : 0]                               w_psum_tmp_line0 [`TIME_STEPS - 1:0]     ;
wire [`ERS_MAX_WIDTH - 1 : 0]                               w_psum_tmp_line1 [`TIME_STEPS - 1:0]     ;
wire [`ERS_MAX_WIDTH - 1 : 0]                               w_psum_tmp_line2 [`TIME_STEPS - 1:0]     ;

wire [`PSUM_RAM_DEPTH - 1 : 0]                              read_1line_addr                          ;
wire                                                        read_1line_req                           ;
wire [`ERS_MAX_WIDTH * `TIME_STEPS - 1 : 0]                 read_1line_data                          ;

wire                                                        w_neg_cal_start                          ;

reg  [15:0]                                                 r_conv_in_ch                             ;
reg  [15:0]                                                 r_conv_out_ch                            ;
reg  [15:0]                                                 r_conv_img_size                          ;
reg                                                         r_conv_or_maxpool                        ;
reg  [15:0]                                                 r_conv_lif_thrd                          ;
reg  [15:0]                                                 r_conv_bias_scale                        ;

reg                                                         read_data_mode                           ;
reg                                                         r_cal_start=0                            ;
reg                                                         r_cal_start_d0=0                         ;
reg                                                         r_cal_start_d1=0                         ;
reg                                                         r_cal_start_d2=0                         ;
reg                                                         r_cal_start_d3=0                         ;
reg                                                         r_cal_start_d4=0                         ;
reg                                                         r_cal_start_d5=0                         ;
reg                                                         r_cal_start_d6=0                         ;
reg  [5:0]                                                  r_cal_cnt                                ;
reg  [9:0]                                                  r_cal_imgsize_cnt                        ;
reg                                                         r_spikes_send_done=0                     ;

reg  [2:0]                                                  s_curr_state                             ;
reg  [2:0]                                                  s_next_state                             ;

reg  [`QUAN_BITS * `ERS_PE_SIZE * `ERS_PE_SIZE - 1 : 0]     r_weight_array                           ;
reg  [`ERS_PE_NUM - 1 : 0]                                  r_weight_valid                           ;
reg  [4:0]                                                  r_weight_cnt                             ;
reg  [`DATA_WIDTH - 1 : 0]                                  r_weight_in_d0                           ;
reg                                                         r_load_weight_done=0                     ;

reg  [9:0]                                                  r_ifmap_cnt                              ;
reg  [`ERS_PE_SIZE*`ERS_PE_SIZE - 1 : 0]                    r_ifmap_valid      [`ERS_PE_NUM - 1 : 0] ;
reg  [`ERS_PE_SIZE*`ERS_PE_SIZE - 1 : 0]                    r_ifmap_valid_d0   [`ERS_PE_NUM - 1 : 0] ;

reg  [(`QUAN_BITS + 4) * `ERS_PE_SIZE - 1 : 0]              r_row_data_t0_line [`ERS_PE_NUM - 1 : 0] ;
reg  [(`QUAN_BITS + 4) * `ERS_PE_SIZE - 1 : 0]              r_row_data_t1_line [`ERS_PE_NUM - 1 : 0] ;
reg  [(`QUAN_BITS + 4) * `ERS_PE_SIZE - 1 : 0]              r_row_data_t2_line [`ERS_PE_NUM - 1 : 0] ;
reg  [(`QUAN_BITS + 4) * `ERS_PE_SIZE - 1 : 0]              r_row_data_t3_line [`ERS_PE_NUM - 1 : 0] ;

reg  [`PSUM_RAM_DEPTH - 1 : 0]                              r_read_addr                              ;
reg  [`PSUM_RAM_DEPTH - 1 : 0]                              r_write_addr                             ;
reg  [`ERS_MAX_WIDTH * `TIME_STEPS - 1 : 0]                 r_psum_line0                             ;
reg  [`ERS_MAX_WIDTH * `TIME_STEPS - 1 : 0]                 r_psum_line1                             ;
reg  [`ERS_MAX_WIDTH * `TIME_STEPS - 1 : 0]                 r_psum_line2                             ;
reg                                                         r_psum_add_flag=0                        ;
reg  [5:0]                                                  r_psum_in_ch_count                       ;

// --------------- state --------------- \\ 
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        s_curr_state <= S_IDLE;
    else
        s_curr_state <= s_next_state;
end

// --------------- code fetch --------------- \\ 
// r_conv
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) begin
        r_conv_in_ch      <= 'd0  ;
        r_conv_out_ch     <= 'd0  ;
        r_conv_img_size   <= 'd0  ;
        r_conv_lif_thrd   <= 'd0  ;
        r_conv_bias_scale <= 'd0  ;
        r_conv_or_maxpool <= 1'b0 ;
    end
    else if (code_valid) begin
        r_conv_in_ch      <= conv_in_ch      ;
        r_conv_out_ch     <= conv_out_ch     ;
        r_conv_img_size   <= conv_img_size   ;
        r_conv_lif_thrd   <= conv_lif_thrd   ;
        r_conv_bias_scale <= conv_bias_scale ;
        r_conv_or_maxpool <= conv_or_maxpool ;
    end
end

// --------------- weight part --------------- \\ 
always@(posedge s_clk) begin
    r_weight_in_d0 <= weight_in;
end

// r_weight_array
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_weight_array <= 'd0;
    else if (r_weight_cnt[0])
        r_weight_array <= {weight_in[`QUAN_BITS*`ERS_PE_SIZE*`ERS_PE_SIZE-`DATA_WIDTH - 1 : 0], r_weight_in_d0};
end

// r_weight_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_weight_cnt <= 'd0;
    else if (s_curr_state == S_PRE_DATA)
        r_weight_cnt <= 'd0;
    else if (weight_valid)
        r_weight_cnt <= r_weight_cnt + 1'b1;
end

// r_load_weight_done
always@(posedge s_clk) begin
    if (r_weight_cnt == 2*`ERS_PE_NUM-1)
        r_load_weight_done <= 1'b1;
    else 
        r_load_weight_done <= 1'b0;
end

// r_weight_valid
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_weight_valid <= 'd0;
    else if (s_curr_state == S_LOAD_WEIGHTS) begin
        case(r_weight_cnt)
            'd1:        r_weight_valid <= 8'b0000_0001;
            'd3:        r_weight_valid <= 8'b0000_0010;
            'd5:        r_weight_valid <= 8'b0000_0100;
            'd7:        r_weight_valid <= 8'b0000_1000;
            'd9:        r_weight_valid <= 8'b0001_0000;
            'd11:       r_weight_valid <= 8'b0010_0000;
            'd13:       r_weight_valid <= 8'b0100_0000;
            'd15:       r_weight_valid <= 8'b1000_0000;
            default:    r_weight_valid <= 'd0;
        endcase
    end
    else
        r_weight_valid <= 'd0;
end

// o_weight_ready
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        o_weight_ready <= 1'b0;
    else if (r_weight_cnt == 2*`ERS_PE_NUM-1)
        o_weight_ready <= 1'b0;
    else if (s_curr_state == S_LOAD_WEIGHTS && ~r_load_weight_done)
        o_weight_ready <= 1'b1;
    else
        o_weight_ready <= 1'b0;
end

// --------------- ifmap part --------------- \\ 
// o_spikes_ready
always@(posedge s_clk) begin
    if (r_ifmap_cnt == `ERS_PE_NUM*`ERS_NEED_ROW_NUM - 1)
        o_spikes_ready <= 1'b0;
    else if (s_curr_state == S_PRE_DATA)
        o_spikes_ready <= 1'b1;
    else
        o_spikes_ready <= 1'b0;
end

// r_ifmap_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_ifmap_cnt <= 'd0;
    else if (o_spikes_ready && i_spikes_valid && s_curr_state == S_PRE_DATA)
        r_ifmap_cnt <= r_ifmap_cnt + 1'b1;
    else if (s_curr_state == S_PRE_DATA)
        r_ifmap_cnt <= r_ifmap_cnt;
    else
        r_ifmap_cnt <= 'd0;
end

// r_ifmap_valid
genvar k;
generate

    for (k = 0; k < `ERS_PE_NUM; k = k + 1) begin: DATA_VALID_GEN
        always@(posedge s_clk, posedge s_rst) begin
            if (s_rst)
                r_ifmap_valid[k] <= 'd0;
            else if (s_curr_state == S_PRE_DATA) begin
                case(r_ifmap_cnt)
                    `ERS_NEED_ROW_NUM*k + 0: r_ifmap_valid[k] <= 9'b0_0000_0001; // 0
                    `ERS_NEED_ROW_NUM*k + 1: r_ifmap_valid[k] <= 9'b0_0000_1010; // 1 3
                    `ERS_NEED_ROW_NUM*k + 2: r_ifmap_valid[k] <= 9'b0_0101_0100; // 2 4 6
                    `ERS_NEED_ROW_NUM*k + 3: r_ifmap_valid[k] <= 9'b0_1010_0000; // 5 7
                    `ERS_NEED_ROW_NUM*k + 4: r_ifmap_valid[k] <= 9'b1_0000_0000; // 8
                    default: r_ifmap_valid[k] <= 'd0;
                endcase
            end
            else
                r_ifmap_valid[k] <= 'd0;
        end

        // r_ifmap_valid_d0
        always@(posedge s_clk) begin
            r_ifmap_valid_d0[k] <= r_ifmap_valid[k];
        end
    end

endgenerate

// --------------- calculate part --------------- \\ 
assign w_neg_cal_start = ~r_cal_start && r_cal_start_d0    ;

// r_cal_start
always@(posedge s_clk) begin
    r_cal_start_d0 <= r_cal_start    ;
    r_cal_start_d1 <= r_cal_start_d0 ;
    r_cal_start_d2 <= r_cal_start_d1 ;
    r_cal_start_d3 <= r_cal_start_d2 ;
    r_cal_start_d4 <= r_cal_start_d3 ;
    r_cal_start_d5 <= r_cal_start_d4 ;
    r_cal_start_d6 <= r_cal_start_d5 ;

    if (s_curr_state == S_CAL)
        r_cal_start <= 1'b1;
    else
        r_cal_start <= 1'b0;
end

// r_cal_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_cal_cnt <= 'd0;
    else if (r_cal_cnt == r_conv_img_size - 3)
        r_cal_cnt <= 'd0;
    else if (s_curr_state == S_CAL)
        r_cal_cnt <= r_cal_cnt + 1'b1;
end

// r_spikes_send_done
always@(posedge s_clk) begin
    if (s_curr_state == S_DONE)
        r_spikes_send_done <= 1'b0;
    else if (i_spikes_done)
        r_spikes_send_done <= 1'b1;
end

// r_cal_imgsize_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_cal_imgsize_cnt <= 'd0;
    else if (r_load_weight_done)
        r_cal_imgsize_cnt <= 'd0;
    else if (w_neg_cal_start)
        r_cal_imgsize_cnt <= r_cal_imgsize_cnt + 'd3;
end

// --------------- Eyeriss array --------------- \\ 
// -----> debug dot

wire [`QUAN_BITS + 1 : 0]       w_debug_PE00_out_t0 ;
wire [`QUAN_BITS + 1 : 0]       w_debug_PE01_out_t0 ;
wire [`QUAN_BITS + 1 : 0]       w_debug_PE02_out_t0 ;

wire [`QUAN_BITS + 1 : 0]       w_debug_PE10_out_t0 ;
wire [`QUAN_BITS + 1 : 0]       w_debug_PE11_out_t0 ;
wire [`QUAN_BITS + 1 : 0]       w_debug_PE12_out_t0 ;

wire [`QUAN_BITS + 1 : 0]       w_debug_PE20_out_t0 ;
wire [`QUAN_BITS + 1 : 0]       w_debug_PE21_out_t0 ;
wire [`QUAN_BITS + 1 : 0]       w_debug_PE22_out_t0 ;

wire [`QUAN_BITS + 3 : 0]       w_debug_row_data_t0_no00_line0;
wire [`QUAN_BITS + 3 : 0]       w_debug_row_data_t0_no00_line1;
wire [`QUAN_BITS + 3 : 0]       w_debug_row_data_t0_no00_line2;

wire [`QUAN_BITS + 3 : 0]       w_debug_row_data_t0_no01_line0;
wire [`QUAN_BITS + 3 : 0]       w_debug_row_data_t0_no01_line1;
wire [`QUAN_BITS + 3 : 0]       w_debug_row_data_t0_no01_line2;

wire [`QUAN_BITS + 3 : 0]       w_debug_row_data_t0_no02_line0;
wire [`QUAN_BITS + 3 : 0]       w_debug_row_data_t0_no02_line1;
wire [`QUAN_BITS + 3 : 0]       w_debug_row_data_t0_no02_line2;

wire [`QUAN_BITS + 3 : 0]       w_debug_row_data_t0_no03_line0;
wire [`QUAN_BITS + 3 : 0]       w_debug_row_data_t0_no03_line1;
wire [`QUAN_BITS + 3 : 0]       w_debug_row_data_t0_no03_line2;

wire [`QUAN_BITS + 3 : 0]       w_debug_row_data_t0_no04_line0;
wire [`QUAN_BITS + 3 : 0]       w_debug_row_data_t0_no04_line1;
wire [`QUAN_BITS + 3 : 0]       w_debug_row_data_t0_no04_line2;

wire [`QUAN_BITS + 3 : 0]       w_debug_row_data_t0_no05_line0;
wire [`QUAN_BITS + 3 : 0]       w_debug_row_data_t0_no05_line1;
wire [`QUAN_BITS + 3 : 0]       w_debug_row_data_t0_no05_line2;

wire [`QUAN_BITS + 3 : 0]       w_debug_row_data_t0_no06_line0;
wire [`QUAN_BITS + 3 : 0]       w_debug_row_data_t0_no06_line1;
wire [`QUAN_BITS + 3 : 0]       w_debug_row_data_t0_no06_line2;

wire [`QUAN_BITS + 3 : 0]       w_debug_row_data_t0_no07_line0;
wire [`QUAN_BITS + 3 : 0]       w_debug_row_data_t0_no07_line1;
wire [`QUAN_BITS + 3 : 0]       w_debug_row_data_t0_no07_line2;

assign w_debug_PE00_out_t0  = w_pe_out_t0[0][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*0+0+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*0+0)] ;
assign w_debug_PE01_out_t0  = w_pe_out_t0[0][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*0+1+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*0+1)] ;
assign w_debug_PE02_out_t0  = w_pe_out_t0[0][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*0+2+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*0+2)] ;

assign w_debug_PE10_out_t0  = w_pe_out_t0[0][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*1+0+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*1+0)] ;
assign w_debug_PE11_out_t0  = w_pe_out_t0[0][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*1+1+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*1+1)] ;
assign w_debug_PE12_out_t0  = w_pe_out_t0[0][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*1+2+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*1+2)] ;

assign w_debug_PE20_out_t0  = w_pe_out_t0[0][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*2+0+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*2+0)] ;
assign w_debug_PE21_out_t0  = w_pe_out_t0[0][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*2+1+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*2+1)] ;
assign w_debug_PE22_out_t0  = w_pe_out_t0[0][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*2+2+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*2+2)] ;

assign w_debug_row_data_t0_no00_line0 = r_row_data_t0_line[0][(`QUAN_BITS + 4) * (0 + 1) - 1 : (`QUAN_BITS + 4) * 0];
assign w_debug_row_data_t0_no00_line1 = r_row_data_t0_line[0][(`QUAN_BITS + 4) * (1 + 1) - 1 : (`QUAN_BITS + 4) * 1];
assign w_debug_row_data_t0_no00_line2 = r_row_data_t0_line[0][(`QUAN_BITS + 4) * (2 + 1) - 1 : (`QUAN_BITS + 4) * 2];

assign w_debug_row_data_t0_no01_line0 = r_row_data_t0_line[1][(`QUAN_BITS + 4) * (0 + 1) - 1 : (`QUAN_BITS + 4) * 0];
assign w_debug_row_data_t0_no01_line1 = r_row_data_t0_line[1][(`QUAN_BITS + 4) * (1 + 1) - 1 : (`QUAN_BITS + 4) * 1];
assign w_debug_row_data_t0_no01_line2 = r_row_data_t0_line[1][(`QUAN_BITS + 4) * (2 + 1) - 1 : (`QUAN_BITS + 4) * 2];

assign w_debug_row_data_t0_no02_line0 = r_row_data_t0_line[2][(`QUAN_BITS + 4) * (0 + 1) - 1 : (`QUAN_BITS + 4) * 0];
assign w_debug_row_data_t0_no02_line1 = r_row_data_t0_line[2][(`QUAN_BITS + 4) * (1 + 1) - 1 : (`QUAN_BITS + 4) * 1];
assign w_debug_row_data_t0_no02_line2 = r_row_data_t0_line[2][(`QUAN_BITS + 4) * (2 + 1) - 1 : (`QUAN_BITS + 4) * 2];

assign w_debug_row_data_t0_no03_line0 = r_row_data_t0_line[3][(`QUAN_BITS + 4) * (0 + 1) - 1 : (`QUAN_BITS + 4) * 0];
assign w_debug_row_data_t0_no03_line1 = r_row_data_t0_line[3][(`QUAN_BITS + 4) * (1 + 1) - 1 : (`QUAN_BITS + 4) * 1];
assign w_debug_row_data_t0_no03_line2 = r_row_data_t0_line[3][(`QUAN_BITS + 4) * (2 + 1) - 1 : (`QUAN_BITS + 4) * 2];

assign w_debug_row_data_t0_no04_line0 = r_row_data_t0_line[4][(`QUAN_BITS + 4) * (0 + 1) - 1 : (`QUAN_BITS + 4) * 0];
assign w_debug_row_data_t0_no04_line1 = r_row_data_t0_line[4][(`QUAN_BITS + 4) * (1 + 1) - 1 : (`QUAN_BITS + 4) * 1];
assign w_debug_row_data_t0_no04_line2 = r_row_data_t0_line[4][(`QUAN_BITS + 4) * (2 + 1) - 1 : (`QUAN_BITS + 4) * 2];

assign w_debug_row_data_t0_no05_line0 = r_row_data_t0_line[5][(`QUAN_BITS + 4) * (0 + 1) - 1 : (`QUAN_BITS + 4) * 0];
assign w_debug_row_data_t0_no05_line1 = r_row_data_t0_line[5][(`QUAN_BITS + 4) * (1 + 1) - 1 : (`QUAN_BITS + 4) * 1];
assign w_debug_row_data_t0_no05_line2 = r_row_data_t0_line[5][(`QUAN_BITS + 4) * (2 + 1) - 1 : (`QUAN_BITS + 4) * 2];

assign w_debug_row_data_t0_no06_line0 = r_row_data_t0_line[6][(`QUAN_BITS + 4) * (0 + 1) - 1 : (`QUAN_BITS + 4) * 0];
assign w_debug_row_data_t0_no06_line1 = r_row_data_t0_line[6][(`QUAN_BITS + 4) * (1 + 1) - 1 : (`QUAN_BITS + 4) * 1];
assign w_debug_row_data_t0_no06_line2 = r_row_data_t0_line[6][(`QUAN_BITS + 4) * (2 + 1) - 1 : (`QUAN_BITS + 4) * 2];

assign w_debug_row_data_t0_no07_line0 = r_row_data_t0_line[7][(`QUAN_BITS + 4) * (0 + 1) - 1 : (`QUAN_BITS + 4) * 0];
assign w_debug_row_data_t0_no07_line1 = r_row_data_t0_line[7][(`QUAN_BITS + 4) * (1 + 1) - 1 : (`QUAN_BITS + 4) * 1];
assign w_debug_row_data_t0_no07_line2 = r_row_data_t0_line[7][(`QUAN_BITS + 4) * (2 + 1) - 1 : (`QUAN_BITS + 4) * 2];

// data in checker
wire  [`IMG_WIDTH - 1 : 0]          spikes_data_t0;
wire  [`IMG_WIDTH - 1 : 0]          spikes_data_t1;
wire  [`IMG_WIDTH - 1 : 0]          spikes_data_t2;
wire  [`IMG_WIDTH - 1 : 0]          spikes_data_t3;

genvar kkk;
generate

    for (kkk = 0; kkk < `IMG_WIDTH; kkk = kkk + 1) begin
        assign spikes_data_t0[kkk] = i_spikes[`TIME_STEPS*kkk + 0];
        assign spikes_data_t1[kkk] = i_spikes[`TIME_STEPS*kkk + 1];
        assign spikes_data_t2[kkk] = i_spikes[`TIME_STEPS*kkk + 2];
        assign spikes_data_t3[kkk] = i_spikes[`TIME_STEPS*kkk + 3];
    end

endgenerate

// -----> end debug dot

genvar i,j,num,line;
generate

    for (num = 0; num < `ERS_PE_NUM; num = num + 1)      begin: PE_ARRAY
        for (i = 0; i < `ERS_PE_SIZE; i = i + 1)         begin: PE_ARRAY_row
            for (j = 0; j < `ERS_PE_SIZE; j = j + 1)     begin: PE_ARRAY_col
            
                simple_eyeriss_pe_unit u_simple_eyeriss_pe_unit (
                    .s_clk                  ( s_clk                                                                         ),
                    .s_rst                  ( s_rst                                                                         ),
                    .i_weight_valid         ( r_weight_valid[num]                                                           ),
                    .i_weights              ( r_weight_array[`QUAN_BITS*`ERS_PE_SIZE*(j+1) -1 : `QUAN_BITS*`ERS_PE_SIZE*j]  ),
                    .i_spikes_valid         ( r_ifmap_valid_d0[num][`ERS_PE_SIZE*j+i]                                       ),
                    .i_spikes               ( i_spikes                                                                      ),
                    .i_cal_start            ( r_cal_start_d0                                                                ),

                    .o_psum_out_t0          ( w_pe_out_t0[num][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*j+i+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*j+i)] ),
                    .o_psum_out_t1          ( w_pe_out_t1[num][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*j+i+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*j+i)] ),
                    .o_psum_out_t2          ( w_pe_out_t2[num][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*j+i+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*j+i)] ),
                    .o_psum_out_t3          ( w_pe_out_t3[num][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*j+i+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*j+i)] )
                );

            end // gen_col

            // sum tmpdata get row_data
            always@(posedge s_clk, posedge s_rst) begin
                if  (s_rst) begin
                    r_row_data_t0_line[num][(`QUAN_BITS + 4) * (i + 1) - 1 : (`QUAN_BITS + 4) * i] <= 'd0;
                    r_row_data_t1_line[num][(`QUAN_BITS + 4) * (i + 1) - 1 : (`QUAN_BITS + 4) * i] <= 'd0;
                    r_row_data_t2_line[num][(`QUAN_BITS + 4) * (i + 1) - 1 : (`QUAN_BITS + 4) * i] <= 'd0;
                    r_row_data_t3_line[num][(`QUAN_BITS + 4) * (i + 1) - 1 : (`QUAN_BITS + 4) * i] <= 'd0;
                end
                else if (r_cal_start_d1) begin
                    r_row_data_t0_line[num][(`QUAN_BITS + 4) * (i + 1) - 1 : (`QUAN_BITS + 4) * i] 
                                            <= $signed(w_pe_out_t0[num][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*0+i+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*0+i)]) 
                                             + $signed(w_pe_out_t0[num][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*1+i+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*1+i)]) 
                                             + $signed(w_pe_out_t0[num][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*2+i+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*2+i)]);
                
                    r_row_data_t1_line[num][(`QUAN_BITS + 4) * (i + 1) - 1 : (`QUAN_BITS + 4) * i] 
                                            <= $signed(w_pe_out_t1[num][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*0+i+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*0+i)]) 
                                             + $signed(w_pe_out_t1[num][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*1+i+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*1+i)]) 
                                             + $signed(w_pe_out_t1[num][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*2+i+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*2+i)]);
                
                    r_row_data_t2_line[num][(`QUAN_BITS + 4) * (i + 1) - 1 : (`QUAN_BITS + 4) * i]  
                                            <= $signed(w_pe_out_t2[num][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*0+i+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*0+i)]) 
                                             + $signed(w_pe_out_t2[num][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*1+i+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*1+i)]) 
                                             + $signed(w_pe_out_t2[num][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*2+i+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*2+i)]);
                
                    r_row_data_t3_line[num][(`QUAN_BITS + 4) * (i + 1) - 1 : (`QUAN_BITS + 4) * i]
                                            <= $signed(w_pe_out_t3[num][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*0+i+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*0+i)]) 
                                             + $signed(w_pe_out_t3[num][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*1+i+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*1+i)]) 
                                             + $signed(w_pe_out_t3[num][(`QUAN_BITS + 2)*(`ERS_PE_SIZE*2+i+1) - 1 : (`QUAN_BITS + 2)*(`ERS_PE_SIZE*2+i)]);
                end
            end

        end // gen_row
    end // gen_num

    for (line = 0; line < `ERS_PE_SIZE; line = line + 1) begin : Add_tree_gen

        assign w_addtree_in_t0[line] = {r_row_data_t0_line[0][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t0_line[1][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t0_line[2][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t0_line[3][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t0_line[4][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t0_line[5][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t0_line[6][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t0_line[7][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line] };

        assign w_addtree_in_t1[line] = {r_row_data_t1_line[0][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t1_line[1][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t1_line[2][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t1_line[3][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t1_line[4][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t1_line[5][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t1_line[6][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t1_line[7][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line] };

        assign w_addtree_in_t2[line] = {r_row_data_t2_line[0][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t2_line[1][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t2_line[2][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t2_line[3][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t2_line[4][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t2_line[5][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t2_line[6][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t2_line[7][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line] };

        assign w_addtree_in_t3[line] = {r_row_data_t3_line[0][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t3_line[1][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t3_line[2][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t3_line[3][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t3_line[4][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t3_line[5][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t3_line[6][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line]
                                      , r_row_data_t3_line[7][(`QUAN_BITS + 4) * (line + 1) - 1 : (`QUAN_BITS + 4) * line] };

        add_tree #(
            .INPUTS_NUM     ( `ERS_PE_NUM           ),
            .IDATA_WIDTH    ( `QUAN_BITS + 4        )
        ) u_add_tree_t0(
            .sclk           ( s_clk                 ),
            .s_rst_n        ( ~s_rst                ),
            .idata          ( w_addtree_in_t0[line] ),
            .data_out       ( w_addtree_out_t0[line])  // 15 bit
        );

        add_tree #(
            .INPUTS_NUM     ( `ERS_PE_NUM           ),
            .IDATA_WIDTH    ( `QUAN_BITS + 4        )
        ) u_add_tree_t1(
            .sclk           ( s_clk                 ),
            .s_rst_n        ( ~s_rst                ),
            .idata          ( w_addtree_in_t1[line] ),
            .data_out       ( w_addtree_out_t1[line])
        );

        add_tree #(
            .INPUTS_NUM     ( `ERS_PE_NUM           ),
            .IDATA_WIDTH    ( `QUAN_BITS + 4        )
        ) u_add_tree_t2(
            .sclk           ( s_clk                 ),
            .s_rst_n        ( ~s_rst                ),
            .idata          ( w_addtree_in_t2[line] ),
            .data_out       ( w_addtree_out_t2[line]) 
        );

        add_tree #(
            .INPUTS_NUM     ( `ERS_PE_NUM           ),
            .IDATA_WIDTH    ( `QUAN_BITS + 4        )
        ) u_add_tree_t3(
            .sclk           ( s_clk                 ),
            .s_rst_n        ( ~s_rst                ),
            .idata          ( w_addtree_in_t3[line] ),
            .data_out       ( w_addtree_out_t3[line])
        );

    end // end_line_gen

endgenerate

// --------------- psum ram --------------- \\ 
// r_write_addr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_write_addr <= 'd0;
    else if (r_load_weight_done)
        r_write_addr <= 'd0;
    else if (r_cal_start_d6)
        r_write_addr <= r_write_addr + 1'b1;
end

// r_read_addr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_read_addr <= 'd0;
    else if (r_load_weight_done)
        r_read_addr <= 'd0;
    else if (r_cal_start_d3)
        r_read_addr <= r_read_addr + 1'b1;
end

// read_data_mode
always@(posedge s_clk) begin
    if (s_curr_state == S_CHECK_FETCH_DATA && Array_out_ready && ~r_cal_start_d6)
        read_data_mode <= 1'b1;
    else
        read_data_mode <= 1'b0;
end

// r_psum_in_ch_count
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_psum_in_ch_count <= 'd0;
    else if (Array_out_done)
        r_psum_in_ch_count <= 'd0;
    else if (r_load_weight_done)
        r_psum_in_ch_count <= r_psum_in_ch_count + 1'b1;
end

// r_psum_add_flag
always@(posedge s_clk) begin
    if (r_psum_in_ch_count == 'd1)
        r_psum_add_flag <= 1'b1;
    else
        r_psum_add_flag <= 1'b0;
end

assign w_psum_tmp_line0[0] = r_psum_add_flag ? $signed(w_addtree_out_t0[0]) : $signed(w_addtree_out_t0[0]) + $signed(w_psum_tmpdata_line0[`ERS_MAX_WIDTH*1 - 1 : `ERS_MAX_WIDTH*0]);
assign w_psum_tmp_line1[0] = r_psum_add_flag ? $signed(w_addtree_out_t0[1]) : $signed(w_addtree_out_t0[1]) + $signed(w_psum_tmpdata_line1[`ERS_MAX_WIDTH*1 - 1 : `ERS_MAX_WIDTH*0]);
assign w_psum_tmp_line2[0] = r_psum_add_flag ? $signed(w_addtree_out_t0[2]) : $signed(w_addtree_out_t0[2]) + $signed(w_psum_tmpdata_line2[`ERS_MAX_WIDTH*1 - 1 : `ERS_MAX_WIDTH*0]);

assign w_psum_tmp_line0[1] = r_psum_add_flag ? $signed(w_addtree_out_t1[0]) : $signed(w_addtree_out_t1[0]) + $signed(w_psum_tmpdata_line0[`ERS_MAX_WIDTH*2 - 1 : `ERS_MAX_WIDTH*1]);
assign w_psum_tmp_line1[1] = r_psum_add_flag ? $signed(w_addtree_out_t1[1]) : $signed(w_addtree_out_t1[1]) + $signed(w_psum_tmpdata_line1[`ERS_MAX_WIDTH*2 - 1 : `ERS_MAX_WIDTH*1]);
assign w_psum_tmp_line2[1] = r_psum_add_flag ? $signed(w_addtree_out_t1[2]) : $signed(w_addtree_out_t1[2]) + $signed(w_psum_tmpdata_line2[`ERS_MAX_WIDTH*2 - 1 : `ERS_MAX_WIDTH*1]);

assign w_psum_tmp_line0[2] = r_psum_add_flag ? $signed(w_addtree_out_t2[0]) : $signed(w_addtree_out_t2[0]) + $signed(w_psum_tmpdata_line0[`ERS_MAX_WIDTH*3 - 1 : `ERS_MAX_WIDTH*2]);
assign w_psum_tmp_line1[2] = r_psum_add_flag ? $signed(w_addtree_out_t2[1]) : $signed(w_addtree_out_t2[1]) + $signed(w_psum_tmpdata_line1[`ERS_MAX_WIDTH*3 - 1 : `ERS_MAX_WIDTH*2]);
assign w_psum_tmp_line2[2] = r_psum_add_flag ? $signed(w_addtree_out_t2[2]) : $signed(w_addtree_out_t2[2]) + $signed(w_psum_tmpdata_line2[`ERS_MAX_WIDTH*3 - 1 : `ERS_MAX_WIDTH*2]);

assign w_psum_tmp_line0[3] = r_psum_add_flag ? $signed(w_addtree_out_t3[0]) : $signed(w_addtree_out_t3[0]) + $signed(w_psum_tmpdata_line0[`ERS_MAX_WIDTH*4 - 1 : `ERS_MAX_WIDTH*3]);
assign w_psum_tmp_line1[3] = r_psum_add_flag ? $signed(w_addtree_out_t3[1]) : $signed(w_addtree_out_t3[1]) + $signed(w_psum_tmpdata_line1[`ERS_MAX_WIDTH*4 - 1 : `ERS_MAX_WIDTH*3]);
assign w_psum_tmp_line2[3] = r_psum_add_flag ? $signed(w_addtree_out_t3[2]) : $signed(w_addtree_out_t3[2]) + $signed(w_psum_tmpdata_line2[`ERS_MAX_WIDTH*4 - 1 : `ERS_MAX_WIDTH*3]);

// r_psum_line
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) begin
        r_psum_line0 <= 'd0;
        r_psum_line1 <= 'd0;
        r_psum_line2 <= 'd0;
    end
    else if (r_cal_start_d5) begin
        r_psum_line0 <= {w_psum_tmp_line0[3], w_psum_tmp_line0[2], w_psum_tmp_line0[1], w_psum_tmp_line0[0]};
        r_psum_line1 <= {w_psum_tmp_line1[3], w_psum_tmp_line1[2], w_psum_tmp_line1[1], w_psum_tmp_line1[0]};
        r_psum_line2 <= {w_psum_tmp_line2[3], w_psum_tmp_line2[2], w_psum_tmp_line2[1], w_psum_tmp_line2[0]};
    end
end

psum_ram_top u_psum_ram_top (
    .s_clk             ( s_clk                 ),
    .s_rst             ( s_rst                 ),

    .code_valid        ( code_valid            ),
    .conv_img_size     ( conv_img_size         ),

    .i_data_valid      ( r_cal_start_d6        ),
    .i_write_addr      ( r_write_addr          ),
    .i_data_in_line0   ( r_psum_line0          ),
    .i_data_in_line1   ( r_psum_line1          ),
    .i_data_in_line2   ( r_psum_line2          ),

    .read_data_mode    ( read_data_mode        ),
    .read_1line_addr   ( read_1line_addr       ),
    .read_1line_req    ( read_1line_req        ),
    .read_1line_data   ( read_1line_data       ),

    .i_data_req        ( r_cal_start_d3        ),
    .read_addr         ( r_read_addr           ),
    .o_data_out_line0  ( w_psum_tmpdata_line0  ),
    .o_data_out_line1  ( w_psum_tmpdata_line1  ),
    .o_data_out_line2  ( w_psum_tmpdata_line2  )
);

psum_callback u_psum_callback(
    .s_clk             ( s_clk             ),
    .s_rst             ( s_rst             ),

    .code_valid        ( code_valid        ),
    .conv_in_ch        ( conv_in_ch        ),
    .conv_out_ch       ( conv_out_ch       ),
    .conv_img_size     ( conv_img_size     ),
    .conv_lif_thrd     ( conv_lif_thrd     ),
    .conv_bias_scale   ( conv_bias_scale   ),
    .conv_or_maxpool   ( conv_or_maxpool   ),

    .i_read_data_mode  ( read_data_mode    ),
    .read_1line_addr   ( read_1line_addr   ),
    .read_1line_req    ( read_1line_req    ),
    .read_1line_data   ( read_1line_data   ),

    .Array_out_valid   ( Array_out_valid   ),
    .Array_out_spikes  ( Array_out_spikes  ),
    .Array_out_done    ( Array_out_done    )
);

// --------------- Finite-State-Machine --------------- \\
always@(*) begin

    case(s_curr_state)
        S_IDLE:             s_next_state = S_LOAD_WEIGHTS;
        S_LOAD_WEIGHTS:     s_next_state = r_load_weight_done ? S_PRE_DATA : S_LOAD_WEIGHTS;
        S_PRE_DATA:         s_next_state = (r_ifmap_cnt == `ERS_PE_NUM*`ERS_NEED_ROW_NUM - 1) ? S_CAL : S_PRE_DATA;
        S_CAL:              s_next_state = (r_cal_cnt == r_conv_img_size - 3) ? S_CHECK_FETCH_DATA : S_CAL;
        S_CHECK_FETCH_DATA: s_next_state = ((r_cal_imgsize_cnt > r_conv_img_size - 6) ? 
                                            (Array_out_ready ? S_CHECK_FETCH_DATA : (r_spikes_send_done ? S_DONE : S_IDLE)): S_PRE_DATA);
        S_DONE:             s_next_state = (fetch_code_done && ~SPS_part_done) ? S_DONE : S_IDLE;
        default:            s_next_state = S_IDLE;
    endcase

end

endmodule // simple_eyeriss_array


