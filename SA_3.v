`timescale 1ns / 1ps
module SA_3(
    input  wire                           clk,
    input  wire                           rst_n,
    input  wire signed [31:0]             data_in,     // 4ch x 8bit
    input  wire signed [32*4*8-1:0]       weight,      // 32 outputs, each with 4x8bit weights
    input  wire        [2:0]              counter,     // current 4-channel group index: 0~7
    // input  wire        [4:0]              acc_addr,    // spatial index: 0~17
    // input  wire                           acc_valid,   // current acc_addr is valid
    output wire signed [1023:0]           data_out
);

localparam integer OUT_CH   = 32;
// localparam integer DEPTH    = 18;
// localparam integer MEM_SIZE = OUT_CH * DEPTH;

wire signed [31:0] partial_sum [0:OUT_CH-1];
// reg  signed [31:0] acc_mem     [0:MEM_SIZE-1];

// reg [2:0] counter_d0, counter_d1, counter_d2;
// reg [4:0] acc_addr_d0, acc_addr_d1, acc_addr_d2;
// reg       acc_valid_d0, acc_valid_d1, acc_valid_d2;

// integer i;
// integer idx;
// integer ch;
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

    // Final output only at the 8th group (counter==7) after accumulation.
    // assign data_out[32*k + 31 : 32*k] =
    //     (acc_valid_d2 && (counter_d2 == 3'd7))
    //     ? ($signed(acc_mem[acc_addr_d2 * OUT_CH + k]) + $signed(partial_sum[k]))
    //     : 32'sd0;
    assign data_out[32*k + 31 : 32*k] = partial_sum[k];
end
endgenerate

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         counter_d0   <= 3'd0;
//         counter_d1   <= 3'd0;
//         counter_d2   <= 3'd0;
//         acc_addr_d0  <= 5'd0;
//         acc_addr_d1  <= 5'd0;
//         acc_addr_d2  <= 5'd0;
//         acc_valid_d0 <= 1'b0;
//         acc_valid_d1 <= 1'b0;
//         acc_valid_d2 <= 1'b0;

//         for(i = 0; i < MEM_SIZE; i = i + 1)
//             acc_mem[i] <= 32'sd0;
//     end else begin
//         // Align control path with SA_channel_3 2-stage pipeline latency.
//         counter_d0   <= counter;
//         counter_d1   <= counter_d0;
//         counter_d2   <= counter_d1;
//         acc_addr_d0  <= acc_addr;
//         acc_addr_d1  <= acc_addr_d0;
//         acc_addr_d2  <= acc_addr_d1;
//         acc_valid_d0 <= acc_valid;
//         acc_valid_d1 <= acc_valid_d0;
//         acc_valid_d2 <= acc_valid_d1;

//         if(acc_valid_d2) begin
//             for(ch = 0; ch < OUT_CH; ch = ch + 1) begin
//                 idx = acc_addr_d2 * OUT_CH + ch;

//                 if(counter_d2 == 3'd0)
//                     acc_mem[idx] <= partial_sum[ch];
//                 else
//                     acc_mem[idx] <= $signed(acc_mem[idx]) + $signed(partial_sum[ch]);
//             end
//         end
//     end
// end

endmodule
