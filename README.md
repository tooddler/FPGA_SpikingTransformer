# Spiking-Transformer-FPGA-impl

本项目实现了基于FPGA的Spiking Transformer加速器，结合了脉冲神经网络(SNN)和Transformer架构的优势，为神经形态计算提供了一个高效的硬件实现方案。

## 项目概述

本项目主要包含以下几个关键部分：

1. **Spiking Transformer算法实现**
   - 基于[Spikformer](https://github.com/ZK-Zhou/spikformer)的开源实现
   - 实现了BN层吸收和低比特感知量化 QAT
   - 参考论文：Spikformer: When Spiking Neural Network Meets Transformer

2. **NeuFlow架构集成**
   - 实现图像数据到脉冲数据的转换
   - 完成Spiking Encoder部分的硬件实现

3. **Eyeriss架构优化**
   - 实现Spiking Patch Splitting Module的加速
   - 采用自定义指令集进行调度
   - 支持灵活的backbone修改

4. **TPU设计参考**
   - 使用脉动矩阵实现脉冲线性层
   - 优化MLP计算性能

## 项目结构

```
.
├── TOP.v                     # 顶层模块
├── hyper_para.v.bak          # 超参数配置备份
├── setup.py                  # vivado 中加入 bd 前需要 run 
├── testbench/                # 测试平台
│  ├── TOP_tb.v                  # 总体仿真模块，sim约需要4小时（intel i9）
│  ├── TOP_tb.v                  # 总体仿真模块，sim约需要4小时（intel i9） 
│  ├── sim_only_v1               # 脉动矩阵模型仿真
│  ├── ...                       # 各小模块仿真
├── 3rdparty/                 # 第三方库
├── ddr_sim/                  # DDR 仿真模块
├── Transformer_part/         # Transformer 相关模块
├── diagram/                  # 项目架构图
├── PE_dsp_part/              # DSP 处理单元 - Spiking Encoder
├── RAM_part/                 # RAM 相关模块
├── eyeriss_part/             # Eyeriss 架构实现
├── proj_lif/                 # LIF 神经元实现
├── arbiter/                  # 仲裁器模块 (供仿真使用)
├── python_scripts/           # Python 脚本工具
├── reset_start_part/         # 复位和启动相关模块 
├── data_4fpga_bin/           # .coe, .bin, .txt files
└── IPs_init/                 # IP核初始化脚本
```

## 架构图

### SpikingEncoder架构
![SpikingEncoder00](/diagram/SpikingEncoder.png)

### Eyeriss架构
![Eyeriss00](/diagram/Eyeriss_part.png)

### Spiking Attention架构
![Attention00](/diagram/SpikingAttn.png)

## 开发进度

- [x] 完成卷积部分仿真 (2025.2.18)
- [x] Spiking Transformer完整实现 (2025.5.25)
- [ ] 性能优化与测试
- [ ] 文档完善

## 使用说明
   - 初步仿真：
      1. 设置 TOP_tb.v 为 top 文件，并配置好 IP；
      2. 这里的 DDR 仿真模型选择的是 ddr_sim_top.v , 使用了
         weight_bin_new.bin  : 脉冲编码层卷积以及各脉冲卷积层的卷积核权重
         img_bin.bin         ：仿真使用的 rgb888 测试数据
         linear_q_weight.bin ：linear_q的权重矩阵以及后续ffn, mlp部分权重
         linear_k_weight.bin ：linear_k的权重矩阵以及后续ffn, mlp部分权重
         linear_v_weight.bin ：linear_v的权重矩阵以及后续ffn, mlp部分权重
      3. run 后会生成每一层的输出结果(.txt files)
      4. 在 python 中与 torch 计算结果对比测试
         ```
         Requirements：
            timm==0.5.4
            cupy==10.3.1
            pytorch==1.10.0+cu111
            spikingjelly==0.0.0.0.12
            pyyaml
         ```
         ```python
            python model_view.py                   # 卷积部分 （写得很乱...）
            python SpikformerEncoderBlock_view.py  # Transformer 部分
         ```
         打印显示示例：

         ![test](/diagram/python_run.png)

      5. 初步速度测试：
         这里很玄学了 待我实习回去再说 ...
         ```python
            python model.py  # 包含了一个 gpu 跑这个 TIMESTEP = 4 的网络用时
         ```
         
         ![gpu_result](/diagram/rtx4090_result.png)

         仿真用时约为 **120 ms** (主频 100MHZ) 只包含了部分 DDR Load 到 register-files 的时间以及计算时间，还有后续从 FPGA 读回的时间还没算且不包含 CPU -> ddr 的时间。
      6. 预综合加布局布线：
         在 xczu7ev-ffvc1156-2-i 上实现，实际主频 **200 MHZ**
         ps 端代码 目前在外地也没板子，后续再说 ...
         
         ![utilization_and_timing](/diagram/utilization_and_timing.png)

   - 后续详细完善... 

## 配置说明
   - 在`hyper_para.v`中配置相关参数
      -- 超参数说明，需要修改 src 文件中的 include 为绝对路径 （保证能加入Block Design 中）
      ```python
         python setup.py "<real_path>/hyper_para.v"
      ```
   - 在 vivado 工程中运行 init_ips.tcl 生成对应的IP
      ```tcl
         source <real_path>/FPGA_SpikingTransformer/IPs_init/init_ips.tcl
      ```