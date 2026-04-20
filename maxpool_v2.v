`timescale 1ns / 1ps
module maxpool_v2(
    input wire clk,
    input wire enable,
    input wire rst_n,
    input wire [15:0] data_in, //一次传2个8bit数据
    output reg [7:0] data_max
);
reg             cnt;//两周期计数器，0或1
reg     [7:0]   temp_max; //暂存前两个数据的最大值
always @(posedge clk or negedge  rst_n)begin
    if(!rst_n)
        cnt <= 0;
    else if (enable == 1)
        cnt <= ~cnt; //翻转实现0、1交替
    else
        cnt <= cnt;
end
//第二拍（cnt=1）：将上一拍的temp_max与当前的两个输入比较，取最大值输出
always @(posedge clk or negedge  rst_n)begin
    if(!rst_n)
        data_max <= 8'b0;
    else if (enable == 1 && cnt == 1)
        data_max <= 
        ($signed(temp_max) > $signed(data_in[15:8]) && $signed(temp_max) > $signed(data_in[7:0]))?temp_max:
        ($signed(data_in[15:8]) > $signed(data_in[7:0]))?data_in[15:8]:data_in[7:0];
    else
        data_max <= data_max;
end
//第一拍（cnt=0）：比较当前的两个输入，结果存入temp_max
always @(posedge clk or negedge  rst_n)begin
    if(!rst_n)
        temp_max <= 8'b0;
    else if (enable == 1 && cnt == 0)
        temp_max <= ($signed(data_in[7:0]) > $signed(data_in[15:8]))?data_in[7:0]:data_in[15:8];
    else
        temp_max <= temp_max;
end
endmodule
