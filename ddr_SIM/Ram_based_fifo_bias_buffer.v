/*
    created by  : <Xidian University>
    created date: 2024-09-24
    author      : <zhiquan huang>
*/
`timescale 1ns/100fs

`include "../../source/parameters.v"

module ram_based_fifo_bias_buffer #(
    parameter DATA_W  = 128,    
    parameter DEPTH_W = 8,    
    parameter DATA_R  = 16,  
    parameter DEPTH_R = 11,
    parameter WRITE_NUM = 2 ** DEPTH_W,
    parameter READ_NUM = 2 ** DEPTH_R,
    parameter ALMOST_FULL_THRESHOLD = 189,
    parameter ALMOST_EMPTY_THRESHOLD = 8
)
(                  	
    input                   system_clk       ,       
    input                   rst_n            ,                                            
    input                   i_wren           ,        // Write Enable
    input  [DATA_W - 1 : 0] i_wrdata         ,        // Write-data                    
    output                  o_full           ,        // Full signal
    output                  o_almost_full    ,        // Almost full signal
    input                   i_rden           ,        // Read Enable
    output [DATA_R - 1 : 0] o_rddata         ,        // Read-data                    
    output                  o_empty          ,        // Empty signal
    output                  o_almost_empty            // Almost empty signal
);


/*---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   Internal Registers / Signals
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
reg  [DEPTH_W - 1 : 0] wrptr_rg  ; // Write pointer
reg  [DEPTH_R - 1 : 0] rdptr_rg  ; // Read pointer
wire [DEPTH_R - 1 : 0] now_data_num; // Number of data in FIFO
wire [DEPTH_R - 1 : 0] nxt_rdptr ; // Next Read pointer
wire [DEPTH_R - 1 : 0] rdaddr    ; // Read-address to RAM
wire [DATA_R - 1 : 0]  rddata_wire; // Read-data from RAM
reg  [DATA_R - 1 : 0]  rddata_rg ; // Read-data registered
 
wire wren            ;        // Write Enable signal generated iff FIFO is not full
reg  rden_rg         ;        // Write Enable signal registered
wire rden_cross_psd  ;
wire rden            ;        // Read Enable signal generated iff FIFO is not empty
wire full            ;        // Full signal
wire empty           ;        // Empty signal
reg  empty_rg        ;        // Empty signal (registered)
reg  state_rg        ;        // State
reg  ex_rg           ;        // Exception


/*---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   Instantiation of RAM
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
generate
    if (`device == "simulation") begin : simulation_ram_inst
        simulation_ram#(
            .DATA_W    ( 128 ),
            .DATA_R    ( 16  ),
            .DEPTH_W   ( 8   ),
            .DEPTH_R   ( 11  )
        )return_ram_inst(
            .clk       ( system_clk),
            .i_wren    ( wren      ),
            .i_waddr   ( wrptr_rg  ),
            .i_wdata   ( i_wrdata  ),
            .i_raddr   ( rdaddr    ),
            .o_rdata   ( rddata_wire  )
        );
    end
    else begin : fpga_ram_inst
        return_ram return_ram_inst (
            .wr_data    (i_wrdata),    
            .wr_addr    (wrptr_rg),    
            .wr_en      (wren),      
            .wr_clk     (system_clk),     
            .wr_rst     (~rst_n),     
            .rd_addr    (rdaddr),    
            .rd_data    (rddata_wire),    
            .rd_clk     (system_clk),     
            .rd_rst     (~rst_n)      
        );
    end
endgenerate

/*---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   Synchronous logic to write to and read from FIFO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
always @ (posedge system_clk or negedge rst_n) begin
    if (!rst_n) begin            
       wrptr_rg  <= 0    ;
       rdptr_rg  <= 0    ; 
       state_rg  <= 1'b0 ;
       ex_rg     <= 1'b0 ;
       rden_rg   <= 1'b0 ;
    end
    else begin   
        /* FIFO write logic */            
        if (wren) begin         
            if (wrptr_rg == WRITE_NUM - 1) begin
                wrptr_rg <= 0               ;        // Reset write pointer  
            end
            else begin
                wrptr_rg <= wrptr_rg + 1    ;        // Increment write pointer            
            end
        end

        /* FIFO read logic */
        if (rden) begin         
            if (rdptr_rg == READ_NUM - 1) begin
               rdptr_rg <= 0               ;        // Reset read pointer
            end
            else begin
               rdptr_rg <= rdptr_rg + 1    ;        // Increment read pointer            
            end
        end

        // 读写位宽不对等，因此在计算full和empty时读信号需要重定义，现在读写位宽差4位，因此采写指针的第四位上升沿
        rden_rg <= rdptr_rg[3];
      
        // State where FIFO is emptied
        if (state_rg == 1'b0) begin
            ex_rg <= 1'b0 ;

            if (wren && !rden_cross_psd) begin
                state_rg <= 1'b1 ;                        
            end 
            else if (wren && rden_cross_psd && (rdaddr[DEPTH_R-1:3] == wrptr_rg)) begin
                ex_rg    <= 1'b1 ;        // Exceptional case where same address is being read and written in FIFO ram
            end
        end
      
        // State where FIFO is filled up
        else begin
            if (!wren && rden_cross_psd) begin
               state_rg <= 1'b0 ;            
            end
        end

        // Empty signal registered
        empty_rg <= empty ;      
    end
end


/*---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   Continuous Assignments
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
// 读使能跨到输出段的使能信号
assign rden_cross_psd = rden_rg ^ rdptr_rg[3];

// Full and Empty internal
assign full      = (wrptr_rg == rdptr_rg[DEPTH_R-1:3]) && (state_rg == 1'b1)            ;
assign empty     = ((wrptr_rg == rdptr_rg[DEPTH_R-1:3]) && (state_rg == 1'b0)) || ex_rg ;

// Write and Read Enables internal
assign wren      = i_wren & !full                                          ;  
assign rden      = i_rden & !empty & !empty_rg                             ;

// Full and Empty to output
assign o_full      = full                                                  ;
assign o_empty     = empty || empty_rg                                     ;

// Read-address to RAM
assign nxt_rdptr   = (rdptr_rg == READ_NUM - 1) ? 'b0 : rdptr_rg + 1        ;
assign rdaddr      = rden ? nxt_rdptr : rdptr_rg                           ;

// almost_full and almost_empty
assign now_data_num = {wrptr_rg, 3'b0} - rdptr_rg;
assign o_almost_full  = now_data_num[DEPTH_R-1:3] >= ALMOST_FULL_THRESHOLD;
assign o_almost_empty = now_data_num < ALMOST_EMPTY_THRESHOLD;

always @(posedge system_clk) begin
    if (rden) begin
        rddata_rg <= rddata_wire;
    end
end

assign o_rddata = rddata_rg;

endmodule

/*=================================================================================================================================================================================
                                                                                 R A M   F I F O
=================================================================================================================================================================================*/