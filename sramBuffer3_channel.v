`timescale 1ns / 1ps
module sramBuffer3_channel(
  input wire [32-1:0] data_in,
  input wire clk,
  input wire rst_n,
  input wire enable,
  input wire [5:0] radddr,
  input wire [2:0] counter,//用于记录当前为第几个通道，输入图（18行2列）呈S型输入，counter为偶数时由左上到右上，counter为奇数时由右上到左上
  output wire [2*32-1:0] data_out //2*32bit 输出，包含SRAM1和SRAM2的输出数据
  );

  
  wire [31:0] temp_out1 ;//用于存储SRAM1取出数据与data_in_buffer相加结果
  wire [31:0] temp_out2 ;//用于存储SRAM1取出数据与data_in_buffer相加结果
  reg [5:0]cnt;//确认当前输入数据应当存到哪个位置，范围为0~35
               //counter为偶数时，0~17，输入图第一列数据存入,18~35，第二列数据存入；counter为奇时，0~17，第二列数据存入,18~35，第一列数据存入
  reg [31:0] data_in_buffer;//输入数据寄存器
  
  wire [31:0]     q1,q2 ;//32个通道SRAM的读数据输出
  wire            cen_temp1,cen_temp2;
  wire            wen_temp1,wen_temp2;
  reg             CEN1,CEN2;
  reg             WEN1,WEN2;
  reg  [4:0]      A1,A2;


  //在下降沿寄存data_in
always@(negedge clk or negedge rst_n) begin
  if(!rst_n)
    data_in_buffer <=  31'b0;
  else
    data_in_buffer <= data_in;
end

//cnt控制逻辑
  always@(posedge clk or negedge rst_n) begin
  if(!rst_n)
    cnt <=  6'b0;
  else if(enable)begin
    if(cnt==6'd35)
    cnt<= 6'b0;
    else 
    cnt<=cnt+1;
  end    
  else
    cnt <= cnt;
end


//将取出数据与data_in_buffer相加
assign temp_out1=q1+data_in_buffer;
assign temp_out2=q2+data_in_buffer;
// --- SRAM 地址与控制信号逻辑 ---

// --- SRAM 地址与控制信号逻辑 ---

always @(*) begin
    // 默认值：高电平无效（低电平使能）
    CEN1 = 1'b1; WEN1 = 1'b1; A1 = 5'b0;
    CEN2 = 1'b1; WEN2 = 1'b1; A2 = 5'b0;

    if (enable) begin
        if(raddr<=17 && raddr>=0)begin
            if(raddr[0]==0)begin
                A1=raddr[5:1]; WEN1=1'b1; CEN1=1'b0;
                A2=5'd17-raddr[5:1]; WEN2=1'b1; CEN2=1'b0;
            end
            else begin
                A1=5'd17-raddr[5:1]; WEN1=1'b1; CEN1=1'b0;
                A2=raddr[5:1]; WEN2=1'b1; CEN2=1'b0;
            end
        end
        
       else begin
            // --- SRAM1 逻辑控制 ---
            CEN1 = 1'b0;
            // 1. 地址逻辑：无论哪一列，A1 = cnt / 2
            // 2. 读写逻辑：
            // counter为偶时：cnt为偶读(WEN=1)，cnt为奇写(WEN=0) -> WEN = ~cnt[0]
            // counter为奇时：cnt为奇读(WEN=1)，cnt为偶写(WEN=0) -> WEN = cnt[0]
            if (counter[0] == 0) begin
                WEN1 = ~cnt[0]; 
                    A1 = cnt[5:1]; 
            end

            else begin
                WEN1 = cnt[0];
                    A1 = 5'd17-cnt[5:1]; 
            end
                // --- SRAM2 逻辑控制 ---
            CEN2 = 1'b0;
            // 1. 地址逻辑：A2 = cnt / 2

            // 2. 读写逻辑（与SRAM1完全相反）：
            // counter为偶时：cnt为奇读(WEN=1)，cnt为偶写(WEN=0) -> WEN = cnt[0]
            // counter为奇时：cnt为偶读(WEN=1)，cnt为奇写(WEN=0) -> WEN = ~cnt[0]
            if (counter[0] == 0)begin
                WEN2 = cnt[0];
                A2 = cnt[5:1];
            end

            else begin
                WEN2 = ~cnt[0];
                A2 = 5'd17- cnt[5:1];
            end
       end
        
        


       
    end
end
assign data_out = {q1, q2};
// --- data_out 输出逻辑 ---
// 当 radddr 为偶数 (0, 2, 4...):
// SRAM1 取“顺向”数据：$A1 = radddr / 2$
// SRAM2 取“逆向”数据：$A2 = 17 - (radddr / 2)$
// 拼接顺序：{q1, q2} (即 SRAM1 在前)
// 当 radddr 为奇数 (1, 3, 5...):
// SRAM1 取“逆向”数据：$A1 = 17 - (radddr >> 1)$
// SRAM2 取“顺向”数据：$A2 = (radddr >> 1)$
// 拼接顺序：{q2, q1} (即 SRAM2 在前)



// --- 实例化 SRAM 模块 (示例) ---
// 假设 SRAM 为单时钟同步读写，且 temp_out 接入 data_in_sram

sram_32x18 u_sram1 (
    .clk  (clk),
    .cen  (CEN1),
    .wen  (WEN1),
    .addr (A1),
    .din  (temp_out1),
    .q    (q1)
);

sram_32x18 u_sram2 (
    .clk  (clk),
    .cen  (CEN2),
    .wen  (WEN2),
    .addr (A2),
    .din  (temp_out2),
    .q    (q2)
);



 //sram1控制逻辑
  //(2,0)代表输入图（18行2列）第二列第一行数据，则SRAM1依次存储(1,0)(1,2)...(1,16)(2,17)(2,15)...(2,1)
  //读出条件：counter为偶数时，cnt为偶数；counter为奇数时，cnt为奇数
  //写入条件：counter为偶数时，cnt为奇数(temp_out存入在读数据的下一个周期)；counter为奇数时，cnt为偶数；

  //sram2控制逻辑
  //(2,0)代表输入图（18行2列）第二列第一行数据，则SRAM1依次存储(1,1)(1,3)...(1,17)(2,16)(2,14)...(2,0)
  //读出条件：counter为偶数时，cnt为奇数；counter为奇数时，cnt为偶数
  //写入条件：counter为偶数时，cnt为偶数(temp_out存入在读数据的下一个周期)；counter为奇数时，cnt为奇数；

endmodule