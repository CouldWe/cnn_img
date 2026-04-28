`timescale 1ns / 1ps

module tb_maxpool;

// 信号定义
reg clk;
reg enable;
reg rst_n;
reg [15:0] data_in;
wire [7:0] data_max;

// 实例化被测模块
maxpool uut (
    .clk(clk),
    .enable(enable),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_max(data_max)
);

// 时钟生成：周期为10ns
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// 测试数据数组（18组，每组2个8bit数据）
reg signed [7:0] test_data [0:35];
integer i;

initial begin
    // 初始化测试数据
    test_data[0]  = 8'sd23;  test_data[1]  = -8'sd42;
    test_data[2]  = 8'sd32;  test_data[3]  = -8'sd51;
    test_data[4]  = 8'sd43;  test_data[5]  = -8'sd39;
    test_data[6]  = 8'sd55;  test_data[7]  = -8'sd20;
    test_data[8]  = 8'sd61;  test_data[9]  = -8'sd28;
    test_data[10] = 8'sd59;  test_data[11] = -8'sd19;
    test_data[12] = 8'sd45;  test_data[13] = -8'sd9;
    test_data[14] = 8'sd53;  test_data[15] = -8'sd12;
    test_data[16] = 8'sd66;  test_data[17] = -8'sd7;
    test_data[18] = 8'sd72;  test_data[19] = -8'sd18;
    test_data[20] = 8'sd60;  test_data[21] = -8'sd4;
    test_data[22] = 8'sd77;  test_data[23] = 8'sd18;
    test_data[24] = 8'sd59;  test_data[25] = 8'sd15;
    test_data[26] = 8'sd49;  test_data[27] = 8'sd41;
    test_data[28] = 8'sd39;  test_data[29] = 8'sd32;
    test_data[30] = 8'sd42;  test_data[31] = 8'sd17;
    test_data[32] = 8'sd40;  test_data[33] = 8'sd6;
    test_data[34] = 8'sd41;  test_data[35] = 8'sd1;

    // 初始化信号
    rst_n = 0;
    enable = 0;
    data_in = 16'b0;

    // 复位
    #20;
    rst_n = 1;
    #10;

    // 使能maxpool
    enable = 1;

    // 输入测试数据
    for (i = 0; i < 18; i = i + 1) begin
        data_in = {test_data[i*2], test_data[i*2+1]};
        #10; // 等待一个时钟周期
    end

    // 等待最后的输出
    #20;

    $display("test completed.");
    $finish;
end

// 监控输出
integer output_count;
initial begin
    output_count = 0;
    $display("time\t\tinput\t\t\tmax_output");
    $display("------------------------------------------------------------");
end

always @(posedge clk) begin
    if (enable && rst_n) begin
        $display("%0t\tdata_in[15:8]=%0d, data_in[7:0]=%0d\tdata_max=%0d",
                 $time, $signed(data_in[15:8]), $signed(data_in[7:0]), data_max);
    end
end

// 验证输出结果
reg [7:0] expected_results [0:8];
integer result_index;

initial begin
    // 预期的9个输出结果
    expected_results[0] = 8'd32;  // max(23, -42, 32, -51) = 32
    expected_results[1] = 8'd55;  // max(43, -39, 55, -20) = 55
    expected_results[2] = 8'd61;  // max(61, -28, 59, -19) = 61
    expected_results[3] = 8'd53;  // max(45, -9, 53, -12) = 53
    expected_results[4] = 8'd72;  // max(66, -7, 72, -18) = 72
    expected_results[5] = 8'd77;  // max(60, -4, 77, 18) = 77
    expected_results[6] = 8'd59;  // max(59, 15, 49, 41) = 59
    expected_results[7] = 8'd42;  // max(39, 32, 42, 17) = 42
    expected_results[8] = 8'd41;  // max(40, 6, 41, 1) = 41

    result_index = 0;

    // 等待复位和使能
    wait(rst_n && enable);

    // 每两个时钟周期检查一次输出
    repeat(9) begin
        @(posedge clk);
        @(posedge clk);
        #1; // 等待输出稳定
        if (data_max === expected_results[result_index]) begin
            $display("✓ No %0d: expected=%0d, actual=%0d - success",
                     result_index+1, expected_results[result_index], data_max);
        end else begin
            $display("✗ No %0d: expected=%0d, actual=%0d - failure",
                     result_index+1, expected_results[result_index], data_max);
        end
        result_index = result_index + 1;
    end
end

// 生成波形文件
// initial begin
//     $dumpfile("maxpool_tb.vcd");
//     $dumpvars(0, maxpool_tb);
// end

endmodule
