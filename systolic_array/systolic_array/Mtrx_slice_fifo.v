/*
    --- Distributed RAM base FIFO width change --- 
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
    func    : - in  -> 64 bit
              - out -> 8  bit  
    **Attention** : only supports the multiples of 8 read
*/

module Mtrx_slice_fifo (
    input                           clk     ,     
    input                           srst    ,         
    input         [63:0]            din     ,         
    input                           wr_en   , 

    input                           rd_en   ,
    output reg    [7:0]             dout    ,     
    output wire                     full    ,     
    output                          empty    
);

wire [63:0]             w_fifo_dout    ;

reg                     r_fifo_rden    ;
reg  [2:0]              r_rd_cnt       ;             

// r_rd_cnt
always@(posedge clk, posedge srst) begin
    if (srst)
        r_rd_cnt <= 'd0;
    else if (rd_en)
        r_rd_cnt <= r_rd_cnt + 1'b1;
end

// r_fifo_rden
always@(posedge clk) begin
    if (r_rd_cnt == 'd6)
        r_fifo_rden <= 1'b1;
    else
        r_fifo_rden <= 1'b0;
end

MtrxA_slice_fifo u_MtrxA_slice_fifo (
    .clk        ( clk           ),
    .srst       ( srst          ),
    .din        ( din           ),
    .wr_en      ( wr_en         ),
    .rd_en      ( r_fifo_rden   ),
    .dout       ( w_fifo_dout   ),
    .full       ( full          ),
    .empty      ( empty         )
);

// dout
always@(*) begin
    case (r_rd_cnt)
        'd0: dout <= w_fifo_dout[7:0];
        'd1: dout <= w_fifo_dout[15:8];
        'd2: dout <= w_fifo_dout[23:16];
        'd3: dout <= w_fifo_dout[31:24];
        'd4: dout <= w_fifo_dout[39:32];
        'd5: dout <= w_fifo_dout[47:40];
        'd6: dout <= w_fifo_dout[55:48];
        'd7: dout <= w_fifo_dout[63:56];
        default: dout <= 8'b0;
    endcase
end

endmodule // Mtrx_slice_fifo
