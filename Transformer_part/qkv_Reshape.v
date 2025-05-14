/*
    --- QKV MATRIX RESHAPE --- 
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "../hyper_para.v"
module qkv_Reshape (
    input                                                       s_clk                ,
    input                                                       s_rst                , 
    // input Spikes
    input       [`TIME_STEPS - 1 : 0]                           i00_spikes_out       ,
    input                                                       i00_spikes_valid     ,   
    input       [`TIME_STEPS - 1 : 0]                           i01_spikes_out       ,
    input                                                       i01_spikes_valid     ,  
    input       [`TIME_STEPS - 1 : 0]                           i02_spikes_out       ,
    input                                                       i02_spikes_valid     ,
    // output SpikesArray
    output reg  [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]      o00_spikesLine_out   ,
    output reg                                                  o00_spikesLine_valid ,
    output reg  [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]      o01_spikesLine_out   ,
    output reg                                                  o01_spikesLine_valid ,
    output reg  [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]      o02_spikesLine_out   ,
    output reg                                                  o02_spikesLine_valid   
);

wire                                             w00_fifo_full              ;
wire                                             w00_fifo_empty             ;
wire                                             w01_fifo_full              ;
wire                                             w01_fifo_empty             ;
wire                                             w02_fifo_full              ;
wire                                             w02_fifo_empty             ;

wire [`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]    w00_linedata               ;
wire [`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]    w01_linedata               ;
wire [`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]    w02_linedata               ;

wire [`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]    w00_fifodata_out           ;
wire [`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]    w01_fifodata_out           ;
wire [`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]    w02_fifodata_out           ;

reg  [`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]    r00_spikes_register        ; // 64
reg  [`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]    r01_spikes_register        ;
reg  [`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]    r02_spikes_register        ;
reg  [$clog2(`SYSTOLIC_UNIT_NUM) - 1 : 0]        r00_ifmap_cnt              ;
reg  [$clog2(`SYSTOLIC_UNIT_NUM) - 1 : 0]        r01_ifmap_cnt              ;
reg  [$clog2(`SYSTOLIC_UNIT_NUM) - 1 : 0]        r02_ifmap_cnt              ;

reg                                              r00_line_data_valid        ;
reg                                              r01_line_data_valid        ;
reg                                              r02_line_data_valid        ;

reg  [2 : 0]                                     r_ReshapeFIFO_Flag         ;
reg  [2 : 0]                                     r00_spikes_valid_delay     ;       
reg  [2 : 0]                                     r01_spikes_valid_delay     ;       
reg  [2 : 0]                                     r02_spikes_valid_delay     ;       

assign w00_linedata = r00_spikes_register ;
assign w01_linedata = r01_spikes_register ;
assign w02_linedata = r02_spikes_register ;

genvar k00;
generate
    // spikes_register
    always@(posedge s_clk, posedge s_rst) begin
        if (s_rst)
            r00_spikes_register[`TIME_STEPS - 1 : 0] <= 'd0;
        else if (i00_spikes_valid && r00_ifmap_cnt == 'd0)
            r00_spikes_register[`TIME_STEPS - 1 : 0] <= i00_spikes_out;
    end

    for (k00 = 1; k00 < `SYSTOLIC_UNIT_NUM; k00 = k00 + 1) begin :  spikes_register_array00
        always@(posedge s_clk, posedge s_rst) begin
            if (s_rst)
                r00_spikes_register[(k00+1)*`TIME_STEPS - 1 : k00*`TIME_STEPS] <= 'd0;
            else if (i00_spikes_valid && r00_ifmap_cnt == 'd0)
                r00_spikes_register[(k00+1)*`TIME_STEPS - 1 : k00*`TIME_STEPS] <= 'd0;
            else if (i00_spikes_valid && r00_ifmap_cnt == k00)
                r00_spikes_register[(k00+1)*`TIME_STEPS - 1 : k00*`TIME_STEPS] <= i00_spikes_out;
        end
    end
endgenerate

genvar k01;
generate
    // spikes_register
    always@(posedge s_clk, posedge s_rst) begin
        if (s_rst)
            r01_spikes_register[`TIME_STEPS - 1 : 0] <= 'd0;
        else if (i01_spikes_valid && r01_ifmap_cnt == 'd0)
            r01_spikes_register[`TIME_STEPS - 1 : 0] <= i01_spikes_out;
    end

    for (k01 = 1; k01 < `SYSTOLIC_UNIT_NUM; k01 = k01 + 1) begin :  spikes_register_array01
        always@(posedge s_clk, posedge s_rst) begin
            if (s_rst)
                r01_spikes_register[(k01+1)*`TIME_STEPS - 1 : k01*`TIME_STEPS] <= 'd0;
            else if (i01_spikes_valid && r01_ifmap_cnt == 'd0)
                r01_spikes_register[(k01+1)*`TIME_STEPS - 1 : k01*`TIME_STEPS] <= 'd0;
            else if (i01_spikes_valid && r01_ifmap_cnt == k01)
                r01_spikes_register[(k01+1)*`TIME_STEPS - 1 : k01*`TIME_STEPS] <= i01_spikes_out;
        end
    end
endgenerate

genvar k02;
generate
    // spikes_register
    always@(posedge s_clk, posedge s_rst) begin
        if (s_rst)
            r02_spikes_register[`TIME_STEPS - 1 : 0] <= 'd0;
        else if (i02_spikes_valid && r02_ifmap_cnt == 'd0)
            r02_spikes_register[`TIME_STEPS - 1 : 0] <= i02_spikes_out;
    end

    for (k02 = 1; k02 < `SYSTOLIC_UNIT_NUM; k02 = k02 + 1) begin :  spikes_register_array02
        always@(posedge s_clk, posedge s_rst) begin
            if (s_rst)
                r02_spikes_register[(k02+1)*`TIME_STEPS - 1 : k02*`TIME_STEPS] <= 'd0;
            else if (i02_spikes_valid && r02_ifmap_cnt == 'd0)
                r02_spikes_register[(k02+1)*`TIME_STEPS - 1 : k02*`TIME_STEPS] <= 'd0;
            else if (i02_spikes_valid && r02_ifmap_cnt == k02)
                r02_spikes_register[(k02+1)*`TIME_STEPS - 1 : k02*`TIME_STEPS] <= i02_spikes_out;
        end
    end
endgenerate

// r00_ifmap_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r00_ifmap_cnt <= 'd0;
    // else if (r00_ifmap_cnt == 4'hF && i00_spikes_valid)
    //     r00_ifmap_cnt <= 'd0;
    else if (i00_spikes_valid)
        r00_ifmap_cnt <= r00_ifmap_cnt + 1'b1;
end

// r00_line_data_valid
always@(posedge s_clk) begin
    if (r00_ifmap_cnt == 4'hF && i00_spikes_valid)
        r00_line_data_valid <= 1'b1;
    else
        r00_line_data_valid <= 1'b0;
end

// r01_ifmap_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r01_ifmap_cnt <= 'd0;
    // else if (r01_ifmap_cnt == 4'hF && i01_spikes_valid)
    //     r01_ifmap_cnt <= 'd0;
    else if (i01_spikes_valid)
        r01_ifmap_cnt <= r01_ifmap_cnt + 1'b1;
end

// r01_line_data_valid
always@(posedge s_clk) begin
    if (r01_ifmap_cnt == 4'hF && i01_spikes_valid)
        r01_line_data_valid <= 1'b1;
    else
        r01_line_data_valid <= 1'b0;
end

// r02_ifmap_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r02_ifmap_cnt <= 'd0;
    // else if (r02_ifmap_cnt == 4'hF && i02_spikes_valid)
    //     r02_ifmap_cnt <= 'd0;
    else if (i02_spikes_valid)
        r02_ifmap_cnt <= r02_ifmap_cnt + 1'b1;
end

// r02_line_data_valid
always@(posedge s_clk) begin
    if (r02_ifmap_cnt == 4'hF && i02_spikes_valid)
        r02_line_data_valid <= 1'b1;
    else
        r02_line_data_valid <= 1'b0;
end

// --------------- Reshape Proc --------------- \\ 
always@(posedge s_clk) begin
    r00_spikes_valid_delay <= {r00_spikes_valid_delay[1 : 0], i00_spikes_valid};
    r01_spikes_valid_delay <= {r01_spikes_valid_delay[1 : 0], i01_spikes_valid};
    r02_spikes_valid_delay <= {r02_spikes_valid_delay[1 : 0], i02_spikes_valid};
end

// r_ReshapeFIFO_Flag
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_ReshapeFIFO_Flag[0] <= 1'b0;
    else if (r00_spikes_valid_delay[2] && ~r00_spikes_valid_delay[1])
        r_ReshapeFIFO_Flag[0] <= ~r_ReshapeFIFO_Flag[0];
end

always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_ReshapeFIFO_Flag[1] <= 1'b0;
    else if (r01_spikes_valid_delay[2] && ~r01_spikes_valid_delay[1])
        r_ReshapeFIFO_Flag[1] <= ~r_ReshapeFIFO_Flag[1];
end

always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_ReshapeFIFO_Flag[2] <= 1'b0;
    else if (r02_spikes_valid_delay[2] && ~r02_spikes_valid_delay[1])
        r_ReshapeFIFO_Flag[2] <= ~r_ReshapeFIFO_Flag[2];
end

// --------------- Output Proc --------------- \\ 
// o00_spikesLine_out  o00_spikesLine_valid
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) begin
        o00_spikesLine_out   <= 'd0;
        o00_spikesLine_valid <= 1'b0;
    end
    else if (r00_line_data_valid && r_ReshapeFIFO_Flag[0]) begin
        o00_spikesLine_out   <= {w00_linedata, w00_fifodata_out};
        o00_spikesLine_valid <= 1'b1;
    end
    else begin
        o00_spikesLine_out   <= o00_spikesLine_out;
        o00_spikesLine_valid <= 1'b0;
    end
end

// o01_spikesLine_out  o01_spikesLine_valid
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) begin
        o01_spikesLine_out   <= 'd0;
        o01_spikesLine_valid <= 1'b0;
    end
    else if (r01_line_data_valid && r_ReshapeFIFO_Flag[1]) begin
        o01_spikesLine_out   <= {w01_linedata, w01_fifodata_out};
        o01_spikesLine_valid <= 1'b1;
    end
    else begin
        o01_spikesLine_out   <= o01_spikesLine_out;
        o01_spikesLine_valid <= 1'b0;
    end
end

// o02_spikesLine_out  o02_spikesLine_valid
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)begin
        o02_spikesLine_out   <= 'd0;
        o02_spikesLine_valid <= 1'b0;
    end
    else if (r02_line_data_valid && r_ReshapeFIFO_Flag[2]) begin
        o02_spikesLine_out   <= {w02_linedata, w02_fifodata_out};
        o02_spikesLine_valid <= 1'b1;
    end
    else begin
        o02_spikesLine_out   <= o02_spikesLine_out;
        o02_spikesLine_valid <= 1'b0;
    end
end

// --------------- Reshape FIFO --------------- \\ 
qkv_ReshapeFIFO M00_qkv_ReshapeFIFO (
    .clk            ( s_clk                                         ),
    .srst           ( s_rst                                         ),
    .din            ( w00_linedata                                  ), // [63 : 0] din
    .wr_en          ( r00_line_data_valid && ~r_ReshapeFIFO_Flag[0] ), 
    .rd_en          ( r00_line_data_valid && r_ReshapeFIFO_Flag[0]  ), 
    .dout           ( w00_fifodata_out                              ), // [63 : 0] dout
    .full           ( w00_fifo_full                                 ), 
    .empty          ( w00_fifo_empty                                )  
);

qkv_ReshapeFIFO M01_qkv_ReshapeFIFO (
    .clk            ( s_clk                                         ),
    .srst           ( s_rst                                         ),
    .din            ( w01_linedata                                  ), // [63 : 0] din
    .wr_en          ( r01_line_data_valid && ~r_ReshapeFIFO_Flag[1] ), 
    .rd_en          ( r01_line_data_valid && r_ReshapeFIFO_Flag[1]  ), 
    .dout           ( w01_fifodata_out                              ), // [63 : 0] dout
    .full           ( w01_fifo_full                                 ), 
    .empty          ( w01_fifo_empty                                )  
);

qkv_ReshapeFIFO M02_qkv_ReshapeFIFO (
    .clk            ( s_clk                                         ),
    .srst           ( s_rst                                         ),
    .din            ( w02_linedata                                  ), // [63 : 0] din
    .wr_en          ( r02_line_data_valid && ~r_ReshapeFIFO_Flag[2] ), 
    .rd_en          ( r02_line_data_valid && r_ReshapeFIFO_Flag[2]  ), 
    .dout           ( w02_fifodata_out                              ), // [63 : 0] dout
    .full           ( w02_fifo_full                                 ), 
    .empty          ( w02_fifo_empty                                )  
);

endmodule // qkv_Reshape
