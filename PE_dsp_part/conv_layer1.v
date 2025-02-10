/*
    -- conv_layer1 --
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "../hyper_para.v"
module conv_layer1 (
    input                                         s_clk                 ,
    input                                         s_rst                 ,
    input                                         network_cal_done      ,
    // interact with data RAM   
    input              [`QUAN_BITS - 1 : 0]       feature_data_ch0      , 
    input              [`QUAN_BITS - 1 : 0]       feature_data_ch1      , 
    input              [`QUAN_BITS - 1 : 0]       feature_data_ch2      , 
    input                                         f_data_valid          , 
    output reg                                    o_data_ready          ,
    output reg                                    o_load_d_once_done    ,
    output reg                                    o_load_d_finish       ,
    // interact with weights RAM    
    input              [`DATA_WIDTH - 1 : 0]      weight_in             ,
    input                                         weight_valid          ,
    output reg                                    o_weight_ready        ,
    output reg                                    o_load_w_finish       ,
    // - interact with spiking domain ram - 
    output reg signed  [`ADD9_ALL_BITS - 1 : 0]   o_conv1_out           ,
    output wire                                   o_conv1_out_valid 
);

localparam  S_IDLE          =   0   ,
            S_LOAD_WEIGHTS  =   1   ,
            S_CAL           =   2   ,
            S_DONE          =   3   ;

// ps : Unused wires will be optimized
wire [`PE_ROW * `PE_COL - 1 : 0]                  w_mac_rlst_valid     [`PE_NUM - 1 : 0]    ;
wire [`ADD9_ALL_BITS * `PE_ROW * `PE_COL - 1 : 0] w_mac_rlst_out       [`PE_NUM - 1 : 0]    ;
wire [`ADD9_ALL_BITS * `PE_ROW * `PE_COL - 1 : 0] w_shift_data         [`PE_NUM - 1 : 0]    ;
wire [`ADD9_ALL_BITS * `PE_ROW * `PE_COL - 1 : 0] w_shift_data_tmp     [`PE_NUM - 1 : 0]    ;
wire [`QUAN_BITS - 1 : 0]                         w_feature_data_array [`PE_NUM - 1 : 0]    ;
wire signed [`QUAN_BITS - 1 : 0]                  w_conv_bias                               ;
wire signed [`ADD9_ALL_BITS - 1 : 0]              w_conv_bias_ext                           ;

reg  [`QUAN_BITS * `PE_ROW * `PE_COL - 1 : 0]     r_weight_array                            ;
reg  [`PE_NUM - 1 : 0]                            r_weight_valid                            ;
reg  [2:0]                                        r_weight_cnt                              ;
reg  [`DATA_WIDTH - 1 : 0]                        r_weight_in_d0                            ;
reg                                               r_load_weight_done=0                      ;
reg                                               r_cal_data_done=0                         ;
reg                                               r_load_d_once_done_d0                     ;
reg                                               r_load_d_once_done_d1                     ;

reg  [9:0]                                        r_pos_x                                   ;
reg  [9:0]                                        r_pos_y                                   ;
reg  [9:0]                                        r_chnnl_cnt                               ;
reg                                               r_conv1_out_valid_d0=0                    ;
reg                                               r_conv1_out_valid_d1=0                    ;

reg                                               r00_conv_en                               ;
reg                                               r01_conv_en                               ;
reg  [9:0]                                        r00_conv_cnt                              ;
reg  [9:0]                                        r01_conv_cnt                              ;

reg  signed  [`ADD9_ALL_BITS - 1 : 0]             r_conv1_out                               ;
reg  [`ADD9_ALL_BITS * `PE_ROW * `PE_COL - 1 : 0] r_shift_data         [`PE_NUM - 1 : 0]    ;
reg                                               r_f_data_valid                            ;

reg  [2:0]                                        s_curr_state                              ;
reg  [2:0]                                        s_next_state                              ;

assign o_conv1_out_valid        =       (r01_conv_en && r00_conv_en) ? r_conv1_out_valid_d1 : 1'b0  ;
assign w_conv_bias_ext          =       w_conv_bias                                                 ;

// < ** simulation debug wire ** >
// wire                                    w_debug_valid                                                 ;
// assign w_debug_valid            =       (r01_conv_en && r00_conv_en) ? r_conv1_out_valid_d0 : 1'b0    ;

always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        s_curr_state <= S_IDLE;
    else
        s_curr_state <= s_next_state;
end

// r00_conv_cnt r00_conv_en
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst || r_cal_data_done) begin
        r00_conv_cnt <= 'd0;
        r00_conv_en  <= 1'b0;
    end
    else if ((r00_conv_cnt == (`PE_ROW - 1) * (`IMG_WIDTH + 2 + 1) - 2) && r_conv1_out_valid_d1) begin
        r00_conv_cnt <= r00_conv_cnt;
        r00_conv_en  <= 1'b1;
    end
    else if (r_conv1_out_valid_d1) begin
        r00_conv_cnt <= r00_conv_cnt + 1'b1;
        r00_conv_en  <= r00_conv_en;
    end
end

// r01_conv_cnt r01_conv_en
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst || r_cal_data_done) begin
        r01_conv_cnt <= 'd0;
        r01_conv_en  <= 1'b0;
    end
    else if (r00_conv_en && r_conv1_out_valid_d1) begin
        case(r01_conv_cnt)
            `IMG_WIDTH + 2 - 3, `IMG_WIDTH + 2 - 2: begin
                r01_conv_en  <= 1'b0;
                r01_conv_cnt <= r01_conv_cnt + 1'b1;
            end
            `IMG_WIDTH + 2 - 1: begin
                r01_conv_en  <= 1'b1;
                r01_conv_cnt <= 'd0 ;
            end
            default: begin
                r01_conv_en  <= 1'b1;
                if (r01_conv_en)
                    r01_conv_cnt <= r01_conv_cnt + 1'b1;
            end
        endcase
    end
end

// r_weight_array
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_weight_array <= 'd0;
    else if (r_weight_cnt[0])
        r_weight_array <= {weight_in[`QUAN_BITS*`PE_ROW*`PE_COL-`DATA_WIDTH - 1 : 0], r_weight_in_d0};
end

// o_load_d_finish
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        o_load_d_finish <= 1'b0;
    else if (s_curr_state == S_DONE)
        o_load_d_finish <= 1'b1;
    else
        o_load_d_finish <= 1'b0;
end

// o_load_w_finish
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        o_load_w_finish <= 1'b0;
    else if (s_curr_state == S_DONE)
        o_load_w_finish <= 1'b1;
    else
        o_load_w_finish <= 1'b0;
end

// r_weight_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_weight_cnt <= 'd0;
    else if (s_curr_state == S_CAL)
        r_weight_cnt <= 'd0;
    else if (weight_valid)
        r_weight_cnt <= r_weight_cnt + 1'b1;
end

// r_weight_valid
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_weight_valid <= 'd0;
    else if (s_curr_state == S_LOAD_WEIGHTS) begin
        case(r_weight_cnt)
            'd1: r_weight_valid <= 3'b001;
            'd3: r_weight_valid <= 3'b010;
            'd5: r_weight_valid <= 3'b100;
            default: r_weight_valid <= 'd0;
        endcase
    end
    else
        r_weight_valid <= 'd0;
end

always@(posedge s_clk) begin
    r_weight_in_d0 <= weight_in;
end

// o_weight_ready
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        o_weight_ready <= 1'b0;
    else if (r_weight_cnt == 2*`PE_NUM-1)
        o_weight_ready <= 1'b0;
    else if (s_curr_state == S_LOAD_WEIGHTS && ~r_load_weight_done)
        o_weight_ready <= 1'b1;
    else
        o_weight_ready <= 1'b0;
end

// o_data_ready
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        o_data_ready <= 1'b0;
    else if (r_pos_y == `IMG_WIDTH + 2 - 1 && r_pos_x == `IMG_WIDTH + 2 - 1 && f_data_valid)
        o_data_ready <= 1'b0;
    else if (s_curr_state == S_CAL && ~o_load_d_once_done)
        o_data_ready <= 1'b1;
    else
        o_data_ready <= 1'b0;
end

// r_load_weight_done
always@(posedge s_clk) begin
    if (r_weight_cnt == 2*`PE_NUM-1)
        r_load_weight_done <= 1'b1;
    else 
        r_load_weight_done <= 1'b0;
end

// r_pos_x
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_pos_x <= 'd0;
    else if ((f_data_valid && r_pos_x == `IMG_WIDTH + 2 - 1) || ~o_data_ready)
        r_pos_x <= 'd0;
    else if (f_data_valid)
        r_pos_x <= r_pos_x + 1'b1;
end

// r_pos_y
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_pos_y <= 'd0;
    else if (r_pos_y == `IMG_HIGH + 2 - 1 && r_pos_x == `IMG_WIDTH + 2 - 1 && f_data_valid)
        r_pos_y <= 'd0;
    else if (f_data_valid && r_pos_x == `IMG_WIDTH + 2 - 1)
        r_pos_y <= r_pos_y + 1'b1;
end

// o_load_d_once_done
always@(posedge s_clk) begin
    r_load_d_once_done_d0 <= o_load_d_once_done     ;
    r_load_d_once_done_d1 <= r_load_d_once_done_d0  ;
    r_cal_data_done       <= r_load_d_once_done_d1  ;

    if (r_pos_y == `IMG_HIGH + 2 - 1 && r_pos_x == `IMG_WIDTH + 2 - 1 && f_data_valid)
        o_load_d_once_done <= 1'b1;
    else 
        o_load_d_once_done <= 1'b0;
end

// r_chnnl_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_chnnl_cnt <= 'd0;
    else if (s_curr_state == S_DONE && r_cal_data_done) // r_chnnl_cnt == `CONV1_KERNEL_CHNNLS
        r_chnnl_cnt <= 'd0;
    else if (r_cal_data_done)
        r_chnnl_cnt <= r_chnnl_cnt + 1'b1;
end

// r_conv1_out
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_conv1_out <= 'd0;
    else if (w_mac_rlst_valid[0][8])
        r_conv1_out <= $signed(w_mac_rlst_out[0][`ADD9_ALL_BITS*(`PE_COL*2+2)+`ADD9_ALL_BITS-1 : `ADD9_ALL_BITS*(`PE_COL*2+2)])
                     + $signed(w_mac_rlst_out[1][`ADD9_ALL_BITS*(`PE_COL*2+2)+`ADD9_ALL_BITS-1 : `ADD9_ALL_BITS*(`PE_COL*2+2)])
                     + $signed(w_mac_rlst_out[2][`ADD9_ALL_BITS*(`PE_COL*2+2)+`ADD9_ALL_BITS-1 : `ADD9_ALL_BITS*(`PE_COL*2+2)]);
end

// o_conv1_out
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        o_conv1_out <= 'd0;
    else
        o_conv1_out <= ($signed(r_conv1_out) + $signed(w_conv_bias_ext <<< `CONV1_WEIGHT_SCALE));
end

// r_conv1_out_valid
always@(posedge s_clk) begin
    r_f_data_valid       <= f_data_valid           ;

    r_conv1_out_valid_d0 <= w_mac_rlst_valid[0][8] ;
    r_conv1_out_valid_d1 <= r_conv1_out_valid_d0   ;
end

genvar i,j,num,k,sft_n, x_1, y_1;
generate

    assign w_feature_data_array[0] = feature_data_ch0;
    assign w_feature_data_array[1] = feature_data_ch1;
    assign w_feature_data_array[2] = feature_data_ch2;

    for (k = 0; k < `PE_NUM; k = k + 1) begin: init_
        assign w_shift_data[k][`ADD9_ALL_BITS - 1 : 0] = 'd0;

        for (sft_n=1; sft_n < `PE_COL; sft_n=sft_n+1) begin: shift_ram_line
            
            conv1_shift_ram u_conv1_shift_ram (
                .D   (w_mac_rlst_out[k][`ADD9_ALL_BITS*(`PE_COL*sft_n-1)+`ADD9_ALL_BITS-1 : `ADD9_ALL_BITS*(`PE_COL*sft_n-1)] ), 
                .CLK (s_clk                                                                                                   ),
                .CE  (w_mac_rlst_valid[k][`PE_COL*sft_n-1]                                                                    ), // 2 ,5
                .Q   (w_shift_data_tmp[k][`ADD9_ALL_BITS*(`PE_COL*sft_n)+`ADD9_ALL_BITS-1 : `ADD9_ALL_BITS*(`PE_COL*sft_n)]   )
            );

            // MAC pipeline stage = 2, need 1 clk delay
            always@(posedge s_clk, posedge s_rst) begin
                if (s_rst)
                    r_shift_data[k][`ADD9_ALL_BITS*(`PE_COL*sft_n)+`ADD9_ALL_BITS-1 : `ADD9_ALL_BITS*(`PE_COL*sft_n)] <= 'd0;
                // Prevent missing data during feature ram data fetch from ddr
                else if (r_f_data_valid || w_mac_rlst_valid[k][`PE_COL*sft_n])
                    r_shift_data[k][`ADD9_ALL_BITS*(`PE_COL*sft_n)+`ADD9_ALL_BITS-1 : `ADD9_ALL_BITS*(`PE_COL*sft_n)]
                    <= w_shift_data_tmp[k][`ADD9_ALL_BITS*(`PE_COL*sft_n)+`ADD9_ALL_BITS-1 : `ADD9_ALL_BITS*(`PE_COL*sft_n)] ;  
                else
                    r_shift_data[k][`ADD9_ALL_BITS*(`PE_COL*sft_n)+`ADD9_ALL_BITS-1 : `ADD9_ALL_BITS*(`PE_COL*sft_n)]
                    <= r_shift_data[k][`ADD9_ALL_BITS*(`PE_COL*sft_n)+`ADD9_ALL_BITS-1 : `ADD9_ALL_BITS*(`PE_COL*sft_n)]     ;
            end

            assign w_shift_data[k][`ADD9_ALL_BITS*(`PE_COL*sft_n)+`ADD9_ALL_BITS-1 : `ADD9_ALL_BITS*(`PE_COL*sft_n)]
                =  r_shift_data[k][`ADD9_ALL_BITS*(`PE_COL*sft_n)+`ADD9_ALL_BITS-1 : `ADD9_ALL_BITS*(`PE_COL*sft_n)]     ;

        end

        for (y_1=0; y_1 < `PE_COL; y_1=y_1+1) begin: shift_data_interact_y
            for (x_1=0; x_1 < `PE_ROW-1; x_1=x_1+1) begin: shift_data_interact_x

                assign w_shift_data[k][`ADD9_ALL_BITS*(`PE_COL*y_1+x_1+1)+`ADD9_ALL_BITS-1: `ADD9_ALL_BITS*(`PE_COL*y_1+x_1+1)] 
                    =  w_mac_rlst_out[k][`ADD9_ALL_BITS*(`PE_COL*y_1+x_1)+`ADD9_ALL_BITS-1: `ADD9_ALL_BITS*(`PE_COL*y_1+x_1)];
            
            end
        end
    end

    for (num = 0; num < `PE_NUM; num = num + 1)  begin: NUM_PE
        for (j = 0; j < `PE_COL; j = j + 1)      begin: PE_ARRAY_col
            for (i = 0; i < `PE_ROW; i = i + 1)  begin: PE_ARRAY_row

                Multi_add_unit u_Multi_add_unit(
                    .s_clk              ( s_clk                     ),
                    .s_rst              ( s_rst                     ),

                    .k_weight_valid     ( r_weight_valid[num]                                                                              ),
                    .kernel_weight      ( r_weight_array[`QUAN_BITS*(`PE_COL*j+i)+`QUAN_BITS-1: `QUAN_BITS*(`PE_COL*j+i)]                  ),

                    .f_data_valid       ( f_data_valid && o_data_ready                                                                     ),
                    .feature_data       ( w_feature_data_array[num]                                                                        ),
                    .shift_data         ( w_shift_data[num][`ADD9_ALL_BITS*(`PE_COL*j+i)+`ADD9_ALL_BITS-1 : `ADD9_ALL_BITS*(`PE_COL*j+i)]  ),
                    .o_mac_rlst_valid   ( w_mac_rlst_valid[num][`PE_COL*j+i]                                                               ),
                    .o_mac_rlst_out     ( w_mac_rlst_out[num][`ADD9_ALL_BITS*(`PE_COL*j+i)+`ADD9_ALL_BITS-1 : `ADD9_ALL_BITS*(`PE_COL*j+i)])
                );

            end
        end
    end
endgenerate

conv_layer1_bias_rom u_conv_layer1_bias_rom (
    .a          (r_chnnl_cnt[5:0]  ),
    .spo        (w_conv_bias       )
);

always@(*) begin

    case(s_curr_state)
        S_IDLE:             s_next_state = S_LOAD_WEIGHTS;
        S_LOAD_WEIGHTS:     s_next_state = r_load_weight_done ? S_CAL : S_LOAD_WEIGHTS;
        S_CAL:              s_next_state = o_load_d_once_done ? ((r_chnnl_cnt == `CONV1_KERNEL_CHNNLS - 1) ? S_DONE : S_IDLE) : S_CAL;
        S_DONE:             s_next_state = network_cal_done   ? S_IDLE : S_DONE;
        default:            s_next_state = S_IDLE;
    endcase

end

endmodule //conv_layer1
