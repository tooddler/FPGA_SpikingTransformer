`define CLK_PERIOD   20
`timescale 1ns / 1ps

module tb_adder ();

reg                     s_clk         ;
reg                     s_rst         ;

reg                     i_data_valid  ;
reg [31:0]              i_data1       ;
reg [31:0]              i_data2       ;

wire                    o_data_valid  ;
wire [31:0]             o_data        ;

wire [31:0]             rlst_0        ;
wire [31:0]             rlst_1        ;

initial s_clk = 1'b1;
always #(`CLK_PERIOD/2) s_clk = ~s_clk;

parameter data_path = "E:/Desktop/spiking-transformer-master/Systolic_data/fp32_test.bin";
integer file, o, addr;
reg [31 : 0]                 fp32_data [5:0]     ;
reg [31 : 0]                 first_addr          ;
reg [7 : 0]                  byte_data [3:0]     ;

initial begin
    file = $fopen(data_path, "rb");
    addr = 0;
    first_addr = 0;
    while (!$feof(file)) begin
        o = $fread(byte_data, file);
        fp32_data[first_addr + addr] = {byte_data[3], byte_data[2], byte_data[1], byte_data[0]};
        addr = addr + 1;
    end
    $display("read data done");
    $fclose(file);
end

initial begin
    s_rst        = 0;
    i_data_valid = 0;
    i_data1      = 0;
    i_data2      = 0;
    # 21
    s_rst        = 1;

    # 200
    i_data_valid = 1'b1;
    // i_data1      = 32'b0_01111111_11000000000000000000000;
    // i_data2      = 32'b0_10000000_01010000000000000000000;
    i_data1      = fp32_data[0];
    i_data2      = fp32_data[1];

    // # (`CLK_PERIOD)
    // i_data_valid = 1'b0;
    // # (`CLK_PERIOD)
    // i_data_valid = 1'b1;
    // i_data1      = fp32_data[2];
    // i_data2      = fp32_data[3];
    # (`CLK_PERIOD)
    i_data_valid = 1'b0;
end

assign rlst_0       = fp32_data[4];
assign rlst_1       = fp32_data[5];

Adder_fp32 u_Adder_fp32(
    .s_clk         ( s_clk         ),

    .i_data_valid  ( i_data_valid  ),
    .i_data1       ( i_data1       ),
    .i_data2       ( i_data2       ),

    .o_data_valid  ( o_data_valid  ),
    .o_data        ( o_data        )
);

endmodule //tb_adder
