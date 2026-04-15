`timescale 1ns / 1ps
module SA_2(
    input wire                          clk,
    input wire                          rst_n,
    input wire signed [4*3*8-1:0]           data_in,//4*3*8bit输入数据
    input wire signed [4*9*8-1:0]          weight, //4*9*8bit权重拼接
    output wire signed [4*32-1:0]         data_out,//4*32bit输出拼接
    input wire [5:0]                    buffer1_addr//来自sramBuffer1的读地址，用于计算控制SA2的卷积核上滑还是下滑的信号m_control_sa2
);

genvar k;
//实例化4个SA_channel_2

// 控制sa2的卷积核上滑还是下滑
// m_control_sa2为0时，下滑，m_control_sa2为1时，上滑
reg m_control_sa2;
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        m_control_sa2 <= 1'b0;
    else if(buffer1_addr>=0 && buffer1_addr<=18 || buffer1_addr>=39)
        m_control_sa2 <= 1'b0;
    else if(buffer1_addr>=19 && buffer1_addr<=38)
        m_control_sa2 <= 1'b1;
end
generate
    for(k = 0;k < 4;k = k + 1)begin:array_loop
        SA_channel_2    channel(
            .clk            (clk),
            .rst_n          (rst_n),
            .data_in        ({data_in[8*k+7+64:8*k+64],data_in[8*k+7+32:8*k+32],data_in[8*k+7:8*k]}),
            .data_out       (data_out[32*k + 31:32*k]),
            .weight         (weight[3*3*8*k + 71:3*3*8*k]),
            .m_control_sa2   (m_control_sa2)
        );
    end
endgenerate

endmodule
