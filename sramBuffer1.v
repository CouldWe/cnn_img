`timescale 1ns / 1ps
module sramBuffer1(
  input       wire    [4*8-1:0]               data_in,//输入数据，4通道×8bit
  input       wire                            clk,
  input       wire                            rst_n,
  input       wire                            enable,
  input       wire    [5:0]                   raddr,//读地址
  input       wire    [2:0]                   counter,
  output      wire    [4*3*8-1:0]             data_out//输出数据，4通道×3*8bit
);

parameter cnt_max = 8'd153;//计数器最大值，根据需要调整
wire [4*8-1:0]    Q1,Q2,Q3,Q4;//四个SRAM的读数据输出
wire            cen_temp1,cen_temp2,cen_temp3,cen_temp4;
wire            wen_temp1,wen_temp2,wen_temp3,wen_temp4;
reg             CEN1,CEN2,CEN3,CEN4;
reg             WEN1,WEN2,WEN3,WEN4;
reg  [4:0]      A1,A2,A3,A4;
reg  [4*8-1:0]    data_in_buffer;//输入数据寄存器
reg     [6:0]   cnt;//内部计数器，用于控制写入时序

//在下降沿寄存data_in
always@(negedge clk or negedge rst_n) begin
  if(!rst_n)
    data_in_buffer <=  32'b0;
  else
    data_in_buffer <= data_in;
end

always@(posedge clk or negedge rst_n) begin
  if(!rst_n)
    cnt <=  7'b0;
  else if(enable)begin
    if(cnt==cnt_max)
    cnt<=7'b0;
    else 
    cnt<=cnt+1;
  end    
  else
    cnt <= cnt;
end

//ARRAY1控制逻辑
//写入条件：enable有效且cnt在0~19
//读出条件：读地址raddr在0~19，cnt在41~60
assign cen_temp1 = !(enable && cnt>=0 && cnt<=19 || raddr>=0 && raddr<=19 );//片选信号拉低
always@(negedge clk or negedge rst_n) begin
  if(!rst_n)
    CEN1 <=  1;
  else
    CEN1 <= cen_temp1;
end

assign wen_temp1 = !(enable && cnt>=0 && cnt<=19);//写使能信号拉低
always@(negedge clk or negedge rst_n) begin
  if(!rst_n)
    WEN1 <=  1;
  else
    WEN1 <= wen_temp1;
end

always@(negedge clk or negedge rst_n) begin
  if(!rst_n)
    A1 <=  5'b0;
  else if(!CEN1 && !WEN1)
    A1 <=  cnt;//写操作：地址取cnt
  else if(!CEN1 && WEN1)
    A1 <=  raddr;//读操作：地址取raddr
  else
    A1 <=  5'b0;
end

//ARRAY2控制逻辑
//写入条件：enable有效且cnt在20~39
//读出条件：raddr在0~39，cnt在41~80
assign cen_temp2 = !(enable && cnt>=20 && cnt<=39 || raddr>=0 && raddr<=39 );//片选信号拉低
always@(negedge clk or negedge rst_n) begin
  if(!rst_n)
    CEN2 <=  1;
  else
    CEN2 <= cen_temp2;
end
assign wen_temp2 = !(enable && cnt>=20 && cnt<=39);//写使能信号拉低
always@(negedge clk or negedge rst_n) begin
  if(!rst_n)
    WEN2 <=  1;
  else
    WEN2 <= wen_temp2;
end
always@(negedge clk or negedge rst_n) begin
  if(!rst_n)
    A2 <=  5'b0;
  else if(!CEN2 && !WEN2)
    A2 <=  19-(cnt-20); //写操作地址
  else if(!CEN2 && WEN2)begin
    if(raddr>=0&&raddr<=19)
      A2 <= raddr;
    else A2 <= 19-(raddr-20);
  end
    
  else
    A2 <=  5'b0;
end

//ARRAY3控制逻辑
//写入条件：enable有效且cnt在40、42...58 (40~58 偶数)                  
//读出条件：raddr在0、2、4...18或raddr在21、23...39
assign cen_temp3 = !( (enable && cnt >= 40 && cnt <= 58 && cnt[0] == 1'b0) || (raddr >= 0 && raddr <= 19 && raddr[0] == 1'b0) || (raddr >= 21 && raddr <= 39 && raddr[0] == 1'b1) );
always@(negedge clk or negedge rst_n) begin
  if(!rst_n)
    CEN3 <=  1;
  else
    CEN3 <= cen_temp3;
end

assign wen_temp3 = !(enable && cnt >= 40 && cnt <= 58 && cnt[0] == 1'b0);
always@(negedge clk or negedge rst_n) begin
  if(!rst_n)
    WEN3 <=  1;
  else
    WEN3 <= wen_temp3;
end
always@(negedge clk or negedge rst_n) begin
  if(!rst_n)
    A3 <=  5'b0;
  else if(!CEN3 && !WEN3)
    A3 <=  cnt - 40;
  else if(!CEN3 && WEN3)
         if(raddr>=6'd0&&raddr<=6'd18)
         A3<= raddr/2;
         else A3<=9-(raddr-21)/2;
  else
    A3 <=  5'b0;
end

//ARRAY4控制逻辑
//写入条件：enable有效且cnt在41、43...59                  
//读出条件：raddr在1、3、5...19或raddr在20、22...38
assign cen_temp4 = !( (enable && cnt >= 40 && cnt <= 58 && cnt[0] == 1'b1) || (raddr >= 0 && raddr <= 19 && raddr[0] == 1'b1) || (raddr >= 21 && raddr <= 39 && raddr[0] == 1'b0) );
always@(negedge clk or negedge rst_n) begin
  if(!rst_n)
    CEN4 <=  1;
  else
    CEN4 <= cen_temp4;
end
assign wen_temp4 = !(enable && cnt>=50 && cnt<=59);
always@(negedge clk or negedge rst_n) begin
  if(!rst_n)
    WEN4 <=  1;
  else
    WEN4 <= wen_temp4;
end
always@(negedge clk or negedge rst_n) begin
  if(!rst_n)
    A4 <=  5'b0;
  else if(!CEN4 && !WEN4)
    A4 <=  cnt - 50;
  else if(!CEN4 && WEN4)
      if(raddr>=6'd1&&raddr<=6'd18)
         A4<= (raddr-1)/2;
      else A4<=9-(raddr-20)/2;
  else
    A4 <=  5'b0;
end

//第四列数据缓存使用2个寄存器构成深度为1的移位寄存器
reg [31:0]     col4_data1;
reg [31:0]     col4_data2;
always @(posedge clk or negedge rst_n) begin
  if(!rst_n)
    col4_data1    <=  32'b0;
  else
    col4_data1    <=  data_in;
end  
always @(posedge clk or negedge rst_n) begin
  if(!rst_n)
    col4_data2    <=  32'b0;
  else
    col4_data2    <=  col4_data1;
end 
//根据raddr范围，选择三个数据源拼接成3*4*8位输出

// 

assign data_out = 
(counter[0]==1'b0)?((raddr>=0 && raddr<=19&&raddr[0]==1'b1)? {Q3,Q2,Q1}:
(raddr>=0 && raddr<=19&&raddr[0]==1'b0)?{Q4,Q2,Q1}:
(raddr>=20 && raddr<=39&&raddr[0]==1'b1)?{col4_data2,Q3,Q2}:
(raddr>=20 && raddr<=39 &&raddr[0]==1'b0)?{col4_data2,Q4,Q2}:
96'b0)
:
((raddr>=0 && raddr<=19&&raddr[0]==1'b1)? {Q1,Q2,Q3}:
(raddr>=0 && raddr<=19&&raddr[0]==1'b0)?{Q1,Q2,Q4}:
(raddr>=20 && raddr<=39&&raddr[0]==1'b1)?{Q2,Q3,col4_data2}:
(raddr>=20 && raddr<=39 &&raddr[0]==1'b0)?{Q2,Q4,col4_data2}:
96'b0);

//实例化两个32位宽、20深度的SRAM，两个32位宽、10深度的SRAM
SRAM_32_20     ARRAY1(
  .Q                (Q1),
  .CLK              (clk),
  .CEN              (CEN1),
  .WEN              (WEN1),
  .A                (A1),
  .D                (data_in_buffer)
);

SRAM_32_20     ARRAY2(
  .Q                (Q2),
  .CLK              (clk),
  .CEN              (CEN2),
  .WEN              (WEN2),
  .A                (A2),
  .D                (data_in_buffer)
);

SRAM_32_10     ARRAY3(
  .Q                (Q3),
  .CLK              (clk),
  .CEN              (CEN3),
  .WEN              (WEN3),
  .A                (A3),
  .D                (data_in_buffer)
);

SRAM_32_10     ARRAY4(
  .Q                (Q4),
  .CLK              (clk),
  .CEN              (CEN4),
  .WEN              (WEN4),
  .A                (A4),
  .D                (data_in_buffer)
);

endmodule
