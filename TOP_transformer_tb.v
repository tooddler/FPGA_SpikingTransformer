/*
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
    func    : Transformer Block testbench
    sim-time: 3365 us -> multi_layer_start
              12640 us -> multi_layer_end
              total_time: 12640 - 3365 = 9275 us
*/

`include "hyper_para.v"
module TOP_transformer_tb ();

reg                                                  s_clk                   ;
reg                                                  s_rst                   ;

wire    [`DATA_WIDTH- 1 : 0]                         M_lq_rd_burst_data      ;
wire    [`ADDR_SIZE - 1 : 0]                         M_lq_rd_burst_addr      ;
wire    [`LEN_WIDTH - 1 : 0]                         M_lq_rd_burst_len       ;
wire                                                 M_lq_rd_burst_req       ;
wire                                                 M_lq_rd_burst_valid     ;
wire                                                 M_lq_rd_burst_finish    ;

wire    [`DATA_WIDTH- 1 : 0]                         M_lk_rd_burst_data      ;
wire    [`ADDR_SIZE - 1 : 0]                         M_lk_rd_burst_addr      ;
wire    [`LEN_WIDTH - 1 : 0]                         M_lk_rd_burst_len       ;
wire                                                 M_lk_rd_burst_req       ;
wire                                                 M_lk_rd_burst_valid     ;
wire                                                 M_lk_rd_burst_finish    ;

wire    [`DATA_WIDTH- 1 : 0]                         M_lv_rd_burst_data      ;
wire    [`ADDR_SIZE - 1 : 0]                         M_lv_rd_burst_addr      ;
wire    [`LEN_WIDTH - 1 : 0]                         M_lv_rd_burst_len       ;
wire                                                 M_lv_rd_burst_req       ;
wire                                                 M_lv_rd_burst_valid     ;
wire                                                 M_lv_rd_burst_finish    ;

wire    [`DATA_WIDTH- 1 : 0]                         burst_read_data         ;
wire    [`ADDR_SIZE - 1 : 0]                         burst_read_addr         ;
wire    [`LEN_WIDTH - 1 : 0]                         burst_read_len          ;
wire                                                 burst_read_req          ;
wire                                                 burst_read_valid        ;
wire                                                 burst_read_finish       ;

initial s_clk = 1'b1;
always #(`CLK_PERIOD/2) s_clk = ~s_clk;

initial begin
    s_rst = 1'b1;
    # 201;
    s_rst = 1'b0;
    # 4000;
end

// --------------- ddr Arbiter --------------- \\ 
ddr_sim_spikformer u_ddr_sim_spikformer(
    .user_clk                ( s_clk                   ),
    .user_rst                ( s_rst                   ),

    .burst_write_data        ( 'd0                     ),
    .burst_write_addr        ( 'd0                     ),
    .burst_write_len         ( 'd0                     ),
    .burst_write_req         ( 1'b0                    ),
    .burst_write_valid       (   ),
    .burst_write_finish      (   ),

    .burst_read_data         ( burst_read_data         ),
    .burst_read_addr         ( burst_read_addr         ),
    .burst_read_len          ( burst_read_len          ),
    .burst_read_req          ( burst_read_req          ),
    .burst_read_valid        ( burst_read_valid        ),
    .burst_read_finish       ( burst_read_finish       )
);

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
    
    .r03_burst_read_data     (  ),
    .r03_burst_read_addr     ( 'd0  ),
    .r03_burst_read_len      ( 'd0  ),
    .r03_burst_read_req      ( 1'b0 ),
    .r03_burst_read_valid    (  ),
    .r03_burst_read_finish   (  ),

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

// --------------- TOP Transformer Instance --------------- \\ 
TOP_Transformer u_TOP_Transformer(
    .s_clk                  ( s_clk                    ),
    .s_rst                  ( s_rst                    ),

    .i_load_w_finish        ( 'd0                      ),
    .i_data_valid           ( 'd0                      ),
    .i_fmap                 ( 'd0                      ),
    .i_patchdata            ( 'd0                      ),
    
    .M_lq_rd_burst_data     ( M_lq_rd_burst_data       ),
    .M_lq_rd_burst_addr     ( M_lq_rd_burst_addr       ),
    .M_lq_rd_burst_len      ( M_lq_rd_burst_len        ),
    .M_lq_rd_burst_req      ( M_lq_rd_burst_req        ),
    .M_lq_rd_burst_valid    ( M_lq_rd_burst_valid      ),
    .M_lq_rd_burst_finish   ( M_lq_rd_burst_finish     ),
    
    .M_lk_rd_burst_data     ( M_lk_rd_burst_data       ),
    .M_lk_rd_burst_addr     ( M_lk_rd_burst_addr       ),
    .M_lk_rd_burst_len      ( M_lk_rd_burst_len        ),
    .M_lk_rd_burst_req      ( M_lk_rd_burst_req        ),
    .M_lk_rd_burst_valid    ( M_lk_rd_burst_valid      ),
    .M_lk_rd_burst_finish   ( M_lk_rd_burst_finish     ),
    
    .M_lv_rd_burst_data     ( M_lv_rd_burst_data       ),
    .M_lv_rd_burst_addr     ( M_lv_rd_burst_addr       ),
    .M_lv_rd_burst_len      ( M_lv_rd_burst_len        ),
    .M_lv_rd_burst_req      ( M_lv_rd_burst_req        ),
    .M_lv_rd_burst_valid    ( M_lv_rd_burst_valid      ),
    .M_lv_rd_burst_finish   ( M_lv_rd_burst_finish     )
);


// GET DATA ----------------------------------------------------------------------------------------------------------------
parameter linear_q_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_q_out_t0.txt";
parameter linear_q_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_q_out_t1.txt";
parameter linear_q_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_q_out_t2.txt";
parameter linear_q_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_q_out_t3.txt";

reg    r_lq_PsumFIFO_Finish_d0;
reg    r_lq_PsumFIFO_Finish_d1;

integer file0, 
        file1, 
        file2, 
        file3;

initial begin
    file0 = $fopen(linear_q_out_t0_path, "w");
    file1 = $fopen(linear_q_out_t1_path, "w");
    file2 = $fopen(linear_q_out_t2_path, "w");
    file3 = $fopen(linear_q_out_t3_path, "w");
end

always@(posedge s_clk) begin
    r_lq_PsumFIFO_Finish_d0 <= u_TOP_Transformer.w_lq_PsumFIFO_Finish;
    r_lq_PsumFIFO_Finish_d1 <= r_lq_PsumFIFO_Finish_d0 ;

    if (r_lq_PsumFIFO_Finish_d1) begin
        $display("linear_q_out cal done");
        $fclose(file0);
        $fclose(file1);
        $fclose(file2);
        $fclose(file3);
    end
    else if (u_TOP_Transformer.w_lq_PsumValid) begin
        $fwrite(file0, "%d\n", $signed(u_TOP_Transformer.w_lq_PsumData[1*20 - 1 : 0*20])); 
        $fwrite(file1, "%d\n", $signed(u_TOP_Transformer.w_lq_PsumData[2*20 - 1 : 1*20])); 
        $fwrite(file2, "%d\n", $signed(u_TOP_Transformer.w_lq_PsumData[3*20 - 1 : 2*20])); 
        $fwrite(file3, "%d\n", $signed(u_TOP_Transformer.w_lq_PsumData[4*20 - 1 : 3*20])); 
    end
end

parameter linear_k_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_k_out_t0.txt";
parameter linear_k_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_k_out_t1.txt";
parameter linear_k_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_k_out_t2.txt";
parameter linear_k_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_k_out_t3.txt";

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

parameter linear_v_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_v_out_t0.txt";
parameter linear_v_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_v_out_t1.txt";
parameter linear_v_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_v_out_t2.txt";
parameter linear_v_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_v_out_t3.txt";

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
parameter attn_lif_q_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_lif_q_out_t0.txt";
parameter attn_lif_q_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_lif_q_out_t1.txt";
parameter attn_lif_q_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_lif_q_out_t2.txt";
parameter attn_lif_q_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_lif_q_out_t3.txt";
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

parameter attn_lif_k_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_lif_k_out_t0.txt";
parameter attn_lif_k_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_lif_k_out_t1.txt";
parameter attn_lif_k_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_lif_k_out_t2.txt";
parameter attn_lif_k_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_lif_k_out_t3.txt";
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

parameter attn_lif_v_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_lif_v_out_t0.txt";
parameter attn_lif_v_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_lif_v_out_t1.txt";
parameter attn_lif_v_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_lif_v_out_t2.txt";
parameter attn_lif_v_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_lif_v_out_t3.txt";
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
parameter align_lif_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/align_lif_out_t0.txt";
parameter align_lif_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/align_lif_out_t1.txt";
parameter align_lif_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/align_lif_out_t2.txt";
parameter align_lif_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/align_lif_out_t3.txt";

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

parameter attn_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/Calc_attn_out_t0.txt";
parameter attn_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/Calc_attn_out_t1.txt";
parameter attn_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/Calc_attn_out_t2.txt";
parameter attn_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/Calc_attn_out_t3.txt";

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

parameter attn_v_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/CalcMulti_attnV_out_t0.txt";
parameter attn_v_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/CalcMulti_attnV_out_t1.txt";
parameter attn_v_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/CalcMulti_attnV_out_t2.txt";
parameter attn_v_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/CalcMulti_attnV_out_t3.txt";

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

parameter lif_attn_v_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/lif_CalcMulti_attnV_out_t0.txt";
parameter lif_attn_v_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/lif_CalcMulti_attnV_out_t1.txt";
parameter lif_attn_v_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/lif_CalcMulti_attnV_out_t2.txt";
parameter lif_attn_v_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/lif_CalcMulti_attnV_out_t3.txt";

integer lif_attnVfile0, 
        lif_attnVfile1, 
        lif_attnVfile2, 
        lif_attnVfile3;

integer lif_attnV_i;
reg [15 : 0]        r_lif_CalcMulti_attnv_cnt=0 ;

wire [1 : 0]        w_trsfrmrdata    [`PATCH_EMBED_WIDTH - 1 : 0];
genvar nnnn;
generate
    for (nnnn = 0; nnnn < `PATCH_EMBED_WIDTH; nnnn = nnnn + 1) begin
        assign w_trsfrmrdata[nnnn] = u_TOP_Transformer.w_attn_v_spikes_data[2*nnnn + 1 : 2*nnnn];
    end
endgenerate

initial begin
    lif_attnVfile0 = $fopen(lif_attn_v_out_t0_path, "w");
    lif_attnVfile1 = $fopen(lif_attn_v_out_t1_path, "w");
    lif_attnVfile2 = $fopen(lif_attn_v_out_t2_path, "w");
    lif_attnVfile3 = $fopen(lif_attn_v_out_t3_path, "w");
end

integer embedpatch_num;
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
        for (embedpatch_num = 0; embedpatch_num < 8; embedpatch_num = embedpatch_num + 1) begin
            $fwrite(lif_attnVfile0, "%d\n", w_trsfrmrdata[4*embedpatch_num + 0]); 
            $fwrite(lif_attnVfile1, "%d\n", w_trsfrmrdata[4*embedpatch_num + 1]); 
            $fwrite(lif_attnVfile2, "%d\n", w_trsfrmrdata[4*embedpatch_num + 2]); 
            $fwrite(lif_attnVfile3, "%d\n", w_trsfrmrdata[4*embedpatch_num + 3]); 
        end
    end
end

// ======= MLP =======
parameter mlp_projfc_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/mlp_projfc_out_t0.txt";
parameter mlp_projfc_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/mlp_projfc_out_t1.txt";
parameter mlp_projfc_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/mlp_projfc_out_t2.txt";
parameter mlp_projfc_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/mlp_projfc_out_t3.txt";

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

parameter mlp_fc0_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/mlp_fc0_out_t0.txt";
parameter mlp_fc0_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/mlp_fc0_out_t1.txt";
parameter mlp_fc0_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/mlp_fc0_out_t2.txt";
parameter mlp_fc0_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/mlp_fc0_out_t3.txt";

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


parameter mlp_fc1_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/mlp_fc1_out_t0.txt";
parameter mlp_fc1_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/mlp_fc1_out_t1.txt";
parameter mlp_fc1_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/mlp_fc1_out_t2.txt";
parameter mlp_fc1_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/mlp_fc1_out_t3.txt";

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
parameter before_act_mlp_projfc_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/before_act_mlp_projfc_t0.txt";
parameter before_act_mlp_projfc_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/before_act_mlp_projfc_t1.txt";
parameter before_act_mlp_projfc_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/before_act_mlp_projfc_t2.txt";
parameter before_act_mlp_projfc_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/before_act_mlp_projfc_t3.txt";

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

parameter before_act_mlp_fc0_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/before_act_mlp_fc0_t0.txt";
parameter before_act_mlp_fc0_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/before_act_mlp_fc0_t1.txt";
parameter before_act_mlp_fc0_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/before_act_mlp_fc0_t2.txt";
parameter before_act_mlp_fc0_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/before_act_mlp_fc0_t3.txt";

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

parameter before_act_mlp_fc1_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/before_act_mlp_fc1_t0.txt";
parameter before_act_mlp_fc1_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/before_act_mlp_fc1_t1.txt";
parameter before_act_mlp_fc1_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/before_act_mlp_fc1_t2.txt";
parameter before_act_mlp_fc1_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/before_act_mlp_fc1_t3.txt";

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
parameter input_add_projfc_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/input_add_projfc_t0.txt";
parameter input_add_projfc_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/input_add_projfc_t1.txt";
parameter input_add_projfc_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/input_add_projfc_t2.txt";
parameter input_add_projfc_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/input_add_projfc_t3.txt";

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
