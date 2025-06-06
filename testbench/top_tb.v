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

wire [`DATA_WIDTH- 1 : 0]                     m00_burst_read_data        ;
wire [`ADDR_SIZE - 1 : 0]                     m00_burst_read_addr        ;
wire [`LEN_WIDTH - 1 : 0]                     m00_burst_read_len         ;
wire                                          m00_burst_read_req         ;
wire                                          m00_burst_read_valid       ;
wire                                          m00_burst_read_finish      ;

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
ddr_sim_top u_ddr_sim_top (
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

// parameter WORKSPACE_PATH = "E:/Desktop/FPGA_SpikingTransformer";
parameter WORKSPACE_PATH = "E:/Desktop/spiking-transformer-master";

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
    else if (u_TOP_Transformer.u_PatchEmbed.r_trsfrmrdata_valid) begin
        $fwrite(embedpatch_file, "%h;\n", u_TOP_Transformer.u_PatchEmbed.r_trsfrmrdata); 
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
        assign w_trsfrmrdata[nnnn] = u_TOP_Transformer.u_PatchEmbed.r_trsfrmrdata[2*nnnn + 1 : 2*nnnn];
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
    else if (u_TOP_Transformer.u_PatchEmbed.r_trsfrmrdata_valid) begin
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

// ======= Transformer PART =======
parameter linear_q_out_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/attn_linear_q_out_t0.txt"};
parameter linear_q_out_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/attn_linear_q_out_t1.txt"};
parameter linear_q_out_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/attn_linear_q_out_t2.txt"};
parameter linear_q_out_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/attn_linear_q_out_t3.txt"};

reg    r_lq_PsumFIFO_Finish_d0;
reg    r_lq_PsumFIFO_Finish_d1;

integer linear_q_out_file0, 
        linear_q_out_file1, 
        linear_q_out_file2, 
        linear_q_out_file3;

initial begin
    linear_q_out_file0 = $fopen(linear_q_out_t0_path, "w");
    linear_q_out_file1 = $fopen(linear_q_out_t1_path, "w");
    linear_q_out_file2 = $fopen(linear_q_out_t2_path, "w");
    linear_q_out_file3 = $fopen(linear_q_out_t3_path, "w");
end

always@(posedge s_clk) begin
    r_lq_PsumFIFO_Finish_d0 <= u_TOP_Transformer.w_lq_PsumFIFO_Finish;
    r_lq_PsumFIFO_Finish_d1 <= r_lq_PsumFIFO_Finish_d0 ;

    if (r_lq_PsumFIFO_Finish_d1) begin
        $display("linear_q_out cal done");
        $fclose(linear_q_out_file0);
        $fclose(linear_q_out_file1);
        $fclose(linear_q_out_file2);
        $fclose(linear_q_out_file3);
    end
    else if (u_TOP_Transformer.w_lq_PsumValid) begin
        $fwrite(linear_q_out_file0, "%d\n", $signed(u_TOP_Transformer.w_lq_PsumData[1*20 - 1 : 0*20])); 
        $fwrite(linear_q_out_file1, "%d\n", $signed(u_TOP_Transformer.w_lq_PsumData[2*20 - 1 : 1*20])); 
        $fwrite(linear_q_out_file2, "%d\n", $signed(u_TOP_Transformer.w_lq_PsumData[3*20 - 1 : 2*20])); 
        $fwrite(linear_q_out_file3, "%d\n", $signed(u_TOP_Transformer.w_lq_PsumData[4*20 - 1 : 3*20])); 
    end
end

parameter linear_k_out_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/attn_linear_k_out_t0.txt"};
parameter linear_k_out_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/attn_linear_k_out_t1.txt"};
parameter linear_k_out_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/attn_linear_k_out_t2.txt"};
parameter linear_k_out_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/attn_linear_k_out_t3.txt"};

reg [15 : 0]       r_linear_k_cnt=0 ; 

integer kfile0, kfile1, kfile2, kfile3;
initial begin
    kfile0 = $fopen(linear_k_out_t0_path, "w");
    kfile1 = $fopen(linear_k_out_t1_path, "w");
    kfile2 = $fopen(linear_k_out_t2_path, "w");
    kfile3 = $fopen(linear_k_out_t3_path, "w");
end

always@(posedge s_clk) begin
    if (r_linear_k_cnt == 'd24576) begin
        $display("linear_k_out cal done");
        $fclose(kfile0);
        $fclose(kfile1);
        $fclose(kfile2);
        $fclose(kfile3);
    end
    else if (u_TOP_Transformer.w_lk_PsumValid) begin
        r_linear_k_cnt <= r_linear_k_cnt + 1'b1;
        $fwrite(kfile0, "%d\n", $signed(u_TOP_Transformer.w_lk_PsumData[1*20 - 1 : 0*20])); 
        $fwrite(kfile1, "%d\n", $signed(u_TOP_Transformer.w_lk_PsumData[2*20 - 1 : 1*20])); 
        $fwrite(kfile2, "%d\n", $signed(u_TOP_Transformer.w_lk_PsumData[3*20 - 1 : 2*20])); 
        $fwrite(kfile3, "%d\n", $signed(u_TOP_Transformer.w_lk_PsumData[4*20 - 1 : 3*20])); 
    end
end

parameter linear_v_out_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/attn_linear_v_out_t0.txt"};
parameter linear_v_out_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/attn_linear_v_out_t1.txt"};
parameter linear_v_out_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/attn_linear_v_out_t2.txt"};
parameter linear_v_out_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/attn_linear_v_out_t3.txt"};

reg [15 : 0]       r_linear_v_cnt=0 ; 

integer vfile0, vfile1, vfile2, vfile3;
initial begin
    vfile0 = $fopen(linear_v_out_t0_path, "w");
    vfile1 = $fopen(linear_v_out_t1_path, "w");
    vfile2 = $fopen(linear_v_out_t2_path, "w");
    vfile3 = $fopen(linear_v_out_t3_path, "w");
end

always@(posedge s_clk) begin
    if (r_linear_v_cnt == 'd24576) begin
        $display("linear_v_out cal done");
        $fclose(vfile0);
        $fclose(vfile1);
        $fclose(vfile2);
        $fclose(vfile3);
    end
    else if (u_TOP_Transformer.w_lv_PsumValid) begin
        r_linear_v_cnt <= r_linear_v_cnt + 1'b1;
        $fwrite(vfile0, "%d\n", $signed(u_TOP_Transformer.w_lv_PsumData[1*20 - 1 : 0*20])); 
        $fwrite(vfile1, "%d\n", $signed(u_TOP_Transformer.w_lv_PsumData[2*20 - 1 : 1*20])); 
        $fwrite(vfile2, "%d\n", $signed(u_TOP_Transformer.w_lv_PsumData[3*20 - 1 : 2*20])); 
        $fwrite(vfile3, "%d\n", $signed(u_TOP_Transformer.w_lv_PsumData[4*20 - 1 : 3*20])); 
    end
end

// ======= SPIKES GET =======
parameter attn_lif_q_out_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/attn_lif_q_out_t0.txt"};
parameter attn_lif_q_out_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/attn_lif_q_out_t1.txt"};
parameter attn_lif_q_out_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/attn_lif_q_out_t2.txt"};
parameter attn_lif_q_out_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/attn_lif_q_out_t3.txt"};
reg [15 : 0]       r_lif_q_cnt=0 ; 

integer lq_file0, lq_file1, lq_file2, lq_file3;
initial begin
    lq_file0 = $fopen(attn_lif_q_out_t0_path, "w");
    lq_file1 = $fopen(attn_lif_q_out_t1_path, "w");
    lq_file2 = $fopen(attn_lif_q_out_t2_path, "w");
    lq_file3 = $fopen(attn_lif_q_out_t3_path, "w");
end
  
always@(posedge s_clk) begin
    if (r_lif_q_cnt == 'd24576) begin
        $display("lif_q_out cal done");
        $fclose(lq_file0);
        $fclose(lq_file1);
        $fclose(lq_file2);
        $fclose(lq_file3);
    end
    else if (u_TOP_Transformer.w_lq_spikes_valid) begin
        r_lif_q_cnt <= r_lif_q_cnt + 1'b1;
        $fwrite(lq_file0, "%b\n", u_TOP_Transformer.w_lq_spikes_out[0]); 
        $fwrite(lq_file1, "%b\n", u_TOP_Transformer.w_lq_spikes_out[1]); 
        $fwrite(lq_file2, "%b\n", u_TOP_Transformer.w_lq_spikes_out[2]); 
        $fwrite(lq_file3, "%b\n", u_TOP_Transformer.w_lq_spikes_out[3]); 
    end
end

parameter attn_lif_k_out_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/attn_lif_k_out_t0.txt"};
parameter attn_lif_k_out_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/attn_lif_k_out_t1.txt"};
parameter attn_lif_k_out_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/attn_lif_k_out_t2.txt"};
parameter attn_lif_k_out_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/attn_lif_k_out_t3.txt"};
reg [15 : 0]       r_lif_k_cnt=0 ; 

integer lk_file0, lk_file1, lk_file2, lk_file3;
initial begin
    lk_file0 = $fopen(attn_lif_k_out_t0_path, "w");
    lk_file1 = $fopen(attn_lif_k_out_t1_path, "w");
    lk_file2 = $fopen(attn_lif_k_out_t2_path, "w");
    lk_file3 = $fopen(attn_lif_k_out_t3_path, "w");
end
  
always@(posedge s_clk) begin
    if (r_lif_k_cnt == 'd24576) begin
        $display("lif_k_out cal done");
        $fclose(lk_file0);
        $fclose(lk_file1);
        $fclose(lk_file2);
        $fclose(lk_file3);
    end
    else if (u_TOP_Transformer.w_lk_spikes_valid) begin
        r_lif_k_cnt <= r_lif_k_cnt + 1'b1;
        $fwrite(lk_file0, "%b\n", u_TOP_Transformer.w_lk_spikes_out[0]); 
        $fwrite(lk_file1, "%b\n", u_TOP_Transformer.w_lk_spikes_out[1]); 
        $fwrite(lk_file2, "%b\n", u_TOP_Transformer.w_lk_spikes_out[2]); 
        $fwrite(lk_file3, "%b\n", u_TOP_Transformer.w_lk_spikes_out[3]); 
    end
end

parameter attn_lif_v_out_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/attn_lif_v_out_t0.txt"};
parameter attn_lif_v_out_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/attn_lif_v_out_t1.txt"};
parameter attn_lif_v_out_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/attn_lif_v_out_t2.txt"};
parameter attn_lif_v_out_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/attn_lif_v_out_t3.txt"};
reg [15 : 0]       r_lif_v_cnt=0 ; 

integer lv_file0, lv_file1, lv_file2, lv_file3;
initial begin
    lv_file0 = $fopen(attn_lif_v_out_t0_path, "w");
    lv_file1 = $fopen(attn_lif_v_out_t1_path, "w");
    lv_file2 = $fopen(attn_lif_v_out_t2_path, "w");
    lv_file3 = $fopen(attn_lif_v_out_t3_path, "w");
end
  
always@(posedge s_clk) begin
    if (r_lif_v_cnt == 'd24576) begin
        $display("lif_k_out cal done");
        $fclose(lv_file0);
        $fclose(lv_file1);
        $fclose(lv_file2);
        $fclose(lv_file3);
    end
    else if (u_TOP_Transformer.w_lv_spikes_valid) begin
        r_lif_v_cnt <= r_lif_v_cnt + 1'b1;
        $fwrite(lv_file0, "%b\n", u_TOP_Transformer.w_lv_spikes_out[0]); 
        $fwrite(lv_file1, "%b\n", u_TOP_Transformer.w_lv_spikes_out[1]); 
        $fwrite(lv_file2, "%b\n", u_TOP_Transformer.w_lv_spikes_out[2]); 
        $fwrite(lv_file3, "%b\n", u_TOP_Transformer.w_lv_spikes_out[3]); 
    end
end

// ======= CHECK ALIGN-DATA =======
parameter align_lif_out_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/align_lif_out_t0.txt"};
parameter align_lif_out_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/align_lif_out_t1.txt"};
parameter align_lif_out_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/align_lif_out_t2.txt"};
parameter align_lif_out_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/align_lif_out_t3.txt"};

wire [`SYSTOLIC_UNIT_NUM*`TIME_STEPS / 2 - 1 : 0]       w_alignSpikes_t0 ;
wire [`SYSTOLIC_UNIT_NUM*`TIME_STEPS / 2 - 1 : 0]       w_alignSpikes_t1 ;
wire [`SYSTOLIC_UNIT_NUM*`TIME_STEPS / 2 - 1 : 0]       w_alignSpikes_t2 ;
wire [`SYSTOLIC_UNIT_NUM*`TIME_STEPS / 2 - 1 : 0]       w_alignSpikes_t3 ;

reg [15 : 0]       r_align_lif_q_cnt=0 ; 
reg [15 : 0]       r_align_lif_k_cnt=0 ; 
reg [15 : 0]       r_align_lif_v_cnt=0 ; 

genvar m;
generate
    for (m = 0; m < `SYSTOLIC_UNIT_NUM*`TIME_STEPS / 2; m = m + 1) begin
        assign w_alignSpikes_t0[m] = u_TOP_Transformer.w00_spikesLine_out[`TIME_STEPS * m + 0]; 
        assign w_alignSpikes_t1[m] = u_TOP_Transformer.w00_spikesLine_out[`TIME_STEPS * m + 1];
        assign w_alignSpikes_t2[m] = u_TOP_Transformer.w00_spikesLine_out[`TIME_STEPS * m + 2];
        assign w_alignSpikes_t3[m] = u_TOP_Transformer.w00_spikesLine_out[`TIME_STEPS * m + 3];
    end
endgenerate

integer align_file0, align_file1, align_file2, align_file3;

initial begin
    align_file0 = $fopen(align_lif_out_t0_path, "w");
    align_file1 = $fopen(align_lif_out_t1_path, "w");
    align_file2 = $fopen(align_lif_out_t2_path, "w");
    align_file3 = $fopen(align_lif_out_t3_path, "w");
end

integer mm;
always@(posedge s_clk) begin
    if (r_align_lif_q_cnt == 'd768) begin
        $display("align q lif cal done");
        $fclose(align_file0);
        $fclose(align_file1);
        $fclose(align_file2);
        $fclose(align_file3);
    end
    else if (u_TOP_Transformer.w00_spikesLine_valid) begin
        r_align_lif_q_cnt <= r_align_lif_q_cnt + 1'b1;
        for (mm = 0; mm < `SYSTOLIC_UNIT_NUM*`TIME_STEPS / 2; mm = mm + 1) begin
            $fwrite(align_file0, "%b\n", w_alignSpikes_t0[mm]); 
            $fwrite(align_file1, "%b\n", w_alignSpikes_t1[mm]); 
            $fwrite(align_file2, "%b\n", w_alignSpikes_t2[mm]); 
            $fwrite(align_file3, "%b\n", w_alignSpikes_t3[mm]); 
        end
    end
end

parameter attn_out_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/Calc_attn_out_t0.txt"};
parameter attn_out_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/Calc_attn_out_t1.txt"};
parameter attn_out_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/Calc_attn_out_t2.txt"};
parameter attn_out_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/Calc_attn_out_t3.txt"};

integer calc_attn_file0, 
        calc_attn_file1, 
        calc_attn_file2, 
        calc_attn_file3;

reg [15 : 0]        r_Calc_attn_cnt=0 ;

initial begin
    calc_attn_file0 = $fopen(attn_out_t0_path, "w");
    calc_attn_file1 = $fopen(attn_out_t1_path, "w");
    calc_attn_file2 = $fopen(attn_out_t2_path, "w");
    calc_attn_file3 = $fopen(attn_out_t3_path, "w");
end
 
always@(posedge s_clk) begin
    if (r_Calc_attn_cnt == 'd49152) begin
        $display("attn cal done");
        $fclose(calc_attn_file0);
        $fclose(calc_attn_file1);
        $fclose(calc_attn_file2);
        $fclose(calc_attn_file3);
    end
    else if (u_TOP_Transformer.w_Calc_valid) begin
        r_Calc_attn_cnt <= r_Calc_attn_cnt + 1'b1;
        $fwrite(calc_attn_file0, "%d\n", u_TOP_Transformer.w_Calc_data[$clog2(2*`SYSTOLIC_UNIT_NUM) * 1 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM) * 0]); 
        $fwrite(calc_attn_file1, "%d\n", u_TOP_Transformer.w_Calc_data[$clog2(2*`SYSTOLIC_UNIT_NUM) * 2 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM) * 1]); 
        $fwrite(calc_attn_file2, "%d\n", u_TOP_Transformer.w_Calc_data[$clog2(2*`SYSTOLIC_UNIT_NUM) * 3 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM) * 2]); 
        $fwrite(calc_attn_file3, "%d\n", u_TOP_Transformer.w_Calc_data[$clog2(2*`SYSTOLIC_UNIT_NUM) * 4 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM) * 3]); 
    end
end

parameter attn_v_out_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/CalcMulti_attnV_out_t0.txt"};
parameter attn_v_out_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/CalcMulti_attnV_out_t1.txt"};
parameter attn_v_out_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/CalcMulti_attnV_out_t2.txt"};
parameter attn_v_out_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/CalcMulti_attnV_out_t3.txt"};

integer attnVfile0, 
        attnVfile1, 
        attnVfile2, 
        attnVfile3;

reg [20 : 0]        r_CalcMulti_attnv_cnt=0 ;

initial begin
    attnVfile0 = $fopen(attn_v_out_t0_path, "w");
    attnVfile1 = $fopen(attn_v_out_t1_path, "w");
    attnVfile2 = $fopen(attn_v_out_t2_path, "w");
    attnVfile3 = $fopen(attn_v_out_t3_path, "w");
end

always@(posedge s_clk) begin
    if (r_CalcMulti_attnv_cnt == 'd24576) begin
        $display("attn @ V cal done");
        $fclose(attnVfile0);
        $fclose(attnVfile1);
        $fclose(attnVfile2);
        $fclose(attnVfile3);
    end
    else if (| u_TOP_Transformer.u_MM_Calculator.r_rdfifo_valid) begin
        r_CalcMulti_attnv_cnt <= r_CalcMulti_attnv_cnt + 1'b1;
        $fwrite(attnVfile0, "%d\n", u_TOP_Transformer.u_MM_Calculator.r4lif_rdfifo_data[11:0]); 
        $fwrite(attnVfile1, "%d\n", u_TOP_Transformer.u_MM_Calculator.r4lif_rdfifo_data[23:12]); 
        $fwrite(attnVfile2, "%d\n", u_TOP_Transformer.u_MM_Calculator.r4lif_rdfifo_data[35:24]); 
        $fwrite(attnVfile3, "%d\n", u_TOP_Transformer.u_MM_Calculator.r4lif_rdfifo_data[47:36]); 
    end
end

parameter lif_attn_v_out_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/lif_CalcMulti_attnV_out_t0.txt"};
parameter lif_attn_v_out_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/lif_CalcMulti_attnV_out_t1.txt"};
parameter lif_attn_v_out_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/lif_CalcMulti_attnV_out_t2.txt"};
parameter lif_attn_v_out_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/lif_CalcMulti_attnV_out_t3.txt"};

integer lif_attnVfile0, 
        lif_attnVfile1, 
        lif_attnVfile2, 
        lif_attnVfile3;

integer lif_attnV_i;
reg [15 : 0]        r_lif_CalcMulti_attnv_cnt=0 ;

wire [1 : 0]        w_trsfrmrdata_cp0    [`PATCH_EMBED_WIDTH - 1 : 0];
genvar nnnnn;
generate
    for (nnnnn = 0; nnnnn < `PATCH_EMBED_WIDTH; nnnnn = nnnnn + 1) begin
        assign w_trsfrmrdata_cp0[nnnnn] = u_TOP_Transformer.w_attn_v_spikes_data[2*nnnnn + 1 : 2*nnnnn];
    end
endgenerate

initial begin
    lif_attnVfile0 = $fopen(lif_attn_v_out_t0_path, "w");
    lif_attnVfile1 = $fopen(lif_attn_v_out_t1_path, "w");
    lif_attnVfile2 = $fopen(lif_attn_v_out_t2_path, "w");
    lif_attnVfile3 = $fopen(lif_attn_v_out_t3_path, "w");
end

integer embedpatch_num_cp0;
always@(posedge s_clk) begin
    if (r_lif_CalcMulti_attnv_cnt == 'd3072) begin
        $display("lif attn @ V cal done");
        $fclose(lif_attnVfile0);
        $fclose(lif_attnVfile1);
        $fclose(lif_attnVfile2);
        $fclose(lif_attnVfile3);
    end
    else if (u_TOP_Transformer.w_attn_v_spikes_valid) begin
        r_lif_CalcMulti_attnv_cnt <= r_lif_CalcMulti_attnv_cnt + 1'b1;
        for (embedpatch_num_cp0 = 0; embedpatch_num_cp0 < 8; embedpatch_num_cp0 = embedpatch_num_cp0 + 1) begin
            $fwrite(lif_attnVfile0, "%d\n", w_trsfrmrdata_cp0[4*embedpatch_num_cp0 + 0]); 
            $fwrite(lif_attnVfile1, "%d\n", w_trsfrmrdata_cp0[4*embedpatch_num_cp0 + 1]); 
            $fwrite(lif_attnVfile2, "%d\n", w_trsfrmrdata_cp0[4*embedpatch_num_cp0 + 2]); 
            $fwrite(lif_attnVfile3, "%d\n", w_trsfrmrdata_cp0[4*embedpatch_num_cp0 + 3]); 
        end
    end
end

// ======= MLP =======
parameter mlp_projfc_out_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/mlp_projfc_out_t0.txt"};
parameter mlp_projfc_out_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/mlp_projfc_out_t1.txt"};
parameter mlp_projfc_out_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/mlp_projfc_out_t2.txt"};
parameter mlp_projfc_out_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/mlp_projfc_out_t3.txt"};

integer mlp_projfc_file0, mlp_projfc_file1, mlp_projfc_file2, mlp_projfc_file3;
integer mlp_projfc_num;

initial begin
    mlp_projfc_file0 = $fopen(mlp_projfc_out_t0_path, "w");
    mlp_projfc_file1 = $fopen(mlp_projfc_out_t1_path, "w");
    mlp_projfc_file2 = $fopen(mlp_projfc_out_t2_path, "w");
    mlp_projfc_file3 = $fopen(mlp_projfc_out_t3_path, "w");
end

always@(posedge s_clk) begin
    if (u_TOP_Transformer.u_mlp_controller.r_WriteBack2Ram_LayerCnt > 0) begin
        $display("mlp projfc cal done");
        $fclose(mlp_projfc_file0);
        $fclose(mlp_projfc_file1);
        $fclose(mlp_projfc_file2);
        $fclose(mlp_projfc_file3);
    end 
    else if (u_TOP_Transformer.u_mlp_controller.r_WriteBack2Ram_LayerCnt == 0 && u_TOP_Transformer.u_mlp_controller.w_MLPsSpikesOut_valid) begin
        for (mlp_projfc_num = 0; mlp_projfc_num < 8; mlp_projfc_num = mlp_projfc_num + 1) begin
            $fwrite(mlp_projfc_file0, "%d\n", (u_TOP_Transformer.u_mlp_controller.w_MLPsSpikesOut_data >> (mlp_projfc_num * 8 + 0)) & 2'b11);
            $fwrite(mlp_projfc_file1, "%d\n", (u_TOP_Transformer.u_mlp_controller.w_MLPsSpikesOut_data >> (mlp_projfc_num * 8 + 2)) & 2'b11);
            $fwrite(mlp_projfc_file2, "%d\n", (u_TOP_Transformer.u_mlp_controller.w_MLPsSpikesOut_data >> (mlp_projfc_num * 8 + 4)) & 2'b11);
            $fwrite(mlp_projfc_file3, "%d\n", (u_TOP_Transformer.u_mlp_controller.w_MLPsSpikesOut_data >> (mlp_projfc_num * 8 + 6)) & 2'b11);
        end
    end
end

parameter mlp_fc0_out_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/mlp_fc0_out_t0.txt"};
parameter mlp_fc0_out_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/mlp_fc0_out_t1.txt"};
parameter mlp_fc0_out_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/mlp_fc0_out_t2.txt"};
parameter mlp_fc0_out_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/mlp_fc0_out_t3.txt"};

integer mlp_fc0_file0, mlp_fc0_file1, mlp_fc0_file2, mlp_fc0_file3;
integer mlp_fc0_num;

initial begin
    mlp_fc0_file0 = $fopen(mlp_fc0_out_t0_path, "w");
    mlp_fc0_file1 = $fopen(mlp_fc0_out_t1_path, "w");
    mlp_fc0_file2 = $fopen(mlp_fc0_out_t2_path, "w");
    mlp_fc0_file3 = $fopen(mlp_fc0_out_t3_path, "w");
end

always@(posedge s_clk) begin
    if (u_TOP_Transformer.u_mlp_controller.r_WriteBack2Ram_LayerCnt > 1) begin
        $display("mlp fc0 cal done");
        $fclose(mlp_fc0_file0);
        $fclose(mlp_fc0_file1);
        $fclose(mlp_fc0_file2);
        $fclose(mlp_fc0_file3);
    end 
    else if (u_TOP_Transformer.u_mlp_controller.r_WriteBack2Ram_LayerCnt == 1 && u_TOP_Transformer.u_mlp_controller.w_MLPsSpikesOut_valid) begin
        for (mlp_fc0_num = 0; mlp_fc0_num < 8; mlp_fc0_num = mlp_fc0_num + 1) begin
            $fwrite(mlp_fc0_file0, "%d\n", (u_TOP_Transformer.u_mlp_controller.w_MLPsSpikesOut_data >> (mlp_fc0_num * 8 + 0)) & 2'b11);
            $fwrite(mlp_fc0_file1, "%d\n", (u_TOP_Transformer.u_mlp_controller.w_MLPsSpikesOut_data >> (mlp_fc0_num * 8 + 2)) & 2'b11);
            $fwrite(mlp_fc0_file2, "%d\n", (u_TOP_Transformer.u_mlp_controller.w_MLPsSpikesOut_data >> (mlp_fc0_num * 8 + 4)) & 2'b11);
            $fwrite(mlp_fc0_file3, "%d\n", (u_TOP_Transformer.u_mlp_controller.w_MLPsSpikesOut_data >> (mlp_fc0_num * 8 + 6)) & 2'b11);
        end
    end
end


parameter mlp_fc1_out_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/mlp_fc1_out_t0.txt"};
parameter mlp_fc1_out_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/mlp_fc1_out_t1.txt"};
parameter mlp_fc1_out_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/mlp_fc1_out_t2.txt"};
parameter mlp_fc1_out_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/mlp_fc1_out_t3.txt"};

integer mlp_fc1_file0, mlp_fc1_file1, mlp_fc1_file2, mlp_fc1_file3;
integer mlp_fc1_num;

initial begin
    mlp_fc1_file0 = $fopen(mlp_fc1_out_t0_path, "w");
    mlp_fc1_file1 = $fopen(mlp_fc1_out_t1_path, "w");
    mlp_fc1_file2 = $fopen(mlp_fc1_out_t2_path, "w");
    mlp_fc1_file3 = $fopen(mlp_fc1_out_t3_path, "w");
end

always@(posedge s_clk) begin
    if (u_TOP_Transformer.u_mlp_controller.r_WriteBack2Ram_LayerCnt > 2) begin
        $display("mlp fc1 cal done");
        $fclose(mlp_fc1_file0);
        $fclose(mlp_fc1_file1);
        $fclose(mlp_fc1_file2);
        $fclose(mlp_fc1_file3);
    end 
    else if (u_TOP_Transformer.u_mlp_controller.r_WriteBack2Ram_LayerCnt == 2 && u_TOP_Transformer.u_mlp_controller.w_MLPsSpikesOut_valid) begin
        for (mlp_fc1_num = 0; mlp_fc1_num < 8; mlp_fc1_num = mlp_fc1_num + 1) begin
            $fwrite(mlp_fc1_file0, "%d\n", (u_TOP_Transformer.u_mlp_controller.w_MLPsSpikesOut_data >> (mlp_fc1_num * 8 + 0)) & 2'b11);
            $fwrite(mlp_fc1_file1, "%d\n", (u_TOP_Transformer.u_mlp_controller.w_MLPsSpikesOut_data >> (mlp_fc1_num * 8 + 2)) & 2'b11);
            $fwrite(mlp_fc1_file2, "%d\n", (u_TOP_Transformer.u_mlp_controller.w_MLPsSpikesOut_data >> (mlp_fc1_num * 8 + 4)) & 2'b11);
            $fwrite(mlp_fc1_file3, "%d\n", (u_TOP_Transformer.u_mlp_controller.w_MLPsSpikesOut_data >> (mlp_fc1_num * 8 + 6)) & 2'b11);
        end
    end
end

// ======= CHECK MLP-OUT =======
parameter before_act_mlp_projfc_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/before_act_mlp_projfc_t0.txt"};
parameter before_act_mlp_projfc_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/before_act_mlp_projfc_t1.txt"};
parameter before_act_mlp_projfc_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/before_act_mlp_projfc_t2.txt"};
parameter before_act_mlp_projfc_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/before_act_mlp_projfc_t3.txt"};

integer before_act_mlp_projfc_file0, before_act_mlp_projfc_file1, before_act_mlp_projfc_file2, before_act_mlp_projfc_file3;

initial begin
    before_act_mlp_projfc_file0 = $fopen(before_act_mlp_projfc_t0_path, "w");
    before_act_mlp_projfc_file1 = $fopen(before_act_mlp_projfc_t1_path, "w");
    before_act_mlp_projfc_file2 = $fopen(before_act_mlp_projfc_t2_path, "w");
    before_act_mlp_projfc_file3 = $fopen(before_act_mlp_projfc_t3_path, "w");
end

always@(posedge s_clk) begin
    if (u_TOP_Transformer.u_mlp_controller.r_WriteBack2Ram_LayerCnt > 0) begin
        $display("before act mlp projfc cal done");
        $fclose(before_act_mlp_projfc_file0);
        $fclose(before_act_mlp_projfc_file1);
        $fclose(before_act_mlp_projfc_file2);
        $fclose(before_act_mlp_projfc_file3);
    end
    else if (u_TOP_Transformer.u_mlp_controller.r_WriteBack2Ram_LayerCnt == 0 && u_TOP_Transformer.u_mlp_controller.r_PsumFIFO_Valid_dly[2]) begin
        $fwrite(before_act_mlp_projfc_file0, "%d\n", $signed(u_TOP_Transformer.u_mlp_controller.w_AddTree_dataout[21: 0]));
        $fwrite(before_act_mlp_projfc_file1, "%d\n", $signed(u_TOP_Transformer.u_mlp_controller.w_AddTree_dataout[43:22]));
        $fwrite(before_act_mlp_projfc_file2, "%d\n", $signed(u_TOP_Transformer.u_mlp_controller.w_AddTree_dataout[65:44]));
        $fwrite(before_act_mlp_projfc_file3, "%d\n", $signed(u_TOP_Transformer.u_mlp_controller.w_AddTree_dataout[87:66]));
    end
end

parameter before_act_mlp_fc0_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/before_act_mlp_fc0_t0.txt"};
parameter before_act_mlp_fc0_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/before_act_mlp_fc0_t1.txt"};
parameter before_act_mlp_fc0_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/before_act_mlp_fc0_t2.txt"};
parameter before_act_mlp_fc0_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/before_act_mlp_fc0_t3.txt"};

integer before_act_mlp_fc0_file0, before_act_mlp_fc0_file1, before_act_mlp_fc0_file2, before_act_mlp_fc0_file3;

initial begin
    before_act_mlp_fc0_file0 = $fopen(before_act_mlp_fc0_t0_path, "w");
    before_act_mlp_fc0_file1 = $fopen(before_act_mlp_fc0_t1_path, "w");
    before_act_mlp_fc0_file2 = $fopen(before_act_mlp_fc0_t2_path, "w");
    before_act_mlp_fc0_file3 = $fopen(before_act_mlp_fc0_t3_path, "w");
end

always@(posedge s_clk) begin
    if (u_TOP_Transformer.u_mlp_controller.r_WriteBack2Ram_LayerCnt > 1) begin
        $display("before act mlp fc0 cal done");
        $fclose(before_act_mlp_fc0_file0);
        $fclose(before_act_mlp_fc0_file1);
        $fclose(before_act_mlp_fc0_file2);
        $fclose(before_act_mlp_fc0_file3);
    end
    else if (u_TOP_Transformer.u_mlp_controller.r_WriteBack2Ram_LayerCnt == 1 && u_TOP_Transformer.u_mlp_controller.r_PsumFIFO_Valid_dly[2]) begin
        $fwrite(before_act_mlp_fc0_file0, "%d\n", $signed(u_TOP_Transformer.u_mlp_controller.w_AddTree_dataout[21: 0]));
        $fwrite(before_act_mlp_fc0_file1, "%d\n", $signed(u_TOP_Transformer.u_mlp_controller.w_AddTree_dataout[43:22]));
        $fwrite(before_act_mlp_fc0_file2, "%d\n", $signed(u_TOP_Transformer.u_mlp_controller.w_AddTree_dataout[65:44]));
        $fwrite(before_act_mlp_fc0_file3, "%d\n", $signed(u_TOP_Transformer.u_mlp_controller.w_AddTree_dataout[87:66]));
    end
end

parameter before_act_mlp_fc1_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/before_act_mlp_fc1_t0.txt"};
parameter before_act_mlp_fc1_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/before_act_mlp_fc1_t1.txt"};
parameter before_act_mlp_fc1_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/before_act_mlp_fc1_t2.txt"};
parameter before_act_mlp_fc1_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/before_act_mlp_fc1_t3.txt"};

integer before_act_mlp_fc1_file0, before_act_mlp_fc1_file1, before_act_mlp_fc1_file2, before_act_mlp_fc1_file3;

initial begin
    before_act_mlp_fc1_file0 = $fopen(before_act_mlp_fc1_t0_path, "w");
    before_act_mlp_fc1_file1 = $fopen(before_act_mlp_fc1_t1_path, "w");
    before_act_mlp_fc1_file2 = $fopen(before_act_mlp_fc1_t2_path, "w");
    before_act_mlp_fc1_file3 = $fopen(before_act_mlp_fc1_t3_path, "w");
end

always@(posedge s_clk) begin
    if (u_TOP_Transformer.u_mlp_controller.r_WriteBack2Ram_LayerCnt > 2) begin
        $display("before act mlp fc1 cal done");
        $fclose(before_act_mlp_fc1_file0);
        $fclose(before_act_mlp_fc1_file1);
        $fclose(before_act_mlp_fc1_file2);
        $fclose(before_act_mlp_fc1_file3);
    end
    else if (u_TOP_Transformer.u_mlp_controller.r_WriteBack2Ram_LayerCnt == 2 && u_TOP_Transformer.u_mlp_controller.r_PsumFIFO_Valid_dly[2]) begin
        $fwrite(before_act_mlp_fc1_file0, "%d\n", $signed(u_TOP_Transformer.u_mlp_controller.w_AddTree_dataout[21: 0]));
        $fwrite(before_act_mlp_fc1_file1, "%d\n", $signed(u_TOP_Transformer.u_mlp_controller.w_AddTree_dataout[43:22]));
        $fwrite(before_act_mlp_fc1_file2, "%d\n", $signed(u_TOP_Transformer.u_mlp_controller.w_AddTree_dataout[65:44]));
        $fwrite(before_act_mlp_fc1_file3, "%d\n", $signed(u_TOP_Transformer.u_mlp_controller.w_AddTree_dataout[87:66]));
    end
end

// ======== Read input + proj_fc data ========
parameter input_add_projfc_t0_path = {WORKSPACE_PATH, "/data4fpga_bin/input_add_projfc_t0.txt"};
parameter input_add_projfc_t1_path = {WORKSPACE_PATH, "/data4fpga_bin/input_add_projfc_t1.txt"};
parameter input_add_projfc_t2_path = {WORKSPACE_PATH, "/data4fpga_bin/input_add_projfc_t2.txt"};
parameter input_add_projfc_t3_path = {WORKSPACE_PATH, "/data4fpga_bin/input_add_projfc_t3.txt"};

integer input_add_projfc_file0, input_add_projfc_file1, input_add_projfc_file2, input_add_projfc_file3;
integer input_add_projfc_num;

initial begin
    input_add_projfc_file0 = $fopen(input_add_projfc_t0_path, "w");
    input_add_projfc_file1 = $fopen(input_add_projfc_t1_path, "w");
    input_add_projfc_file2 = $fopen(input_add_projfc_t2_path, "w");
    input_add_projfc_file3 = $fopen(input_add_projfc_t3_path, "w");
end

always@(posedge s_clk) begin
    if (u_TOP_Transformer.r_Mlp_read_addr_d0 == 3072) begin
        $display("input add projfc cal done");
        $fclose(input_add_projfc_file0);
        $fclose(input_add_projfc_file1);
        $fclose(input_add_projfc_file2);
        $fclose(input_add_projfc_file3);
    end
    else if (u_TOP_Transformer.r_Mlp_read_valid_delay) begin
        for (input_add_projfc_num = 0; input_add_projfc_num < 8; input_add_projfc_num = input_add_projfc_num + 1) begin
            $fwrite(input_add_projfc_file0, "%d\n", (u_TOP_Transformer.w_Mlp_Ram03_doutb >> (input_add_projfc_num * 8 + 0)) & 2'b11);
            $fwrite(input_add_projfc_file1, "%d\n", (u_TOP_Transformer.w_Mlp_Ram03_doutb >> (input_add_projfc_num * 8 + 2)) & 2'b11);
            $fwrite(input_add_projfc_file2, "%d\n", (u_TOP_Transformer.w_Mlp_Ram03_doutb >> (input_add_projfc_num * 8 + 4)) & 2'b11);
            $fwrite(input_add_projfc_file3, "%d\n", (u_TOP_Transformer.w_Mlp_Ram03_doutb >> (input_add_projfc_num * 8 + 6)) & 2'b11);
        end
    end
end

endmodule
