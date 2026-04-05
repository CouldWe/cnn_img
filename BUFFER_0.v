`timescale 1ns / 1ps
module BUFFER_0(
    input       wire    [55:0]                 data_in,//32通道*8bit输入数据
    input       wire                            clk,
    input       wire                            rst_n,
    input      wire                            enable,//为0代表可以从内存读取数据 ，不能给sa1输出数据
    output      reg     [55:0]                 data_out
);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        data_out    <=  56'b0;
    else begin
        if(enable)
            data_out    <=  data_in;
        else
            data_out <= 56'b0;
    end
SRAM_93_56      sram(
  .Q                (data_out),
  .CLK              (clk),
  .CEN              (1'b0),//片选信号一直有效
  .WEN              (1'b1),//写使能一直无效
  .A                (5'b0),//地址线不使用
  .D                (56'b0)//写数据输入不使用
  );  

end    
endmodule
