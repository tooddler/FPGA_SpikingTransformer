set script_path [file normalize [info script]]
set script_dir [file dirname $script_path]

puts "----------------------------------------"
puts " Author : Toddler. "
puts " Email  : 23011211185@stu.xidian.edu.cn"
puts " Use \"report_property [get_ips XXX]\" to check the IP core "
puts "----------------------------------------"
puts "脚本路径: $script_path"
puts "脚本目录: $script_dir"
puts "vivado 版本: Vivado v2022.2 (64-bit)"
puts "当前使用 vivado 版本："
version
puts "----------------------------------------"
puts "开始设置工程需要的 IP 核..."

puts "BRAM PART BEGIN ..."
puts "开始创建 BRAM IP 核 Attn_TmpRam..."
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name Attn_TmpRam
set_property -dict [list \
    CONFIG.Component_Name {Attn_TmpRam} \
    CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
    CONFIG.Interface_Type {Native} \
    CONFIG.Enable_32bit_Address {false} \
    CONFIG.Write_Width_A {20} \
    CONFIG.Read_Width_A {20} \
    CONFIG.Write_Depth_A {4096} \
    CONFIG.Operating_Mode_A {NO_CHANGE} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    CONFIG.READ_LATENCY_A {1} \
    CONFIG.Write_Width_B {20} \
    CONFIG.Read_Width_B {20} \
    CONFIG.Operating_Mode_B {WRITE_FIRST} \
    CONFIG.Enable_B {Always_Enabled} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortB_Output_of_Memory_Core {false} \
    CONFIG.READ_LATENCY_B {1} \
    CONFIG.Use_Byte_Write_Enable {false} \
    CONFIG.Byte_Size {9} \
    CONFIG.Algorithm {Minimum_Area} \
    CONFIG.Primitive {8kx2} \
    CONFIG.Port_A_Clock {100} \
    CONFIG.Port_A_Enable_Rate {100} \
    CONFIG.Port_A_Write_Rate {50} \
    CONFIG.Port_B_Clock {100} \
    CONFIG.Port_B_Enable_Rate {100} \
    CONFIG.Reset_Type {SYNC} \
    CONFIG.Use_RSTA_Pin {false} \
    CONFIG.Use_RSTB_Pin {false} \
    CONFIG.Reset_Priority_A {CE} \
    CONFIG.Reset_Priority_B {CE} \
    CONFIG.ECC {false} \
    CONFIG.ecctype {No_ECC} \
    CONFIG.Collision_Warnings {ALL} \
    CONFIG.Assume_Synchronous_Clk {false} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.use_bram_block {Stand_Alone} \
    CONFIG.Load_Init_File {false} \
    CONFIG.Coe_File {no_coe_file_loaded} \
    CONFIG.MEM_FILE {no_mem_loaded} \
] [get_ips Attn_TmpRam]
generate_target all [get_ips Attn_TmpRam]
puts "BRAM IP 核 Attn_TmpRam 已成功生成"

puts "开始创建 BRAM IP 核 EmbeddedRAM..."
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name EmbeddedRAM
set_property -dict [list \
    CONFIG.Component_Name {EmbeddedRAM} \
    CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
    CONFIG.Interface_Type {Native} \
    CONFIG.Enable_32bit_Address {false} \
    CONFIG.Write_Width_A {64} \
    CONFIG.Read_Width_A {64} \
    CONFIG.Write_Depth_A {3072} \
    CONFIG.Operating_Mode_A {NO_CHANGE} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    CONFIG.READ_LATENCY_A {1} \
    CONFIG.Write_Width_B {64} \
    CONFIG.Read_Width_B {64} \
    CONFIG.Operating_Mode_B {READ_FIRST} \
    CONFIG.Enable_B {Always_Enabled} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortB_Output_of_Memory_Core {false} \
    CONFIG.READ_LATENCY_B {1} \
    CONFIG.Use_Byte_Write_Enable {false} \
    CONFIG.Byte_Size {9} \
    CONFIG.Algorithm {Minimum_Area} \
    CONFIG.Primitive {8kx2} \
    CONFIG.Port_A_Clock {100} \
    CONFIG.Port_A_Enable_Rate {100} \
    CONFIG.Port_A_Write_Rate {50} \
    CONFIG.Port_B_Clock {100} \
    CONFIG.Port_B_Enable_Rate {100} \
    CONFIG.Reset_Type {SYNC} \
    CONFIG.Use_RSTA_Pin {false} \
    CONFIG.Use_RSTB_Pin {false} \
    CONFIG.Reset_Priority_A {CE} \
    CONFIG.Reset_Priority_B {CE} \
    CONFIG.ECC {false} \
    CONFIG.ecctype {No_ECC} \
    CONFIG.Collision_Warnings {ALL} \
    CONFIG.Assume_Synchronous_Clk {true} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.use_bram_block {Stand_Alone} \
    CONFIG.Load_Init_File {false} \
    CONFIG.Coe_File {no_coe_file_loaded} \
    CONFIG.MEM_FILE {no_mem_loaded} \
] [get_ips EmbeddedRAM]
generate_target all [get_ips EmbeddedRAM]
puts "BRAM IP 核 EmbeddedRAM 已成功生成"

puts "开始创建 BRAM IP 核 MLP_hidden_TmpSpikesRam..."
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name MLP_hidden_TmpSpikesRam
set_property -dict [list \
    CONFIG.Component_Name {MLP_hidden_TmpSpikesRam} \
    CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
    CONFIG.Interface_Type {Native} \
    CONFIG.Enable_32bit_Address {false} \
    CONFIG.Write_Width_A {64} \
    CONFIG.Read_Width_A {64} \
    CONFIG.Write_Depth_A {12288} \
    CONFIG.Operating_Mode_A {NO_CHANGE} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    CONFIG.READ_LATENCY_A {1} \
    CONFIG.Write_Width_B {64} \
    CONFIG.Read_Width_B {64} \
    CONFIG.Operating_Mode_B {READ_FIRST} \
    CONFIG.Enable_B {Always_Enabled} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortB_Output_of_Memory_Core {false} \
    CONFIG.READ_LATENCY_B {1} \
    CONFIG.Use_Byte_Write_Enable {false} \
    CONFIG.Byte_Size {9} \
    CONFIG.Algorithm {Minimum_Area} \
    CONFIG.Primitive {8kx2} \
    CONFIG.Port_A_Clock {100} \
    CONFIG.Port_A_Enable_Rate {100} \
    CONFIG.Port_A_Write_Rate {50} \
    CONFIG.Port_B_Clock {100} \
    CONFIG.Port_B_Enable_Rate {100} \
    CONFIG.Reset_Type {SYNC} \
    CONFIG.Use_RSTA_Pin {false} \
    CONFIG.Use_RSTB_Pin {false} \
    CONFIG.Reset_Priority_A {CE} \
    CONFIG.Reset_Priority_B {CE} \
    CONFIG.ECC {false} \
    CONFIG.ecctype {No_ECC} \
    CONFIG.Collision_Warnings {ALL} \
    CONFIG.Assume_Synchronous_Clk {true} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.use_bram_block {Stand_Alone} \
    CONFIG.Load_Init_File {false} \
    CONFIG.Coe_File {no_coe_file_loaded} \
    CONFIG.MEM_FILE {no_mem_loaded} \
] [get_ips MLP_hidden_TmpSpikesRam]
generate_target all [get_ips MLP_hidden_TmpSpikesRam]
puts "BRAM IP 核 MLP_hidden_TmpSpikesRam 已成功生成"

puts "开始创建 BRAM IP 核 psum_ram..."
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name psum_ram
set_property -dict [list \
    CONFIG.Component_Name {psum_ram} \
    CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
    CONFIG.Interface_Type {Native} \
    CONFIG.Enable_32bit_Address {false} \
    CONFIG.Write_Width_A {84} \
    CONFIG.Read_Width_A {84} \
    CONFIG.Write_Depth_A {512} \
    CONFIG.Operating_Mode_A {NO_CHANGE} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    CONFIG.READ_LATENCY_A {1} \
    CONFIG.Write_Width_B {84} \
    CONFIG.Read_Width_B {84} \
    CONFIG.Operating_Mode_B {READ_FIRST} \
    CONFIG.Enable_B {Always_Enabled} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortB_Output_of_Memory_Core {false} \
    CONFIG.READ_LATENCY_B {1} \
    CONFIG.Use_Byte_Write_Enable {false} \
    CONFIG.Byte_Size {9} \
    CONFIG.Algorithm {Minimum_Area} \
    CONFIG.Primitive {8kx2} \
    CONFIG.Port_A_Clock {100} \
    CONFIG.Port_A_Enable_Rate {100} \
    CONFIG.Port_A_Write_Rate {50} \
    CONFIG.Port_B_Clock {100} \
    CONFIG.Port_B_Enable_Rate {100} \
    CONFIG.Reset_Type {SYNC} \
    CONFIG.Use_RSTA_Pin {false} \
    CONFIG.Use_RSTB_Pin {false} \
    CONFIG.Reset_Priority_A {CE} \
    CONFIG.Reset_Priority_B {CE} \
    CONFIG.ECC {false} \
    CONFIG.ecctype {No_ECC} \
    CONFIG.Collision_Warnings {ALL} \
    CONFIG.Assume_Synchronous_Clk {false} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.use_bram_block {Stand_Alone} \
    CONFIG.Load_Init_File {false} \
    CONFIG.Coe_File {no_coe_file_loaded} \
    CONFIG.MEM_FILE {no_mem_loaded} \
] [get_ips psum_ram]
generate_target all [get_ips psum_ram]
puts "BRAM IP 核 psum_ram 已成功生成"

puts "开始创建 BRAM IP 核 qkv_SpikesTmpRam..."
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name qkv_SpikesTmpRam
set_property -dict [list \
    CONFIG.Component_Name {qkv_SpikesTmpRam} \
    CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
    CONFIG.Interface_Type {Native} \
    CONFIG.Enable_32bit_Address {false} \
    CONFIG.Write_Width_A {128} \
    CONFIG.Read_Width_A {128} \
    CONFIG.Write_Depth_A {1024} \
    CONFIG.Operating_Mode_A {NO_CHANGE} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    CONFIG.READ_LATENCY_A {1} \
    CONFIG.Write_Width_B {128} \
    CONFIG.Read_Width_B {128} \
    CONFIG.Operating_Mode_B {READ_FIRST} \
    CONFIG.Enable_B {Always_Enabled} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortB_Output_of_Memory_Core {false} \
    CONFIG.READ_LATENCY_B {1} \
    CONFIG.Use_Byte_Write_Enable {false} \
    CONFIG.Byte_Size {9} \
    CONFIG.Algorithm {Minimum_Area} \
    CONFIG.Primitive {8kx2} \
    CONFIG.Port_A_Clock {100} \
    CONFIG.Port_A_Enable_Rate {100} \
    CONFIG.Port_A_Write_Rate {50} \
    CONFIG.Port_B_Clock {100} \
    CONFIG.Port_B_Enable_Rate {100} \
    CONFIG.Reset_Type {SYNC} \
    CONFIG.Use_RSTA_Pin {false} \
    CONFIG.Use_RSTB_Pin {false} \
    CONFIG.Reset_Priority_A {CE} \
    CONFIG.Reset_Priority_B {CE} \
    CONFIG.ECC {false} \
    CONFIG.ecctype {No_ECC} \
    CONFIG.Collision_Warnings {ALL} \
    CONFIG.Assume_Synchronous_Clk {false} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.use_bram_block {Stand_Alone} \
    CONFIG.Load_Init_File {false} \
    CONFIG.Coe_File {no_coe_file_loaded} \
    CONFIG.MEM_FILE {no_mem_loaded} \
] [get_ips qkv_SpikesTmpRam]
generate_target all [get_ips qkv_SpikesTmpRam]
puts "BRAM IP 核 qkv_SpikesTmpRam 已成功生成"

puts "开始创建 BRAM IP 核 SpikesTmpRam..."
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name SpikesTmpRam
set_property -dict [list \
    CONFIG.Component_Name {SpikesTmpRam} \
    CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
    CONFIG.Interface_Type {Native} \
    CONFIG.Enable_32bit_Address {false} \
    CONFIG.Write_Width_A {128} \
    CONFIG.Read_Width_A {128} \
    CONFIG.Write_Depth_A {8192} \
    CONFIG.Operating_Mode_A {NO_CHANGE} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    CONFIG.READ_LATENCY_A {1} \
    CONFIG.Write_Width_B {128} \
    CONFIG.Read_Width_B {128} \
    CONFIG.Operating_Mode_B {READ_FIRST} \
    CONFIG.Enable_B {Always_Enabled} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortB_Output_of_Memory_Core {false} \
    CONFIG.READ_LATENCY_B {1} \
    CONFIG.Use_Byte_Write_Enable {false} \
    CONFIG.Byte_Size {9} \
    CONFIG.Algorithm {Minimum_Area} \
    CONFIG.Primitive {8kx2} \
    CONFIG.Port_A_Clock {100} \
    CONFIG.Port_A_Enable_Rate {100} \
    CONFIG.Port_A_Write_Rate {50} \
    CONFIG.Port_B_Clock {100} \
    CONFIG.Port_B_Enable_Rate {100} \
    CONFIG.Reset_Type {SYNC} \
    CONFIG.Use_RSTA_Pin {false} \
    CONFIG.Use_RSTB_Pin {false} \
    CONFIG.Reset_Priority_A {CE} \
    CONFIG.Reset_Priority_B {CE} \
    CONFIG.ECC {false} \
    CONFIG.ecctype {No_ECC} \
    CONFIG.Collision_Warnings {ALL} \
    CONFIG.Assume_Synchronous_Clk {false} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.use_bram_block {Stand_Alone} \
    CONFIG.Load_Init_File {false} \
    CONFIG.Coe_File {no_coe_file_loaded} \
    CONFIG.MEM_FILE {no_mem_loaded} \
] [get_ips SpikesTmpRam]
generate_target all [get_ips SpikesTmpRam]
puts "BRAM IP 核 SpikesTmpRam 已成功生成"

puts "----------------------------------------"
puts "FIFO PART BEGIN ..."
puts "开始创建 FIFO IP 核 conv1_weight_fifo..."
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name conv1_weight_fifo
set_property -dict [list \
    CONFIG.Component_Name {conv1_weight_fifo} \
    CONFIG.INTERFACE_TYPE {Native} \
    CONFIG.Fifo_Implementation {Common_Clock_Block_RAM} \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width {64} \
    CONFIG.Output_Data_Width {64} \
    CONFIG.Input_Depth {32} \
    CONFIG.Data_Count_Width {6} \
    CONFIG.Reset_Type {Synchronous_Reset} \
    CONFIG.Reset_Pin {true} \
    CONFIG.Enable_Reset_Synchronization {true} \
    CONFIG.Clock_Enable_Type {Slave_Interface_Clock_Enable} \
    CONFIG.Full_Flags_Reset_Value {0} \
    CONFIG.Use_Dout_Reset {true} \
    CONFIG.Dout_Reset_Value {0} \
    CONFIG.Underflow_Flag {false} \
    CONFIG.Overflow_Flag {false} \
    CONFIG.Programmable_Full_Type {No_Programmable_Full_Threshold} \
    CONFIG.Programmable_Empty_Type {No_Programmable_Empty_Threshold} \
    CONFIG.Full_Threshold_Assert_Value {31} \
    CONFIG.Full_Threshold_Negate_Value {30} \
    CONFIG.Empty_Threshold_Assert_Value {4} \
    CONFIG.Empty_Threshold_Negate_Value {5} \
    CONFIG.Use_Extra_Logic {true} \
    CONFIG.asymmetric_port_width {false} \
    CONFIG.dynamic_power_saving {false} \
    CONFIG.Use_Embedded_Registers {false} \
    CONFIG.Output_Register_Type {Embedded_Reg} \
    CONFIG.Enable_ECC {false} \
    CONFIG.Enable_ECC_Type {Hard_ECC} \
    CONFIG.Data_Count {false} \
    CONFIG.Write_Data_Count {false} \
    CONFIG.Read_Data_Count {false} \
    CONFIG.CORE_CLK.FREQ_HZ {100000000} \
    CONFIG.READ_CLK.FREQ_HZ {100000000} \
    CONFIG.WRITE_CLK.FREQ_HZ {100000000} \
] [get_ips conv1_weight_fifo]
generate_target all [get_ips conv1_weight_fifo]
puts "FIFO IP 核 conv1_weight_fifo 已成功生成"

puts "开始创建 FIFO IP 核 features_in_fifo..."
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name features_in_fifo
set_property -dict [list \
    CONFIG.Component_Name {features_in_fifo} \
    CONFIG.INTERFACE_TYPE {Native} \
    CONFIG.Fifo_Implementation {Common_Clock_Block_RAM} \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width {64} \
    CONFIG.Output_Data_Width {16} \
    CONFIG.Input_Depth {64} \
    CONFIG.Data_Count_Width {6} \
    CONFIG.Reset_Type {Synchronous_Reset} \
    CONFIG.Reset_Pin {true} \
    CONFIG.Enable_Reset_Synchronization {true} \
    CONFIG.Clock_Enable_Type {Slave_Interface_Clock_Enable} \
    CONFIG.Full_Flags_Reset_Value {0} \
    CONFIG.Use_Dout_Reset {true} \
    CONFIG.Dout_Reset_Value {0} \
    CONFIG.Underflow_Flag {false} \
    CONFIG.Overflow_Flag {false} \
    CONFIG.Programmable_Full_Type {No_Programmable_Full_Threshold} \
    CONFIG.Programmable_Empty_Type {No_Programmable_Empty_Threshold} \
    CONFIG.Full_Threshold_Assert_Value {31} \
    CONFIG.Full_Threshold_Negate_Value {30} \
    CONFIG.Empty_Threshold_Assert_Value {4} \
    CONFIG.Empty_Threshold_Negate_Value {5} \
    CONFIG.Use_Extra_Logic {true} \
    CONFIG.asymmetric_port_width {true} \
    CONFIG.dynamic_power_saving {false} \
    CONFIG.Use_Embedded_Registers {false} \
    CONFIG.Output_Register_Type {Embedded_Reg} \
    CONFIG.Enable_ECC {false} \
    CONFIG.Enable_ECC_Type {Hard_ECC} \
    CONFIG.Data_Count {false} \
    CONFIG.Write_Data_Count {false} \
    CONFIG.Read_Data_Count {false} \
    CONFIG.CORE_CLK.FREQ_HZ {100000000} \
    CONFIG.READ_CLK.FREQ_HZ {100000000} \
    CONFIG.WRITE_CLK.FREQ_HZ {100000000} \
] [get_ips features_in_fifo]
generate_target all [get_ips features_in_fifo]
puts "FIFO IP 核 features_in_fifo 已成功生成"

puts "开始创建 FIFO IP 核 MaxPool_fifo..."
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name MaxPool_fifo
set_property -dict [list \
    CONFIG.Component_Name {MaxPool_fifo} \
    CONFIG.INTERFACE_TYPE {Native} \
    CONFIG.Fifo_Implementation {Common_Clock_Block_RAM} \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width {128} \
    CONFIG.Output_Data_Width {128} \
    CONFIG.Input_Depth {1024} \
    CONFIG.Data_Count_Width {10} \
    CONFIG.Reset_Type {Synchronous_Reset} \
    CONFIG.Reset_Pin {true} \
    CONFIG.Enable_Reset_Synchronization {true} \
    CONFIG.Clock_Enable_Type {Slave_Interface_Clock_Enable} \
    CONFIG.Full_Flags_Reset_Value {0} \
    CONFIG.Use_Dout_Reset {true} \
    CONFIG.Dout_Reset_Value {0} \
    CONFIG.Underflow_Flag {false} \
    CONFIG.Overflow_Flag {false} \
    CONFIG.Programmable_Full_Type {No_Programmable_Full_Threshold} \
    CONFIG.Programmable_Empty_Type {No_Programmable_Empty_Threshold} \
    CONFIG.Full_Threshold_Assert_Value {31} \
    CONFIG.Full_Threshold_Negate_Value {30} \
    CONFIG.Empty_Threshold_Assert_Value {4} \
    CONFIG.Empty_Threshold_Negate_Value {5} \
    CONFIG.Use_Extra_Logic {true} \
    CONFIG.asymmetric_port_width {false} \
    CONFIG.dynamic_power_saving {false} \
    CONFIG.Use_Embedded_Registers {false} \
    CONFIG.Output_Register_Type {Embedded_Reg} \
    CONFIG.Enable_ECC {false} \
    CONFIG.Enable_ECC_Type {Hard_ECC} \
    CONFIG.Data_Count {false} \
    CONFIG.Write_Data_Count {false} \
    CONFIG.Read_Data_Count {false} \
    CONFIG.CORE_CLK.FREQ_HZ {100000000} \
    CONFIG.READ_CLK.FREQ_HZ {100000000} \
    CONFIG.WRITE_CLK.FREQ_HZ {100000000} \
] [get_ips MaxPool_fifo]
generate_target all [get_ips MaxPool_fifo]
puts "FIFO IP 核 MaxPool_fifo 已成功生成"

puts "开始创建 FIFO IP 核 MM_Calc_FIFO..."
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name MM_Calc_FIFO
set_property -dict [list \
    CONFIG.Component_Name {MM_Calc_FIFO} \
    CONFIG.INTERFACE_TYPE {Native} \
    CONFIG.Fifo_Implementation {Common_Clock_Block_RAM} \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width {48} \
    CONFIG.Output_Data_Width {48} \
    CONFIG.Input_Depth {64} \
    CONFIG.Data_Count_Width {6} \
    CONFIG.Reset_Type {Synchronous_Reset} \
    CONFIG.Reset_Pin {true} \
    CONFIG.Enable_Reset_Synchronization {true} \
    CONFIG.Clock_Enable_Type {Slave_Interface_Clock_Enable} \
    CONFIG.Full_Flags_Reset_Value {0} \
    CONFIG.Use_Dout_Reset {true} \
    CONFIG.Dout_Reset_Value {0} \
    CONFIG.Underflow_Flag {false} \
    CONFIG.Overflow_Flag {false} \
    CONFIG.Programmable_Full_Type {No_Programmable_Full_Threshold} \
    CONFIG.Programmable_Empty_Type {No_Programmable_Empty_Threshold} \
    CONFIG.Full_Threshold_Assert_Value {31} \
    CONFIG.Full_Threshold_Negate_Value {30} \
    CONFIG.Empty_Threshold_Assert_Value {4} \
    CONFIG.Empty_Threshold_Negate_Value {5} \
    CONFIG.Use_Extra_Logic {true} \
    CONFIG.asymmetric_port_width {false} \
    CONFIG.dynamic_power_saving {false} \
    CONFIG.Use_Embedded_Registers {false} \
    CONFIG.Output_Register_Type {Embedded_Reg} \
    CONFIG.Enable_ECC {false} \
    CONFIG.Enable_ECC_Type {Hard_ECC} \
    CONFIG.Data_Count {false} \
    CONFIG.Write_Data_Count {false} \
    CONFIG.Read_Data_Count {false} \
    CONFIG.CORE_CLK.FREQ_HZ {100000000} \
    CONFIG.READ_CLK.FREQ_HZ {100000000} \
    CONFIG.WRITE_CLK.FREQ_HZ {100000000} \
] [get_ips MM_Calc_FIFO]
generate_target all [get_ips MM_Calc_FIFO]
puts "FIFO IP 核 MM_Calc_FIFO 已成功生成"

puts "开始创建 FIFO IP 核 MtrxA_slice_fifo..."
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name MtrxA_slice_fifo
set_property -dict [list \
    CONFIG.Component_Name {MtrxA_slice_fifo} \
    CONFIG.INTERFACE_TYPE {Native} \
    CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width {64} \
    CONFIG.Output_Data_Width {64} \
    CONFIG.Input_Depth {16} \
    CONFIG.Data_Count_Width {6} \
    CONFIG.Reset_Type {Synchronous_Reset} \
    CONFIG.Reset_Pin {true} \
    CONFIG.Enable_Reset_Synchronization {true} \
    CONFIG.Clock_Enable_Type {Slave_Interface_Clock_Enable} \
    CONFIG.Full_Flags_Reset_Value {0} \
    CONFIG.Use_Dout_Reset {true} \
    CONFIG.Dout_Reset_Value {0} \
    CONFIG.Underflow_Flag {false} \
    CONFIG.Overflow_Flag {false} \
    CONFIG.Programmable_Full_Type {No_Programmable_Full_Threshold} \
    CONFIG.Programmable_Empty_Type {No_Programmable_Empty_Threshold} \
    CONFIG.Full_Threshold_Assert_Value {31} \
    CONFIG.Full_Threshold_Negate_Value {30} \
    CONFIG.Empty_Threshold_Assert_Value {4} \
    CONFIG.Empty_Threshold_Negate_Value {5} \
    CONFIG.Use_Extra_Logic {true} \
    CONFIG.asymmetric_port_width {false} \
    CONFIG.dynamic_power_saving {false} \
    CONFIG.Use_Embedded_Registers {false} \
    CONFIG.Output_Register_Type {Embedded_Reg} \
    CONFIG.Enable_ECC {false} \
    CONFIG.Enable_ECC_Type {Hard_ECC} \
    CONFIG.Data_Count {false} \
    CONFIG.Write_Data_Count {false} \
    CONFIG.Read_Data_Count {false} \
    CONFIG.CORE_CLK.FREQ_HZ {100000000} \
    CONFIG.READ_CLK.FREQ_HZ {100000000} \
    CONFIG.WRITE_CLK.FREQ_HZ {100000000} \
] [get_ips MtrxA_slice_fifo]
generate_target all [get_ips MtrxA_slice_fifo]
puts "FIFO IP 核 MtrxA_slice_fifo 已成功生成"

puts "开始创建 FIFO IP 核 Psum_slice_fifo..."
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name Psum_slice_fifo
set_property -dict [list \
    CONFIG.Component_Name {Psum_slice_fifo} \
    CONFIG.INTERFACE_TYPE {Native} \
    CONFIG.Fifo_Implementation {Common_Clock_Block_RAM} \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width {80} \
    CONFIG.Output_Data_Width {80} \
    CONFIG.Input_Depth {128} \
    CONFIG.Data_Count_Width {7} \
    CONFIG.Reset_Type {Synchronous_Reset} \
    CONFIG.Reset_Pin {true} \
    CONFIG.Enable_Reset_Synchronization {true} \
    CONFIG.Clock_Enable_Type {Slave_Interface_Clock_Enable} \
    CONFIG.Full_Flags_Reset_Value {0} \
    CONFIG.Use_Dout_Reset {true} \
    CONFIG.Dout_Reset_Value {0} \
    CONFIG.Underflow_Flag {false} \
    CONFIG.Overflow_Flag {false} \
    CONFIG.Programmable_Full_Type {No_Programmable_Full_Threshold} \
    CONFIG.Programmable_Empty_Type {No_Programmable_Empty_Threshold} \
    CONFIG.Full_Threshold_Assert_Value {31} \
    CONFIG.Full_Threshold_Negate_Value {30} \
    CONFIG.Empty_Threshold_Assert_Value {4} \
    CONFIG.Empty_Threshold_Negate_Value {5} \
    CONFIG.Use_Extra_Logic {true} \
    CONFIG.asymmetric_port_width {false} \
    CONFIG.dynamic_power_saving {false} \
    CONFIG.Use_Embedded_Registers {false} \
    CONFIG.Output_Register_Type {Embedded_Reg} \
    CONFIG.Enable_ECC {false} \
    CONFIG.Enable_ECC_Type {Hard_ECC} \
    CONFIG.Data_Count {false} \
    CONFIG.Write_Data_Count {false} \
    CONFIG.Read_Data_Count {false} \
    CONFIG.CORE_CLK.FREQ_HZ {100000000} \
    CONFIG.READ_CLK.FREQ_HZ {100000000} \
    CONFIG.WRITE_CLK.FREQ_HZ {100000000} \
] [get_ips Psum_slice_fifo]
generate_target all [get_ips Psum_slice_fifo]
puts "FIFO IP 核 Psum_slice_fifo 已成功生成"

puts "开始创建 FIFO IP 核 qkv_linearWeights_fifo..."
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name qkv_linearWeights_fifo
set_property -dict [list \
    CONFIG.Component_Name {qkv_linearWeights_fifo} \
    CONFIG.INTERFACE_TYPE {Native} \
    CONFIG.Fifo_Implementation {Common_Clock_Block_RAM} \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width {64} \
    CONFIG.Output_Data_Width {64} \
    CONFIG.Input_Depth {512} \
    CONFIG.Data_Count_Width {9} \
    CONFIG.Reset_Type {Synchronous_Reset} \
    CONFIG.Reset_Pin {true} \
    CONFIG.Enable_Reset_Synchronization {true} \
    CONFIG.Clock_Enable_Type {Slave_Interface_Clock_Enable} \
    CONFIG.Full_Flags_Reset_Value {0} \
    CONFIG.Use_Dout_Reset {true} \
    CONFIG.Dout_Reset_Value {0} \
    CONFIG.Underflow_Flag {false} \
    CONFIG.Overflow_Flag {false} \
    CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant} \
    CONFIG.Programmable_Empty_Type {Single_Programmable_Empty_Threshold_Constant} \
    CONFIG.Full_Threshold_Assert_Value {448} \
    CONFIG.Full_Threshold_Negate_Value {447} \
    CONFIG.Empty_Threshold_Assert_Value {64} \
    CONFIG.Empty_Threshold_Negate_Value {65} \
    CONFIG.Use_Extra_Logic {true} \
    CONFIG.asymmetric_port_width {false} \
    CONFIG.dynamic_power_saving {false} \
    CONFIG.Use_Embedded_Registers {false} \
    CONFIG.Output_Register_Type {Embedded_Reg} \
    CONFIG.Enable_ECC {false} \
    CONFIG.Enable_ECC_Type {Hard_ECC} \
    CONFIG.Data_Count {false} \
    CONFIG.Write_Data_Count {false} \
    CONFIG.Read_Data_Count {false} \
    CONFIG.CORE_CLK.FREQ_HZ {100000000} \
    CONFIG.READ_CLK.FREQ_HZ {100000000} \
    CONFIG.WRITE_CLK.FREQ_HZ {100000000} \
] [get_ips qkv_linearWeights_fifo]
generate_target all [get_ips qkv_linearWeights_fifo]
puts "FIFO IP 核 qkv_linearWeights_fifo 已成功生成"

puts "开始创建 FIFO IP 核 qkv_ReshapeFIFO..."
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name qkv_ReshapeFIFO
set_property -dict [list \
    CONFIG.Component_Name {qkv_ReshapeFIFO} \
    CONFIG.INTERFACE_TYPE {Native} \
    CONFIG.Fifo_Implementation {Common_Clock_Block_RAM} \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width {64} \
    CONFIG.Output_Data_Width {64} \
    CONFIG.Input_Depth {256} \
    CONFIG.Data_Count_Width {8} \
    CONFIG.Reset_Type {Synchronous_Reset} \
    CONFIG.Reset_Pin {true} \
    CONFIG.Enable_Reset_Synchronization {true} \
    CONFIG.Clock_Enable_Type {Slave_Interface_Clock_Enable} \
    CONFIG.Full_Flags_Reset_Value {0} \
    CONFIG.Use_Dout_Reset {true} \
    CONFIG.Dout_Reset_Value {0} \
    CONFIG.Underflow_Flag {false} \
    CONFIG.Overflow_Flag {false} \
    CONFIG.Programmable_Full_Type {No_Programmable_Full_Threshold} \
    CONFIG.Programmable_Empty_Type {No_Programmable_Empty_Threshold} \
    CONFIG.Full_Threshold_Assert_Value {31} \
    CONFIG.Full_Threshold_Negate_Value {30} \
    CONFIG.Empty_Threshold_Assert_Value {4} \
    CONFIG.Empty_Threshold_Negate_Value {5} \
    CONFIG.Use_Extra_Logic {true} \
    CONFIG.asymmetric_port_width {false} \
    CONFIG.dynamic_power_saving {false} \
    CONFIG.Use_Embedded_Registers {false} \
    CONFIG.Output_Register_Type {Embedded_Reg} \
    CONFIG.Enable_ECC {false} \
    CONFIG.Enable_ECC_Type {Hard_ECC} \
    CONFIG.Data_Count {false} \
    CONFIG.Write_Data_Count {false} \
    CONFIG.Read_Data_Count {false} \
    CONFIG.CORE_CLK.FREQ_HZ {100000000} \
    CONFIG.READ_CLK.FREQ_HZ {100000000} \
    CONFIG.WRITE_CLK.FREQ_HZ {100000000} \
] [get_ips qkv_ReshapeFIFO]
generate_target all [get_ips qkv_ReshapeFIFO]
puts "FIFO IP 核 qkv_ReshapeFIFO 已成功生成"

puts "开始创建 FIFO IP 核 SlaveControllerRec_FIFO..."
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name SlaveControllerRec_FIFO
set_property -dict [list \
    CONFIG.Component_Name {SlaveControllerRec_FIFO} \
    CONFIG.INTERFACE_TYPE {Native} \
    CONFIG.Fifo_Implementation {Common_Clock_Block_RAM} \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width {65} \
    CONFIG.Output_Data_Width {65} \
    CONFIG.Input_Depth {256} \
    CONFIG.Data_Count_Width {8} \
    CONFIG.Reset_Type {Synchronous_Reset} \
    CONFIG.Reset_Pin {true} \
    CONFIG.Enable_Reset_Synchronization {true} \
    CONFIG.Clock_Enable_Type {Slave_Interface_Clock_Enable} \
    CONFIG.Full_Flags_Reset_Value {0} \
    CONFIG.Use_Dout_Reset {true} \
    CONFIG.Dout_Reset_Value {0} \
    CONFIG.Underflow_Flag {false} \
    CONFIG.Overflow_Flag {false} \
    CONFIG.Programmable_Full_Type {No_Programmable_Full_Threshold} \
    CONFIG.Programmable_Empty_Type {No_Programmable_Empty_Threshold} \
    CONFIG.Full_Threshold_Assert_Value {31} \
    CONFIG.Full_Threshold_Negate_Value {30} \
    CONFIG.Empty_Threshold_Assert_Value {4} \
    CONFIG.Empty_Threshold_Negate_Value {5} \
    CONFIG.Use_Extra_Logic {true} \
    CONFIG.asymmetric_port_width {false} \
    CONFIG.dynamic_power_saving {false} \
    CONFIG.Use_Embedded_Registers {false} \
    CONFIG.Output_Register_Type {Embedded_Reg} \
    CONFIG.Enable_ECC {false} \
    CONFIG.Enable_ECC_Type {Hard_ECC} \
    CONFIG.Data_Count {false} \
    CONFIG.Write_Data_Count {false} \
    CONFIG.Read_Data_Count {false} \
    CONFIG.CORE_CLK.FREQ_HZ {100000000} \
    CONFIG.READ_CLK.FREQ_HZ {100000000} \
    CONFIG.WRITE_CLK.FREQ_HZ {100000000} \
] [get_ips SlaveControllerRec_FIFO]
generate_target all [get_ips SlaveControllerRec_FIFO]
puts "FIFO IP 核 SlaveControllerRec_FIFO 已成功生成"

puts "----------------------------------------"
puts "ROM PART BEGIN ..."
puts "开始创建 DISTRIBUTED ROM IP 核 cal_code_rom..."
create_ip -name dist_mem_gen -vendor xilinx.com -library ip -version 8.0 -module_name cal_code_rom
set_property -dict [list \
    CONFIG.Component_Name {cal_code_rom} \
    CONFIG.memory_type {rom} \
    CONFIG.data_width {96} \
    CONFIG.depth {32} \
    CONFIG.default_data {0} \
    CONFIG.default_data_radix {16} \
    CONFIG.input_options {non_registered} \
    CONFIG.output_options {non_registered} \
    CONFIG.dual_port_address {non_registered} \
    CONFIG.simple_dual_port_address {non_registered} \
    CONFIG.input_clock_enable {false} \
    CONFIG.single_port_output_clock_enable {false} \
    CONFIG.dual_port_output_clock_enable {false} \
    CONFIG.simple_dual_port_output_clock_enable {false} \
    CONFIG.reset_qspo {false} \
    CONFIG.reset_qdpo {false} \
    CONFIG.reset_qsdpo {false} \
    CONFIG.sync_reset_qspo {false} \
    CONFIG.sync_reset_qdpo {false} \
    CONFIG.sync_reset_qsdpo {false} \
    CONFIG.ce_overrides {ce_overrides_sync_controls} \
    CONFIG.qualify_we_with_i_ce {false} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.coefficient_file "[file join $script_dir coe_files fetch_code.coe]" \
] [get_ips cal_code_rom]
generate_target all [get_ips cal_code_rom]
puts "ROM IP核 cal_code_rom 已成功生成"

puts "开始创建 DISTRIBUTED ROM IP 核 conv_layer1_bias_rom..."
create_ip -name dist_mem_gen -vendor xilinx.com -library ip -version 8.0 -module_name conv_layer1_bias_rom
set_property -dict [list \
    CONFIG.Component_Name {conv_layer1_bias_rom} \
    CONFIG.memory_type {rom} \
    CONFIG.data_width {8} \
    CONFIG.depth {64} \
    CONFIG.default_data {0} \
    CONFIG.default_data_radix {16} \
    CONFIG.input_options {non_registered} \
    CONFIG.output_options {non_registered} \
    CONFIG.dual_port_address {non_registered} \
    CONFIG.simple_dual_port_address {non_registered} \
    CONFIG.input_clock_enable {false} \
    CONFIG.single_port_output_clock_enable {false} \
    CONFIG.dual_port_output_clock_enable {false} \
    CONFIG.simple_dual_port_output_clock_enable {false} \
    CONFIG.reset_qspo {false} \
    CONFIG.reset_qdpo {false} \
    CONFIG.reset_qsdpo {false} \
    CONFIG.sync_reset_qspo {false} \
    CONFIG.sync_reset_qdpo {false} \
    CONFIG.sync_reset_qsdpo {false} \
    CONFIG.ce_overrides {ce_overrides_sync_controls} \
    CONFIG.qualify_we_with_i_ce {false} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.coefficient_file "[file join $script_dir coe_files conv1_bias.coe]" \
] [get_ips conv_layer1_bias_rom]
generate_target all [get_ips conv_layer1_bias_rom]
puts "ROM IP核 conv_layer1_bias_rom 已成功生成"

puts "开始创建 BLOCK ROM IP 核 linear_k_bias_rom..."
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name linear_k_bias_rom
set_property -dict [list \
    CONFIG.Component_Name {linear_k_bias_rom} \
    CONFIG.Memory_Type {Single_Port_ROM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {512} \
    CONFIG.Operating_Mode_A {WRITE_FIRST} \
    CONFIG.Fill_Remaining_Memory_Locations {false} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    CONFIG.READ_LATENCY_A {1} \
    CONFIG.Port_A_Clock {100} \
    CONFIG.Port_A_Enable_Rate {100} \
    CONFIG.Algorithm {Minimum_Area} \
    CONFIG.Primitive {8kx2} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Reset_Type {SYNC} \
    CONFIG.Use_RSTA_Pin {false} \
    CONFIG.Output_Reset_Value_A {0} \
    CONFIG.Interface_Type {Native} \
    CONFIG.Enable_32bit_Address {false} \
    CONFIG.Collision_Warnings {ALL} \
    CONFIG.ecctype {No_ECC} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File "[file join $script_dir coe_files linear_k_bias.coe]" \
] [get_ips linear_k_bias_rom]
generate_target all [get_ips linear_k_bias_rom]
puts "ROM IP 核 linear_k_bias_rom 已成功生成"


puts "开始创建 BLOCK ROM IP 核 linear_q_bias_rom..."
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name linear_q_bias_rom
set_property -dict [list \
    CONFIG.Component_Name {linear_q_bias_rom} \
    CONFIG.Memory_Type {Single_Port_ROM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {512} \
    CONFIG.Operating_Mode_A {WRITE_FIRST} \
    CONFIG.Fill_Remaining_Memory_Locations {false} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    CONFIG.READ_LATENCY_A {1} \
    CONFIG.Port_A_Clock {100} \
    CONFIG.Port_A_Enable_Rate {100} \
    CONFIG.Algorithm {Minimum_Area} \
    CONFIG.Primitive {8kx2} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Reset_Type {SYNC} \
    CONFIG.Use_RSTA_Pin {false} \
    CONFIG.Output_Reset_Value_A {0} \
    CONFIG.Interface_Type {Native} \
    CONFIG.Enable_32bit_Address {false} \
    CONFIG.Collision_Warnings {ALL} \
    CONFIG.ecctype {No_ECC} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File "[file join $script_dir coe_files linear_q_bias.coe]" \
] [get_ips linear_q_bias_rom]
generate_target all [get_ips linear_q_bias_rom]
puts "ROM IP 核 linear_q_bias_rom 已成功生成"

puts "开始创建 BLOCK ROM IP 核 linear_v_bias_rom..."
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name linear_v_bias_rom
set_property -dict [list \
    CONFIG.Component_Name {linear_v_bias_rom} \
    CONFIG.Memory_Type {Single_Port_ROM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {512} \
    CONFIG.Operating_Mode_A {WRITE_FIRST} \
    CONFIG.Fill_Remaining_Memory_Locations {false} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    CONFIG.READ_LATENCY_A {1} \
    CONFIG.Port_A_Clock {100} \
    CONFIG.Port_A_Enable_Rate {100} \
    CONFIG.Algorithm {Minimum_Area} \
    CONFIG.Primitive {8kx2} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Reset_Type {SYNC} \
    CONFIG.Use_RSTA_Pin {false} \
    CONFIG.Output_Reset_Value_A {0} \
    CONFIG.Interface_Type {Native} \
    CONFIG.Enable_32bit_Address {false} \
    CONFIG.Collision_Warnings {ALL} \
    CONFIG.ecctype {No_ECC} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File "[file join $script_dir coe_files linear_v_bias.coe]" \
] [get_ips linear_v_bias_rom]
generate_target all [get_ips linear_v_bias_rom]
puts "ROM IP 核 linear_v_bias_rom 已成功生成"

puts "开始创建 BLOCK ROM IP 核 MLPs_bias_Rom..."
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name MLPs_bias_Rom
set_property -dict [list \
    CONFIG.Component_Name {MLPs_bias_Rom} \
    CONFIG.Memory_Type {Single_Port_ROM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {4096} \
    CONFIG.Operating_Mode_A {WRITE_FIRST} \
    CONFIG.Fill_Remaining_Memory_Locations {false} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    CONFIG.READ_LATENCY_A {1} \
    CONFIG.Port_A_Clock {100} \
    CONFIG.Port_A_Enable_Rate {100} \
    CONFIG.Algorithm {Minimum_Area} \
    CONFIG.Primitive {8kx2} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Reset_Type {SYNC} \
    CONFIG.Use_RSTA_Pin {false} \
    CONFIG.Output_Reset_Value_A {0} \
    CONFIG.Interface_Type {Native} \
    CONFIG.Enable_32bit_Address {false} \
    CONFIG.Collision_Warnings {ALL} \
    CONFIG.ecctype {No_ECC} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File "[file join $script_dir coe_files mlp_bias.coe]" \
] [get_ips MLPs_bias_Rom]
generate_target all [get_ips MLPs_bias_Rom]
puts "ROM IP 核 MLPs_bias_Rom 已成功生成"

puts "开始创建 DISTRIBUTED ROM IP 核 proj_spikingconv_bias_rom..."
create_ip -name dist_mem_gen -vendor xilinx.com -library ip -version 8.0 -module_name proj_spikingconv_bias_rom
set_property -dict [list \
    CONFIG.Component_Name {proj_spikingconv_bias_rom} \
    CONFIG.memory_type {rom} \
    CONFIG.data_width {8} \
    CONFIG.depth {2048} \
    CONFIG.default_data {0} \
    CONFIG.default_data_radix {16} \
    CONFIG.input_options {non_registered} \
    CONFIG.output_options {non_registered} \
    CONFIG.dual_port_address {non_registered} \
    CONFIG.simple_dual_port_address {non_registered} \
    CONFIG.input_clock_enable {false} \
    CONFIG.single_port_output_clock_enable {false} \
    CONFIG.dual_port_output_clock_enable {false} \
    CONFIG.simple_dual_port_output_clock_enable {false} \
    CONFIG.reset_qspo {false} \
    CONFIG.reset_qdpo {false} \
    CONFIG.reset_qsdpo {false} \
    CONFIG.sync_reset_qspo {false} \
    CONFIG.sync_reset_qdpo {false} \
    CONFIG.sync_reset_qsdpo {false} \
    CONFIG.ce_overrides {ce_overrides_sync_controls} \
    CONFIG.qualify_we_with_i_ce {false} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.coefficient_file "[file join $script_dir coe_files sps_conv_bias.coe]" \
] [get_ips proj_spikingconv_bias_rom]
generate_target all [get_ips proj_spikingconv_bias_rom]
puts "ROM IP核 proj_spikingconv_bias_rom 已成功生成"

puts "----------------------------------------"
puts "MULTIPLIER PART BEGIN ..."
puts "开始创建 MULTIPLIER IP 核 conv1_multi..."
create_ip -name mult_gen -vendor xilinx.com -library ip -version 12.0 -module_name conv1_multi
set_property -dict [list \
    CONFIG.PortAWidth {8} \
    CONFIG.PortBWidth {8} \
    CONFIG.Multiplier_Construction {Use_Mults} \
    CONFIG.PipeStages {1} \
    CONFIG.OutputWidthHigh {15} \
    CONFIG.OutputWidthLow {0} \
] [get_ips conv1_multi]
generate_target all [get_ips conv1_multi]
puts "MULTIPLIER IP 核 conv1_multi 已成功生成"

puts "----------------------------------------"
puts "SHIFT RAM PART BEGIN ..."
create_ip -name c_shift_ram -vendor xilinx.com -library ip -version 12.0 -module_name conv1_shift_ram
set_property -dict [list \
  CONFIG.Width {25} \
  CONFIG.Depth {31} \
  CONFIG.ShiftRegType {Fixed_Length} \
  CONFIG.CE {true} \
  CONFIG.DefaultData {0000000000000000000000000} \
  CONFIG.OptGoal {Resources} \
] [get_ips conv1_shift_ram]
generate_target all [get_ips conv1_shift_ram]
puts "SHIFT RAM IP 核 conv1_shift_ram 已成功生成"

puts ">>>>>>>>>>>>>>>>>>>> ATTENTION <<<<<<<<<<<<<<<<<<<<"
puts "所有IP核生成完毕, 请检查是否正确 (VIVADO 的版本也许会也许生成)"
puts "check the WARNINGS and ERRORS in the console"
puts "注意其中 ROM 导入的 .coe 文件位置(需要根据实际情况修改)"
