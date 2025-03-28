/*
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
    func    : Spikformer Encoder Block testbench
*/

`include "hyper_para.v"
module SpikformerEncoderBlock_tb ();

reg                                     s_clk               ;
reg                                     s_rst               ;

wire [11 : 0]                           w_rd_addr           ;
wire [`PATCH_EMBED_WIDTH * 2 - 1 : 0]   w_ramout_data       ;
wire                                    w_ramout_ready      ;

wire     [`DATA_WIDTH - 1 : 0]          w_weight_out        ;
wire                                    w_weight_valid      ;
wire                                    w_weight_ready      ;
wire                                    load_w_finish       ;

wire                                    MtrxA_slice_valid   ;
wire  [`DATA_WIDTH - 1 : 0]             MtrxA_slice_data    ;
wire                                    MtrxA_slice_done    ;
wire                                    MtrxA_slice_ready   ;
wire                                    MtrxB_slice_valid   ;
wire  [`DATA_WIDTH - 1 : 0]             MtrxB_slice_data    ;
wire                                    MtrxB_slice_done    ;
wire                                    MtrxB_slice_ready   ;

wire                                    w_Init_PrepareData  ;
wire                                    w_Finish_Calc       ;

wire [`SYSTOLIC_UNIT_NUM - 1 : 0]       w_PsumFIFO_Grant    ;
wire                                    w_PsumFIFO_Valid    ;
wire                                    w_PsumFIFO_Finish   ;
reg                                     r_PsumFIFO_Valid    ;

reg                                     r_PsumFIFO_Finish_d0;
reg                                     r_PsumFIFO_Finish_d1;

wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]     w_PsumFIFO_Data     ;

wire [`DATA_WIDTH- 1 : 0]               M_lq_rd_burst_data   ;
wire [`ADDR_SIZE - 1 : 0]               M_lq_rd_burst_addr   ;
wire [`LEN_WIDTH - 1 : 0]               M_lq_rd_burst_len    ;
wire                                    M_lq_rd_burst_req    ;
wire                                    M_lq_rd_burst_valid  ;
wire                                    M_lq_rd_burst_finish ;

wire [`SYSTOLIC_PSUM_WIDTH - 1 : 0]     w_PsumData          ;
wire                                    w_PsumValid         ;

initial s_clk = 1'b1;
always #(`CLK_PERIOD/2) s_clk = ~s_clk;

initial begin
    s_rst = 1'b1;
    # 201;
    s_rst = 1'b0;
    # 400;
    # 4000;
end

ddr_sim_spikformer u_ddr_sim_spikformer(
    .user_clk            ( s_clk               ),
    .user_rst            ( s_rst               ),

    .burst_write_data    ( 'd0                 ),
    .burst_write_addr    ( 'd0                 ),
    .burst_write_len     ( 'd0                 ),
    .burst_write_req     ( 1'b0                ),
    .burst_write_valid   (   ),
    .burst_write_finish  (   ),

    .burst_read_data     ( M_lq_rd_burst_data   ),
    .burst_read_addr     ( M_lq_rd_burst_addr   ),
    .burst_read_len      ( M_lq_rd_burst_len    ),
    .burst_read_req      ( M_lq_rd_burst_req    ),
    .burst_read_valid    ( M_lq_rd_burst_valid  ),
    .burst_read_finish   ( M_lq_rd_burst_finish )
);

PatchEmbed u_PatchEmbed (
    .s_clk                  ( s_clk             ),
    .s_rst                  ( s_rst             ),
    .i_data_valid           ( 'd0               ),
    .i_fmap                 ( 'd0               ),
    .i_patchdata            ( 'd0               ),
    .i_rd_addr              ( w_rd_addr         ),
    .o_ramout_data          ( w_ramout_data     ),
    .o_ramout_ready         ( w_ramout_ready    )
);

weight_fifo_v1 #(
    .WEIGHTS_BASEADDR       ( `WEIGHTS_Q_BASEADDR  )
) u_weight_fifo_linear_Q(
    .s_clk                  ( s_clk                ),
    .s_rst                  ( s_rst                ),

    .rd_burst_data          ( M_lq_rd_burst_data   ),
    .rd_burst_addr          ( M_lq_rd_burst_addr   ),
    .rd_burst_len           ( M_lq_rd_burst_len    ),
    .rd_burst_req           ( M_lq_rd_burst_req    ),
    .rd_burst_valid         ( M_lq_rd_burst_valid  ),
    .rd_burst_finish        ( M_lq_rd_burst_finish ),

    .o_weight_out           ( w_weight_out         ),
    .i_weight_valid         ( w_weight_valid       ),
    .o_weight_ready         ( w_weight_ready       ),
    .load_w_finish          ( load_w_finish        )
);

SystolicController u_SystolicController(
    .s_clk               ( s_clk               ),
    .s_rst               ( s_rst               ),

    .o_rd_addr           ( w_rd_addr           ),
    .i_ramout_data       ( w_ramout_data       ),
    .i_ramout_ready      ( w_ramout_ready      ),

    .i_weight_out        ( w_weight_out        ),
    .o_weight_valid      ( w_weight_valid      ),
    .i_weight_ready      ( w_weight_ready      ),
    .load_w_finish       ( load_w_finish       ),

    .o_Init_PrepareData  ( w_Init_PrepareData  ),
    .i_Finish_Calc       ( w_Finish_Calc       ),

    .MtrxA_slice_valid   ( MtrxA_slice_valid   ),
    .MtrxA_slice_data    ( MtrxA_slice_data    ),
    .MtrxA_slice_done    ( MtrxA_slice_done    ),
    .MtrxA_slice_ready   ( MtrxA_slice_ready   ),
    .MtrxB_slice_valid   ( MtrxB_slice_valid   ),
    .MtrxB_slice_data    ( MtrxB_slice_data    ),
    .MtrxB_slice_done    ( MtrxB_slice_done    ),
    .MtrxB_slice_ready   ( MtrxB_slice_ready   ),

    .o_PsumFIFO_Grant    ( w_PsumFIFO_Grant    ),
    .o_PsumFIFO_Valid    ( w_PsumFIFO_Valid    ),
    .i_PsumFIFO_Data     ( w_PsumFIFO_Data     ),

    .o_Psum_Finish       ( w_PsumFIFO_Finish   ),
    .o_PsumData          ( w_PsumData          ),
    .o_PsumValid         ( w_PsumValid         )
);

SystolicArray u_SystolicArray(
    .s_clk                ( s_clk                ),
    .s_rst                ( s_rst                ),

    .i_Init_PrepareData   ( w_Init_PrepareData   ),
    .o_Finish_Calc        ( w_Finish_Calc        ),

    .MtrxA_slice_valid    ( MtrxA_slice_valid    ),
    .MtrxA_slice_data     ( MtrxA_slice_data     ),
    .MtrxA_slice_done     ( MtrxA_slice_done     ),
    .MtrxA_slice_ready    ( MtrxA_slice_ready    ),
    .MtrxB_slice_valid    ( MtrxB_slice_valid    ),
    .MtrxB_slice_data     ( MtrxB_slice_data     ),
    .MtrxB_slice_done     ( MtrxB_slice_done     ),
    .MtrxB_slice_ready    ( MtrxB_slice_ready    ),

    .i_PsumFIFO_Grant     ( w_PsumFIFO_Grant     ),
    .i_PsumFIFO_Valid     ( w_PsumFIFO_Valid     ),
    .o_PsumFIFO_Data      ( w_PsumFIFO_Data      )
);

parameter linear_q_out_t0_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_q_out_t0.txt";
parameter linear_q_out_t1_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_q_out_t1.txt";
parameter linear_q_out_t2_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_q_out_t2.txt";
parameter linear_q_out_t3_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/attn_linear_q_out_t3.txt";

integer file0, file1, file2, file3;
initial begin
    file0 = $fopen(linear_q_out_t0_path, "w");
    file1 = $fopen(linear_q_out_t1_path, "w");
    file2 = $fopen(linear_q_out_t2_path, "w");
    file3 = $fopen(linear_q_out_t3_path, "w");
end

always@(posedge s_clk) begin
    r_PsumFIFO_Finish_d0 <= w_PsumFIFO_Finish    ;
    r_PsumFIFO_Finish_d1 <= r_PsumFIFO_Finish_d0 ;

    if (r_PsumFIFO_Finish_d1) begin
        $display("linear_q_out cal done");
        $fclose(file0);
        $fclose(file1);
        $fclose(file2);
        $fclose(file3);
    end
    else if (w_PsumValid) begin
        $fwrite(file0, "%d\n", $signed(w_PsumData[1*20 - 1 : 0*20])); 
        $fwrite(file1, "%d\n", $signed(w_PsumData[2*20 - 1 : 1*20])); 
        $fwrite(file2, "%d\n", $signed(w_PsumData[3*20 - 1 : 2*20])); 
        $fwrite(file3, "%d\n", $signed(w_PsumData[4*20 - 1 : 3*20])); 
    end
end

endmodule // SpikformerEncoderBlock_tb
