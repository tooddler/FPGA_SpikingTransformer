/*
    --- ATTN @ V -> LIF -> RESHAPE --- 
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "../../hyper_para.v"
module attn_v_spikes_reshaping (
    input                                        s_clk                 ,
    input                                        s_rst                 ,
    // proj_lif(attn@v)-in  
    input [`TIME_STEPS*2 - 1 : 0]                i_spikes_out_ext      ,
    input                                        i_spikes_valid        ,
    // reshape-out
    output wire [`PATCH_EMBED_WIDTH*2 - 1 : 0]   o_attn_v_spikes_data  ,
    output wire                                  o_attn_v_spikes_valid 
);

localparam P_CNT_MAX = `PATCH_EMBED_WIDTH / `TIME_STEPS; // 8

// -- reg -- 
reg [$clog2(P_CNT_MAX) - 1 : 0]          r_reshape_cnt      ;
reg [`PATCH_EMBED_WIDTH*2 - 1 : 0]       r_spikes_register  ; // 64
reg                                      r_spikes_valid     ;

// -------------- main code -------------- \\
assign o_attn_v_spikes_data  = r_spikes_register ;
assign o_attn_v_spikes_valid = r_spikes_valid    ;

// r_reshape_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_reshape_cnt <= 'd0;
    else if (i_spikes_valid)
        r_reshape_cnt <= r_reshape_cnt + 1'b1;
end

// r_spikes_register
genvar k;
generate
    always@(posedge s_clk, posedge s_rst) begin
        if (s_rst)
            r_spikes_register[`TIME_STEPS*2 - 1 : 0] <= 'd0;
        else if (i_spikes_valid && r_reshape_cnt == 'd0)
            r_spikes_register[`TIME_STEPS*2 - 1 : 0] <= i_spikes_out_ext;
    end

    for (k = 1; k < P_CNT_MAX; k = k + 1) begin :  spikes_array
        always@(posedge s_clk, posedge s_rst) begin
            if (s_rst)
                r_spikes_register[(k+1)*`TIME_STEPS*2 - 1 : 2*k*`TIME_STEPS] <= 'd0;
            else if (i_spikes_valid && r_reshape_cnt == 'd0)
                r_spikes_register[(k+1)*`TIME_STEPS*2 - 1 : 2*k*`TIME_STEPS] <= 'd0;
            else if (i_spikes_valid && r_reshape_cnt == k)
                r_spikes_register[(k+1)*`TIME_STEPS*2 - 1 : 2*k*`TIME_STEPS] <= i_spikes_out_ext;
        end
    end
endgenerate

// r_spikes_valid
always@(posedge s_clk) begin
    if (r_reshape_cnt == P_CNT_MAX - 1 && i_spikes_valid)
        r_spikes_valid <= 1'b1;
    else
        r_spikes_valid <= 1'b0;
end

endmodule // attn_v_spikes_reshaping
