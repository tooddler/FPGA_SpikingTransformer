/*
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
    func    : Spikformer ATTN Block testbench
    sim-time: 600 us
*/

`include "hyper_para.v"
module AttnCalcBlock_tb ();

reg                                                      s_clk                ;
reg                                                      s_rst                ;

wire                                                     w_SpikesTmpRam_Ready ; 
wire [9 : 0]                                             w_QueryRam_rdaddr    ; 
wire [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]          w_QueryRam_out       ; 
wire [9 : 0]                                             w_KeyRam_rdaddr      ; 
wire [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]          w_KeyRam_out         ; 
wire [9 : 0]                                             w_ValueRam_rdaddr    ; 
wire [2*`SYSTOLIC_UNIT_NUM*`TIME_STEPS - 1 : 0]          w_ValueRam_out       ; 

wire                                                     w_AttnRAM_Ready      ;
wire [$clog2(2*`SYSTOLIC_UNIT_NUM)*`TIME_STEPS - 1 : 0]  w_Calc_data          ;
wire                                                     w_Calc_valid         ;

wire                                                     w_AttnRam_Done       ; 
wire [11 : 0]                                            w_AttnRam_rd_addr    ; 
wire                                                     w_AttnRAM_Empty      ; 
wire [$clog2(2*`SYSTOLIC_UNIT_NUM)*`TIME_STEPS - 1 : 0]  w_AttnRAM_data       ; 

wire [`TIME_STEPS * `FINAL_FMAPS_CHNNLS / `MULTI_HEAD_NUMS  - 1 : 0]    w_spikes_out   ;
wire                                                                    w_spikes_valid ;

initial s_clk = 1'b1;
always #(`CLK_PERIOD/2) s_clk = ~s_clk;

initial begin
    s_rst = 1'b1;
    # 201;
    s_rst = 1'b0;
    # 400;
    # 4000;
end

qkv_BRAM_group u_qkv_BRAM_group(
    .s_clk                 ( s_clk                 ),
    .s_rst                 ( s_rst                 ),

    .i00_spikesLine_in     (  ),
    .i00_spikesLine_valid  (  ),
    .i01_spikesLine_in     (  ),
    .i01_spikesLine_valid  (  ),
    .i02_spikesLine_in     (  ),
    .i02_spikesLine_valid  (  ),
    .o_SpikesTmpRam_Ready  ( w_SpikesTmpRam_Ready  ),

    .i_QueryRam_rdaddr     ( w_QueryRam_rdaddr     ),
    .o_QueryRam_out        ( w_QueryRam_out        ),
    .i_KeyRam_rdaddr       ( w_KeyRam_rdaddr       ),
    .o_KeyRam_out          ( w_KeyRam_out          ),
    .i_ValueRam_rdaddr     ( w_ValueRam_rdaddr     ),
    .o_ValueRam_out        ( w_ValueRam_out        )
);

SpikesAccumulation u_SpikesAccumulation(
    .s_clk                 ( s_clk                 ),
    .s_rst                 ( s_rst                 ),

    .i_SpikesTmpRam_Ready  ( w_SpikesTmpRam_Ready  ),
    .o_QueryRam_rdaddr     ( w_QueryRam_rdaddr     ),
    .i_QueryRam_out        ( w_QueryRam_out        ),
    .o_KeyRam_rdaddr       ( w_KeyRam_rdaddr       ),
    .i_KeyRam_out          ( w_KeyRam_out          ),

    .i_AttnRAM_Ready       ( w_AttnRAM_Ready       ),
    .o_Calc_data           ( w_Calc_data           ),
    .o_Calc_valid          ( w_Calc_valid          )
);

Tmp_AttnRAM_group u_Tmp_AttnRAM_group(
    .s_clk                 ( s_clk                 ),
    .s_rst                 ( s_rst                 ),

    .o_AttnRAM_Ready       ( w_AttnRAM_Ready       ),
    .i_Calc_data           ( w_Calc_data           ),
    .i_Calc_valid          ( w_Calc_valid          ),

    .i_AttnRam_Done        ( w_AttnRam_Done        ),
    .i_AttnRam_rd_addr     ( w_AttnRam_rd_addr     ),
    .o_AttnRAM_Empty       ( w_AttnRAM_Empty       ),
    .o_AttnRAM_data        ( w_AttnRAM_data        )
);

MM_Calculator u_MM_Calculator(
    .s_clk                 ( s_clk                 ),
    .s_rst                 ( s_rst                 ),

    .o_AttnRam_Done        ( w_AttnRam_Done        ),
    .o_AttnRam_rd_addr     ( w_AttnRam_rd_addr     ),
    .i_AttnRAM_Empty       ( w_AttnRAM_Empty       ),
    .i_AttnRAM_data        ( w_AttnRAM_data        ),

    .o_ValueRam_rdaddr     ( w_ValueRam_rdaddr     ),
    .i_ValueRam_out        ( w_ValueRam_out        ),

    .o_spikes_out          ( w_spikes_out          ),
    .o_spikes_valid        ( w_spikes_valid        )
);

// GET DATA ----------------------------------------------------------------------------------------------------------------
parameter attn_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/Calc_attn_out_t0.txt";
parameter attn_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/Calc_attn_out_t1.txt";
parameter attn_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/Calc_attn_out_t2.txt";
parameter attn_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/Calc_attn_out_t3.txt";

integer file0, 
        file1, 
        file2, 
        file3;
reg [15 : 0]        r_Calc_attn_cnt=0 ;

initial begin
    file0 = $fopen(attn_out_t0_path, "w");
    file1 = $fopen(attn_out_t1_path, "w");
    file2 = $fopen(attn_out_t2_path, "w");
    file3 = $fopen(attn_out_t3_path, "w");
end
 
always@(posedge s_clk) begin
    if (r_Calc_attn_cnt == 'd49152) begin
        $display("attn cal done");
        $fclose(file0);
        $fclose(file1);
        $fclose(file2);
        $fclose(file3);
    end
    else if (w_Calc_valid) begin
        r_Calc_attn_cnt <= r_Calc_attn_cnt + 1'b1;
        $fwrite(file0, "%d\n", w_Calc_data[$clog2(2*`SYSTOLIC_UNIT_NUM) * 1 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM) * 0]); 
        $fwrite(file1, "%d\n", w_Calc_data[$clog2(2*`SYSTOLIC_UNIT_NUM) * 2 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM) * 1]); 
        $fwrite(file2, "%d\n", w_Calc_data[$clog2(2*`SYSTOLIC_UNIT_NUM) * 3 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM) * 2]); 
        $fwrite(file3, "%d\n", w_Calc_data[$clog2(2*`SYSTOLIC_UNIT_NUM) * 4 - 1 : $clog2(2*`SYSTOLIC_UNIT_NUM) * 3]); 
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

integer attnV_i;
reg [15 : 0]        r_CalcMulti_attnv_cnt=0 ;

initial begin
    attnVfile0 = $fopen(attn_v_out_t0_path, "w");
    attnVfile1 = $fopen(attn_v_out_t1_path, "w");
    attnVfile2 = $fopen(attn_v_out_t2_path, "w");
    attnVfile3 = $fopen(attn_v_out_t3_path, "w");
end

always@(posedge s_clk) begin
    if (r_CalcMulti_attnv_cnt == 'd768) begin
        $display("attn @ V cal done");
        $fclose(attnVfile0);
        $fclose(attnVfile1);
        $fclose(attnVfile2);
        $fclose(attnVfile3);
    end
    else if (u_MM_Calculator.r_rdfifo_valid) begin
        r_CalcMulti_attnv_cnt <= r_CalcMulti_attnv_cnt + 1'b1;
        for (attnV_i = 0; attnV_i < `FINAL_FMAPS_CHNNLS / `MULTI_HEAD_NUMS; attnV_i = attnV_i + 1) begin
            $fwrite(attnVfile0, "%d\n", u_MM_Calculator.w_rdfifo_data[attnV_i][11:0]); 
            $fwrite(attnVfile1, "%d\n", u_MM_Calculator.w_rdfifo_data[attnV_i][23:12]); 
            $fwrite(attnVfile2, "%d\n", u_MM_Calculator.w_rdfifo_data[attnV_i][35:24]); 
            $fwrite(attnVfile3, "%d\n", u_MM_Calculator.w_rdfifo_data[attnV_i][47:36]); 
        end
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

wire [`SYSTOLIC_UNIT_NUM*`TIME_STEPS / 2 - 1 : 0]       w_attnv_Spikes_t0 ;
wire [`SYSTOLIC_UNIT_NUM*`TIME_STEPS / 2 - 1 : 0]       w_attnv_Spikes_t1 ;
wire [`SYSTOLIC_UNIT_NUM*`TIME_STEPS / 2 - 1 : 0]       w_attnv_Spikes_t2 ;
wire [`SYSTOLIC_UNIT_NUM*`TIME_STEPS / 2 - 1 : 0]       w_attnv_Spikes_t3 ;

genvar m;
generate
    for (m = 0; m < `SYSTOLIC_UNIT_NUM*`TIME_STEPS / 2; m = m + 1) begin
        assign w_attnv_Spikes_t0[m] = w_spikes_out[`TIME_STEPS * m + 0]; 
        assign w_attnv_Spikes_t1[m] = w_spikes_out[`TIME_STEPS * m + 1];
        assign w_attnv_Spikes_t2[m] = w_spikes_out[`TIME_STEPS * m + 2];
        assign w_attnv_Spikes_t3[m] = w_spikes_out[`TIME_STEPS * m + 3];
    end
endgenerate

initial begin
    lif_attnVfile0 = $fopen(lif_attn_v_out_t0_path, "w");
    lif_attnVfile1 = $fopen(lif_attn_v_out_t1_path, "w");
    lif_attnVfile2 = $fopen(lif_attn_v_out_t2_path, "w");
    lif_attnVfile3 = $fopen(lif_attn_v_out_t3_path, "w");
end

always@(posedge s_clk) begin
    if (r_lif_CalcMulti_attnv_cnt == 'd768) begin
        $display("lif attn @ V cal done");
        $fclose(lif_attnVfile0);
        $fclose(lif_attnVfile1);
        $fclose(lif_attnVfile2);
        $fclose(lif_attnVfile3);
    end
    else if (w_spikes_valid) begin
        r_lif_CalcMulti_attnv_cnt <= r_lif_CalcMulti_attnv_cnt + 1'b1;
        for (lif_attnV_i = 0; lif_attnV_i < `FINAL_FMAPS_CHNNLS / `MULTI_HEAD_NUMS; lif_attnV_i = lif_attnV_i + 1) begin
            $fwrite(lif_attnVfile0, "%b\n", w_attnv_Spikes_t0[lif_attnV_i]); 
            $fwrite(lif_attnVfile1, "%b\n", w_attnv_Spikes_t1[lif_attnV_i]); 
            $fwrite(lif_attnVfile2, "%b\n", w_attnv_Spikes_t2[lif_attnV_i]); 
            $fwrite(lif_attnVfile3, "%b\n", w_attnv_Spikes_t3[lif_attnV_i]); 
        end
    end
end

endmodule // AttnCalcBlock_tb
