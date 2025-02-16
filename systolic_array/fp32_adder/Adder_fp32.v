/*
    func : IEEE 754 pipelined float point 32 adder. 

    Ps:
        NaN / Infinity -> data[30:23] == 8'hFF 
*/

module Adder_fp32 (
    input                     s_clk               ,

    input                     i_data_valid        ,
    input  [31:0]             i_data1             ,
    input  [31:0]             i_data2             ,

    output                    o_data_valid        ,
    output [31:0]             o_data  
);

reg [31:0]             r_data1=0    ;
reg [31:0]             r_data2=0    ;

always@(posedge s_clk) begin
    if (i_data_valid) begin
        r_data1 <= i_data1;
        r_data2 <= i_data2;
    end
    else begin
        r_data1 <= r_data1;
        r_data2 <= r_data2;
    end
end

// --- wire ---
wire                w_state_flag0   ; // Check data (NaN or Infinity)
wire signed [9:0]   w_expo_data1_0  ;
wire signed [9:0]   w_expo_data2_0  ;
wire [25:0]         w_mant_data1_0  ;
wire [25:0]         w_mant_data2_0  ;

wire [7:0]          w_exponent_diff1;
wire [7:0]          w_exponent_diff2;

wire [25:0]         w_shift_out1    ;
wire [25:0]         w_shift_out2    ;

// --- reg ---
reg [5:0]           r_data_valid_dly;

reg                 r_state_flag1=0 ;
reg                 r_state_flag2=0 ;
reg                 r_state_flag3=0 ;
reg                 r_state_flag4=0 ;

reg         [25:0]  r_mant_max_1=0  ;
reg signed  [9:0]   r_expo_max_1=0  ;
reg                 r_sign_max_1=0  ;

reg         [25:0]  r_mant_min_1=0  ;
reg                 r_sign_min_1=0  ;

reg         [25:0]  r_mant_2=0      ;
reg signed  [9:0]   r_expo_2=0      ;
reg                 r_sign_2=0      ;

reg         [25:0]  r_mant_3=0      ;
reg signed  [9:0]   r_expo_3=0      ;
reg                 r_sign_3=0      ;

reg         [25:0]  r_mant_4=0      ;
reg signed  [9:0]   r_expo_4=0      ;
reg                 r_sign_4=0      ;

reg         [25:0]  r_mant_5=0      ;
reg signed  [9:0]   r_expo_5=0      ;
reg                 r_sign_5=0      ;

// -- cal exp
assign w_state_flag0  = (r_data1[30:23] == 8'hff) | (r_data2[30:23] == 8'hff);

assign w_expo_data1_0 = (r_data1[30:23] == 8'h00) ? -127 : (r_data1[30:23] - 127);
assign w_expo_data2_0 = (r_data2[30:23] == 8'h00) ? -127 : (r_data2[30:23] - 127);

// -- Mantissa cal (fraction proc
assign w_mant_data1_0 = (r_data1[30:23] == 8'h00) ? {1'b0, r_data1[22:0], 2'b0} : {2'b01, r_data1[22:0], 1'b0};
assign w_mant_data2_0 = (r_data2[30:23] == 8'h00) ? {1'b0, r_data2[22:0], 2'b0} : {2'b01, r_data2[22:0], 1'b0};

assign w_exponent_diff1 = r_data2[30:23] - r_data1[30:23];
assign w_exponent_diff2 = r_data1[30:23] - r_data2[30:23];

// out 
assign o_data[31]     = r_sign_5            ;
assign o_data[30:23]  = r_expo_5[7:0]       ;
assign o_data[22:0]   = r_mant_5[23:1]      ;
assign o_data_valid   = r_data_valid_dly[5] ;

always@(posedge s_clk) begin
    r_state_flag1 <= w_state_flag0;
    r_state_flag2 <= r_state_flag1;
    r_state_flag3 <= r_state_flag2;
    r_state_flag4 <= r_state_flag3;
end

genvar k;
generate

    for (k = 0; k < 6; k = k + 1) begin
        if (k == 0) begin

            always@(posedge s_clk) begin
                r_data_valid_dly[k] <= i_data_valid;
            end

        end else begin

            always@(posedge s_clk) begin
                r_data_valid_dly[k] <= r_data_valid_dly[k - 1];
            end

        end
    end

endgenerate

// ---------- stage-1 ---------- \\
always@(posedge s_clk) begin
    if (r_data1[30:23] == r_data2[30:23]) begin
        if (w_mant_data1_0 > w_mant_data2_0) begin
            r_mant_max_1 <= w_mant_data1_0;
            r_expo_max_1 <= w_expo_data1_0;
            r_sign_max_1 <= r_data1[31];

            r_mant_min_1 <= w_mant_data2_0;
            r_sign_min_1 <= r_data2[31];
        end
        else begin
            r_mant_max_1 <= w_mant_data2_0;
            r_expo_max_1 <= w_expo_data2_0;
            r_sign_max_1 <= r_data2[31];

            r_mant_min_1 <= w_mant_data1_0;
            r_sign_min_1 <= r_data1[31];
        end
    end
    else if (r_data1[30:23] > r_data2[30:23]) begin
        r_mant_max_1 <= w_mant_data1_0;
        r_expo_max_1 <= w_expo_data1_0;
        r_sign_max_1 <= r_data1[31];

        r_mant_min_1 <= w_shift_out2;
        r_sign_min_1 <= r_data2[31];
    end
    else begin
        r_mant_max_1 <= w_mant_data2_0;
        r_expo_max_1 <= w_expo_data2_0;
        r_sign_max_1 <= r_data2[31];

        r_mant_min_1 <= w_shift_out1;
        r_sign_min_1 <= r_data1[31];
    end
end

// ---------- stage-2 ---------- \\
always@(posedge s_clk) begin
    if (r_sign_max_1 == r_sign_min_1) begin
        r_mant_2  <= r_mant_max_1 + r_mant_min_1;
        r_expo_2  <= r_expo_max_1;
        r_sign_2  <= r_sign_max_1;
    end
    else begin
        r_mant_2  <= r_mant_max_1 - r_mant_min_1;
        r_expo_2  <= r_expo_max_1;
        r_sign_2  <= r_sign_max_1;
    end
end

// ---------- stage-3 ---------- \\
always @(posedge s_clk) begin
    if (r_mant_2[25:13] != 13'h0) begin
        r_mant_3 <= r_mant_2;
        r_expo_3 <= r_expo_2;
        r_sign_3 <= r_sign_2;
    end
    else if (r_mant_2[12:0] != 13'h0) begin
        r_mant_3 <= r_mant_2 << 13;
        r_expo_3 <= r_expo_2 - 13;
        r_sign_3 <= r_sign_2;
    end
    else begin
        r_mant_3 <= 26'h0;
        r_expo_3 <= 0;
        r_sign_3 <= 0;
    end
end

// ---------- stage-4 ---------- \\
always @(posedge s_clk) begin
    if (r_mant_3[25]) begin
        r_mant_4  <= r_mant_3 >> 1;
        r_expo_4  <= r_expo_3 + 1;
        r_sign_4  <= r_sign_3;
    end
    else if (r_mant_3[24]) begin
        r_mant_4  <= r_mant_3;
        r_expo_4  <= r_expo_3;
        r_sign_4  <= r_sign_3;
    end
    else if (r_mant_3[23]) begin
        r_mant_4  <= r_mant_3 << 1;
        r_expo_4  <= r_expo_3 - 1;
        r_sign_4  <= r_sign_3;
    end
    else if (r_mant_3[22]) begin
        r_mant_4  <= r_mant_3 << 2;
        r_expo_4  <= r_expo_3 - 2;
        r_sign_4  <= r_sign_3;
    end
    else if (r_mant_3[21]) begin
        r_mant_4  <= r_mant_3 << 3;
        r_expo_4  <= r_expo_3 - 3;
        r_sign_4  <= r_sign_3;
    end
    else if (r_mant_3[20]) begin
        r_mant_4  <= r_mant_3 << 4;
        r_expo_4  <= r_expo_3 - 4;
        r_sign_4  <= r_sign_3;
    end
    else if (r_mant_3[19]) begin
        r_mant_4  <= r_mant_3 << 5;
        r_expo_4  <= r_expo_3 - 5;
        r_sign_4  <= r_sign_3;
    end
    else if (r_mant_3[18]) begin
        r_mant_4  <= r_mant_3 << 6;
        r_expo_4  <= r_expo_3 - 6;
        r_sign_4  <= r_sign_3;
    end
    else if (r_mant_3[17]) begin
        r_mant_4  <= r_mant_3 << 7;
        r_expo_4  <= r_expo_3 - 7;
        r_sign_4  <= r_sign_3;
    end
    else if (r_mant_3[16]) begin
        r_mant_4  <= r_mant_3 << 8;
        r_expo_4  <= r_expo_3 - 8;
        r_sign_4  <= r_sign_3;
    end
    else if (r_mant_3[15]) begin
        r_mant_4  <= r_mant_3 << 9;
        r_expo_4  <= r_expo_3 - 9;
        r_sign_4  <= r_sign_3;
    end
    else if (r_mant_3[14]) begin
        r_mant_4  <= r_mant_3 << 10;
        r_expo_4  <= r_expo_3 - 10;
        r_sign_4  <= r_sign_3;
    end
    else if (r_mant_3[13]) begin
        r_mant_4  <= r_mant_3 << 11;
        r_expo_4  <= r_expo_3 - 11;
        r_sign_4  <= r_sign_3;
    end
    else begin
        r_mant_4  <= r_mant_3;
        r_expo_4  <= -127;
        r_sign_4  <= r_sign_3;
    end
end

// ---------- stage-5 ---------- \\
always @(posedge s_clk) begin
    if (r_state_flag4) begin
        r_expo_5 <= 8'b11111111;
        r_mant_5 <= 26'h0;
        r_sign_5 <= r_sign_4;
    end
    else if (r_expo_4 > 127)begin
        r_expo_5 <= 8'b11111111;
        r_mant_5 <= 26'h0;
        r_sign_5 <= r_sign_4;
    end
    else if (r_expo_4 < -126)begin
        r_expo_5 <= 9'h0;
        r_mant_5 <= r_mant_4 >> (-126 - r_expo_4);
        r_sign_5 <= r_sign_4;
    end
    else begin
        r_expo_5 <= r_expo_4 + 127;
        r_mant_5 <= r_mant_4;
        r_sign_5 <= r_sign_4;
    end
end

variable_shift u_shift_m00(
    .i_num_shifts  ( w_exponent_diff2   ),
    .i_TargetData  ( w_mant_data2_0     ),
    .o_data_out    ( w_shift_out2       )
);

variable_shift u_shift_m01(
    .i_num_shifts  ( w_exponent_diff1   ),
    .i_TargetData  ( w_mant_data1_0     ),
    .o_data_out    ( w_shift_out1       )
);

// // debug wire
// wire [7:0]   exponent_data1 = i_data1[30:23];
// wire [22:0]  mantissa_data1 = i_data1[22:0];
// wire [7:0]   exponent_data2 = i_data2[30:23];
// wire [22:0]  mantissa_data2 = i_data2[22:0];

// wire [7:0]   exponent_out1 = o_data[30:23];
// wire [22:0]  mantissa_out1 = o_data[22:0];

endmodule // fp32_adder
