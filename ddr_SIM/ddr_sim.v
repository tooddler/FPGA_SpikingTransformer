/*
    created by  : <Xidian University>
    created date: 2024-09-24
    author      : <zhiquan huang>
*/

`include "E:/Desktop/Zynq_Spikformer/Zynq_Spikformer.srcs/sources_1/hyper_para.v"
module ddr_sim (
    input                                     user_clk             ,
    input                                     user_rst             ,

    // - user interface -
    input       [`DATA_WIDTH- 1 : 0]          burst_write_data     ,   
    input       [`ADDR_SIZE - 1 : 0]          burst_write_addr     ,   
    input       [`LEN_WIDTH - 1 : 0]          burst_write_len      ,   
    input                                     burst_write_req      ,    
    output reg                                burst_write_valid    ,  
    output reg                                burst_write_finish   , 

    output reg [`DATA_WIDTH- 1 : 0]           burst_read_data      ,    
    input      [`ADDR_SIZE - 1 : 0]           burst_read_addr      ,    
    input      [`LEN_WIDTH - 1 : 0]           burst_read_len       ,    
    input                                     burst_read_req       ,     
    output reg                                burst_read_valid     ,   
    output reg                                burst_read_finish   
);

// sim ddr
reg [`DATA_WIDTH - 1 : 0] mem [`MEM_LENGTH - 1 : 0];

// -----> initial part <----- \\
parameter weight_data_path = "E:/Desktop/spiking-transformer-master/data4fpga_bin/weight_bin_new.bin";
parameter img_data_path    = "E:/Desktop/spiking-transformer-master/data4fpga_bin/img_bin.bin";

integer file, o, addr;
reg [`ADDR_SIZE-1 : 0]  first_addr          ;
reg [7:0]               byte_data [7:0]     ;

initial begin

    // load weight
    file = $fopen(weight_data_path, "rb");
    addr = 0;
    first_addr = `CONV1_BASEADDR / 8;
    while (!$feof(file)) begin
        o = $fread(byte_data, file);
        mem[first_addr + addr] = {byte_data[7], byte_data[6], byte_data[5], byte_data[4], byte_data[3], byte_data[2], byte_data[1], byte_data[0]};
        addr = addr + 1;
    end
    addr = addr - 1;
    $display("read weight num: %d", addr<<3);
    $fclose(file);

    // load imgdata
    file = $fopen(img_data_path, "rb");
    addr = 0;
    first_addr = `IMG_BASEADDR / 8;
    while (!$feof(file)) begin
        o = $fread(byte_data, file);
        mem[first_addr + addr] = {byte_data[7], byte_data[6], byte_data[5], byte_data[4], byte_data[3], byte_data[2], byte_data[1], byte_data[0]};
        addr = addr + 1;
    end
    addr = addr - 1;
    $display("read data num: %d", addr<<3);
    $fclose(file);

end

// ---------- write part ---------- \\
reg [2:0]                        wr_state   ;
reg [`ADDR_SIZE - 1 : 0]         wr_addr    ;
reg [`LEN_WIDTH - 1 : 0]         wr_len     ;
localparam WR_IDLE    = 3'b000;
localparam WR_WRITE   = 3'b001;
localparam WR_FINISH  = 3'b010;
localparam WR_WAIT    = 3'b011;

always @(posedge user_clk, posedge user_rst) begin
    if (user_rst) begin
        wr_state            <= WR_IDLE;
        wr_addr             <= 0;
        wr_len              <= 0;
        burst_write_valid   <= 0;
    end
    else begin
        case (wr_state)
            WR_IDLE: begin
                burst_write_finish <= 1'b0;
                if (burst_write_req) begin
                    wr_state <= WR_WRITE;
                    wr_len   <= burst_write_len;
                end
            end

            WR_WRITE: begin
                if (wr_len > 0) begin
                    burst_write_valid <= 1'b1;
                    wr_len            <= wr_len - 1;
                end
                else begin
                    burst_write_valid <= 1'b0;
                    wr_state          <= WR_FINISH;
                end
            end

            WR_FINISH: begin
                burst_write_finish  <= 1;
                wr_state            <= WR_WAIT;
            end

            WR_WAIT : begin
                burst_write_finish  <= 0;
                wr_state            <= WR_IDLE;
            end
        endcase
    end
end

always @(posedge user_clk, posedge user_rst) begin
    if (user_rst) begin
        wr_addr  <= 0;
    end
    else if (burst_write_valid) begin
        wr_addr  <= wr_addr + 1;
    end
    else if (burst_write_req) begin
        wr_addr  <= burst_write_addr >> 3;
    end
end

always @(posedge user_clk) begin
    if (burst_write_valid) begin
        mem[wr_addr]  <= burst_write_data;
    end
end

// ---------- read part ---------- \\
reg [2:0]                        rd_state   ;
reg [`ADDR_SIZE - 1 : 0]         rd_addr    ;
reg [`LEN_WIDTH - 1 : 0]         rd_len     ;

localparam RD_IDLE    = 3'b000;
localparam RD_READ    = 3'b001;
localparam RD_FINISH  = 3'b010;
localparam RD_WAIT    = 3'b011;

always @(posedge user_clk, posedge user_rst) begin
    if (user_rst) begin
        rd_state            <= RD_IDLE;
        rd_addr             <= 0;
        rd_len              <= 0;
        burst_read_valid    <= 0;
        burst_read_data     <= 0;
    end
    else begin
        case (rd_state)
            RD_IDLE: begin
                if (burst_read_req) begin
                    rd_state <= RD_READ;
                    rd_addr  <= burst_read_addr >> 3;
                    rd_len   <= burst_read_len;
                end
            end

            RD_READ: begin
                if (rd_len > 0) begin
                    burst_read_valid    <= 1;
                    burst_read_data     <= mem[rd_addr];
                    rd_addr             <= rd_addr + 1;
                    rd_len              <= rd_len  - 1;
                end
                else begin
                    burst_read_valid    <= 0;
                    rd_state            <= RD_FINISH;
                end
            end

            RD_FINISH: begin
                burst_read_finish  <= 1;
                rd_state           <= RD_WAIT;
            end

            RD_WAIT: begin
                burst_read_finish  <= 1'b0;
                rd_state           <= RD_IDLE;
            end
        endcase
    end
end

endmodule //ddr_sim


