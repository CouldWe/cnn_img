`timescale 1ns / 1ps
module BUFFER_2(
    input       wire    [31:0]                 data_in,//4通道*8bit输入数据
    input       wire                            clk,
    input       wire                            rst_n,
    output      reg     [31:0]                 data_out
);
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        data_out    <=  32'b0;
    else
        data_out    <=  data_in;
end    
endmodule
