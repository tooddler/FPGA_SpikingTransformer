/*
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/
`timescale 1ns / 1ps

`include "hyper_para.v"
module top_spikingencoder_tb ();

reg                                 s_clk                       ;
reg                                 s_rst                       ;

reg                                 sps_conv2_flag              ;
reg                                 sps_conv3_flag              ;
reg                                 sps_conv4_flag              ;

reg                                 sps_mp_flag                 ;

wire  [`DATA_WIDTH- 1 : 0]          burst_write_data            ;  
wire  [`ADDR_SIZE - 1 : 0]          burst_write_addr            ;  
wire  [`LEN_WIDTH - 1 : 0]          burst_write_len             ;  
wire                                burst_write_req             ;   
wire                                burst_write_valid           ; 
wire                                burst_write_finish          ;

wire [`DATA_WIDTH- 1 : 0]           burst_read_data             ;   
wire [`ADDR_SIZE - 1 : 0]           burst_read_addr             ;   
wire [`LEN_WIDTH - 1 : 0]           burst_read_len              ;   
wire                                burst_read_req              ;    
wire                                burst_read_valid            ;  
wire                                burst_read_finish           ;

wire                                o_SpikingEncoder_out_done   ;    
wire [`TIME_STEPS - 1 : 0]          o_SpikingEncoder_out        ;
wire                                o_SpikingEncoder_out_valid  ;

wire [`DATA_WIDTH - 1 : 0]          Eyeriss_weight_in           ;
wire                                Eyeriss_weight_valid        ;
wire                                Eyeriss_weight_ready        ;

initial s_clk = 1'b1;
always #(`CLK_PERIOD/2) s_clk = ~s_clk;

initial begin
    s_rst = 1'b1;
    # 201;
    s_rst = 1'b0;
    # 400;
    # 4000;
end

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

SpikingEncoder u_SpikingEncoder(
    .s_clk                          ( s_clk                         ),
    .s_rst                          ( s_rst                         ),

    .network_cal_done               ( 1'b0                          ),

    .burst_read_data                ( burst_read_data               ),
    .burst_read_addr                ( burst_read_addr               ),
    .burst_read_len                 ( burst_read_len                ),
    .burst_read_req                 ( burst_read_req                ),
    .burst_read_valid               ( burst_read_valid              ),
    .burst_read_finish              ( burst_read_finish             ),

    .Eyeriss_weight_in              ( Eyeriss_weight_in             ),
    .Eyeriss_weight_valid           ( Eyeriss_weight_valid          ),
    .Eyeriss_weight_ready           ( Eyeriss_weight_ready          ),
    .i_weight_load_done             ( 1'b0                          ),

    .o_SpikingEncoder_out_done      ( o_SpikingEncoder_out_done     ),
    .o_SpikingEncoder_out           ( o_SpikingEncoder_out          ),
    .o_SpikingEncoder_out_valid     ( o_SpikingEncoder_out_valid    )
);

simple_eyeriss_top u_simple_eyeriss_top(
    .s_clk                         ( s_clk                      ),
    .s_rst                         ( s_rst                      ),

    .SPS_part_done                 ( 1'b0                       ),

    .weight_in                     ( Eyeriss_weight_in          ),
    .weight_valid                  ( Eyeriss_weight_valid       ),
    .o_weight_ready                ( Eyeriss_weight_ready       ),

    .SpikingEncoder_out_done       ( o_SpikingEncoder_out_done  ),
    .SpikingEncoder_out            ( o_SpikingEncoder_out       ),
    .SpikingEncoder_out_valid      ( o_SpikingEncoder_out_valid )
);

parameter spiking0_out_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/spiking0_out_out.txt";
parameter spiking1_out_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/spiking1_out_out.txt";
parameter spiking2_out_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/spiking2_out_out.txt";
parameter spiking3_out_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/spiking3_out_out.txt";


integer file0, file1, file2, file3;
initial begin
    file0 = $fopen(spiking0_out_path, "w");
    file1 = $fopen(spiking1_out_path, "w");
    file2 = $fopen(spiking2_out_path, "w");
    file3 = $fopen(spiking3_out_path, "w");
end

always@(posedge s_clk) begin
    if (o_SpikingEncoder_out_done) begin
        $display("spiking cal done");
        $fclose(file0);
        $fclose(file1);
        $fclose(file2);
        $fclose(file3);
    end
    else if (o_SpikingEncoder_out_valid) begin
        $fwrite(file0, "%b\n", o_SpikingEncoder_out[0]); 
        $fwrite(file1, "%b\n", o_SpikingEncoder_out[1]); 
        $fwrite(file2, "%b\n", o_SpikingEncoder_out[2]); 
        $fwrite(file3, "%b\n", o_SpikingEncoder_out[3]); 
    end
end

// ======= SPS CONV1 PART =======
parameter sps_conv1_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_conv1_out_t0.txt";
parameter sps_conv1_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_conv1_out_t1.txt";
parameter sps_conv1_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_conv1_out_t2.txt";
parameter sps_conv1_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_conv1_out_t3.txt";

integer sps_file0, sps_file1, sps_file2, sps_file3;
initial begin
    sps_file0 = $fopen(sps_conv1_out_t0_path, "w");
    sps_file1 = $fopen(sps_conv1_out_t1_path, "w");
    sps_file2 = $fopen(sps_conv1_out_t2_path, "w");
    sps_file3 = $fopen(sps_conv1_out_t3_path, "w");
end

always@(posedge s_clk) begin
    if (u_simple_eyeriss_top.u_simple_eyeriss_Controller.r_cycle_cnt == 'd96 && u_simple_eyeriss_top.u_simple_eyeriss_Controller.Array_out_done) begin
        $display("sps conv1 data get done !");
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

parameter sps_lif1_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_lif1_out_t0.txt";
parameter sps_lif1_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_lif1_out_t1.txt";
parameter sps_lif1_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_lif1_out_t2.txt";
parameter sps_lif1_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_lif1_out_t3.txt";

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
        $display("sps lif1 data get done !");
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
parameter sps_conv2_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_conv2_out_t0.txt";
parameter sps_conv2_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_conv2_out_t1.txt";
parameter sps_conv2_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_conv2_out_t2.txt";
parameter sps_conv2_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_conv2_out_t3.txt";

integer sps1_file0, sps1_file1, sps1_file2, sps1_file3;
initial begin
    sps1_file0 = $fopen(sps_conv2_out_t0_path, "w");
    sps1_file1 = $fopen(sps_conv2_out_t1_path, "w");
    sps1_file2 = $fopen(sps_conv2_out_t2_path, "w");
    sps1_file3 = $fopen(sps_conv2_out_t3_path, "w");
end

always@(posedge s_clk) begin
    if (u_simple_eyeriss_top.u_simple_eyeriss_Controller.r_cycle_cnt == 'd192 && u_simple_eyeriss_top.u_simple_eyeriss_Controller.Array_out_done) begin
        $display("sps conv2 data get done !");
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

parameter sps_lif2_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_lif2_out_t0.txt";
parameter sps_lif2_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_lif2_out_t1.txt";
parameter sps_lif2_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_lif2_out_t2.txt";
parameter sps_lif2_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_lif2_out_t3.txt";

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
        $display("sps lif2 data get done !");
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
parameter sps_maxpool1_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_maxpool1_out_t0.txt";
parameter sps_maxpool1_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_maxpool1_out_t1.txt";
parameter sps_maxpool1_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_maxpool1_out_t2.txt";
parameter sps_maxpool1_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_maxpool1_out_t3.txt";

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
        $display("sps maxpool_1 data get done !");
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
parameter sps_conv3_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_conv3_out_t0.txt";
parameter sps_conv3_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_conv3_out_t1.txt";
parameter sps_conv3_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_conv3_out_t2.txt";
parameter sps_conv3_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_conv3_out_t3.txt";

integer sps3_file0, sps3_file1, sps3_file2, sps3_file3;
initial begin
    sps3_file0 = $fopen(sps_conv3_out_t0_path, "w");
    sps3_file1 = $fopen(sps_conv3_out_t1_path, "w");
    sps3_file2 = $fopen(sps_conv3_out_t2_path, "w");
    sps3_file3 = $fopen(sps_conv3_out_t3_path, "w");
end

always@(posedge s_clk) begin
    if (u_simple_eyeriss_top.u_simple_eyeriss_Controller.r_cycle_cnt == 'd384 && u_simple_eyeriss_top.u_simple_eyeriss_Controller.Array_out_done) begin
        $display("sps conv3 data get done !");
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

parameter sps_lif3_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_lif3_out_t0.txt";
parameter sps_lif3_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_lif3_out_t1.txt";
parameter sps_lif3_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_lif3_out_t2.txt";
parameter sps_lif3_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_lif3_out_t3.txt";

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
        $display("sps lif3 data get done !");
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
parameter sps_maxpool2_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_maxpool2_out_t0.txt";
parameter sps_maxpool2_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_maxpool2_out_t1.txt";
parameter sps_maxpool2_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_maxpool2_out_t2.txt";
parameter sps_maxpool2_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_maxpool2_out_t3.txt";

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
        $display("sps maxpool_2 data get done !");
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
parameter sps_conv4_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_conv4_out_t0.txt";
parameter sps_conv4_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_conv4_out_t1.txt";
parameter sps_conv4_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_conv4_out_t2.txt";
parameter sps_conv4_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_conv4_out_t3.txt";

integer sps4_file0, sps4_file1, sps4_file2, sps4_file3;
initial begin
    sps4_file0 = $fopen(sps_conv4_out_t0_path, "w");
    sps4_file1 = $fopen(sps_conv4_out_t1_path, "w");
    sps4_file2 = $fopen(sps_conv4_out_t2_path, "w");
    sps4_file3 = $fopen(sps_conv4_out_t3_path, "w");
end

always@(posedge s_clk) begin
    if (sps_conv4_flag && u_simple_eyeriss_top.u_simple_eyeriss_Controller.r_cycle_cnt == 'd384 && u_simple_eyeriss_top.u_simple_eyeriss_Controller.Array_out_done) begin
        $display("sps conv4 data get done !");
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

parameter sps_lif4_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_lif4_out_t0.txt";
parameter sps_lif4_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_lif4_out_t1.txt";
parameter sps_lif4_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_lif4_out_t2.txt";
parameter sps_lif4_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/sps_lif4_out_t3.txt";

integer sps_lif4_file0, sps_lif4_file1, sps_lif4_file2, sps_lif4_file3;
initial begin
    sps_lif4_file0 = $fopen(sps_lif4_out_t0_path, "w");
    sps_lif4_file1 = $fopen(sps_lif4_out_t1_path, "w");
    sps_lif4_file2 = $fopen(sps_lif4_out_t2_path, "w");
    sps_lif4_file3 = $fopen(sps_lif4_out_t3_path, "w");
end

always@(posedge s_clk) begin
    if (sps_conv4_flag && u_simple_eyeriss_top.u_simple_eyeriss_Controller.r_cycle_cnt == 'd384 && u_simple_eyeriss_top.u_simple_eyeriss_Controller.Array_out_done) begin
        $display("sps lif4 data get done !");
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

endmodule // top_spikingencoder_tb
