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
├── TOP.v                    # 顶层模块
├── hyper_para.v            # 超参数配置
├── testbench/              # 测试平台
├── 3rdparty/              # 第三方库
├── ddr_sim/               # DDR仿真模块
├── Transformer_part/      # Transformer相关模块
├── diagram/               # 项目架构图
├── PE_dsp_part/          # DSP处理单元
├── RAM_part/             # RAM相关模块
├── eyeriss_part/         # Eyeriss架构实现
├── proj_lif/             # LIF神经元实现
└── arbiter/              # 仲裁器模块 (供仿真使用)
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
   - 后续更新...

## 配置说明
   - 在`hyper_para.v`中配置相关参数
      -- 超参数说明，需要修改 src 文件中的 include 为绝对路径 （保证能加入Block Design 中）
      ```python
         python setup.py "hyper_para.v"
      ```
   - 在 vivado 工程中运行 init_ips.tcl 生成对应的IP
      ```tcl
         source <real_path>/FPGA_SpikingTransformer/IPs_init/init_ips.tcl
      ```

## 贡献指南

欢迎提交Issue和Pull Request来帮助改进项目。

---
*项目持续更新中...*
