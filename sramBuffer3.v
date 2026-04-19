`timescale 1ns / 1ps
module sramBuffer3(
  input       wire    [32*32-1:0]               data_in,//输入数据，4通道×8bit
  input       wire                            clk,
  input       wire                            rst_n,
  input       wire                            enable,
  input       wire    [5:0]                   raddr,//读地址
  input       wire    [2:0]                   counter,
  output      wire    [32*32*2-1:0]             data_out//输出数据，32通道32bit,两个sram同时输出
);
generate
    for(k = 0;k < 32;k = k + 1)begin:array_loop
        sramBuffer3_channel    channel(
            .data_in    (data_in[32*k + 31:32*k]),
            .clk        (clk),
            .rst_n      (rst_n),
            .enable     (enable),
            .radddr     (raddr),
            .counter    (counter),
            .data_out   (data_out[64*k + 63:64*k])
        );
    end
endgenerate


endmodule