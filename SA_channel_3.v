`timescale 1ns / 1ps
module SA_channel_3(
    input  wire                           clk,
    input  wire                           rst_n,
    input  wire signed [31:0]             data_in,  // 4ch x 8bit
    input  wire signed [4*8-1:0]          weight,   // 4 x 8bit
    output wire signed [31:0]             data_out
);

wire signed [31:0] mul0;
wire signed [31:0] mul1;
wire signed [31:0] mul2;
wire signed [31:0] mul3;

wire signed [31:0] mul_reg [0:3];
wire signed [31:0] sum_reg [0:1];
wire signed [31:0] sum0;
wire signed [31:0] sum1;

assign mul0 = $signed(data_in[0*8+7:0*8]) * $signed(weight[0*8+7:0*8]);
assign mul1 = $signed(data_in[1*8+7:1*8]) * $signed(weight[1*8+7:1*8]);
assign mul2 = $signed(data_in[2*8+7:2*8]) * $signed(weight[2*8+7:2*8]);
assign mul3 = $signed(data_in[3*8+7:3*8]) * $signed(weight[3*8+7:3*8]);

// pipeline stage 1: register four products
FF_32 treeBuffer0_0(.clk(clk), .rst_n(rst_n), .data_in(mul0), .data_out(mul_reg[0]));
FF_32 treeBuffer0_1(.clk(clk), .rst_n(rst_n), .data_in(mul1), .data_out(mul_reg[1]));
FF_32 treeBuffer0_2(.clk(clk), .rst_n(rst_n), .data_in(mul2), .data_out(mul_reg[2]));
FF_32 treeBuffer0_3(.clk(clk), .rst_n(rst_n), .data_in(mul3), .data_out(mul_reg[3]));

assign sum0 = $signed(mul_reg[0]) + $signed(mul_reg[1]);
assign sum1 = $signed(mul_reg[2]) + $signed(mul_reg[3]);

// pipeline stage 2: register pair sums
FF_32 treeBuffer1(.clk(clk), .rst_n(rst_n), .data_in(sum0), .data_out(sum_reg[0]));
FF_32 treeBuffer2(.clk(clk), .rst_n(rst_n), .data_in(sum1), .data_out(sum_reg[1]));

assign data_out = $signed(sum_reg[0]) + $signed(sum_reg[1]);

endmodule
