# CNN RTL 项目结构分析结论

## 1. 顶层架构概览

本项目是一个完整的 CNN 推理硬件链路，整体数据流为：

`data_in(7x8bit)` -> `SA1` -> 量化/ReLU -> `Buffer1` -> `SA2` -> 量化/ReLU -> `Buffer2` -> `SA3` -> 量化/ReLU -> `Buffer3 + MaxPool` -> `FC` -> 量化 -> `SigLUT` -> `data_out`

顶层模块在 `CNN_top.v`，通过 `cnt` 统一控制各阶段使能窗口，`enable_out` 在末端输出有效周期拉高。

## 2. 主要模块分层

### 2.1 卷积计算主干

- `SA1.v` / `SA1_channel.v`：第一层常规卷积，32 通道并行，单通道为 11x7 PE 阵列 + 流水加法树  
- `SA_2.v` / `SA_channel_2.v`：第二层深度可分离卷积（3x3 结构）  
- `SA_3.v` / `SA_channel_3.v`：第三层逐点卷积，本质是 32 维乘加 + 加法树  
- `PE.v`：基础乘加处理单元（输入寄存 + 乘法 + 数据脉动传递）

### 2.2 缓存与存储

- `sramBuffer1.v`：第一缓存层，4 组 SRAM + 移位寄存器，输出 3 组 256bit 以匹配 SA2 输入窗口  
- `BUFFER_2.v`：第二缓存层，1 级 256bit 寄存  
- `CNN_top.v` 中的 `buffer3(SRAM_32_256)`：第三缓存层，存 SA3 第一列结果供池化  
- `SRAM_32_256.v`：256bit x 32 深度封装，内部由两个 128bit 宏拼接  
- `S018V3EBCDSP_X8Y4D128_PR.v`：底层 SRAM 宏模型

### 2.3 后处理与输出

- `rescale_conv.v` / `rescale_dwconv.v` / `rescale_pwconv.v` / `rescale_linear.v`：分层量化（移位加 + 算术右移 + 饱和截断）  
- `relu.v`：ReLU 激活  
- `maxpool_v2.v`：两拍池化逻辑  
- `FC.v` / `FC_PE.v`：32 路折叠 PE + 流水加法树输出 2 个分类通道  
- `SigLUT.v`：256 项 Sigmoid 查找表，输出 FP32

## 3. 时序与流水特征

- 顶层 `cnt` 驱动整机调度：从 SA1 输入窗口到最终输出形成固定时序管线  
- 不同阶段采用多级寄存器（`FF_8` / `FF_32`）进行关键路径切分  
- 卷积层和 FC 均为“并行计算 + 流水加法树”结构，实时性导向明显

## 4. 发现的结构风险点

1. `FC.v` 端口方向问题  
   - `FC.v` 中 `data_out` 被声明为 `input wire signed [63:0]`，但在顶层中作为 `FC` 输出连接到 `after_fc`。  
   - 从功能语义看，这里应为 `output`，否则顶层该网络无法被 `FC` 驱动。

2. 未使用信号  
   - `CNN_top.v` 中 `sigEN0/sigEN1` 被定义并赋值，但未用于 `SigLUT` 或输出路径控制，属于冗余控制信号。

3. 工程验证状态  
   - 项目当前未提供 testbench（README 已注明）。  
   - 当前环境未安装 `iverilog`，无法在本地完成语法编译与仿真验证。

## 5. 总结

该 RTL 工程模块化清晰，主干数据路径完整，三层卷积与缓存配合关系明确，体现了“高吞吐优先”的硬件设计思路。  
后续若要进入可交付状态，建议优先修正 `FC.v` 端口方向，并补齐最小可运行 testbench 做端到端时序/功能回归。

