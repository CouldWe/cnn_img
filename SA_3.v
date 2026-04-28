`timescale 1ns / 1ps
module SA_3(
    input  wire                           clk,
    input  wire                           rst_n,
    input  wire signed [31:0]             data_in,     // 4ch x 8bit
    input  wire signed [32*4*8-1:0]       weight,      // 32 outputs, each with 4x8bit weights
    input  wire        [2:0]              counter,     // current 4-channel group index: 0~7
    output wire signed [1023:0]           data_out
);

localparam integer OUT_CH   = 32;

wire signed [31:0] partial_sum [0:OUT_CH-1];
genvar  k;

// 32-way parallel partial dot products (4 channels each cycle)
generate
for(k = 0; k < OUT_CH; k = k + 1) begin: array_loop
    SA_channel_3 channel(
        .clk      (clk),
        .rst_n    (rst_n),
        .data_in  (data_in),
        .data_out (partial_sum[k]),
        .weight   (weight[4*8*k + 4*8-1 : 4*8*k])
    );
    assign data_out[32*k + 31 : 32*k] = partial_sum[k];
end
endgenerate

endmodule
