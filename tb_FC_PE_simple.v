`timescale 1ns / 1ps

module tb_FC_PE_simple;

reg clk;
reg rst_n;
reg enable;
reg signed [7:0] data_in;
reg signed [143:0] weight;

wire signed [31:0] temp_out_0;
wire signed [31:0] temp_out_1;

// Instantiate FC_PE
FC_PE uut (
    .clk(clk),
    .rst_n(rst_n),
    .enable(enable),
    .data_in(data_in),
    .weight(weight),
    .temp_out_0(temp_out_0),
    .temp_out_1(temp_out_1)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// Test data for channel 0
reg signed [7:0] data_array [0:8];
reg signed [7:0] weight_array [0:17];

integer i;

initial begin
    // Channel 0 data
    data_array[0] = 32;
    data_array[1] = 55;
    data_array[2] = 61;
    data_array[3] = 53;
    data_array[4] = 72;
    data_array[5] = 77;
    data_array[6] = 59;
    data_array[7] = 42;
    data_array[8] = 41;

    // Channel 0 weights
    weight_array[0] = 10;   weight_array[1] = 19;
    weight_array[2] = -27;  weight_array[3] = -7;
    weight_array[4] = 47;   weight_array[5] = -50;
    weight_array[6] = 15;   weight_array[7] = -23;
    weight_array[8] = -4;   weight_array[9] = 4;
    weight_array[10] = -37; weight_array[11] = 0;
    weight_array[12] = 38;  weight_array[13] = -2;
    weight_array[14] = -19; weight_array[15] = 0;
    weight_array[16] = 14;  weight_array[17] = -43;

    // Pack weights
    for (i = 0; i < 18; i = i + 1) begin
        weight[i*8 +: 8] = weight_array[i];
    end

    // Initialize
    rst_n = 0;
    enable = 0;
    data_in = 0;

    $display("========================================");
    $display("FC_PE Simple Testbench");
    $display("========================================");

    #20;
    rst_n = 1;
    #10;
    enable = 1;

    // Feed 9 time steps, each held for 2 cycles
    for (i = 0; i < 9; i = i + 1) begin
        data_in = data_array[i];
        #20;  // Hold for 2 clock cycles
    end

    // Wait a bit more
    #50;

    $display("========================================");
    $display("Final Results:");
    $display("temp_out_0 (Kernel 0) = %d (expected: 1378)", $signed(temp_out_0));
    $display("temp_out_1 (Kernel 1) = %d (expected: -5639)", $signed(temp_out_1));
    $display("========================================");

    $finish;
end

// Monitor
always @(posedge clk) begin
    if (enable && rst_n) begin
        $display("Time=%0t | cnt=%0d | data_in=%0d | temp_out_0=%0d | temp_out_1=%0d",
                 $time, uut.cnt, $signed(data_in), $signed(temp_out_0), $signed(temp_out_1));
    end
end

endmodule
