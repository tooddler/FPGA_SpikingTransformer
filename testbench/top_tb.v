/*
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/
`timescale 1ns / 1ps

`include "E:/Desktop/Zynq_Spikformer/Zynq_Spikformer.srcs/sources_1/hyper_para.v"
module TOP_tb ();

reg         s_clk                   ;
reg         s_rst                   ;
reg         sps_conv2_flag          ;
reg         sps_conv3_flag          ;
reg         sps_conv4_flag          ;

reg         sps_mp_flag             ;

initial s_clk = 1'b1;
always #(`CLK_PERIOD/2) s_clk = ~s_clk;
initial begin
    s_rst = 1'b1;
    # 201;
    s_rst = 1'b0;
    # 400;
end

wire [`DATA_WIDTH- 1 : 0]                     burst_read_data            ;   
wire [`ADDR_SIZE - 1 : 0]                     burst_read_addr            ;   
wire [`LEN_WIDTH - 1 : 0]                     burst_read_len             ;   
wire                                          burst_read_req             ;    
wire                                          burst_read_valid           ;  
wire                                          burst_read_finish          ;

wire     [`DATA_WIDTH - 1 : 0]                w_Eyeriss_weight_in        ;
wire                                          w_Eyeriss_weight_valid     ;
wire                                          w_Eyeriss_weight_ready     ;

wire                                          w_SpikingEncoder_out_done  ;
wire     [`TIME_STEPS - 1 : 0]                w_SpikingEncoder_out       ;
wire                                          w_SpikingEncoder_out_valid ;

wire                                          w_data_valid               ;
wire     [`PATCH_EMBED_WIDTH - 1 : 0]         w_fmap                     ;
wire     [`PATCH_EMBED_WIDTH - 1 : 0]         w_patchdata                ;

wire     [`DATA_WIDTH- 1 : 0]                 M_lq_rd_burst_data         ;
wire     [`ADDR_SIZE - 1 : 0]                 M_lq_rd_burst_addr         ;
wire     [`LEN_WIDTH - 1 : 0]                 M_lq_rd_burst_len          ;
wire                                          M_lq_rd_burst_req          ;
wire                                          M_lq_rd_burst_valid        ;
wire                                          M_lq_rd_burst_finish       ;

wire     [`DATA_WIDTH- 1 : 0]                 M_lk_rd_burst_data         ;
wire     [`ADDR_SIZE - 1 : 0]                 M_lk_rd_burst_addr         ;
wire     [`LEN_WIDTH - 1 : 0]                 M_lk_rd_burst_len          ;
wire                                          M_lk_rd_burst_req          ;
wire                                          M_lk_rd_burst_valid        ;
wire                                          M_lk_rd_burst_finish       ;

wire     [`DATA_WIDTH- 1 : 0]                 M_lv_rd_burst_data         ;
wire     [`ADDR_SIZE - 1 : 0]                 M_lv_rd_burst_addr         ;
wire     [`LEN_WIDTH - 1 : 0]                 M_lv_rd_burst_len          ;
wire                                          M_lv_rd_burst_req          ;
wire                                          M_lv_rd_burst_valid        ;
wire                                          M_lv_rd_burst_finish       ;

// --------------- DDR --------------- \\ 
ddr_sim u_ddr_sim(
    .user_clk                       ( s_clk                                 ),
    .user_rst                       ( s_rst                                 ),

    .burst_write_data               ( 'd0  ),
    .burst_write_addr               ( 'd0  ),
    .burst_write_len                ( 'd0  ),
    .burst_write_req                ( 1'b0 ),
    .burst_write_valid              (      ),
    .burst_write_finish             (      ),

    .burst_read_data                ( burst_read_data                       ),
    .burst_read_addr                ( burst_read_addr                       ),
    .burst_read_len                 ( burst_read_len                        ),
    .burst_read_req                 ( burst_read_req                        ),
    .burst_read_valid               ( burst_read_valid                      ),
    .burst_read_finish              ( burst_read_finish                     )
);

// --------------- Arbiter --------------- \\ 
round_robin_arb u_round_robin_arb(
    .ddr_clk                 ( s_clk                   ),
    .ddr_rstn                ( ~s_rst                  ),

    .w00_burst_write_data    ( 'd0   ),
    .w00_burst_write_addr    ( 'd0   ),
    .w00_burst_write_len     ( 'd0   ),
    .w00_burst_write_req     ( 1'b0  ),
    .w00_burst_write_valid   (       ),
    .w00_burst_write_finish  (       ),

    .r00_burst_read_data     ( M_lq_rd_burst_data      ),
    .r00_burst_read_addr     ( M_lq_rd_burst_addr      ),
    .r00_burst_read_len      ( M_lq_rd_burst_len       ),
    .r00_burst_read_req      ( M_lq_rd_burst_req       ),
    .r00_burst_read_valid    ( M_lq_rd_burst_valid     ),
    .r00_burst_read_finish   ( M_lq_rd_burst_finish    ),
    
    .w01_burst_write_data    ( 'd0   ),
    .w01_burst_write_addr    ( 'd0   ),
    .w01_burst_write_len     ( 'd0   ),
    .w01_burst_write_req     ( 1'b0  ),
    .w01_burst_write_valid   (       ),
    .w01_burst_write_finish  (       ),
    
    .r01_burst_read_data     ( M_lk_rd_burst_data      ),
    .r01_burst_read_addr     ( M_lk_rd_burst_addr      ),
    .r01_burst_read_len      ( M_lk_rd_burst_len       ),
    .r01_burst_read_req      ( M_lk_rd_burst_req       ),
    .r01_burst_read_valid    ( M_lk_rd_burst_valid     ),
    .r01_burst_read_finish   ( M_lk_rd_burst_finish    ),
    
    .w02_burst_write_data    ( 'd0  ),
    .w02_burst_write_addr    ( 'd0  ),
    .w02_burst_write_len     ( 'd0  ),
    .w02_burst_write_req     ( 1'b0 ),
    .w02_burst_write_valid   (  ),
    .w02_burst_write_finish  (  ),
    
    .r02_burst_read_data     ( M_lv_rd_burst_data      ),
    .r02_burst_read_addr     ( M_lv_rd_burst_addr      ),
    .r02_burst_read_len      ( M_lv_rd_burst_len       ),
    .r02_burst_read_req      ( M_lv_rd_burst_req       ),
    .r02_burst_read_valid    ( M_lv_rd_burst_valid     ),
    .r02_burst_read_finish   ( M_lv_rd_burst_finish    ),
    
    .w03_burst_write_data    ( 'd0  ),
    .w03_burst_write_addr    ( 'd0  ),
    .w03_burst_write_len     ( 'd0  ),
    .w03_burst_write_req     ( 1'b0 ),
    .w03_burst_write_valid   (  ),
    .w03_burst_write_finish  (  ),
    
    .r03_burst_read_data     ( m00_burst_read_data      ),
    .r03_burst_read_addr     ( m00_burst_read_addr      ),
    .r03_burst_read_len      ( m00_burst_read_len       ),
    .r03_burst_read_req      ( m00_burst_read_req       ),
    .r03_burst_read_valid    ( m00_burst_read_valid     ),
    .r03_burst_read_finish   ( m00_burst_read_finish    ),

    .wr_burst_data           (    ), 
    .wr_burst_addr           (    ), 
    .wr_burst_len            (    ), 
    .wr_burst_req            (    ), 
    .wr_burst_data_req       ( 'd0), 
    .wr_burst_finish         ( 'd0), 
    
    .rd_burst_data           ( burst_read_data         ), 
    .rd_burst_addr           ( burst_read_addr         ), 
    .rd_burst_len            ( burst_read_len          ), 
    .rd_burst_req            ( burst_read_req          ), 
    .rd_burst_data_valid     ( burst_read_valid        ), 
    .rd_burst_finish         ( burst_read_finish       )  
);

// --------------- SpikingEncoder --------------- \\ 
SpikingEncoder u_SpikingEncoder(
    .s_clk                          ( s_clk                                 ),
    .s_rst                          ( s_rst                                 ),

    .network_cal_done               ( 1'b0                                  ),

    .burst_read_data                ( m00_burst_read_data                   ),
    .burst_read_addr                ( m00_burst_read_addr                   ),
    .burst_read_len                 ( m00_burst_read_len                    ),
    .burst_read_req                 ( m00_burst_read_req                    ),
    .burst_read_valid               ( m00_burst_read_valid                  ),
    .burst_read_finish              ( m00_burst_read_finish                 ),
    
    .Eyeriss_weight_in              ( w_Eyeriss_weight_in                   ),
    .Eyeriss_weight_valid           ( w_Eyeriss_weight_valid                ),
    .Eyeriss_weight_ready           ( w_Eyeriss_weight_ready                ),
    .i_weight_load_done             ( 1'b0                                  ),

    .o_SpikingEncoder_out_done      ( w_SpikingEncoder_out_done             ),
    .o_SpikingEncoder_out           ( w_SpikingEncoder_out                  ),
    .o_SpikingEncoder_out_valid     ( w_SpikingEncoder_out_valid            )
);

// --------------- Simple Eyeriss --------------- \\ 
simple_eyeriss_top u_simple_eyeriss_top(
    .s_clk                          ( s_clk                                 ),
    .s_rst                          ( s_rst                                 ),

    .SPS_part_done                  ( 1'b0                                  ),

    .weight_in                      ( w_Eyeriss_weight_in                   ),
    .weight_valid                   ( w_Eyeriss_weight_valid                ),
    .o_weight_ready                 ( w_Eyeriss_weight_ready                ),

    .SpikingEncoder_out_done        ( w_SpikingEncoder_out_done             ),
    .SpikingEncoder_out             ( w_SpikingEncoder_out                  ),
    .SpikingEncoder_out_valid       ( w_SpikingEncoder_out_valid            ),

    .o_data_valid                   ( w_data_valid                          ),
    .o_fmap                         ( w_fmap                                ),
    .o_patchdata                    ( w_patchdata                           )
);

// --------------- Transformer --------------- \\ 
TOP_Transformer u_TOP_Transformer(
    .s_clk                          ( s_clk                                 ),
    .s_rst                          ( s_rst                                 ),

    .i_load_w_finish                ( 1'b0                                  ),

    .i_data_valid                   ( w_data_valid                          ),
    .i_fmap                         ( w_fmap                                ),
    .i_patchdata                    ( w_patchdata                           ),

    .M_lq_rd_burst_data             ( M_lq_rd_burst_data                    ),
    .M_lq_rd_burst_addr             ( M_lq_rd_burst_addr                    ),
    .M_lq_rd_burst_len              ( M_lq_rd_burst_len                     ),
    .M_lq_rd_burst_req              ( M_lq_rd_burst_req                     ),
    .M_lq_rd_burst_valid            ( M_lq_rd_burst_valid                   ),
    .M_lq_rd_burst_finish           ( M_lq_rd_burst_finish                  ),

    .M_lk_rd_burst_data             ( M_lk_rd_burst_data                    ),
    .M_lk_rd_burst_addr             ( M_lk_rd_burst_addr                    ),
    .M_lk_rd_burst_len              ( M_lk_rd_burst_len                     ),
    .M_lk_rd_burst_req              ( M_lk_rd_burst_req                     ),
    .M_lk_rd_burst_valid            ( M_lk_rd_burst_valid                   ),
    .M_lk_rd_burst_finish           ( M_lk_rd_burst_finish                  ),

    .M_lv_rd_burst_data             ( M_lv_rd_burst_data                    ),
    .M_lv_rd_burst_addr             ( M_lv_rd_burst_addr                    ),
    .M_lv_rd_burst_len              ( M_lv_rd_burst_len                     ),
    .M_lv_rd_burst_req              ( M_lv_rd_burst_req                     ),
    .M_lv_rd_burst_valid            ( M_lv_rd_burst_valid                   ),
    .M_lv_rd_burst_finish           ( M_lv_rd_burst_finish                  )
);

parameter WORKSPACE_PATH = "E:/Desktop/FPGA_SpikingTransformer";

// --- FETCH DATA PART
parameter conv1_out_path = {WORKSPACE_PATH, "/data4fpga_bin/conv1_out.txt"};
parameter data_img_path = {WORKSPACE_PATH, "/data4fpga_bin/data_img_out.txt"};

reg  r_cal_data_done_r0=0;
reg  r_cal_data_done_r1=0;
reg  r_cal_data_done_r2=0;

integer file, file1;
initial begin
    file = $fopen(conv1_out_path, "w");
    file1 = $fopen(data_img_path, "w");
end 

always@(posedge s_clk) begin
    if (r_cal_data_done_r2 && u_SpikingEncoder.u_conv_layer1.s_curr_state == u_SpikingEncoder.u_conv_layer1.S_DONE) begin
        $display("INFO: conv cal done");
        $fclose(file);
    end
    else if (u_SpikingEncoder.o_conv1_out_valid) // u_conv_layer1.w_debug_valid o_conv1_out_valid
        $fwrite(file, "%d\n", $signed(u_SpikingEncoder.o_conv1_out)); //u_conv_layer1.r_conv1_out o_conv1_out
end

always@(posedge s_clk) begin
    r_cal_data_done_r0 <= u_SpikingEncoder.u_conv_layer1.r_cal_data_done ;
    r_cal_data_done_r1 <= r_cal_data_done_r0            ;
    r_cal_data_done_r2 <= r_cal_data_done_r1            ;

    if (r_cal_data_done_r2 && u_SpikingEncoder.u_conv_layer1.r_chnnl_cnt == 2) begin
        $display("INFO: write features done");
        $fclose(file1);
    end
    if (u_SpikingEncoder.o_f_data_valid && u_SpikingEncoder.data_ready && u_SpikingEncoder.u_conv_layer1.r_chnnl_cnt == 1) begin
        $fwrite(file1, "%d\n", $signed(u_SpikingEncoder.o_feature_data_ch0));
        $fwrite(file1, "%d\n", $signed(u_SpikingEncoder.o_feature_data_ch1));
        $fwrite(file1, "%d\n", $signed(u_SpikingEncoder.o_feature_data_ch2));
    end
end

parameter spiking0_out_path = {WORKSPACE_PATH, "/data4fpga_bin/spiking0_out_out.txt"};
parameter spiking1_out_path = {WORKSPACE_PATH, "/data4fpga_bin/spiking1_out_out.txt"};
parameter spiking2_out_path = {WORKSPACE_PATH, "/data4fpga_bin/spiking2_out_out.txt"};
parameter spiking3_out_path = {WORKSPACE_PATH, "/data4fpga_bin/spiking3_out_out.txt"};

integer spiking_file0, spiking_file1, spiking_file2, spiking_file3;
initial begin
    spiking_file0 = $fopen(spiking0_out_path, "w");
    spiking_file1 = $fopen(spiking1_out_path, "w");
    spiking_file2 = $fopen(spiking2_out_path, "w");
    spiking_file3 = $fopen(spiking3_out_path, "w");
end

always@(posedge s_clk) begin
    if (u_SpikingEncoder.o_SpikingEncoder_out_done) begin
        $display("INFO: spiking cal done");
        $fclose(spiking_file0);
        $fclose(spiking_file1);
        $fclose(spiking_file2);
        $fclose(spiking_file3);
    end
    else if (u_SpikingEncoder.o_SpikingEncoder_out_valid) begin
        $fwrite(spiking_file0, "%b\n", u_SpikingEncoder.o_SpikingEncoder_out[0]); 
        $fwrite(spiking_file1, "%b\n", u_SpikingEncoder.o_SpikingEncoder_out[1]); 
        $fwrite(spiking_file2, "%b\n", u_SpikingEncoder.o_SpikingEncoder_out[2]); 
        $fwrite(spiking_file3, "%b\n", u_SpikingEncoder.o_SpikingEncoder_out[3]); 
    end
end

// ======= SPS CONV1 PART =======
parameter sps_conv1_out_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_conv1_out_t0.txt"};
parameter sps_conv1_out_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_conv1_out_t1.txt"};
parameter sps_conv1_out_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_conv1_out_t2.txt"};
parameter sps_conv1_out_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_conv1_out_t3.txt"};

integer sps_file0, sps_file1, sps_file2, sps_file3;
initial begin
    sps_file0 = $fopen(sps_conv1_out_t0_path, "w");
    sps_file1 = $fopen(sps_conv1_out_t1_path, "w");
    sps_file2 = $fopen(sps_conv1_out_t2_path, "w");
    sps_file3 = $fopen(sps_conv1_out_t3_path, "w");
end

always@(posedge s_clk) begin
    if (u_simple_eyeriss_top.u_simple_eyeriss_Controller.r_cycle_cnt == 'd96 && u_simple_eyeriss_top.u_simple_eyeriss_Controller.Array_out_done) begin
        $display("INFO: sps conv1 data get done !");
        $fclose(sps_file0);
        $fclose(sps_file1);
        $fclose(sps_file2);
        $fclose(sps_file3);
    end
    else if (u_simple_eyeriss_top.u_simple_eyeriss_Controller.r_cycle_cnt >= 'd1 && u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.r_read_1line_req_d2) begin
        $fwrite(sps_file0, "%d\n", $signed(u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.read_1line_data[`ERS_MAX_WIDTH * (0 + 1) - 1 : `ERS_MAX_WIDTH * 0])); 
        $fwrite(sps_file1, "%d\n", $signed(u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.read_1line_data[`ERS_MAX_WIDTH * (1 + 1) - 1 : `ERS_MAX_WIDTH * 1])); 
        $fwrite(sps_file2, "%d\n", $signed(u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.read_1line_data[`ERS_MAX_WIDTH * (2 + 1) - 1 : `ERS_MAX_WIDTH * 2])); 
        $fwrite(sps_file3, "%d\n", $signed(u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.read_1line_data[`ERS_MAX_WIDTH * (3 + 1) - 1 : `ERS_MAX_WIDTH * 3])); 
    end
end

parameter sps_lif1_out_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_lif1_out_t0.txt"};
parameter sps_lif1_out_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_lif1_out_t1.txt"};
parameter sps_lif1_out_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_lif1_out_t2.txt"};
parameter sps_lif1_out_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_lif1_out_t3.txt"};

integer sps_lif_file0, sps_lif_file1, sps_lif_file2, sps_lif_file3;
initial begin
    sps_lif_file0 = $fopen(sps_lif1_out_t0_path, "w");
    sps_lif_file1 = $fopen(sps_lif1_out_t1_path, "w");
    sps_lif_file2 = $fopen(sps_lif1_out_t2_path, "w");
    sps_lif_file3 = $fopen(sps_lif1_out_t3_path, "w");
end

always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        sps_conv2_flag <= 1'b0;
    else if (u_simple_eyeriss_top.u_simple_eyeriss_Controller.r_cycle_cnt == 'd96 && u_simple_eyeriss_top.u_simple_eyeriss_Controller.Array_out_done) begin
        $display("INFO: sps lif1 data get done !");
        $fclose(sps_lif_file0);
        $fclose(sps_lif_file1);
        $fclose(sps_lif_file2);
        $fclose(sps_lif_file3);
        sps_conv2_flag <= 1'b1;
    end
    else if (u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.u_psum_lif_top.w_spike_valid_t3) begin
        $fwrite(sps_lif_file0, "%b\n", u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.u_psum_lif_top.w_spikes_out[0]); 
        $fwrite(sps_lif_file1, "%b\n", u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.u_psum_lif_top.w_spikes_out[1]); 
        $fwrite(sps_lif_file2, "%b\n", u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.u_psum_lif_top.w_spikes_out[2]); 
        $fwrite(sps_lif_file3, "%b\n", u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.u_psum_lif_top.w_spikes_out[3]); 
    end
end

// ======= SPS CONV2 PART =======
parameter sps_conv2_out_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_conv2_out_t0.txt"};
parameter sps_conv2_out_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_conv2_out_t1.txt"};
parameter sps_conv2_out_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_conv2_out_t2.txt"};
parameter sps_conv2_out_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_conv2_out_t3.txt"};

integer sps1_file0, sps1_file1, sps1_file2, sps1_file3;
initial begin
    sps1_file0 = $fopen(sps_conv2_out_t0_path, "w");
    sps1_file1 = $fopen(sps_conv2_out_t1_path, "w");
    sps1_file2 = $fopen(sps_conv2_out_t2_path, "w");
    sps1_file3 = $fopen(sps_conv2_out_t3_path, "w");
end

always@(posedge s_clk) begin
    if (u_simple_eyeriss_top.u_simple_eyeriss_Controller.r_cycle_cnt == 'd192 && u_simple_eyeriss_top.u_simple_eyeriss_Controller.Array_out_done) begin
        $display("INFO: sps conv2 data get done !");
        $fclose(sps1_file0);
        $fclose(sps1_file1);
        $fclose(sps1_file2);
        $fclose(sps1_file3);
    end
    else if (u_simple_eyeriss_top.u_simple_eyeriss_Controller.u_code_fetch.r_code_addr == 'd2 && u_simple_eyeriss_top.u_simple_eyeriss_Controller.r_cycle_cnt >= 'd1 && u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.r_read_1line_req_d2) begin
        $fwrite(sps1_file0, "%d\n", $signed(u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.read_1line_data[`ERS_MAX_WIDTH * (0 + 1) - 1 : `ERS_MAX_WIDTH * 0])); 
        $fwrite(sps1_file1, "%d\n", $signed(u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.read_1line_data[`ERS_MAX_WIDTH * (1 + 1) - 1 : `ERS_MAX_WIDTH * 1])); 
        $fwrite(sps1_file2, "%d\n", $signed(u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.read_1line_data[`ERS_MAX_WIDTH * (2 + 1) - 1 : `ERS_MAX_WIDTH * 2])); 
        $fwrite(sps1_file3, "%d\n", $signed(u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.read_1line_data[`ERS_MAX_WIDTH * (3 + 1) - 1 : `ERS_MAX_WIDTH * 3])); 
    end
end

parameter sps_lif2_out_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_lif2_out_t0.txt"};
parameter sps_lif2_out_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_lif2_out_t1.txt"};
parameter sps_lif2_out_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_lif2_out_t2.txt"};
parameter sps_lif2_out_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_lif2_out_t3.txt"};

integer sps_lif2_file0, sps_lif2_file1, sps_lif2_file2, sps_lif2_file3;
initial begin
    sps_lif2_file0 = $fopen(sps_lif2_out_t0_path, "w");
    sps_lif2_file1 = $fopen(sps_lif2_out_t1_path, "w");
    sps_lif2_file2 = $fopen(sps_lif2_out_t2_path, "w");
    sps_lif2_file3 = $fopen(sps_lif2_out_t3_path, "w");
end

always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        sps_conv3_flag <= 1'b0;
    else if (u_simple_eyeriss_top.u_simple_eyeriss_Controller.r_cycle_cnt == 'd192 && u_simple_eyeriss_top.u_simple_eyeriss_Controller.Array_out_done) begin
        $display("INFO: sps lif2 data get done !");
        $fclose(sps_lif2_file0);
        $fclose(sps_lif2_file1);
        $fclose(sps_lif2_file2);
        $fclose(sps_lif2_file3);
        sps_conv3_flag <= 1'b1;
    end
    else if (sps_conv2_flag && u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.u_psum_lif_top.w_spike_valid_t3) begin
        $fwrite(sps_lif2_file0, "%b\n", u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.u_psum_lif_top.w_spikes_out[0]); 
        $fwrite(sps_lif2_file1, "%b\n", u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.u_psum_lif_top.w_spikes_out[1]); 
        $fwrite(sps_lif2_file2, "%b\n", u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.u_psum_lif_top.w_spikes_out[2]); 
        $fwrite(sps_lif2_file3, "%b\n", u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.u_psum_lif_top.w_spikes_out[3]); 
    end
end

// ======= MaxPool2d 1 PART =======
parameter sps_maxpool1_out_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_maxpool1_out_t0.txt"};
parameter sps_maxpool1_out_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_maxpool1_out_t1.txt"};
parameter sps_maxpool1_out_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_maxpool1_out_t2.txt"};
parameter sps_maxpool1_out_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_maxpool1_out_t3.txt"};

wire  [`IMG_WIDTH / 2 - 1 : 0]          maxpool1_data_t0;
wire  [`IMG_WIDTH / 2 - 1 : 0]          maxpool1_data_t1;
wire  [`IMG_WIDTH / 2 - 1 : 0]          maxpool1_data_t2;
wire  [`IMG_WIDTH / 2 - 1 : 0]          maxpool1_data_t3;

genvar kkk;
integer sps_maxpool1_file0, sps_maxpool1_file1, sps_maxpool1_file2, sps_maxpool1_file3;

initial begin
    sps_maxpool1_file0 = $fopen(sps_maxpool1_out_t0_path, "w");
    sps_maxpool1_file1 = $fopen(sps_maxpool1_out_t1_path, "w");
    sps_maxpool1_file2 = $fopen(sps_maxpool1_out_t2_path, "w");
    sps_maxpool1_file3 = $fopen(sps_maxpool1_out_t3_path, "w");
end

generate
    for (kkk = 0; kkk < `IMG_WIDTH / 2; kkk = kkk + 1) begin
        assign maxpool1_data_t0[kkk] = u_simple_eyeriss_top.u_simple_maxpool_unit.Pooling_out_spikes[`TIME_STEPS*kkk + 0];
        assign maxpool1_data_t1[kkk] = u_simple_eyeriss_top.u_simple_maxpool_unit.Pooling_out_spikes[`TIME_STEPS*kkk + 1];
        assign maxpool1_data_t2[kkk] = u_simple_eyeriss_top.u_simple_maxpool_unit.Pooling_out_spikes[`TIME_STEPS*kkk + 2];
        assign maxpool1_data_t3[kkk] = u_simple_eyeriss_top.u_simple_maxpool_unit.Pooling_out_spikes[`TIME_STEPS*kkk + 3];
    end
endgenerate

integer iii;
always@(posedge s_clk) begin
    if (s_rst)
        sps_mp_flag <= 1'b0;
    else if (u_simple_eyeriss_top.u_simple_maxpool_unit.Pooling_out_done) begin
        $display("INFO: sps maxpool_1 data get done !");
        $fclose(sps_maxpool1_file0);
        $fclose(sps_maxpool1_file1);
        $fclose(sps_maxpool1_file2);
        $fclose(sps_maxpool1_file3);
        sps_mp_flag <= 1'b1;
    end
    else if (u_simple_eyeriss_top.u_simple_maxpool_unit.Pooling_out_valid) begin
        for (iii = 0; iii < `IMG_WIDTH / 2; iii = iii + 1) begin
            $fwrite(sps_maxpool1_file0, "%b\n", maxpool1_data_t0[iii]); 
            $fwrite(sps_maxpool1_file1, "%b\n", maxpool1_data_t1[iii]); 
            $fwrite(sps_maxpool1_file2, "%b\n", maxpool1_data_t2[iii]); 
            $fwrite(sps_maxpool1_file3, "%b\n", maxpool1_data_t3[iii]); 
        end
    end
end

// ======= SPS CONV3 PART =======
parameter sps_conv3_out_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_conv3_out_t0.txt"};
parameter sps_conv3_out_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_conv3_out_t1.txt"};
parameter sps_conv3_out_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_conv3_out_t2.txt"};
parameter sps_conv3_out_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_conv3_out_t3.txt"};

integer sps3_file0, sps3_file1, sps3_file2, sps3_file3;
initial begin
    sps3_file0 = $fopen(sps_conv3_out_t0_path, "w");
    sps3_file1 = $fopen(sps_conv3_out_t1_path, "w");
    sps3_file2 = $fopen(sps_conv3_out_t2_path, "w");
    sps3_file3 = $fopen(sps_conv3_out_t3_path, "w");
end

always@(posedge s_clk) begin
    if (u_simple_eyeriss_top.u_simple_eyeriss_Controller.r_cycle_cnt == 'd384 && u_simple_eyeriss_top.u_simple_eyeriss_Controller.Array_out_done) begin
        $display("INFO: sps conv3 data get done !");
        $fclose(sps3_file0);
        $fclose(sps3_file1);
        $fclose(sps3_file2);
        $fclose(sps3_file3);
    end
    else if (u_simple_eyeriss_top.u_simple_eyeriss_Controller.u_code_fetch.r_code_addr == 'd4 && u_simple_eyeriss_top.u_simple_eyeriss_Controller.r_cycle_cnt >= 'd1 && u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.r_read_1line_req_d2) begin
        $fwrite(sps3_file0, "%d\n", $signed(u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.read_1line_data[`ERS_MAX_WIDTH * (0 + 1) - 1 : `ERS_MAX_WIDTH * 0])); 
        $fwrite(sps3_file1, "%d\n", $signed(u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.read_1line_data[`ERS_MAX_WIDTH * (1 + 1) - 1 : `ERS_MAX_WIDTH * 1])); 
        $fwrite(sps3_file2, "%d\n", $signed(u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.read_1line_data[`ERS_MAX_WIDTH * (2 + 1) - 1 : `ERS_MAX_WIDTH * 2])); 
        $fwrite(sps3_file3, "%d\n", $signed(u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.read_1line_data[`ERS_MAX_WIDTH * (3 + 1) - 1 : `ERS_MAX_WIDTH * 3])); 
    end
end

parameter sps_lif3_out_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_lif3_out_t0.txt"};
parameter sps_lif3_out_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_lif3_out_t1.txt"};
parameter sps_lif3_out_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_lif3_out_t2.txt"};
parameter sps_lif3_out_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_lif3_out_t3.txt"};

integer sps_lif3_file0, sps_lif3_file1, sps_lif3_file2, sps_lif3_file3;
initial begin
    sps_lif3_file0 = $fopen(sps_lif3_out_t0_path, "w");
    sps_lif3_file1 = $fopen(sps_lif3_out_t1_path, "w");
    sps_lif3_file2 = $fopen(sps_lif3_out_t2_path, "w");
    sps_lif3_file3 = $fopen(sps_lif3_out_t3_path, "w");
end

always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        sps_conv4_flag <= 1'b0;
    else if (u_simple_eyeriss_top.u_simple_eyeriss_Controller.r_cycle_cnt == 'd384 && u_simple_eyeriss_top.u_simple_eyeriss_Controller.Array_out_done) begin
        $display("INFO: sps lif3 data get done !");
        $fclose(sps_lif3_file0);
        $fclose(sps_lif3_file1);
        $fclose(sps_lif3_file2);
        $fclose(sps_lif3_file3);
        sps_conv4_flag <= 1'b1;
    end
    else if (sps_conv3_flag && u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.u_psum_lif_top.w_spike_valid_t3) begin
        $fwrite(sps_lif3_file0, "%b\n", u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.u_psum_lif_top.w_spikes_out[0]); 
        $fwrite(sps_lif3_file1, "%b\n", u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.u_psum_lif_top.w_spikes_out[1]); 
        $fwrite(sps_lif3_file2, "%b\n", u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.u_psum_lif_top.w_spikes_out[2]); 
        $fwrite(sps_lif3_file3, "%b\n", u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.u_psum_lif_top.w_spikes_out[3]); 
    end
end

// ======= MaxPool2d 2 PART =======
parameter sps_maxpool2_out_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_maxpool2_out_t0.txt"};
parameter sps_maxpool2_out_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_maxpool2_out_t1.txt"};
parameter sps_maxpool2_out_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_maxpool2_out_t2.txt"};
parameter sps_maxpool2_out_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_maxpool2_out_t3.txt"};

wire  [`IMG_WIDTH / 4 - 1 : 0]          maxpool2_data_t0;
wire  [`IMG_WIDTH / 4 - 1 : 0]          maxpool2_data_t1;
wire  [`IMG_WIDTH / 4 - 1 : 0]          maxpool2_data_t2;
wire  [`IMG_WIDTH / 4 - 1 : 0]          maxpool2_data_t3;

genvar kkkk;
integer sps_maxpool2_file0, sps_maxpool2_file1, sps_maxpool2_file2, sps_maxpool2_file3;

initial begin
    sps_maxpool2_file0 = $fopen(sps_maxpool2_out_t0_path, "w");
    sps_maxpool2_file1 = $fopen(sps_maxpool2_out_t1_path, "w");
    sps_maxpool2_file2 = $fopen(sps_maxpool2_out_t2_path, "w");
    sps_maxpool2_file3 = $fopen(sps_maxpool2_out_t3_path, "w");
end

generate
    for (kkkk = 0; kkkk < `IMG_WIDTH / 2; kkkk = kkkk + 1) begin
        assign maxpool2_data_t0[kkkk] = u_simple_eyeriss_top.u_simple_maxpool_unit.Pooling_out_spikes[`TIME_STEPS*kkkk + 0];
        assign maxpool2_data_t1[kkkk] = u_simple_eyeriss_top.u_simple_maxpool_unit.Pooling_out_spikes[`TIME_STEPS*kkkk + 1];
        assign maxpool2_data_t2[kkkk] = u_simple_eyeriss_top.u_simple_maxpool_unit.Pooling_out_spikes[`TIME_STEPS*kkkk + 2];
        assign maxpool2_data_t3[kkkk] = u_simple_eyeriss_top.u_simple_maxpool_unit.Pooling_out_spikes[`TIME_STEPS*kkkk + 3];
    end
endgenerate

integer iiii;
always@(posedge s_clk) begin
    if (sps_mp_flag && u_simple_eyeriss_top.u_simple_maxpool_unit.Pooling_out_done) begin
        $display("INFO: sps maxpool_2 data get done !");
        $fclose(sps_maxpool2_file0);
        $fclose(sps_maxpool2_file1);
        $fclose(sps_maxpool2_file2);
        $fclose(sps_maxpool2_file3);
    end
    else if (sps_mp_flag && u_simple_eyeriss_top.u_simple_maxpool_unit.Pooling_out_valid) begin
        for (iiii = 0; iiii < `IMG_WIDTH / 4; iiii = iiii + 1) begin
            $fwrite(sps_maxpool2_file0, "%b\n", maxpool2_data_t0[iiii]); 
            $fwrite(sps_maxpool2_file1, "%b\n", maxpool2_data_t1[iiii]); 
            $fwrite(sps_maxpool2_file2, "%b\n", maxpool2_data_t2[iiii]); 
            $fwrite(sps_maxpool2_file3, "%b\n", maxpool2_data_t3[iiii]); 
        end
    end
end

// ======= SPS CONV4 PART =======
parameter sps_conv4_out_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_conv4_out_t0.txt"};
parameter sps_conv4_out_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_conv4_out_t1.txt"};
parameter sps_conv4_out_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_conv4_out_t2.txt"};
parameter sps_conv4_out_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_conv4_out_t3.txt"};

integer sps4_file0, sps4_file1, sps4_file2, sps4_file3;
initial begin
    sps4_file0 = $fopen(sps_conv4_out_t0_path, "w");
    sps4_file1 = $fopen(sps_conv4_out_t1_path, "w");
    sps4_file2 = $fopen(sps_conv4_out_t2_path, "w");
    sps4_file3 = $fopen(sps_conv4_out_t3_path, "w");
end

always@(posedge s_clk) begin
    if (sps_conv4_flag && u_simple_eyeriss_top.u_simple_eyeriss_Controller.r_cycle_cnt == 'd384 && u_simple_eyeriss_top.u_simple_eyeriss_Controller.Array_out_done) begin
        $display("INFO: sps conv4 data get done !");
        $fclose(sps4_file0);
        $fclose(sps4_file1);
        $fclose(sps4_file2);
        $fclose(sps4_file3);
    end
    else if (sps_conv4_flag && u_simple_eyeriss_top.u_simple_eyeriss_Controller.u_code_fetch.r_code_addr == 'd6 && u_simple_eyeriss_top.u_simple_eyeriss_Controller.r_cycle_cnt >= 'd1 && u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.r_read_1line_req_d2) begin
        $fwrite(sps4_file0, "%d\n", $signed(u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.read_1line_data[`ERS_MAX_WIDTH * (0 + 1) - 1 : `ERS_MAX_WIDTH * 0])); 
        $fwrite(sps4_file1, "%d\n", $signed(u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.read_1line_data[`ERS_MAX_WIDTH * (1 + 1) - 1 : `ERS_MAX_WIDTH * 1])); 
        $fwrite(sps4_file2, "%d\n", $signed(u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.read_1line_data[`ERS_MAX_WIDTH * (2 + 1) - 1 : `ERS_MAX_WIDTH * 2])); 
        $fwrite(sps4_file3, "%d\n", $signed(u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.read_1line_data[`ERS_MAX_WIDTH * (3 + 1) - 1 : `ERS_MAX_WIDTH * 3])); 
    end
end

parameter sps_lif4_out_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_lif4_out_t0.txt"};
parameter sps_lif4_out_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_lif4_out_t1.txt"};
parameter sps_lif4_out_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_lif4_out_t2.txt"};
parameter sps_lif4_out_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/sps_lif4_out_t3.txt"};

integer sps_lif4_file0, sps_lif4_file1, sps_lif4_file2, sps_lif4_file3;
initial begin
    sps_lif4_file0 = $fopen(sps_lif4_out_t0_path, "w");
    sps_lif4_file1 = $fopen(sps_lif4_out_t1_path, "w");
    sps_lif4_file2 = $fopen(sps_lif4_out_t2_path, "w");
    sps_lif4_file3 = $fopen(sps_lif4_out_t3_path, "w");
end

always@(posedge s_clk) begin
    if (sps_conv4_flag && u_simple_eyeriss_top.u_simple_eyeriss_Controller.r_cycle_cnt == 'd384 && u_simple_eyeriss_top.u_simple_eyeriss_Controller.Array_out_done) begin
        $display("INFO: sps lif4 data get done !");
        $fclose(sps_lif4_file0);
        $fclose(sps_lif4_file1);
        $fclose(sps_lif4_file2);
        $fclose(sps_lif4_file3);
    end
    else if (sps_conv4_flag && u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.u_psum_lif_top.w_spike_valid_t3) begin
        $fwrite(sps_lif4_file0, "%b\n", u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.u_psum_lif_top.w_spikes_out[0]); 
        $fwrite(sps_lif4_file1, "%b\n", u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.u_psum_lif_top.w_spikes_out[1]); 
        $fwrite(sps_lif4_file2, "%b\n", u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.u_psum_lif_top.w_spikes_out[2]); 
        $fwrite(sps_lif4_file3, "%b\n", u_simple_eyeriss_top.u_simple_eyeriss_array.u_psum_callback.u_psum_lif_top.w_spikes_out[3]); 
    end
end

// ======= EMBED PATCH PART =======
parameter PATCH_EMBED_coe_path = {WORKSPACE_PATH, "/data4fpga_bin/PATCH_EMBED_coe.txt"};
integer embedpatch_file;
initial begin
    embedpatch_file = $fopen(PATCH_EMBED_coe_path, "w");
end

always@(posedge s_clk) begin
    if (u_TOP_Transformer.w_ramout_ready) begin
        $display("INFO: coe embed patch data get done !");
        $fclose(embedpatch_file);
    end
    else if (u_PatchEmbed.r_trsfrmrdata_valid) begin
        $fwrite(embedpatch_file, "%h;\n", u_PatchEmbed.r_trsfrmrdata); 
    end
end

parameter embedpatch_out_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/embedpatch_out_t0.txt"};
parameter embedpatch_out_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/embedpatch_out_t1.txt"};
parameter embedpatch_out_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/embedpatch_out_t2.txt"};
parameter embedpatch_out_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/embedpatch_out_t3.txt"};

integer embedpatch_file0, embedpatch_file1, embedpatch_file2, embedpatch_file3;
initial begin
    embedpatch_file0 = $fopen(embedpatch_out_t0_path, "w");
    embedpatch_file1 = $fopen(embedpatch_out_t1_path, "w");
    embedpatch_file2 = $fopen(embedpatch_out_t2_path, "w");
    embedpatch_file3 = $fopen(embedpatch_out_t3_path, "w");
end

wire [1 : 0]        w_trsfrmrdata    [`PATCH_EMBED_WIDTH - 1 : 0];
genvar nnnn;
generate
    for (nnnn = 0; nnnn < `PATCH_EMBED_WIDTH; nnnn = nnnn + 1) begin
        assign w_trsfrmrdata[nnnn] = u_PatchEmbed.r_trsfrmrdata[2*nnnn + 1 : 2*nnnn];
    end
endgenerate

integer embedpatch_num;
always@(posedge s_clk) begin
    if (u_TOP_Transformer.w_ramout_ready) begin
        $display("INFO: embed patch data get done !");
        $fclose(embedpatch_file0);
        $fclose(embedpatch_file1);
        $fclose(embedpatch_file2);
        $fclose(embedpatch_file3);
    end
    else if (u_PatchEmbed.r_trsfrmrdata_valid) begin
        for (embedpatch_num = 0; embedpatch_num < 8; embedpatch_num = embedpatch_num + 1) begin
            $fwrite(embedpatch_file0, "%d\n", w_trsfrmrdata[4*embedpatch_num + 0]); 
            $fwrite(embedpatch_file1, "%d\n", w_trsfrmrdata[4*embedpatch_num + 1]); 
            $fwrite(embedpatch_file2, "%d\n", w_trsfrmrdata[4*embedpatch_num + 2]); 
            $fwrite(embedpatch_file3, "%d\n", w_trsfrmrdata[4*embedpatch_num + 3]); 
        end
    end
end

parameter embedpatch_in00_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/embedpatch_in00_t0.txt"};
parameter embedpatch_in00_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/embedpatch_in00_t1.txt"};
parameter embedpatch_in00_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/embedpatch_in00_t2.txt"};
parameter embedpatch_in00_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/embedpatch_in00_t3.txt"};

integer in00_embedpatch_file0, in00_embedpatch_file1, in00_embedpatch_file2, in00_embedpatch_file3;
initial begin
    in00_embedpatch_file0 = $fopen(embedpatch_in00_t0_path, "w");
    in00_embedpatch_file1 = $fopen(embedpatch_in00_t1_path, "w");
    in00_embedpatch_file2 = $fopen(embedpatch_in00_t2_path, "w");
    in00_embedpatch_file3 = $fopen(embedpatch_in00_t3_path, "w");
end

integer embedpatch_num_in00;
always@(posedge s_clk) begin
    if (u_TOP_Transformer.w_ramout_ready) begin
        $display("INFO: in 00 embed patch data get done !");
        $fclose(in00_embedpatch_file0);
        $fclose(in00_embedpatch_file1);
        $fclose(in00_embedpatch_file2);
        $fclose(in00_embedpatch_file3);
    end
    else if (w_data_valid) begin
        for (embedpatch_num_in00 = 0; embedpatch_num_in00 < 8; embedpatch_num_in00 = embedpatch_num_in00 + 1) begin
            $fwrite(in00_embedpatch_file0, "%b\n", w_fmap[4*embedpatch_num_in00 + 0]); 
            $fwrite(in00_embedpatch_file1, "%b\n", w_fmap[4*embedpatch_num_in00 + 1]); 
            $fwrite(in00_embedpatch_file2, "%b\n", w_fmap[4*embedpatch_num_in00 + 2]); 
            $fwrite(in00_embedpatch_file3, "%b\n", w_fmap[4*embedpatch_num_in00 + 3]); 
        end
    end
end

parameter embedpatch_in01_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/embedpatch_in01_t0.txt"};
parameter embedpatch_in01_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/embedpatch_in01_t1.txt"};
parameter embedpatch_in01_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/embedpatch_in01_t2.txt"};
parameter embedpatch_in01_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/embedpatch_in01_t3.txt"};

integer in01_embedpatch_file0, in01_embedpatch_file1, in01_embedpatch_file2, in01_embedpatch_file3;
initial begin
    in01_embedpatch_file0 = $fopen(embedpatch_in01_t0_path, "w");
    in01_embedpatch_file1 = $fopen(embedpatch_in01_t1_path, "w");
    in01_embedpatch_file2 = $fopen(embedpatch_in01_t2_path, "w");
    in01_embedpatch_file3 = $fopen(embedpatch_in01_t3_path, "w");
end

integer embedpatch_num_in01;
always@(posedge s_clk) begin
    if (u_TOP_Transformer.w_ramout_ready) begin
        $display("INFO: in 01 embed patch data get done !");
        $fclose(in01_embedpatch_file0);
        $fclose(in01_embedpatch_file1);
        $fclose(in01_embedpatch_file2);
        $fclose(in01_embedpatch_file3);
    end
    else if (w_data_valid) begin
        for (embedpatch_num_in01 = 0; embedpatch_num_in01 < 8; embedpatch_num_in01 = embedpatch_num_in01 + 1) begin
            $fwrite(in01_embedpatch_file0, "%b\n", w_patchdata[4*embedpatch_num_in01 + 0]); 
            $fwrite(in01_embedpatch_file1, "%b\n", w_patchdata[4*embedpatch_num_in01 + 1]); 
            $fwrite(in01_embedpatch_file2, "%b\n", w_patchdata[4*embedpatch_num_in01 + 2]); 
            $fwrite(in01_embedpatch_file3, "%b\n", w_patchdata[4*embedpatch_num_in01 + 3]); 
        end
    end
end

endmodule
