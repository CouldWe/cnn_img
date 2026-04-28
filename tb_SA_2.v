`timescale 1ns / 1ps

module tb_SA_2;

// ============================================================
// 端口信号声明
// ============================================================
reg                         clk;
reg                         rst_n;
reg  signed [4*3*8-1:0]     data_in;    // 4通道 * 3列 * 8bit
reg  signed [4*9*8-1:0]     weight;     // 4通道 * 9个权重 * 8bit
wire signed [4*32-1:0]      data_out;   // 4通道 * 32bit
reg  [5:0]                  buffer1_addr;

// ============================================================
// Bias 和量化相关信号
// ============================================================
parameter signed [15:0] BIAS_CH1 = 16'd1009;
parameter signed [15:0] BIAS_CH2 = -16'd1164;
parameter signed [15:0] BIAS_CH3 = -16'd788;
parameter signed [15:0] BIAS_CH4 = 16'd1016;

wire signed [31:0] after_bias [3:0];      // 4个通道加bias后的结果
reg  signed [31:0] quantBuffer [3:0];     // 4个通道的量化输入缓冲
wire signed [7:0]  after_quant [3:0];     // 4个通道量化后的结果

// ============================================================
// 实例化被测模块
// ============================================================
SA_2 uut (
    .clk            (clk),
    .rst_n          (rst_n),
    .data_in        (data_in),
    .weight         (weight),
    .data_out       (data_out),
    .buffer1_addr   (buffer1_addr)
);

// ============================================================
// 后处理：偏置、重量化（4个通道）
// ============================================================
// 通道1：加bias
assign after_bias[0] = $signed(data_out[31:0]) + $signed(BIAS_CH1);
// 通道2：加bias
assign after_bias[1] = $signed(data_out[63:32]) + $signed(BIAS_CH2);
// 通道3：加bias
assign after_bias[2] = $signed(data_out[95:64]) + $signed(BIAS_CH3);
// 通道4：加bias
assign after_bias[3] = $signed(data_out[127:96]) + $signed(BIAS_CH4);

// bias后的结果打一拍
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        quantBuffer[0] <= 32'd0;
        quantBuffer[1] <= 32'd0;
        quantBuffer[2] <= 32'd0;
        quantBuffer[3] <= 32'd0;
    end else begin
        quantBuffer[0] <= after_bias[0];
        quantBuffer[1] <= after_bias[1];
        quantBuffer[2] <= after_bias[2];
        quantBuffer[3] <= after_bias[3];
    end
end

// 量化模块（4个通道）
rescale_dwconv quant_ch1 (
    .clk        (clk),
    .rst_n      (rst_n),
    .data_in    (quantBuffer[0]),
    .data_out   (after_quant[0])
);

rescale_dwconv quant_ch2 (
    .clk        (clk),
    .rst_n      (rst_n),
    .data_in    (quantBuffer[1]),
    .data_out   (after_quant[1])
);

rescale_dwconv quant_ch3 (
    .clk        (clk),
    .rst_n      (rst_n),
    .data_in    (quantBuffer[2]),
    .data_out   (after_quant[2])
);

rescale_dwconv quant_ch4 (
    .clk        (clk),
    .rst_n      (rst_n),
    .data_in    (quantBuffer[3]),
    .data_out   (after_quant[3])
);

// ============================================================
// 时钟生成：周期 10ns
// ============================================================
initial clk = 0;
always #5 clk = ~clk;

// ============================================================
// 权重初始化（4个通道，每个通道9个8bit权重）
// ============================================================
initial begin
    // 通道1权重：-8,5,-7,22,10,-36,37,-5,-12
    // 通道2权重：7,24,25,0,12,6,18,13,-13
    // 通道3权重：5,-7,-12,12,8,5,12,6,-3
    // 通道4权重：-6,-5,51,-22,-20,-10,-4,14,-2
    weight = {
        // 通道4 (bits[287:216])
        8'hFE,  // -2
        8'h0E,  // 14
        8'hFC,  // -4
        8'hF6,  // -10
        8'hEC,  // -20
        8'hEA,  // -22
        8'h33,  // 51
        8'hFB,  // -5
        8'hFA,  // -6
        // 通道3 (bits[215:144])
        8'hFD,  // -3
        8'h06,  // 6
        8'h0C,  // 12
        8'h05,  // 5
        8'h08,  // 8
        8'h0C,  // 12
        8'hF4,  // -12
        8'hF9,  // -7
        8'h05,  // 5
        // 通道2 (bits[143:72])
        8'hF3,  // -13
        8'h0D,  // 13
        8'h12,  // 18
        8'h06,  // 6
        8'h0C,  // 12
        8'h00,  // 0
        8'h19,  // 25
        8'h18,  // 24
        8'h07,   // 7
        // 通道1 (bits[71:0])
        8'hF4,  // -12
        8'hFB,  // -5
        8'h25,  // 37
        8'hDC,  // -36
        8'h0A,  // 10
        8'h16,  // 22
        8'hF9,  // -7
        8'h05,  // 5
        8'hF8  // -8
    };
end

// ============================================================
// 输入数据：40组，每组4通道，每通道3个8bit值
// ============================================================
reg signed [7:0] input_ch1 [0:39][0:2];
reg signed [7:0] input_ch2 [0:39][0:2];
reg signed [7:0] input_ch3 [0:39][0:2];
reg signed [7:0] input_ch4 [0:39][0:2];

initial begin
    // 通道1数据
    input_ch1[0][0]=28;   input_ch1[0][1]=91;   input_ch1[0][2]=78;
    input_ch1[1][0]=52;   input_ch1[1][1]=89;   input_ch1[1][2]=72;
    input_ch1[2][0]=53;   input_ch1[2][1]=108;  input_ch1[2][2]=91;
    input_ch1[3][0]=43;   input_ch1[3][1]=88;   input_ch1[3][2]=84;
    input_ch1[4][0]=63;   input_ch1[4][1]=68;   input_ch1[4][2]=80;
    input_ch1[5][0]=69;   input_ch1[5][1]=61;   input_ch1[5][2]=70;
    input_ch1[6][0]=67;   input_ch1[6][1]=63;   input_ch1[6][2]=67;
    input_ch1[7][0]=52;   input_ch1[7][1]=67;   input_ch1[7][2]=84;
    input_ch1[8][0]=17;   input_ch1[8][1]=75;   input_ch1[8][2]=89;
    input_ch1[9][0]=0;    input_ch1[9][1]=66;   input_ch1[9][2]=90;
    input_ch1[10][0]=-5;  input_ch1[10][1]=80;  input_ch1[10][2]=110;
    input_ch1[11][0]=16;  input_ch1[11][1]=73;  input_ch1[11][2]=93;
    input_ch1[12][0]=23;  input_ch1[12][1]=52;  input_ch1[12][2]=75;
    input_ch1[13][0]=25;  input_ch1[13][1]=52;  input_ch1[13][2]=51;
    input_ch1[14][0]=17;  input_ch1[14][1]=41;  input_ch1[14][2]=84;
    input_ch1[15][0]=2;   input_ch1[15][1]=48;  input_ch1[15][2]=103;
    input_ch1[16][0]=-23; input_ch1[16][1]=35;  input_ch1[16][2]=83;
    input_ch1[17][0]=7;   input_ch1[17][1]=41;  input_ch1[17][2]=101;
    input_ch1[18][0]=2;   input_ch1[18][1]=55;  input_ch1[18][2]=94;
    input_ch1[19][0]=17;  input_ch1[19][1]=57;  input_ch1[19][2]=102;
    input_ch1[20][0]=57;  input_ch1[20][1]=102; input_ch1[20][2]=87;
    input_ch1[21][0]=55;  input_ch1[21][1]=94;  input_ch1[21][2]=71;
    input_ch1[22][0]=41;  input_ch1[22][1]=101; input_ch1[22][2]=73;
    input_ch1[23][0]=35;  input_ch1[23][1]=83;  input_ch1[23][2]=98;
    input_ch1[24][0]=48;  input_ch1[24][1]=103; input_ch1[24][2]=100;
    input_ch1[25][0]=41;  input_ch1[25][1]=84;  input_ch1[25][2]=91;
    input_ch1[26][0]=52;  input_ch1[26][1]=51;  input_ch1[26][2]=81;
    input_ch1[27][0]=52;  input_ch1[27][1]=75;  input_ch1[27][2]=79;
    input_ch1[28][0]=73;  input_ch1[28][1]=93;  input_ch1[28][2]=79;
    input_ch1[29][0]=80;  input_ch1[29][1]=110; input_ch1[29][2]=82;
    input_ch1[30][0]=66;  input_ch1[30][1]=90;  input_ch1[30][2]=74;
    input_ch1[31][0]=75;  input_ch1[31][1]=89;  input_ch1[31][2]=78;
    input_ch1[32][0]=67;  input_ch1[32][1]=84;  input_ch1[32][2]=77;
    input_ch1[33][0]=63;  input_ch1[33][1]=67;  input_ch1[33][2]=87;
    input_ch1[34][0]=61;  input_ch1[34][1]=70;  input_ch1[34][2]=84;
    input_ch1[35][0]=68;  input_ch1[35][1]=80;  input_ch1[35][2]=76;
    input_ch1[36][0]=88;  input_ch1[36][1]=84;  input_ch1[36][2]=59;
    input_ch1[37][0]=108; input_ch1[37][1]=91;  input_ch1[37][2]=47;
    input_ch1[38][0]=89;  input_ch1[38][1]=72;  input_ch1[38][2]=39;
    input_ch1[39][0]=91;  input_ch1[39][1]=78;  input_ch1[39][2]=63;

    // 通道2数据
    input_ch2[0][0]=91;   input_ch2[0][1]=-23;  input_ch2[0][2]=-93;
    input_ch2[1][0]=93;   input_ch2[1][1]=-22;  input_ch2[1][2]=-87;
    input_ch2[2][0]=105;  input_ch2[2][1]=-24;  input_ch2[2][2]=-96;
    input_ch2[3][0]=113;  input_ch2[3][1]=-24;  input_ch2[3][2]=-102;
    input_ch2[4][0]=113;  input_ch2[4][1]=-26;  input_ch2[4][2]=-109;
    input_ch2[5][0]=113;  input_ch2[5][1]=-12;  input_ch2[5][2]=-105;
    input_ch2[6][0]=108;  input_ch2[6][1]=-2;   input_ch2[6][2]=-92;
    input_ch2[7][0]=113;  input_ch2[7][1]=6;    input_ch2[7][2]=-83;
    input_ch2[8][0]=111;  input_ch2[8][1]=7;    input_ch2[8][2]=-77;
    input_ch2[9][0]=115;  input_ch2[9][1]=9;    input_ch2[9][2]=-70;
    input_ch2[10][0]=112; input_ch2[10][1]=9;   input_ch2[10][2]=-75;
    input_ch2[11][0]=88;  input_ch2[11][1]=6;   input_ch2[11][2]=-67;
    input_ch2[12][0]=74;  input_ch2[12][1]=7;   input_ch2[12][2]=-61;
    input_ch2[13][0]=81;  input_ch2[13][1]=17;  input_ch2[13][2]=-63;
    input_ch2[14][0]=88;  input_ch2[14][1]=12;  input_ch2[14][2]=-72;
    input_ch2[15][0]=102; input_ch2[15][1]=-4;  input_ch2[15][2]=-93;
    input_ch2[16][0]=105; input_ch2[16][1]=-18; input_ch2[16][2]=-102;
    input_ch2[17][0]=95;  input_ch2[17][1]=-23; input_ch2[17][2]=-93;
    input_ch2[18][0]=90;  input_ch2[18][1]=-23; input_ch2[18][2]=-80;
    input_ch2[19][0]=95;  input_ch2[19][1]=-19; input_ch2[19][2]=-67;
    input_ch2[20][0]=-19; input_ch2[20][1]=-67; input_ch2[20][2]=-72;
    input_ch2[21][0]=-23; input_ch2[21][1]=-80; input_ch2[21][2]=-69;
    input_ch2[22][0]=-23; input_ch2[22][1]=-93; input_ch2[22][2]=-67;
    input_ch2[23][0]=-18; input_ch2[23][1]=-102;input_ch2[23][2]=-71;
    input_ch2[24][0]=-4;  input_ch2[24][1]=-93; input_ch2[24][2]=-72;
    input_ch2[25][0]=12;  input_ch2[25][1]=-72; input_ch2[25][2]=-69;
    input_ch2[26][0]=17;  input_ch2[26][1]=-63; input_ch2[26][2]=-77;
    input_ch2[27][0]=7;   input_ch2[27][1]=-61; input_ch2[27][2]=-83;
    input_ch2[28][0]=6;   input_ch2[28][1]=-67; input_ch2[28][2]=-89;
    input_ch2[29][0]=9;   input_ch2[29][1]=-75; input_ch2[29][2]=-95;
    input_ch2[30][0]=9;   input_ch2[30][1]=-70; input_ch2[30][2]=-83;
    input_ch2[31][0]=7;   input_ch2[31][1]=-77; input_ch2[31][2]=-87;
    input_ch2[32][0]=6;   input_ch2[32][1]=-83; input_ch2[32][2]=-84;
    input_ch2[33][0]=-2;  input_ch2[33][1]=-92; input_ch2[33][2]=-94;
    input_ch2[34][0]=-12; input_ch2[34][1]=-105;input_ch2[34][2]=-101;
    input_ch2[35][0]=-26; input_ch2[35][1]=-109;input_ch2[35][2]=-97;
    input_ch2[36][0]=-24; input_ch2[36][1]=-102;input_ch2[36][2]=-91;
    input_ch2[37][0]=-24; input_ch2[37][1]=-96; input_ch2[37][2]=-79;
    input_ch2[38][0]=-22; input_ch2[38][1]=-87; input_ch2[38][2]=-72;
    input_ch2[39][0]=-23; input_ch2[39][1]=-93; input_ch2[39][2]=-72;

    // 通道3数据
    input_ch3[0][0]=127;  input_ch3[0][1]=36;   input_ch3[0][2]=-66;
    input_ch3[1][0]=127;  input_ch3[1][1]=39;   input_ch3[1][2]=-59;
    input_ch3[2][0]=127;  input_ch3[2][1]=43;   input_ch3[2][2]=-64;
    input_ch3[3][0]=127;  input_ch3[3][1]=39;   input_ch3[3][2]=-75;
    input_ch3[4][0]=127;  input_ch3[4][1]=48;   input_ch3[4][2]=-86;
    input_ch3[5][0]=127;  input_ch3[5][1]=51;   input_ch3[5][2]=-83;
    input_ch3[6][0]=127;  input_ch3[6][1]=60;   input_ch3[6][2]=-76;
    input_ch3[7][0]=127;  input_ch3[7][1]=54;   input_ch3[7][2]=-71;
    input_ch3[8][0]=127;  input_ch3[8][1]=41;   input_ch3[8][2]=-60;
    input_ch3[9][0]=127;  input_ch3[9][1]=42;   input_ch3[9][2]=-64;
    input_ch3[10][0]=127; input_ch3[10][1]=57;  input_ch3[10][2]=-66;
    input_ch3[11][0]=127; input_ch3[11][1]=53;  input_ch3[11][2]=-72;
    input_ch3[12][0]=127; input_ch3[12][1]=54;  input_ch3[12][2]=-63;
    input_ch3[13][0]=127; input_ch3[13][1]=67;  input_ch3[13][2]=-68;
    input_ch3[14][0]=127; input_ch3[14][1]=44;  input_ch3[14][2]=-66;
    input_ch3[15][0]=127; input_ch3[15][1]=27;  input_ch3[15][2]=-63;
    input_ch3[16][0]=127; input_ch3[16][1]=15;  input_ch3[16][2]=-43;
    input_ch3[17][0]=127; input_ch3[17][1]=10;  input_ch3[17][2]=-58;
    input_ch3[18][0]=127; input_ch3[18][1]=24;  input_ch3[18][2]=-48;
    input_ch3[19][0]=127; input_ch3[19][1]=18;  input_ch3[19][2]=-31;
    input_ch3[20][0]=18;  input_ch3[20][1]=-31; input_ch3[20][2]=-59;
    input_ch3[21][0]=24;  input_ch3[21][1]=-48; input_ch3[21][2]=-53;
    input_ch3[22][0]=10;  input_ch3[22][1]=-58; input_ch3[22][2]=-57;
    input_ch3[23][0]=15;  input_ch3[23][1]=-43; input_ch3[23][2]=-46;
    input_ch3[24][0]=27;  input_ch3[24][1]=-63; input_ch3[24][2]=-55;
    input_ch3[25][0]=44;  input_ch3[25][1]=-66; input_ch3[25][2]=-53;
    input_ch3[26][0]=67;  input_ch3[26][1]=-68; input_ch3[26][2]=-66;
    input_ch3[27][0]=54;  input_ch3[27][1]=-63; input_ch3[27][2]=-75;
    input_ch3[28][0]=53;  input_ch3[28][1]=-72; input_ch3[28][2]=-73;
    input_ch3[29][0]=57;  input_ch3[29][1]=-66; input_ch3[29][2]=-67;
    input_ch3[30][0]=42;  input_ch3[30][1]=-64; input_ch3[30][2]=-82;
    input_ch3[31][0]=41;  input_ch3[31][1]=-60; input_ch3[31][2]=-84;
    input_ch3[32][0]=54;  input_ch3[32][1]=-71; input_ch3[32][2]=-91;
    input_ch3[33][0]=60;  input_ch3[33][1]=-76; input_ch3[33][2]=-87;
    input_ch3[34][0]=51;  input_ch3[34][1]=-83; input_ch3[34][2]=-74;
    input_ch3[35][0]=48;  input_ch3[35][1]=-86; input_ch3[35][2]=-71;
    input_ch3[36][0]=39;  input_ch3[36][1]=-75; input_ch3[36][2]=-70;
    input_ch3[37][0]=43;  input_ch3[37][1]=-64; input_ch3[37][2]=-66;
    input_ch3[38][0]=39;  input_ch3[38][1]=-59; input_ch3[38][2]=-66;
    input_ch3[39][0]=36;  input_ch3[39][1]=-66; input_ch3[39][2]=-67;

    // 通道4数据
    input_ch4[0][0]=101;  input_ch4[0][1]=-19;  input_ch4[0][2]=-115;
    input_ch4[1][0]=107;  input_ch4[1][1]=-1;   input_ch4[1][2]=-106;
    input_ch4[2][0]=104;  input_ch4[2][1]=10;   input_ch4[2][2]=-109;
    input_ch4[3][0]=127;  input_ch4[3][1]=22;   input_ch4[3][2]=-106;
    input_ch4[4][0]=127;  input_ch4[4][1]=22;   input_ch4[4][2]=-113;
    input_ch4[5][0]=127;  input_ch4[5][1]=16;   input_ch4[5][2]=-112;
    input_ch4[6][0]=123;  input_ch4[6][1]=24;   input_ch4[6][2]=-100;
    input_ch4[7][0]=114;  input_ch4[7][1]=6;    input_ch4[7][2]=-99;
    input_ch4[8][0]=97;   input_ch4[8][1]=-9;   input_ch4[8][2]=-93;
    input_ch4[9][0]=97;   input_ch4[9][1]=-8;   input_ch4[9][2]=-94;
    input_ch4[10][0]=110; input_ch4[10][1]=-4;  input_ch4[10][2]=-115;
    input_ch4[11][0]=122; input_ch4[11][1]=7;   input_ch4[11][2]=-126;
    input_ch4[12][0]=117; input_ch4[12][1]=2;   input_ch4[12][2]=-125;
    input_ch4[13][0]=104; input_ch4[13][1]=-18; input_ch4[13][2]=-123;
    input_ch4[14][0]=106; input_ch4[14][1]=-29; input_ch4[14][2]=-119;
    input_ch4[15][0]=98;  input_ch4[15][1]=-20; input_ch4[15][2]=-107;
    input_ch4[16][0]=124; input_ch4[16][1]=-4;  input_ch4[16][2]=-83;
    input_ch4[17][0]=126; input_ch4[17][1]=-15; input_ch4[17][2]=-93;
    input_ch4[18][0]=123; input_ch4[18][1]=-10; input_ch4[18][2]=-84;
    input_ch4[19][0]=102; input_ch4[19][1]=8;   input_ch4[19][2]=-76;
    input_ch4[20][0]=8;   input_ch4[20][1]=-76; input_ch4[20][2]=-44;
    input_ch4[21][0]=-10; input_ch4[21][1]=-84; input_ch4[21][2]=-41;
    input_ch4[22][0]=-15; input_ch4[22][1]=-93; input_ch4[22][2]=-48;
    input_ch4[23][0]=-4;  input_ch4[23][1]=-83; input_ch4[23][2]=-41;
    input_ch4[24][0]=-20; input_ch4[24][1]=-107;input_ch4[24][2]=-46;
    input_ch4[25][0]=-29; input_ch4[25][1]=-119;input_ch4[25][2]=-50;
    input_ch4[26][0]=-18; input_ch4[26][1]=-123;input_ch4[26][2]=-66;
    input_ch4[27][0]=2;   input_ch4[27][1]=-125;input_ch4[27][2]=-66;
    input_ch4[28][0]=7;   input_ch4[28][1]=-126;input_ch4[28][2]=-70;
    input_ch4[29][0]=-4;  input_ch4[29][1]=-115;input_ch4[29][2]=-73;
    input_ch4[30][0]=-8;  input_ch4[30][1]=-94; input_ch4[30][2]=-58;
    input_ch4[31][0]=-9;  input_ch4[31][1]=-93; input_ch4[31][2]=-65;
    input_ch4[32][0]=6;   input_ch4[32][1]=-99; input_ch4[32][2]=-67;
    input_ch4[33][0]=24;  input_ch4[33][1]=-100;input_ch4[33][2]=-73;
    input_ch4[34][0]=16;  input_ch4[34][1]=-112;input_ch4[34][2]=-71;
    input_ch4[35][0]=22;  input_ch4[35][1]=-113;input_ch4[35][2]=-71;
    input_ch4[36][0]=22;  input_ch4[36][1]=-106;input_ch4[36][2]=-78;
    input_ch4[37][0]=10;  input_ch4[37][1]=-109;input_ch4[37][2]=-85;
    input_ch4[38][0]=-1;  input_ch4[38][1]=-106;input_ch4[38][2]=-89;
    input_ch4[39][0]=-19; input_ch4[39][1]=-115;input_ch4[39][2]=-90;
end

// ============================================================
// 激励主流程
// ============================================================
integer k;

initial begin
    // 初始化
    rst_n        = 0;
    data_in      = 96'd0;
    buffer1_addr = 6'd0;

    // 复位两个周期
    @(posedge clk); #1;
    @(posedge clk); #1;
    rst_n = 1;

    // 逐周期送入40组数据
    for (k = 0; k < 40; k = k + 1) begin
        @(posedge clk); #1;
        buffer1_addr = k;
        // 打包4个通道的数据到data_in
        // data_in格式：{ch4_col2, ch4_col1, ch4_col0, ch3_col2, ch3_col1, ch3_col0, ch2_col2, ch2_col1, ch2_col0, ch1_col2, ch1_col1, ch1_col0}
        // data_in = {
        //     input_ch4[k][2], input_ch4[k][1], input_ch4[k][0],
        //     input_ch3[k][2], input_ch3[k][1], input_ch3[k][0],
        //     input_ch2[k][2], input_ch2[k][1], input_ch2[k][0],
        //     input_ch1[k][2], input_ch1[k][1], input_ch1[k][0]
        // };
        data_in = {
            input_ch4[k][2],input_ch3[k][2], input_ch2[k][2], input_ch1[k][2],
            input_ch4[k][1],input_ch3[k][1], input_ch2[k][1], input_ch1[k][1],
            input_ch4[k][0],input_ch3[k][0], input_ch2[k][0], input_ch1[k][0]
        };
    end

    // 等待流水线排空
    repeat (15) @(posedge clk);

    $display("Simulation finished.");
    $finish;
end

// ============================================================
// 结果打印
// ============================================================
integer cycle_cnt;
initial cycle_cnt = 0;

always @(posedge clk) begin
    if (rst_n) begin
        cycle_cnt <= cycle_cnt + 1;
        $display("Cycle %0d | addr=%0d", cycle_cnt, buffer1_addr);
        $display("  data_out    = [%0d, %0d, %0d, %0d]",
            $signed(data_out[31:0]),
            $signed(data_out[63:32]),
            $signed(data_out[95:64]),
            $signed(data_out[127:96])
        );
        $display("  after_bias  = [%0d, %0d, %0d, %0d]",
            $signed(after_bias[0]),
            $signed(after_bias[1]),
            $signed(after_bias[2]),
            $signed(after_bias[3])
        );
        $display("  quantBuffer = [%0d, %0d, %0d, %0d]",
            $signed(quantBuffer[0]),
            $signed(quantBuffer[1]),
            $signed(quantBuffer[2]),
            $signed(quantBuffer[3])
        );
        $display("  after_quant = [%0d, %0d, %0d, %0d]",
            $signed(after_quant[0]),
            $signed(after_quant[1]),
            $signed(after_quant[2]),
            $signed(after_quant[3])
        );
    end
end

// ============================================================
// 波形转储
// ============================================================
// initial begin
//     $dumpfile("tb_SA_2.vcd");
//     $dumpvars(0, tb_SA_2);
// end

endmodule
