`timescale 1ns / 1ps

module tb_SA_channel_2;

// ============================================================
// 端口信号声明
// ============================================================
reg                     clk;
reg                     rst_n;
reg  signed  [23:0]     data_in;
reg  signed  [71:0]     weight;
wire signed  [31:0]     data_out;
reg                     m_control_sa2;

// ============================================================
// 实例化被测模块
// ============================================================
SA_channel_2 uut (
    .clk            (clk),
    .rst_n          (rst_n),
    .data_in        (data_in),
    .weight         (weight),
    .data_out       (data_out),
    .m_control_sa2  (m_control_sa2)
);

// ============================================================
// 时钟生成：周期 10ns
// ============================================================
initial clk = 0;
always #5 clk = ~clk;

// ============================================================
// 卷积核权重（行优先，低位存第一个元素）
// weight = { w[8], w[7], ..., w[0] }，每个 8bit
// 排列：
//   w[0]=-8  w[1]=5   w[2]=-7
//   w[3]=22  w[4]=10  w[5]=-36
//   w[6]=37  w[7]=-5  w[8]=-12
// ============================================================
initial begin
    // 负数用补码十六进制表示，避免拼接中负号歧义
    // -12 -> 8'hF4, -5 -> 8'hFB, 37 -> 8'h25
    // -36 -> 8'hDC, 10 -> 8'h0A, 22 -> 8'h16
    // -7  -> 8'hF9,  5 -> 8'h05, -8 -> 8'hF8
    weight = {
        8'hF4,  // w[8] = -12  → bits[71:64]
        8'hFB,  // w[7] = -5   → bits[63:56]
        8'h25,  // w[6] = 37   → bits[55:48]
        8'hDC,  // w[5] = -36  → bits[47:40]
        8'h0A,  // w[4] = 10   → bits[39:32]
        8'h16,  // w[3] = 22   → bits[31:24]
        8'hF9,  // w[2] = -7   → bits[23:16]
        8'h05,  // w[1] = 5    → bits[15:8]
        8'hF8   // w[0] = -8   → bits[7:0]
    };
end

// ============================================================
// 输入数据：40 组，每组 3 个 8bit 有符号值
// data_in[7:0]   = col0
// data_in[15:8]  = col1
// data_in[23:16] = col2
// ============================================================
// 定义存储输入数据的数组
reg signed [7:0] input_data [0:39][0:2];

initial begin
    // row 0
    input_data[0][0]=28;  input_data[0][1]=91;  input_data[0][2]=78;
    input_data[1][0]=52;  input_data[1][1]=89;  input_data[1][2]=72;
    input_data[2][0]=53;  input_data[2][1]=108; input_data[2][2]=91;
    input_data[3][0]=43;  input_data[3][1]=88;  input_data[3][2]=84;
    input_data[4][0]=63;  input_data[4][1]=68;  input_data[4][2]=80;
    input_data[5][0]=69;  input_data[5][1]=61;  input_data[5][2]=70;
    input_data[6][0]=67;  input_data[6][1]=63;  input_data[6][2]=67;
    input_data[7][0]=52;  input_data[7][1]=67;  input_data[7][2]=84;
    input_data[8][0]=17;  input_data[8][1]=75;  input_data[8][2]=89;
    input_data[9][0]=0;   input_data[9][1]=66;  input_data[9][2]=90;
    input_data[10][0]=-5; input_data[10][1]=80; input_data[10][2]=110;
    input_data[11][0]=16; input_data[11][1]=73; input_data[11][2]=93;
    input_data[12][0]=23; input_data[12][1]=52; input_data[12][2]=75;
    input_data[13][0]=25; input_data[13][1]=52; input_data[13][2]=51;
    input_data[14][0]=17; input_data[14][1]=41; input_data[14][2]=84;
    input_data[15][0]=2;  input_data[15][1]=48; input_data[15][2]=103;
    input_data[16][0]=-23;input_data[16][1]=35; input_data[16][2]=83;
    input_data[17][0]=7;  input_data[17][1]=41; input_data[17][2]=101;
    input_data[18][0]=2;  input_data[18][1]=55; input_data[18][2]=94;
    input_data[19][0]=17; input_data[19][1]=57; input_data[19][2]=102;
    // row 20
    input_data[20][0]=57; input_data[20][1]=102;input_data[20][2]=87;
    input_data[21][0]=55; input_data[21][1]=94; input_data[21][2]=71;
    input_data[22][0]=41; input_data[22][1]=101;input_data[22][2]=73;
    input_data[23][0]=35; input_data[23][1]=83; input_data[23][2]=98;
    input_data[24][0]=48; input_data[24][1]=103;input_data[24][2]=100;
    input_data[25][0]=41; input_data[25][1]=84; input_data[25][2]=91;
    input_data[26][0]=52; input_data[26][1]=51; input_data[26][2]=81;
    input_data[27][0]=52; input_data[27][1]=75; input_data[27][2]=79;
    input_data[28][0]=73; input_data[28][1]=93; input_data[28][2]=79;
    input_data[29][0]=80; input_data[29][1]=110;input_data[29][2]=82;
    input_data[30][0]=66; input_data[30][1]=90; input_data[30][2]=74;
    input_data[31][0]=75; input_data[31][1]=89; input_data[31][2]=78;
    input_data[32][0]=67; input_data[32][1]=84; input_data[32][2]=77;
    input_data[33][0]=63; input_data[33][1]=67; input_data[33][2]=87;
    input_data[34][0]=61; input_data[34][1]=70; input_data[34][2]=84;
    input_data[35][0]=68; input_data[35][1]=80; input_data[35][2]=76;
    input_data[36][0]=88; input_data[36][1]=84; input_data[36][2]=59;
    input_data[37][0]=108;input_data[37][1]=91; input_data[37][2]=47;
    input_data[38][0]=89; input_data[38][1]=72; input_data[38][2]=39;
    input_data[39][0]=91; input_data[39][1]=78; input_data[39][2]=63;
end

// ============================================================
// 激励主流程
// ============================================================
integer k;

initial begin
    // 初始化
    rst_n        = 0;
    data_in      = 24'sd0;
    m_control_sa2 = 0;

    // 复位两个周期
    @(posedge clk); #1;
    @(posedge clk); #1;
    rst_n = 1;
    @(posedge clk); #1;  // 等待复位生效

    // 逐周期送入 40 组数据
    for (k = 0; k < 40; k = k + 1) begin
        @(posedge clk); #1;
        // 前 20 组 m_control=0（下滑），后 20 组 m_control=1（上滑）
        m_control_sa2 = (k < 20) ? 1'b0 : 1'b1;
        // 打包三列数据到 data_in
        data_in = {input_data[k][2], input_data[k][1], input_data[k][0]};
    end

    // 等待流水线排空（加法树深度约 5 级）
    repeat (10) @(posedge clk);

    $display("Simulation finished.");
    $finish;
end

// ============================================================
// 结果打印：每个时钟上升沿打印输出
// ============================================================
integer cycle_cnt;
initial cycle_cnt = 0;

always @(posedge clk) begin
    if (rst_n) begin
        cycle_cnt <= cycle_cnt + 1;
        $display("Cycle %0d | m_ctrl=%b | data_in=[%0d,%0d,%0d] | data_out=%0d (0x%08h)",
            cycle_cnt,
            m_control_sa2,
            $signed(data_in[7:0]),
            $signed(data_in[15:8]),
            $signed(data_in[23:16]),
            $signed(data_out),
            data_out
        );
    end
end

// ============================================================
// 可选：波形转储
// ============================================================
/*initial begin
    $dumpfile("tb_SA_channel_2.vcd");
    $dumpvars(0, tb_SA_channel_2);
end
*/
endmodule