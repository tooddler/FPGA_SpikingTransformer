/*
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
*/

`include "E:/Desktop/Zynq_Spikformer/Zynq_Spikformer.srcs/sources_1/hyper_para.v"
module sim_rr_arbiter (
    input                                  ddr_clk                  ,
    input                                  ddr_rstn                 ,

// Multi-channels-in
    /*---------------------------------- CH00 ------------------------------------*/
    // -- ch00-wr --
    input   [`DATA_WIDTH- 1 : 0]           w00_burst_write_data     ,   
    input   [`ADDR_SIZE - 1 : 0]           w00_burst_write_addr     ,   
    input   [`LEN_WIDTH - 1 : 0]           w00_burst_write_len      ,   
    input                                  w00_burst_write_req      ,    
    output                                 w00_burst_write_valid    ,  
    output                                 w00_burst_write_finish   , 
    // -- ch00-rd --
    output  [`DATA_WIDTH- 1 : 0]           r00_burst_read_data      ,    
    input   [`ADDR_SIZE - 1 : 0]           r00_burst_read_addr      ,    
    input   [`LEN_WIDTH - 1 : 0]           r00_burst_read_len       ,    
    input                                  r00_burst_read_req       ,     
    output                                 r00_burst_read_valid     ,   
    output                                 r00_burst_read_finish    ,
    /*---------------------------------- CH01 ------------------------------------*/
    // -- ch01-wr --
    input   [`DATA_WIDTH- 1 : 0]           w01_burst_write_data     ,   
    input   [`ADDR_SIZE - 1 : 0]           w01_burst_write_addr     ,   
    input   [`LEN_WIDTH - 1 : 0]           w01_burst_write_len      ,   
    input                                  w01_burst_write_req      ,    
    output                                 w01_burst_write_valid    ,  
    output                                 w01_burst_write_finish   , 
    // -- ch01-rd --
    output  [`DATA_WIDTH- 1 : 0]           r01_burst_read_data      ,    
    input   [`ADDR_SIZE - 1 : 0]           r01_burst_read_addr      ,    
    input   [`LEN_WIDTH - 1 : 0]           r01_burst_read_len       ,    
    input                                  r01_burst_read_req       ,     
    output                                 r01_burst_read_valid     ,   
    output                                 r01_burst_read_finish    ,
    /*---------------------------------- CH02 ------------------------------------*/
    // -- ch02-wr --
    input   [`DATA_WIDTH- 1 : 0]           w02_burst_write_data     ,   
    input   [`ADDR_SIZE - 1 : 0]           w02_burst_write_addr     ,   
    input   [`LEN_WIDTH - 1 : 0]           w02_burst_write_len      ,   
    input                                  w02_burst_write_req      ,    
    output                                 w02_burst_write_valid    ,  
    output                                 w02_burst_write_finish   , 
    // -- ch02-rd --
    output  [`DATA_WIDTH- 1 : 0]           r02_burst_read_data      ,    
    input   [`ADDR_SIZE - 1 : 0]           r02_burst_read_addr      ,    
    input   [`LEN_WIDTH - 1 : 0]           r02_burst_read_len       ,    
    input                                  r02_burst_read_req       ,     
    output                                 r02_burst_read_valid     ,   
    output                                 r02_burst_read_finish    ,
    /*---------------------------------- CH03 ------------------------------------*/
    // -- ch03-wr --
    input   [`DATA_WIDTH- 1 : 0]           w03_burst_write_data     ,
    input   [`ADDR_SIZE - 1 : 0]           w03_burst_write_addr     ,
    input   [`LEN_WIDTH - 1 : 0]           w03_burst_write_len      ,
    input                                  w03_burst_write_req      ,
    output                                 w03_burst_write_valid    ,
    output                                 w03_burst_write_finish   ,
    // -- ch03-rd --
    output  [`DATA_WIDTH- 1 : 0]           r03_burst_read_data      ,
    input   [`ADDR_SIZE - 1 : 0]           r03_burst_read_addr      ,
    input   [`LEN_WIDTH - 1 : 0]           r03_burst_read_len       ,
    input                                  r03_burst_read_req       ,
    output                                 r03_burst_read_valid     ,
    output                                 r03_burst_read_finish    ,
    /*---------------------------------- CH04 ------------------------------------*/
    // -- ch04-wr --
    input   [`DATA_WIDTH- 1 : 0]           w04_burst_write_data     ,
    input   [`ADDR_SIZE - 1 : 0]           w04_burst_write_addr     ,
    input   [`LEN_WIDTH - 1 : 0]           w04_burst_write_len      ,
    input                                  w04_burst_write_req      ,
    output                                 w04_burst_write_valid    ,
    output                                 w04_burst_write_finish   ,
    // -- ch04-rd --
    output  [`DATA_WIDTH- 1 : 0]           r04_burst_read_data      ,
    input   [`ADDR_SIZE - 1 : 0]           r04_burst_read_addr      ,
    input   [`LEN_WIDTH - 1 : 0]           r04_burst_read_len       ,
    input                                  r04_burst_read_req       ,
    output                                 r04_burst_read_valid     ,
    output                                 r04_burst_read_finish    ,

//Arbiter-out
    // ch-wr
    output    [`DATA_WIDTH- 1 : 0]         wr_burst_data            ,
    output reg[`ADDR_SIZE - 1 : 0]         wr_burst_addr            ,
    output reg[`LEN_WIDTH - 1 : 0]         wr_burst_len             ,
    output reg                             wr_burst_req             ,
    input                                  wr_burst_data_req        ,
    input                                  wr_burst_finish          ,
    // ch-rd
    input     [`DATA_WIDTH- 1 : 0]         rd_burst_data            ,
    output reg[`ADDR_SIZE - 1 : 0]         rd_burst_addr            ,
    output reg[`LEN_WIDTH - 1 : 0]         rd_burst_len             ,
    output reg                             rd_burst_req             ,
    input                                  rd_burst_data_valid      ,
    input                                  rd_burst_finish          
);

reg [4:0]  wr_sel       ;
reg [4:0]  wr_cur_state ;
reg [4:0]  wr_nxt_state ;
reg [4:0]  rd_sel_r0    ;
reg [4:0]  wr_sel_r0    ;

localparam  S_IDLE     = 4'd0   ,
            S_CH0_PRE  = 4'd1   ,
            S_CH0      = 4'd2   ,
            S_CH1_PRE  = 4'd3   ,
            S_CH1      = 4'd4   ,
            S_CH2_PRE  = 4'd5   ,
            S_CH2      = 4'd6   ,
            S_CH3_PRE  = 4'd7   ,
            S_CH3      = 4'd8   ,
            S_CH4_PRE  = 4'd9   ,
            S_CH4      = 4'd10  ;

always@(posedge ddr_clk or negedge ddr_rstn) begin
    if (~ddr_rstn)
        wr_cur_state <= S_IDLE;
    else 
        wr_cur_state <= wr_nxt_state;
end

// --- Loop priority arbiter ---
// --- WRITE CHANNEL ---
always@(*) begin
    if (~ddr_rstn) begin
        wr_nxt_state <= S_IDLE;
    end
    else begin
        case(wr_cur_state)
            S_IDLE : begin
                wr_nxt_state <= S_CH0_PRE;
            end
            S_CH0_PRE : begin
                if (~w00_burst_write_req)   wr_nxt_state <= S_CH1_PRE;
                else                        wr_nxt_state <= S_CH0;
            end
            S_CH0: begin
                if (wr_burst_finish)        wr_nxt_state <= S_CH1_PRE;
                else                        wr_nxt_state <= S_CH0;
            end

            S_CH1_PRE : begin
                if (~w01_burst_write_req)   wr_nxt_state <= S_CH2_PRE;
                else                        wr_nxt_state <= S_CH1;
            end
            S_CH1: begin
                if (wr_burst_finish)        wr_nxt_state <= S_CH2_PRE;
                else                        wr_nxt_state <= S_CH1;
            end

            S_CH2_PRE : begin
                if (~w02_burst_write_req)   wr_nxt_state <= S_CH3_PRE;
                else                        wr_nxt_state <= S_CH2;
            end
            S_CH2: begin
                if (wr_burst_finish)        wr_nxt_state <= S_CH3_PRE;
                else                        wr_nxt_state <= S_CH2;
            end

            S_CH3_PRE : begin
                if (~w03_burst_write_req)   wr_nxt_state <= S_CH4_PRE;
                else                        wr_nxt_state <= S_CH3;
            end
            S_CH3: begin
                if (wr_burst_finish)        wr_nxt_state <= S_CH4_PRE;
                else                        wr_nxt_state <= S_CH3;
            end
            S_CH4_PRE: begin
                if (~w04_burst_write_req)   wr_nxt_state <= S_CH0_PRE;
                else                        wr_nxt_state <= S_CH4;
            end
            S_CH4: begin
                if (wr_burst_finish)        wr_nxt_state <= S_CH0_PRE;
                else                        wr_nxt_state <= S_CH4;
            end
            default: wr_nxt_state <= S_IDLE;
        endcase
    end
end

// do
always@(posedge ddr_clk or negedge ddr_rstn) begin
    if (~ddr_rstn) begin
        wr_burst_req <= 0;
        wr_sel       <= 0;
    end
    else begin
        case(wr_cur_state)
            S_CH0_PRE: begin
                if (w00_burst_write_req) begin
                    wr_sel        <= 5'b00001;
                    wr_burst_req  <= 1;
                    wr_burst_len  <= w00_burst_write_len;
                    wr_burst_addr <= w00_burst_write_addr;
                end
            end
            
            S_CH1_PRE: begin
                if (w01_burst_write_req) begin
                    wr_sel        <= 5'b00010;
                    wr_burst_req  <= 1;
                    wr_burst_len  <= w01_burst_write_len;
                    wr_burst_addr <= w01_burst_write_addr;
                end
            end

            S_CH2_PRE: begin
                if (w02_burst_write_req) begin
                    wr_sel        <= 5'b00100;
                    wr_burst_req  <= 1;
                    wr_burst_len  <= w02_burst_write_len;
                    wr_burst_addr <= w02_burst_write_addr;
                end
            end
            
            S_CH3_PRE: begin
                if (w03_burst_write_req) begin
                    wr_sel        <= 5'b01000;
                    wr_burst_req  <= 1;
                    wr_burst_len  <= w03_burst_write_len;
                    wr_burst_addr <= w03_burst_write_addr;
                end
            end

            S_CH4_PRE: begin
                if (w04_burst_write_req) begin
                    wr_sel        <= 5'b10000;
                    wr_burst_req  <= 1;
                    wr_burst_len  <= w04_burst_write_len;
                    wr_burst_addr <= w04_burst_write_addr;
                end
            end

            default: begin
                if (wr_burst_finish) begin
                    wr_burst_req <= 0;
                    wr_sel       <= 0;
                end
                else begin
                    wr_burst_req <= wr_burst_req;
                    wr_sel       <= wr_sel      ;
                end
            end
        endcase
    end
end

assign wr_burst_data = (wr_sel_r0[0]) ? w00_burst_write_data :
                       (wr_sel_r0[1]) ? w01_burst_write_data :
                       (wr_sel_r0[2]) ? w02_burst_write_data :
                       (wr_sel_r0[3]) ? w03_burst_write_data :
                       (wr_sel_r0[4]) ? w04_burst_write_data : 128'd0;

assign   w00_burst_write_valid    =   (wr_sel_r0[0])  ?  wr_burst_data_req  :  1'b0 ;
assign   w01_burst_write_valid    =   (wr_sel_r0[1])  ?  wr_burst_data_req  :  1'b0 ;
assign   w02_burst_write_valid    =   (wr_sel_r0[2])  ?  wr_burst_data_req  :  1'b0 ;
assign   w03_burst_write_valid    =   (wr_sel_r0[3])  ?  wr_burst_data_req  :  1'b0 ;
assign   w04_burst_write_valid    =   (wr_sel_r0[4])  ?  wr_burst_data_req  :  1'b0 ;

assign   w00_burst_write_finish   =   (wr_sel_r0[0])  ?  wr_burst_finish  :  1'b0 ;
assign   w01_burst_write_finish   =   (wr_sel_r0[1])  ?  wr_burst_finish  :  1'b0 ;
assign   w02_burst_write_finish   =   (wr_sel_r0[2])  ?  wr_burst_finish  :  1'b0 ;
assign   w03_burst_write_finish   =   (wr_sel_r0[3])  ?  wr_burst_finish  :  1'b0 ;
assign   w04_burst_write_finish   =   (wr_sel_r0[4])  ?  wr_burst_finish  :  1'b0 ;

reg [4:0]  rd_sel       ;
reg [4:0]  rd_cur_state ;
reg [4:0]  rd_nxt_state ;

always@(posedge ddr_clk or negedge ddr_rstn) begin
    if (~ddr_rstn)
        rd_cur_state <= S_IDLE;
    else 
        rd_cur_state <= rd_nxt_state;
end

// --- READ CHANNEL ---
always@(*) begin
    if (~ddr_rstn) begin
        rd_nxt_state <= S_IDLE;
    end
    else begin
        case(rd_cur_state)
            S_IDLE : begin
                rd_nxt_state <= S_CH0_PRE;
            end
            S_CH0_PRE : begin
                if (~r00_burst_read_req)    rd_nxt_state <= S_CH1_PRE;
                else                        rd_nxt_state <= S_CH0;
            end
            S_CH0: begin
                if (rd_burst_finish)        rd_nxt_state <= S_CH1_PRE;
                else                        rd_nxt_state <= S_CH0;
            end

            S_CH1_PRE : begin
                if (~r01_burst_read_req)    rd_nxt_state <= S_CH2_PRE;
                else                        rd_nxt_state <= S_CH1;
            end
            S_CH1: begin
                if (rd_burst_finish)        rd_nxt_state <= S_CH2_PRE;
                else                        rd_nxt_state <= S_CH1;
            end

            S_CH2_PRE : begin
                if (~r02_burst_read_req)    rd_nxt_state <= S_CH3_PRE;
                else                        rd_nxt_state <= S_CH2;
            end
            S_CH2: begin
                if (rd_burst_finish)        rd_nxt_state <= S_CH3_PRE;
                else                        rd_nxt_state <= S_CH2;
            end

            S_CH3_PRE : begin
                if (~r03_burst_read_req)    rd_nxt_state <= S_CH4_PRE;
                else                        rd_nxt_state <= S_CH3;
            end
            S_CH3: begin
                if (rd_burst_finish)        rd_nxt_state <= S_CH4_PRE;
                else                        rd_nxt_state <= S_CH3;
            end

            S_CH4_PRE : begin
                if (~r04_burst_read_req)    rd_nxt_state <= S_CH0_PRE;
                else                        rd_nxt_state <= S_CH4;
            end
            S_CH4: begin
                if (rd_burst_finish)        rd_nxt_state <= S_CH0_PRE;
                else                        rd_nxt_state <= S_CH4;
            end

            default:rd_nxt_state <= S_IDLE;
        endcase
    end
end

// do
always@(posedge ddr_clk or negedge ddr_rstn) begin
    if (~ddr_rstn) begin
        rd_burst_req <= 0;
        rd_sel       <= 0;
    end
    else begin
        case(rd_cur_state)
            S_CH0_PRE: begin
                if (r00_burst_read_req) begin
                    rd_sel        <= 5'b00001;
                    rd_burst_req  <= 1;
                    rd_burst_len  <= r00_burst_read_len;
                    rd_burst_addr <= r00_burst_read_addr;
                end
            end
            
            S_CH1_PRE: begin
                if (r01_burst_read_req) begin
                    rd_sel        <= 5'b00010;
                    rd_burst_req  <= 1;
                    rd_burst_len  <= r01_burst_read_len;
                    rd_burst_addr <= r01_burst_read_addr;
                end
            end

            S_CH2_PRE: begin
                if (r02_burst_read_req) begin
                    rd_sel        <= 5'b00100;
                    rd_burst_req  <= 1;
                    rd_burst_len  <= r02_burst_read_len;
                    rd_burst_addr <= r02_burst_read_addr;
                end
            end
            
            S_CH3_PRE: begin
                if (r03_burst_read_req) begin
                    rd_sel        <= 5'b01000;
                    rd_burst_req  <= 1;
                    rd_burst_len  <= r03_burst_read_len;
                    rd_burst_addr <= r03_burst_read_addr;
                end
            end

            S_CH4_PRE: begin
                if (r04_burst_read_req) begin
                    rd_sel        <= 5'b10000;
                    rd_burst_req  <= 1;
                    rd_burst_len  <= r04_burst_read_len;
                    rd_burst_addr <= r04_burst_read_addr;
                end
            end

            default: begin
                if (rd_burst_finish) begin
                    rd_burst_req <= 0;
                    rd_sel       <= 0;
                end
                else begin
                    rd_burst_req <= rd_burst_req;
                    rd_sel       <= rd_sel      ;
                end
            end
        endcase
    end
end

always@(posedge ddr_clk) begin
    rd_sel_r0 <= rd_sel;
    wr_sel_r0 <= wr_sel;
end

assign r00_burst_read_data   =   rd_burst_data;
assign r01_burst_read_data   =   rd_burst_data;
assign r02_burst_read_data   =   rd_burst_data;
assign r03_burst_read_data   =   rd_burst_data;
assign r04_burst_read_data   =   rd_burst_data;

assign r00_burst_read_valid   =   (rd_sel_r0[0])  ?  rd_burst_data_valid  :  1'b0 ;
assign r01_burst_read_valid   =   (rd_sel_r0[1])  ?  rd_burst_data_valid  :  1'b0 ;
assign r02_burst_read_valid   =   (rd_sel_r0[2])  ?  rd_burst_data_valid  :  1'b0 ;
assign r03_burst_read_valid   =   (rd_sel_r0[3])  ?  rd_burst_data_valid  :  1'b0 ;
assign r04_burst_read_valid   =   (rd_sel_r0[4])  ?  rd_burst_data_valid  :  1'b0 ;

assign r00_burst_read_finish  =   (rd_sel_r0[0])  ?  rd_burst_finish  :  1'b0 ;
assign r01_burst_read_finish  =   (rd_sel_r0[1])  ?  rd_burst_finish  :  1'b0 ;
assign r02_burst_read_finish  =   (rd_sel_r0[2])  ?  rd_burst_finish  :  1'b0 ;
assign r03_burst_read_finish  =   (rd_sel_r0[3])  ?  rd_burst_finish  :  1'b0 ;
assign r04_burst_read_finish  =   (rd_sel_r0[4])  ?  rd_burst_finish  :  1'b0 ;

endmodule // sim_rr_arbiter


