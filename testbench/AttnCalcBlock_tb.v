/*
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
    func    : Spikformer ATTN Block testbench
    sim-time: 820 us
*/

`include "../hyper_para.v"
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

wire [`PATCH_EMBED_WIDTH*2 - 1 : 0]                      w_attn_v_spikes_data ;
wire                                                     w_attn_v_spikes_valid;
wire                                                     w_attn_v_spikes_done ;

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

    .o_attn_v_spikes_data  ( w_attn_v_spikes_data  ),
    .o_attn_v_spikes_valid ( w_attn_v_spikes_valid ),
    .o_attn_v_spikes_done  ( w_attn_v_spikes_done  )
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
    else if (| u_MM_Calculator.r_rdfifo_valid) begin
        r_CalcMulti_attnv_cnt <= r_CalcMulti_attnv_cnt + 1'b1;
        $fwrite(attnVfile0, "%d\n", u_MM_Calculator.r4lif_rdfifo_data[11:0]); 
        $fwrite(attnVfile1, "%d\n", u_MM_Calculator.r4lif_rdfifo_data[23:12]); 
        $fwrite(attnVfile2, "%d\n", u_MM_Calculator.r4lif_rdfifo_data[35:24]); 
        $fwrite(attnVfile3, "%d\n", u_MM_Calculator.r4lif_rdfifo_data[47:36]); 
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
        assign w_trsfrmrdata[nnnn] = w_attn_v_spikes_data[2*nnnn + 1 : 2*nnnn];
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
    else if (w_attn_v_spikes_valid) begin
        r_lif_CalcMulti_attnv_cnt <= r_lif_CalcMulti_attnv_cnt + 1'b1;
        for (embedpatch_num = 0; embedpatch_num < 8; embedpatch_num = embedpatch_num + 1) begin
            $fwrite(lif_attnVfile0, "%d\n", w_trsfrmrdata[4*embedpatch_num + 0]); 
            $fwrite(lif_attnVfile1, "%d\n", w_trsfrmrdata[4*embedpatch_num + 1]); 
            $fwrite(lif_attnVfile2, "%d\n", w_trsfrmrdata[4*embedpatch_num + 2]); 
            $fwrite(lif_attnVfile3, "%d\n", w_trsfrmrdata[4*embedpatch_num + 3]); 
        end
    end
end


endmodule // AttnCalcBlock_tb
