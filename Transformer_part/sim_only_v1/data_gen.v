/*
    Author  : Toddler. 
    Email   : 23011211185@stu.xidian.edu.cn
    Encoder : UTF-8
    func    : generate data
    ** Attn ** : simulation only
*/

`include "E:/Desktop/spiking_transformer/spiking_transformer/spiking_transformer.srcs/sources_1/imports/FPGA_SpikingTransformer/hyper_para.v"
module data_gen (
    input                                             s_clk               ,
    input                                             s_rst               ,    
    // -- generate Matrix Data Slices
    output reg                                        MtrxA_slice_valid=0 ,
    output wire  [`SYSTOLIC_DATA_WIDTH - 1 : 0]       MtrxA_slice_data    ,
    output reg                                        MtrxA_slice_done=0  ,
    input                                             MtrxA_slice_ready   ,

    output reg                                        MtrxB_slice_valid=0 ,
    output wire  [`SYSTOLIC_DATA_WIDTH - 1 : 0]       MtrxB_slice_data    ,
    output reg                                        MtrxB_slice_done=0  ,
    input                                             MtrxB_slice_ready       
);

reg [`DATA_WIDTH/8 - 1 : 0]                           mem [`MEM_LENGTH - 1 : 0]   ;
reg [15:0]                                            r_MtrxA_cnt                 ;
reg [15:0]                                            r_MtrxB_cnt                 ;

reg [`ADDR_SIZE - 1 : 0]                              r_MtrxA_addr                ;
reg [`ADDR_SIZE - 1 : 0]                              r_MtrxB_addr                ;

parameter MtrxA_data_path = "E:/Desktop/spiking-transformer-master/Systolic_data/MtrxA.bin";
parameter MtrxB_data_path = "E:/Desktop/spiking-transformer-master/Systolic_data/MtrxB.bin";

integer file, o, addr;
reg [`ADDR_SIZE - 1 : 0]  first_addr          ;
reg [7:0]                 byte_data [0:0]     ;

initial begin

    // load MtrxA
    file = $fopen(MtrxA_data_path, "rb");
    addr = 0;
    first_addr = 0;
    while (!$feof(file)) begin
        o = $fread(byte_data, file);
        mem[first_addr + addr] = {byte_data[0]};
        addr = addr + 1;
    end
    addr = addr - 1;
    $display("read MtrxA num: %d", addr);
    $fclose(file);

    // load MtrxB
    file = $fopen(MtrxB_data_path, "rb");
    addr = 0;
    first_addr = `IMG_BASEADDR;
    while (!$feof(file)) begin
        o = $fread(byte_data, file);
        mem[first_addr + addr] = {byte_data[0]};
        addr = addr + 1;
    end
    addr = addr - 1;
    $display("read MtrxB num: %d", addr);
    $fclose(file);

end

// --------------- MTRXA GEN --------------- \\ 
// r_MtrxA_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_MtrxA_cnt <= 'd0;
    else if (MtrxA_slice_ready && MtrxA_slice_valid)
        r_MtrxA_cnt <= r_MtrxA_cnt + 1'b1;
end

// MtrxA_slice_valid
always@(posedge s_clk) begin
    if (MtrxA_slice_ready && MtrxA_slice_valid && r_MtrxA_cnt == `SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1)
        MtrxA_slice_valid <= 1'b0;
    else if (MtrxA_slice_ready)
        MtrxA_slice_valid <= 1'b1;
    else 
        MtrxA_slice_valid <= 1'b0;
end

// r_MtrxA_addr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_MtrxA_addr <= 'd0;
    else if (r_MtrxA_cnt[0])
        r_MtrxA_addr <= r_MtrxA_addr + 1'b1;
end

// MtrxA_slice_data 
assign MtrxA_slice_data = mem[r_MtrxA_cnt];

// MtrxA_slice_done
always@(posedge s_clk) begin
    if (MtrxA_slice_ready && MtrxA_slice_valid && r_MtrxA_cnt == `SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 2)
        MtrxA_slice_done <= 1'b1;
    else
        MtrxA_slice_done <= 1'b0;
end

// --------------- MTRXB GEN --------------- \\ 
// r_MtrxB_cnt
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_MtrxB_cnt <= 'd0;
    else if (MtrxB_slice_ready && MtrxB_slice_valid)
        r_MtrxB_cnt <= r_MtrxB_cnt + 1'b1;
end

// MtrxB_slice_valid
always@(posedge s_clk) begin
    if (MtrxB_slice_ready && MtrxB_slice_valid && r_MtrxB_cnt == `SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 1)
        MtrxB_slice_valid <= 1'b0;
    else if (MtrxB_slice_ready)
        MtrxB_slice_valid <= 1'b1;
    else 
        MtrxB_slice_valid <= 1'b0;
end

// r_MtrxB_addr
always@(posedge s_clk, posedge s_rst) begin
    if (s_rst)
        r_MtrxB_addr <= `IMG_BASEADDR;
    else if (r_MtrxB_cnt[0])
        r_MtrxB_addr <= r_MtrxB_addr + 1'b1;
end

// MtrxB_slice_data 
assign MtrxB_slice_data = mem[r_MtrxB_cnt + `IMG_BASEADDR];

// MtrxB_slice_done 
always@(posedge s_clk) begin
    if (MtrxB_slice_ready && MtrxB_slice_valid && r_MtrxB_cnt == `SYSTOLIC_UNIT_NUM * `SYSTOLIC_UNIT_NUM - 2)
        MtrxB_slice_done <= 1'b1;
    else
        MtrxB_slice_done <= 1'b0;
end

endmodule //data_gen


