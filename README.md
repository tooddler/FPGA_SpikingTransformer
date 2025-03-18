# Spiking-Transformer-FPGA-impl

## 找完工作再写

1. 完成 Spiking Transformer 算法训练，吸收 BN 层，进行低比特感知量化；
    - 参考大佬算法开源： https://github.com/ZK-Zhou/spikformer
    - 论文：Spikformer: When Spiking Neural Network Meets Transformer

2. 结合 NeuFlow 的通用卷积加速架构，实现图像数据到脉冲数据的转换，实现 Spiking Encoder 部分；

3. 对于脉冲卷积部分，参考 Eyeriss 通用卷积加速器，完成 Spiking Patch Splitting Module 部分加速，计算方式由自定义的指令集去调度，便于后续修改算法的 backbone 后，依然适用；

4. 参考Google的TPU设计，采用脉动矩阵完成脉冲线性层和 MLP 计算；

2025.2.18 做完卷积部分仿真

更新中。。。

## SpikingEncoder

![SpikingEncoder00](/Toddler_proj_fig/SpikingEncoder.png)

![SpikingEncoder01](/Toddler_proj_fig/SpikingEncoder_1.png)

## Simple Eyeriss

![Eyeriss00](/Toddler_proj_fig/Eyeriss_part.png)

## Spiking Attention

![Attention00](/Toddler_proj_fig/SpikingAttn.png)


