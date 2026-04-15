module SA1(
    input wire clk,
    input wire rst_n,
    input wire sa1_control, //SA1控制信号，右移时为1
    input wire   [2:0] counter,//counter，PE arry设计为4通道，counter用于记录现在为第几个四通道，最小0，最大7 
    input wire signed [56-1:0] data_in,   //7*8bit输入数据
    input wire signed [4*616-1:0] weight,  //4*11*7*8bit权重拼接
    output wire signed [4*32-1:0] data_out //4*32bit输出拼接
);

    genvar i;
    //实例化4个SA1_channel
    generate
        for (i = 0; i < 4; i = i + 1) begin : sa1_channels
            SA1_channel u_SA1_channel (
                .clk(clk),
                .rst_n(rst_n),
                .sa1_control(sa1_control), //SA1控制信号，右移时为1
                .counter(counter),//counter，PE arry设计为4通道，counter用于记录现在为第几个四通道，最小0，最大7 
                .data_in(data_in),   //输入数据广播到所有通道   
                .weight(weight[i*616 +615: i*616]), //每个通道对应11*7*8bit的权重  
                .data_out(data_out[i*32 +31: i*32])
            );
        end
    endgenerate

endmodule
