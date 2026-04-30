`timescale 1ns / 1ps
module FC_PE(
    input wire                          clk,
    input wire                          rst_n,
    input wire                          enable,
    input wire signed [7:0]             data_in,
    input wire signed [143:0]           weight,//2*9*8bit
    output wire signed [31:0]           temp_out_0,//通道0的部分和
    output wire signed [31:0]           temp_out_1 //通道1的部分和
);
    
reg     [4:0]   cnt;
reg     signed [7:0]   weight_tenmp;//当前周期选择的权重
wire    signed [15:0]  product;//乘积结果8bit*8bit
reg     signed [31:0]   partial_sum_0;
reg     signed [31:0]   partial_sum_1;

reg     signed [15:0]   mux_00;
reg     signed [31:0]   mux_01;
reg     signed [15:0]   mux_10;
reg     signed [31:0]   mux_11;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        cnt <= 5'b0;
    else if(enable) begin
        if(cnt == 17)
            cnt <= 5'b0;  // 重新开始计数
        else
            cnt <= cnt + 1;
    end
    else
        cnt <= cnt;
end

//cnt从0到17依次选择weight[0]到weight[17]
always@(*) begin
    case(cnt)
        0:weight_tenmp = weight[0*8+7:0*8];
        1:weight_tenmp = weight[1*8+7:1*8];
        2:weight_tenmp = weight[2*8+7:2*8];
        3:weight_tenmp = weight[3*8+7:3*8];
        4:weight_tenmp = weight[4*8+7:4*8];
        5:weight_tenmp = weight[5*8+7:5*8];
        6:weight_tenmp = weight[6*8+7:6*8];
        7:weight_tenmp = weight[7*8+7:7*8];
        8:weight_tenmp = weight[8*8+7:8*8];
        9:weight_tenmp = weight[9*8+7:9*8];
        10:weight_tenmp = weight[10*8+7:10*8];
        11:weight_tenmp = weight[11*8+7:11*8];
        12:weight_tenmp = weight[12*8+7:12*8];
        13:weight_tenmp = weight[13*8+7:13*8];
        14:weight_tenmp = weight[14*8+7:14*8];
        15:weight_tenmp = weight[15*8+7:15*8];
        16:weight_tenmp = weight[16*8+7:16*8];
        17:weight_tenmp = weight[17*8+7:17*8];
        default:weight_tenmp = 8'b00000000;
    endcase
end

assign product = $signed(weight_tenmp) * $signed(data_in);

//mux_00：cnt为偶数时选择product，否则0，因为通道0在偶数周期累加
always@(*) begin
    case(cnt%2)
        0:mux_00 = product;
        1:mux_00 = 0;
        default:mux_00 = 0;
    endcase
end

//mux_01：当enable有效时，将mux_00与当前的partial_sum_0相加，用于更新；cnt==0时从0开始累加
always@(*) begin
    if(!enable)
        mux_01 = 32'b0;
    else if(cnt == 0)
        mux_01 = $signed(mux_00);  // cnt=0时，从mux_00开始（不加partial_sum_0）
    else
        mux_01 = $signed(mux_00) + $signed(partial_sum_0);
end

//mux_10：cnt为奇数时选择product，否则0，因为通道1在奇数周期累加
always@(*) begin
    case(cnt%2)
        0:mux_10 = 0;
        1:mux_10 = product;
        default:mux_10 = 0;
    endcase
end

//mux_11：当enable有效时，将mux_10与partial_sum_1相加，用于更新；cnt==1时从0开始累加
always@(*) begin
    if(!enable)
        mux_11 = 32'b0;
    else if(cnt == 1)
        mux_11 = $signed(mux_10);  // cnt=1时，从mux_10开始（不加partial_sum_1）
    else
        mux_11 = $signed(mux_10) + $signed(partial_sum_1);
end

//partial_sum_0
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        partial_sum_0 <= 32'b0;
    else
        partial_sum_0 <= mux_01;
end

//partial_sum_1
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        partial_sum_1 <= 32'b0;
    else
        partial_sum_1 <= mux_11;
end

assign temp_out_0 = $signed(partial_sum_0);
assign temp_out_1 = $signed(partial_sum_1);
endmodule