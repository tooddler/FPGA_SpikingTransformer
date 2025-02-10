/*
    created by  : <Xidian University>
    created date: 2024-09-24
    author      : <zhiquan huang>
*/
`timescale 1ns/100fs

module simulation_ram #(
    parameter DATA_W    = 8       ,
    parameter DATA_R    = 8       ,        
    parameter DEPTH_W   = 8       ,
    parameter DEPTH_R   = 8       ,
    parameter RAM_NUM_W = 2**DEPTH_W,
    parameter RAM_NUM_R = 2**DEPTH_R,
    parameter INIT_FILE = ""
)
(              
    input  wire                  clk    ,      // Clock                    
    input  wire                  i_wren ,      // Write Enable
    input  wire [DEPTH_W- 1 : 0] i_waddr,      // Write-address                    
    input  wire [DATA_W - 1 : 0] i_wdata,      // Write-data 
    input  wire [DEPTH_R- 1 : 0] i_raddr,      // Read-address                   
    output reg  [DATA_R - 1 : 0] o_rdata       // Read-data                   
);

initial begin
    if (DATA_W * RAM_NUM_W != DATA_R * RAM_NUM_R) begin : error_check
        $display("Error: the total width of the RAM must be the same!!");
        $stop;
    end
end

generate
    if (DATA_W > DATA_R) begin : ram_gen
        localparam times = (DATA_W / DATA_R);
        localparam times_bit = $clog2(times);
        // 保证读位宽是写位宽的整数倍
        initial begin
            if (DATA_W % DATA_R != 0) begin : error_check1
                $display("Error: the write width must be a multiple of the read width!!");
                $stop;
            end
            else if (times != 2**times_bit) begin : error_check2
                $display("Error: the write width times to the read width must be 2^n!!");
                $stop;
            end
        end

        reg [DATA_R-1:0] data_rg[RAM_NUM_R-1:0];       // Data array
        if (INIT_FILE != "") begin
            initial begin
                $readmemb(INIT_FILE, data_rg);
            end
        end
        else begin
            for (genvar i = 0; i < RAM_NUM_W; i = i + 1) begin
                initial begin
                    data_rg[i] = 0;
                end
            end
        end

        for (genvar i = 0; i < times; i = i + 1) begin : write_ram
            wire [DEPTH_R-1:0] addr_w;
            assign addr_w = {i_waddr, {times_bit{1'b0}}} + i;
            always @ (posedge clk) begin     
                if (i_wren) begin                          
                    data_rg[addr_w] <= i_wdata[DATA_R*(i+1)-1 : DATA_R*i];      
                end
            end
        end

        always @ (posedge clk) begin
            o_rdata <= data_rg [i_raddr] ;  
        end
    end
    else if (DATA_W < DATA_R) begin : ram_gen2
        localparam times = (DATA_R / DATA_W);
        localparam times_bit = $clog2(times);
        // 保证读位宽是写位宽的整数倍
        initial begin
            if (DATA_R % DATA_W != 0) begin : error_check1
                $display("Error: the read width must be a multiple of the write width!!");
                $stop;
            end
            else if (times != 2**times_bit) begin : error_check2
                $display("Error: the read width times to the write width must be 2^n!!");
                $stop;
            end
        end

        reg [DATA_W-1:0] data_rg[RAM_NUM_W-1:0];       // Data array
        if (INIT_FILE != "") begin
            initial begin
                $readmemb(INIT_FILE, data_rg);
            end
        end
        else begin
            for (genvar i = 0; i < RAM_NUM_W; i = i + 1) begin
                initial begin
                    data_rg[i] = 0;
                end
            end
        end

        always @ (posedge clk) begin     
            if (i_wren) begin                          
                data_rg[i_waddr] <= i_wdata;      
            end
        end

        for (genvar i = 0; i < times; i = i + 1) begin : read_ram
            wire [DEPTH_W-1:0] addr_r;
            assign addr_r = {i_raddr, {times_bit{1'b0}}} + i;
            always @ (posedge clk) begin
                o_rdata[DATA_W*(i+1)-1 : DATA_W*i] <= data_rg[addr_r];  
            end
        end
    end
    else begin : ram_gen3
        reg [DATA_W-1:0] data_rg[RAM_NUM_W-1:0];       // Data array
        if (INIT_FILE != "") begin
            initial begin
                $readmemb(INIT_FILE, data_rg);
            end
        end
        else begin
            for (genvar i = 0; i < RAM_NUM_W; i = i + 1) begin
                initial begin
                    data_rg[i] = 0;
                end
            end
        end

        
        always @ (posedge clk) begin     
            if (i_wren) begin                          
                data_rg[i_waddr] <= i_wdata;        
            end
        end
        always @ (posedge clk) begin
            o_rdata <= data_rg[i_raddr];  
        end
    end
endgenerate

endmodule