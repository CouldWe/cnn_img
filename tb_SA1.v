`timescale 1ns / 1ps

// ============================================================
//  SA1 第一层卷积 Testbench
//  被测模块：SA1（顶层，4通道并行）+ SA1_channel（单通道）
//
//  输入特征图：30×10，每次输入7×8bit（一行7像素）
//  卷积核：11×7，32通道（4通道/次，共8次，counter 0~7）
//  cnt时序：0~153，sa1_control 在 cnt=29/30/50/51/71/72 拉高
//  输出：4通道×32bit，经bias/量化/ReLU后为4×8bit
// ============================================================

module tb_SA1;

// ─────────────────── 时钟 / 复位 ───────────────────
reg clk;
reg rst_n;

initial clk = 0;
always #5 clk = ~clk;          // 100 MHz

// ─────────────────── DUT 端口 ───────────────────────
// 仅测试 SA1_channel 单通道（便于波形定向分析）
// 若需测 SA1 顶层，注释掉下方单通道实例，换成 SA1 顶层实例即可

reg         sa1_control;
reg  [2:0]  counter;
reg  signed [55:0]  data_in;        // 7×8bit 一行输入
reg  signed [615:0] weight;         // 11×7×8bit 单通道权重
wire signed [31:0]  data_out_ch;    // 单通道输出

SA1_channel dut_ch (
    .clk        (clk),
    .rst_n      (rst_n),
    .sa1_control(sa1_control),
    .counter    (counter),
    .data_in    (data_in),
    .weight     (weight),
    .data_out   (data_out_ch)
);

// ─────────────────── 局部变量 ───────────────────────
integer i;
reg [7:0] cnt;          // 镜像 CNN_top 中的 cnt，用于产生 sa1_control

// ─────────────────── 权重赋值（第0通道，全1方便手算验证）───
task set_weight_all_one;
    integer k;
    begin
        for (k = 0; k < 77; k = k + 1)
            weight[k*8 +: 8] = 8'sd1;
    end
endtask

// 全零权重（输出应为0）
task set_weight_all_zero;
    integer k;
    begin
        for (k = 0; k < 77; k = k + 1)
            weight[k*8 +: 8] = 8'sd0;
    end
endtask

// 随机权重
task set_weight_random;
    integer k;
    begin
        for (k = 0; k < 77; k = k + 1)
            weight[k*8 +: 8] = $random;
    end
endtask

// ─────────────────── 输入数据任务 ───────────────────
// 输入全1的一行（每个像素值=1）
task set_data_all_one;
    integer k;
    begin
        for (k = 0; k < 7; k = k + 1)
            data_in[k*8 +: 8] = 8'sd1;
    end
endtask

// 输入全零
task set_data_all_zero;
    begin
        data_in = 56'sd0;
    end
endtask

// 输入递增序列（0,1,2,3,4,5,6）
task set_data_incremental;
    integer k;
    begin
        for (k = 0; k < 7; k = k + 1)
            data_in[k*8 +: 8] = k[7:0];
    end
endtask

// 随机输入
task set_data_random;
    integer k;
    begin
        for (k = 0; k < 7; k = k + 1)
            data_in[k*8 +: 8] = $random;
    end
endtask

// ─────────────────── cnt → sa1_control 映射（与CNN_top一致）─
// T29/30/50/51/71/72 拉高 sa1_control
task update_sa1_control;
    begin
        if (cnt == 29 || cnt == 30 || cnt == 50 ||
            cnt == 51 || cnt == 71 || cnt == 72)
            sa1_control = 1'b1;
        else
            sa1_control = 1'b0;
    end
endtask

// ─────────────────── 计数器逻辑（与CNN_top一致）────────────
// counter 在 cnt==153 时加1，到7后归0
task update_counter;
    begin
        if (cnt == 8'd153) begin
            if (counter == 3'b111)
                counter = 3'b0;
            else
                counter = counter + 1;
        end
    end
endtask

// ─────────────────── 打印输出辅助 ───────────────────
task print_output;
    input [7:0] t;
    begin
        if (data_out_ch !== 32'bx)
            $display("[T=%0d cnt=%0d counter=%0d ctrl=%b] data_out_ch = %0d (0x%08h)",
                     $time, cnt, counter, sa1_control, $signed(data_out_ch), data_out_ch);
    end
endtask

// ─────────────────── 期望值校验 ─────────────────────
// 全1权重×全1输入：11×7个PE各自乘积=1，加法树求和=77
// 注意加法树有多级流水线寄存器（约6~7拍延迟），需要等待
task check_all_ones_result;
    begin
        // 加法树流水线级数：inputReg(1) + l2 reg(1) + l3 reg(1) + l4 reg(1) + l5 reg(1) + l6 reg(1) = 6级
        // PE自身也有1级寄存器
        // 总延迟 ≈ 7个时钟周期
        repeat(10) @(posedge clk);
        $display("=== 全1校验: 期望 data_out_ch = 77, 实际 = %0d ===", $signed(data_out_ch));
        if ($signed(data_out_ch) === 77)
            $display("PASS: 全1权重×全1输入结果正确");
        else
            $display("FAIL: 期望77，得到%0d", $signed(data_out_ch));
    end
endtask

// ─────────────────── 主测试流程 ─────────────────────
initial begin
    $dumpfile("tb_SA1.vcd");
    $dumpvars(0, tb_SA1);

    // ── 初始化 ──
    rst_n       = 0;
    sa1_control = 0;
    counter     = 3'b0;
    data_in     = 56'd0;
    weight      = 616'd0;
    cnt         = 8'd0;

    repeat(3) @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    // ═══════════════════════════════════════════════
    // 测试1：复位验证
    // ═══════════════════════════════════════════════
    $display("\n========== TEST 1: 复位验证 ==========");
    rst_n = 0;
    @(posedge clk);
    rst_n = 1;
    $display("复位释放后 data_out_ch = %0d", $signed(data_out_ch));

    // ═══════════════════════════════════════════════
    // 测试2：全零权重输入，输出应为0
    // ═══════════════════════════════════════════════
    $display("\n========== TEST 2: 全零权重 ==========");
    set_weight_all_zero;
    counter = 3'd0;
    // 模拟 cnt 0~30 的纵向滑动阶段（sa1_control=0）
    for (i = 0; i < 31; i = i + 1) begin
        cnt = i;
        update_sa1_control;
        set_data_all_one;
        @(posedge clk);
    end
    repeat(10) @(posedge clk);
    $display("全零权重结果: data_out_ch = %0d (期望0)", $signed(data_out_ch));
    if ($signed(data_out_ch) === 0)
        $display("PASS");
    else
        $display("FAIL");

    // ═══════════════════════════════════════════════
    // 测试3：全1权重 + 全1输入，验证加法树
    // ═══════════════════════════════════════════════
    $display("\n========== TEST 3: 全1权重×全1输入，期望77 ==========");
    rst_n = 0;
    @(posedge clk);
    rst_n = 1;
    set_weight_all_one;
    set_data_all_one;
    counter = 3'd0;
    sa1_control = 1'b0;     // 纵向滑动阶段

    // 持续输入若干周期，让流水线填满
    repeat(20) @(posedge clk);
    check_all_ones_result;

    // ═══════════════════════════════════════════════
    // 测试4：模拟完整的 cnt 0~153 时序（counter=0，单通道）
    // 此为最接近真实运行的测试
    // ═══════════════════════════════════════════════
    $display("\n========== TEST 4: 完整时序仿真 (counter=0) ==========");
    rst_n = 0;
    @(posedge clk);
    rst_n = 1;

    set_weight_random;
    counter = 3'd0;

    for (i = 0; i <= 153; i = i + 1) begin
        cnt = i[7:0];
        update_sa1_control;

        // 根据 cnt 阶段切换输入数据
        // T0~T10：纵向下滑初始阶段（m_control=0，data从最后一行流入）
        // T11~T28：稳定输出阶段
        // T29~T30：横向右滑阶段（sa1_control=1）
        // T31~T49：纵向上滑阶段（m_control=1）
        // T50~T51：横向右滑/左滑阶段
        // T72~T153：继续滑动...
        if (cnt <= 10)
            set_data_all_one;
        else if (cnt >= 11 && cnt <= 28)
            set_data_incremental;
        else if (cnt >= 29 && cnt <= 30)
            set_data_all_one;           // 横向滑动期间注入新列
        else if (cnt >= 31 && cnt <= 49)
            set_data_incremental;
        else if (cnt >= 50 && cnt <= 51)
            set_data_all_one;
        else
            set_data_random;

        @(posedge clk);
        #1;                             // 采样延迟，避免时钟边沿采样竞争

        // 在关键时刻打印输出
        if (cnt >= 10 && cnt <= 30)
            print_output(cnt);
        if (cnt == 30 || cnt == 51 || cnt == 72 || cnt == 153)
            $display("[关键时刻 cnt=%0d] sa1_ctrl=%b m_state观察 data_out=%0d",
                     cnt, sa1_control, $signed(data_out_ch));
    end

    // ═══════════════════════════════════════════════
    // 测试5：counter 切换（0→1，r_or_l从0变1，左滑模式）
    // ═══════════════════════════════════════════════
    $display("\n========== TEST 5: counter=1 左滑模式 ==========");
    rst_n = 0;
    @(posedge clk);
    rst_n = 1;

    set_weight_random;
    counter = 3'd1;             // counter奇数 → r_or_l=1（左滑）
    sa1_control = 1'b0;

    // 先填充纵向阶段
    for (i = 0; i <= 28; i = i + 1) begin
        cnt = i[7:0];
        update_sa1_control;
        set_data_all_one;
        @(posedge clk);
    end

    // 触发横向左滑（cnt=29/30，sa1_control=1）
    for (i = 29; i <= 31; i = i + 1) begin
        cnt = i[7:0];
        update_sa1_control;
        set_data_all_one;
        @(posedge clk);
        #1;
        $display("[左滑测试 cnt=%0d ctrl=%b] data_out=%0d", cnt, sa1_control, $signed(data_out_ch));
    end

    // ═══════════════════════════════════════════════
    // 测试6：m_control 翻转（下滑→上滑切换验证）
    // 下降沿（cnt从30变31）时 m_control 翻转
    // ═══════════════════════════════════════════════
    $display("\n========== TEST 6: m_control 翻转边界 ==========");
    // cnt=30时 sa1_control=1，cnt=31时 sa1_control=0 → 下降沿 → m_control切换
    // 在 TEST 4 的完整时序中已覆盖，此处单独打印
    $display("m_control 翻转在 sa1_control 下降沿（cnt=31 / 52 / 73）触发");
    $display("（已在 TEST4 完整时序中覆盖，请查看 VCD 波形确认 m_control 信号）");

    // ═══════════════════════════════════════════════
    // 测试7：溢出/边界值（输入最大正/负，权重最大值）
    // ═══════════════════════════════════════════════
    $display("\n========== TEST 7: 边界值测试 ==========");
    rst_n = 0;
    @(posedge clk);
    rst_n = 1;

    // 权重全部设为最大正值 +127
    for (i = 0; i < 77; i = i + 1)
        weight[i*8 +: 8] = 8'sd127;

    // 输入全部设为最大正值 +127
    for (i = 0; i < 7; i = i + 1)
        data_in[i*8 +: 8] = 8'sd127;

    counter = 3'd0;
    sa1_control = 1'b0;
    repeat(20) @(posedge clk);
    // 期望：77 × (127×127) = 77 × 16129 = 1,241,933
    // 32bit有符号范围 [-2147483648, 2147483647]，不应溢出
    $display("最大正值×最大正值: data_out_ch = %0d (期望约1241933)", $signed(data_out_ch));

    // 权重最大负值 -128，输入 +127
    for (i = 0; i < 77; i = i + 1)
        weight[i*8 +: 8] = -8'sd128;
    for (i = 0; i < 7; i = i + 1)
        data_in[i*8 +: 8] = 8'sd127;

    repeat(20) @(posedge clk);
    // 期望：77 × (-128×127) = 77 × (-16256) = -1,251,712
    $display("最大负权重×最大正输入: data_out_ch = %0d (期望约-1251712)", $signed(data_out_ch));

    // ─────────────────────────────────────────────
    $display("\n========== 所有测试完成 ==========");
    #100;
    $finish;
end

// ─────────────────── 超时保护 ───────────────────────
initial begin
    #500000;
    $display("ERROR: 仿真超时");
    $finish;
end

// ─────────────────── 波形监控 ───────────────────────
// 监控关键信号变化（可选，信息量大时建议注释掉）
// initial begin
//     $monitor("[%0t] sa1_ctrl=%b cnt=%0d counter=%0d data_out=%0d",
//              $time, sa1_control, cnt, counter, $signed(data_out_ch));
// end

endmodule