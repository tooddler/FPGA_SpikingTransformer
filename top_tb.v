/*
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/
`timescale 1ns / 1ps

`include "hyper_para.v"
module top_tb ();

reg         s_clk                   ;
reg         s_rst                   ;
reg         r_cal_data_done_r0=0    ;
reg         r_cal_data_done_r1=0    ;
reg         r_cal_data_done_r2=0    ;
initial s_clk = 1'b1;
always #(`CLK_PERIOD/2) s_clk = ~s_clk;

initial begin
    s_rst = 1'b1;
    # 201;
    s_rst = 1'b0;
    # 400;
    # 4000;
//    $stop;
end

wire [`DATA_WIDTH- 1 : 0]           r00_burst_read_data   ;    
wire [`ADDR_SIZE - 1 : 0]           r00_burst_read_addr   ;    
wire [`LEN_WIDTH - 1 : 0]           r00_burst_read_len    ;    
wire                                r00_burst_read_req    ;     
wire                                r00_burst_read_valid  ;   
wire                                r00_burst_read_finish ;

wire [`DATA_WIDTH- 1 : 0]           r01_burst_read_data   ;    
wire [`ADDR_SIZE - 1 : 0]           r01_burst_read_addr   ;    
wire [`LEN_WIDTH - 1 : 0]           r01_burst_read_len    ;    
wire                                r01_burst_read_req    ;     
wire                                r01_burst_read_valid  ;   
wire                                r01_burst_read_finish ;

wire  [`DATA_WIDTH- 1 : 0]          burst_write_data      ;  
wire  [`ADDR_SIZE - 1 : 0]          burst_write_addr      ;  
wire  [`LEN_WIDTH - 1 : 0]          burst_write_len       ;  
wire                                burst_write_req       ;   
wire                                burst_write_valid     ; 
wire                                burst_write_finish    ;

wire [`DATA_WIDTH- 1 : 0]           burst_read_data       ;   
wire [`ADDR_SIZE - 1 : 0]           burst_read_addr       ;   
wire [`LEN_WIDTH - 1 : 0]           burst_read_len        ;   
wire                                burst_read_req        ;    
wire                                burst_read_valid      ;  
wire                                burst_read_finish     ;

wire [`DATA_WIDTH - 1 : 0]          o_weight_out          ;
wire                                o_weight_valid        ;
wire                                weight_ready          ;
wire                                load_w_finish         ;

wire  [`QUAN_BITS - 1 : 0]          o_feature_data_ch0    ;
wire  [`QUAN_BITS - 1 : 0]          o_feature_data_ch1    ;
wire  [`QUAN_BITS - 1 : 0]          o_feature_data_ch2    ;
wire                                o_f_data_valid        ;
wire                                data_ready            ;
wire                                data_load_done        ;
wire                                o_load_d_once_done    ;

wire  [`ADD9_ALL_BITS - 1 : 0]      o_conv1_out           ;
wire                                o_conv1_out_valid     ;

ddr_sim u_ddr_sim(
    .user_clk            ( s_clk               ),
    .user_rst            ( s_rst               ),

    .burst_write_data    ( burst_write_data    ),
    .burst_write_addr    ( burst_write_addr    ),
    .burst_write_len     ( burst_write_len     ),
    .burst_write_req     ( burst_write_req     ),
    .burst_write_valid   ( burst_write_valid   ),
    .burst_write_finish  ( burst_write_finish  ),

    .burst_read_data     ( burst_read_data     ),
    .burst_read_addr     ( burst_read_addr     ),
    .burst_read_len      ( burst_read_len      ),
    .burst_read_req      ( burst_read_req      ),
    .burst_read_valid    ( burst_read_valid    ),
    .burst_read_finish   ( burst_read_finish   )
);

round_robin_arb u_round_robin_arb(
    .ddr_clk                 ( s_clk                   ),
    .ddr_rstn                ( ~s_rst                  ),

    .w00_burst_write_data    ( 'd0   ),
    .w00_burst_write_addr    ( 'd0   ),
    .w00_burst_write_len     ( 'd0   ),
    .w00_burst_write_req     ( 1'b0  ),
    .w00_burst_write_valid   (   ),
    .w00_burst_write_finish  (   ),
    
    .r00_burst_read_data     ( r00_burst_read_data      ),
    .r00_burst_read_addr     ( r00_burst_read_addr      ),
    .r00_burst_read_len      ( r00_burst_read_len       ),
    .r00_burst_read_req      ( r00_burst_read_req       ),
    .r00_burst_read_valid    ( r00_burst_read_valid     ),
    .r00_burst_read_finish   ( r00_burst_read_finish    ),
    
    .w01_burst_write_data    ( 'd0   ),
    .w01_burst_write_addr    ( 'd0   ),
    .w01_burst_write_len     ( 'd0   ),
    .w01_burst_write_req     ( 1'b0  ),
    .w01_burst_write_valid   (   ),
    .w01_burst_write_finish  (   ),
    
    .r01_burst_read_data     ( r01_burst_read_data     ),
    .r01_burst_read_addr     ( r01_burst_read_addr     ),
    .r01_burst_read_len      ( r01_burst_read_len      ),
    .r01_burst_read_req      ( r01_burst_read_req      ),
    .r01_burst_read_valid    ( r01_burst_read_valid    ),
    .r01_burst_read_finish   ( r01_burst_read_finish   ),
    
    .w02_burst_write_data    ( 'd0  ),
    .w02_burst_write_addr    ( 'd0  ),
    .w02_burst_write_len     ( 'd0  ),
    .w02_burst_write_req     ( 1'b0 ),
    .w02_burst_write_valid   (  ),
    .w02_burst_write_finish  (  ),
    
    .r02_burst_read_data     (  ),
    .r02_burst_read_addr     ( 'd0  ),
    .r02_burst_read_len      ( 'd0  ),
    .r02_burst_read_req      ( 1'b0 ),
    .r02_burst_read_valid    (  ),
    .r02_burst_read_finish   (  ),
    
    .w03_burst_write_data    ( 'd0  ),
    .w03_burst_write_addr    ( 'd0  ),
    .w03_burst_write_len     ( 'd0  ),
    .w03_burst_write_req     ( 1'b0 ),
    .w03_burst_write_valid   (  ),
    .w03_burst_write_finish  (  ),
    
    .r03_burst_read_data     (  ),
    .r03_burst_read_addr     ( 'd0  ),
    .r03_burst_read_len      ( 'd0  ),
    .r03_burst_read_req      ( 1'b0 ),
    .r03_burst_read_valid    (  ),
    .r03_burst_read_finish   (  ),

    .wr_burst_data           ( burst_write_data        ), 
    .wr_burst_addr           ( burst_write_addr        ), 
    .wr_burst_len            ( burst_write_len         ), 
    .wr_burst_req            ( burst_write_req         ), 
    .wr_burst_data_req       ( burst_write_valid       ), 
    .wr_burst_finish         ( burst_write_finish      ), 
    
    .rd_burst_data           ( burst_read_data         ), 
    .rd_burst_addr           ( burst_read_addr         ), 
    .rd_burst_len            ( burst_read_len          ), 
    .rd_burst_req            ( burst_read_req          ), 
    .rd_burst_data_valid     ( burst_read_valid        ), 
    .rd_burst_finish         ( burst_read_finish       )  
);


features_ram_v1 u_features_ram_v1(
    .s_clk               ( s_clk                ),
    .s_rst               ( s_rst                ),

    .rd_burst_data       ( r00_burst_read_data  ),
    .rd_burst_addr       ( r00_burst_read_addr  ),
    .rd_burst_len        ( r00_burst_read_len   ),
    .rd_burst_req        ( r00_burst_read_req   ),
    .rd_burst_valid      ( r00_burst_read_valid ),
    .rd_burst_finish     ( r00_burst_read_finish),

    .o_feature_data_ch0  ( o_feature_data_ch0   ),
    .o_feature_data_ch1  ( o_feature_data_ch1   ),
    .o_feature_data_ch2  ( o_feature_data_ch2   ),
    .o_f_data_valid      ( o_f_data_valid       ),
    .data_ready          ( data_ready           ),
    .load_d_once_done    ( o_load_d_once_done   ),
    .data_load_done      ( data_load_done       )
);

weights_ram u_weights_ram(
    .s_clk               ( s_clk                 ),
    .s_rst               ( s_rst                 ),

    .rd_burst_data       ( r01_burst_read_data   ),
    .rd_burst_addr       ( r01_burst_read_addr   ),
    .rd_burst_len        ( r01_burst_read_len    ),
    .rd_burst_req        ( r01_burst_read_req    ),
    .rd_burst_valid      ( r01_burst_read_valid  ),
    .rd_burst_finish     ( r01_burst_read_finish ),

    .o_weight_out        ( o_weight_out          ),
    .o_weight_valid      ( o_weight_valid        ),
    .weight_ready        ( weight_ready          ),
    .load_w_finish       ( load_w_finish         )
);

conv_layer1 u_conv_layer1(
    .s_clk              ( s_clk              ),
    .s_rst              ( s_rst              ),

    .network_cal_done   ( 1'b0               ),

    .feature_data_ch0   ( o_feature_data_ch0 ),
    .feature_data_ch1   ( o_feature_data_ch1 ),
    .feature_data_ch2   ( o_feature_data_ch2 ),
    .f_data_valid       ( o_f_data_valid     ),
    .o_data_ready       ( data_ready         ),
    .o_load_d_finish    ( data_load_done     ),
    .o_load_d_once_done ( o_load_d_once_done ),
    
    .weight_in          ( o_weight_out       ),
    .weight_valid       ( o_weight_valid     ),
    .o_weight_ready     ( weight_ready       ),
    .o_load_w_finish    ( load_w_finish      ),
    
    .o_conv1_out        ( o_conv1_out        ),
    .o_conv1_out_valid  ( o_conv1_out_valid  )
);

parameter conv1_out_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/conv1_out.txt";
parameter data_img_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/data_img_out.txt";

integer file, file1;
initial begin
    file = $fopen(conv1_out_path, "w");
    file1 = $fopen(data_img_path, "w");
end

always@(posedge s_clk) begin
    if (r_cal_data_done_r2 && u_conv_layer1.s_curr_state == u_conv_layer1.S_DONE) begin
        $display("conv cal done");
        $fclose(file);
    end
    else if (o_conv1_out_valid) // u_conv_layer1.w_debug_valid o_conv1_out_valid
        $fwrite(file, "%d\n", $signed(o_conv1_out)); //u_conv_layer1.r_conv1_out o_conv1_out
end

always@(posedge s_clk) begin
    r_cal_data_done_r0 <= u_conv_layer1.r_cal_data_done ;
    r_cal_data_done_r1 <= r_cal_data_done_r0            ;
    r_cal_data_done_r2 <= r_cal_data_done_r1            ;

    if (r_cal_data_done_r2 && u_conv_layer1.r_chnnl_cnt == 2) begin
        $display("write features done");
        $fclose(file1);
    end
    if (o_f_data_valid && data_ready && u_conv_layer1.r_chnnl_cnt == 1) begin
        $fwrite(file1, "%d\n", $signed(o_feature_data_ch0));
        $fwrite(file1, "%d\n", $signed(o_feature_data_ch1));
        $fwrite(file1, "%d\n", $signed(o_feature_data_ch2));
    end
end

endmodule // top
