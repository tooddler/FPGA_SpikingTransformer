
`include "../../hyper_para.v"
module mutil_unit_sim (
    input                                                    s_clk               ,
    input                                                    s_rst               ,

    input                                                    valid               ,
    input       [`SYSTOLIC_DATA_WIDTH - 1 : 0]               a                   ,  
    input       [`SYSTOLIC_DATA_WIDTH - 1 : 0]               b                   ,  

    output reg  [`SYSTOLIC_PSUM_WIDTH - 1 : 0]               rlst                ,
    output reg                                               rlst_vld  
);

wire signed [`SYSTOLIC_PSUM_WIDTH - 1 : 0]         w_multi_data ;

reg                                             r_vld_delay_r0  ;
reg                                             r_vld_delay_r1  ;
reg                                             r_vld_delay_r2  ;
reg                                             r_vld_delay_r3  ;

reg [`SYSTOLIC_DATA_WIDTH - 1 : 0]              r_a_r0  ;
reg [`SYSTOLIC_DATA_WIDTH - 1 : 0]              r_a_r1  ;
reg [`SYSTOLIC_DATA_WIDTH - 1 : 0]              r_a_r2  ;
reg [`SYSTOLIC_DATA_WIDTH - 1 : 0]              r_a_r3  ;

reg [`SYSTOLIC_DATA_WIDTH - 1 : 0]              r_b_r0  ;
reg [`SYSTOLIC_DATA_WIDTH - 1 : 0]              r_b_r1  ;
reg [`SYSTOLIC_DATA_WIDTH - 1 : 0]              r_b_r2  ;
reg [`SYSTOLIC_DATA_WIDTH - 1 : 0]              r_b_r3  ;

assign w_multi_data = $signed(r_a_r3) * $signed(r_b_r3);

always@(posedge s_clk) begin
    r_vld_delay_r0 <= valid         ;
    r_vld_delay_r1 <= r_vld_delay_r0;
    r_vld_delay_r2 <= r_vld_delay_r1;
    r_vld_delay_r3 <= r_vld_delay_r2;

    r_a_r0 <= a;
    r_a_r1 <= r_a_r0; 
    r_a_r2 <= r_a_r1;
    r_a_r3 <= r_a_r2;

    r_b_r0 <= b;
    r_b_r1 <= r_b_r0; 
    r_b_r2 <= r_b_r1;
    r_b_r3 <= r_b_r2;
end

always@(posedge s_clk, posedge s_rst) begin
    if (s_rst) begin
        rlst     <= 'd0;
        rlst_vld <= 'd0;
    end
    else if (r_vld_delay_r3) begin
        rlst     <= w_multi_data;
        rlst_vld <= 1'b1;
    end
    else begin
        rlst     <= rlst;
        rlst_vld <= 1'b0;
    end
end

endmodule //mutil_unit_sim
