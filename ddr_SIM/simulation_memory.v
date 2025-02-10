/*
    created by  : <Xidian University>
    created date: 2024-09-24
    author      : <zhiquan huang>
*/
`timescale 1ns/100fs

`include "../../../parameters.v"

module simulation_memory #(
    parameter DATA_WIDTH            = `MAC_PE_DATA_WIDTH,
    parameter MEM_DQ_WIDTH          = `MEM_DQ_WIDTH,
    parameter LEN_WIDTH             = `LEN_WIDTH,
    parameter CTRL_ADDR_WIDTH       = `CTRL_ADDR_WIDTH,
    parameter MAC_OUTPUT_WIDTH      = `MAC_OUTPUT_WIDTH
)(
    input                                  system_clk         ,
    input                                  rst_n              ,
    // read port
    output reg  [8*MEM_DQ_WIDTH-1 : 0]     rd_burst_data      ,
    input                                  rd_burst_req       ,
    input [LEN_WIDTH- 1'b1 : 0]            rd_burst_len       ,
    input  [CTRL_ADDR_WIDTH- 1'b1 : 0]     rd_burst_addr      ,
    output reg                             rd_burst_data_valid,
    output reg                             rd_burst_finish    ,
    // write port
    input  [8*MEM_DQ_WIDTH-1 : 0]          wr_burst_data      ,
    input                                  wr_burst_req       ,
    input  [LEN_WIDTH- 1'b1 : 0]           wr_burst_len       ,
    input  [CTRL_ADDR_WIDTH- 1'b1 : 0]     wr_burst_addr      ,
    output reg                             wr_burst_data_req  ,
    output reg                             wr_burst_finish
);

// memory instance
reg [127:0] memory[4194303:0];  //128MB memory
wire[127:0] m1;
assign m1 = memory[`BIAS_MEMORY_ADDR/8];

parameter memory_patch     = "F:/FPGA/ziguang/dataprocess/memory.txt";
parameter weight_data_path = "F:/FPGA/ziguang/dataprocess/weight_bin_v2.0.bin";
parameter bias_data_path   = "F:/FPGA/ziguang/dataprocess/bias_bin_v2.0.bin";
parameter picture_data_path= "F:/FPGA/ziguang/dataprocess/picture.bin";


// 读取权重文件
integer file, o, addr;
reg [27:0]weight_first_addr, bias_first_addr, picture_first_addr;
reg [7:0] byte_data[15:0];
integer i;
initial begin
    // load weight
    file = $fopen(weight_data_path, "rb");
    addr = 0;
    weight_first_addr = `WEIGHT_MEMORY_ADDR/8;
    while (!$feof(file)) begin
        o = $fread(byte_data, file);
        memory[weight_first_addr + addr] = {byte_data[15], byte_data[14], byte_data[13], byte_data[12], byte_data[11], byte_data[10], byte_data[9], byte_data[8], byte_data[7], byte_data[6], byte_data[5], byte_data[4], byte_data[3], byte_data[2], byte_data[1], byte_data[0]};
        addr = addr + 1;
    end
    $display("read data num: %d", addr<<4);
    $fclose(file);
    // load bias
    file = $fopen(bias_data_path, "rb");
    addr = 0;
    bias_first_addr = `BIAS_MEMORY_ADDR / 8;
    while (!$feof(file)) begin
        o = $fread(byte_data, file);
        memory[bias_first_addr + addr] = {byte_data[15], byte_data[14], byte_data[13], byte_data[12], byte_data[11], byte_data[10], byte_data[9], byte_data[8], byte_data[7], byte_data[6], byte_data[5], byte_data[4], byte_data[3], byte_data[2], byte_data[1], byte_data[0]};
        addr = addr + 1;
    end
    $display("read data num: %d", addr<<4);
    $fclose(file);
    // load picture
    file = $fopen(picture_data_path, "rb");
    addr = 0;
    picture_first_addr = `PICTURE_ADDR / 8;
    while (!$feof(file)) begin
        o = $fread(byte_data, file);
        memory[picture_first_addr + addr] = {byte_data[15], byte_data[14], byte_data[13], byte_data[12], byte_data[11], byte_data[10], byte_data[9], byte_data[8], byte_data[7], byte_data[6], byte_data[5], byte_data[4], byte_data[3], byte_data[2], byte_data[1], byte_data[0]};
        addr = addr + 1;
    end
    $display("read data num: %d", addr<<4);
    $fclose(file);
    // save memory to txt
    file = $fopen(memory_patch, "w");
    $writememh(memory_patch, memory);
    $fclose(file);

    file = $fopen(memory_patch, "r");
    $readmemh(memory_patch, memory);
end

/*---------------------- 读接口 ---------------------------*/
reg [2:0]    rd_state;
reg [31:0]   rd_addr;
reg [31:0]   rd_len;
localparam RD_IDLE    = 3'b000;
localparam RD_READ    = 3'b001;
localparam RD_FINISH  = 3'b010;
localparam RD_WAIT    = 3'b011;

always @(posedge system_clk or negedge rst_n) begin
    if (!rst_n) begin
        rd_state            <= RD_IDLE;
        rd_addr             <= 0;
        rd_len              <= 0;
        rd_burst_data_valid <= 0;
        rd_burst_data       <= 0;
    end
    else begin
        case (rd_state)
            RD_IDLE: begin
                if (rd_burst_req) begin
                    rd_state <= RD_READ;
                    rd_addr  <= rd_burst_addr >> 3;
                    rd_len   <= rd_burst_len;
                end
            end

            RD_READ: begin
                if (rd_len > 0) begin
                    rd_burst_data_valid <= 1;
                    rd_burst_data       <= memory[rd_addr];
                    rd_addr             <= rd_addr + 1;
                    rd_len              <= rd_len - 1;
                end
                else begin
                    rd_burst_data_valid <= 0;
                    rd_state            <= RD_FINISH;
                end
            end

            RD_FINISH: begin
                rd_burst_finish <= 1;
                rd_state        <= RD_WAIT;
            end

            RD_WAIT: begin
                rd_burst_finish <= 1'b0;
                rd_state <= RD_IDLE;
            end
        endcase
    end
end

/*---------------------- 写接口 ----------------------*/
reg [2:0]    wr_state;
reg [31:0]   wr_addr;
reg [15:0]   wr_len;
localparam WR_IDLE    = 3'b000;
localparam WR_WRITE   = 3'b001;
localparam WR_FINISH  = 3'b010;
localparam WR_WAIT    = 3'b011;

always @(posedge system_clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_state            <= WR_IDLE;
        wr_addr             <= 0;
        wr_len              <= 0;
        wr_burst_data_req   <= 0;
    end
    else begin
        case (wr_state)
            WR_IDLE: begin
                wr_burst_finish <= 1'b0;
                if (wr_burst_req) begin
                    wr_state <= WR_WRITE;
                    wr_len   <= wr_burst_len;
                end
            end

            WR_WRITE: begin
                if (wr_len > 0) begin
                    wr_burst_data_req <= 1'b1;
                    wr_len            <= wr_len - 1;
                end
                else begin
                    wr_burst_data_req <= 1'b0;
                    wr_state          <= WR_FINISH;
                end
            end

            WR_FINISH: begin
                wr_burst_finish <= 1;
                wr_state        <= WR_WAIT;
            end

            WR_WAIT : begin
                wr_burst_finish <= 0;
                wr_state <= WR_IDLE;
            end
        endcase
    end
end

always @(posedge system_clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_addr  <= 0;
    end
    else if (wr_burst_data_req) begin
        wr_addr  <= wr_addr + 1;
    end
    else if (wr_burst_req) begin
        wr_addr  <= wr_burst_addr >> 3;
    end
end

always @(posedge system_clk or negedge rst_n) begin
    if (wr_burst_data_req) begin
        memory[wr_addr]  <= wr_burst_data;
    end
end

// save the memory data to file
always @(posedge system_clk or negedge rst_n) begin
    if (conv_control_tb.u_convolution_control.yolo_control_state == 11)begin
        if (conv_control_tb.u_convolution_control.order_addr==50) begin
            if (file != 0) begin
                $writememh(memory_patch, memory);
                $display("the %d layer simulation is finish", conv_control_tb.u_convolution_control.order_addr-1);
                $display("save memory data to file");
                $display("weight_cnt==%d", conv_control_tb.u_convolution_control.u_weight_buffer.debug_weight_cnt);
                $display("bias_cnt==%d", conv_control_tb.u_convolution_control.u_weight_buffer.debug_bias_cnt);
                $fclose(file);
                file = 0;
                $stop;
            end
        end
        else begin
            $display("the %d layer simulation is finish", conv_control_tb.u_convolution_control.order_addr-1);
            $display("weight_cnt==%d", conv_control_tb.u_convolution_control.u_weight_buffer.debug_weight_cnt);
            $display("bias_cnt==%d", conv_control_tb.u_convolution_control.u_weight_buffer.debug_bias_cnt);  
        end
    end 
end

endmodule