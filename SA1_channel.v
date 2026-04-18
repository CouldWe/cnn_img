module SA1_channel(
    input wire clk,
    input wire rst_n,
    input wire sa1_control,        // SA1控制信号，右移时为1
    input wire   [2:0] counter,//counter，PE arry设计为4通道，counter用于记录现在为第几个四通道，最小0，最大7 
    input wire signed [55:0] data_in, //7*8bit输入数据，按行脉动进入
    input wire signed [615:0] weight, //11*7*8bit权重
    output wire signed [31:0] data_out
);

genvar i,j;
wire signed     [615:0]         data_temp   ;//用于PE之间传递的脉动数据，宽度与weight相同
wire signed     [32*11*7-1:0]        partial_product_temp    ;//所有PE的乘积结果，32*11*7
//加法树各级部分和信号
wire signed     [32*5*7-1:0]    partial_product_temp_l2; 
wire signed     [32*3*7-1:0]    partial_product_temp_l3; 
wire signed     [32*7-1:0]      partial_product_temp_l4; 
wire signed     [32*3-1:0]      partial_product_temp_l5; 
wire signed     [32*2-1:0]      partial_product_temp_l6; 

// sa1_control信号的前一个cycle的信号值
reg sa1_control_d1;
wire p_control;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sa1_control_d1 <= 1'b0;
    end else begin
        sa1_control_d1 <= sa1_control;
    end
end

assign p_control = sa1_control & sa1_control_d1;
// p_control为0时表示当前cycle是SA1的第一个cycle；p_control为1时表示当前cycle是SA1的第二个cycle

//r_or_l，用于控制卷积核向左滑动还是向右滑动，r_or_l=0时，卷积核向右滑动
reg r_or_l;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        r_or_l<= 1'b0;
    end else if(counter==0||counter==2||counter==4||counter==6) begin
         r_or_l<= 1'b0;
    end else  r_or_l<= 1'b1;
end

// 控制上滑还是下滑
reg m_control;
wire sa1_falling_edge;
assign sa1_falling_edge = (~sa1_control) & sa1_control_d1;

// 2. m_control 状态 控制卷积核是下滑还是上滑
// m_control为0时表示卷积核下滑，数据从上一行输入；m_control为1时表示卷积核上滑，数据从下一行输入
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        m_control <= 1'b0;
    end else begin
        if (sa1_falling_edge) begin
            // 右移结束，开始上滑
            m_control <= ~m_control; // 切换到上滑状态
        end
    end
end

// ===================== 11×7 卷积核数据选择（核心逻辑） =====================
generate
    for(i = 0; i < 11; i = i + 1) begin: row_loop  // 11行
        for(j = 0; j < 7; j = j + 1) begin: col_loop   // 7列
            // 修复：定义为有符号数，匹配输入数据类型
            wire signed [7:0] selected_data_in;  // 每个位置选中的8bit数据

            // 组合逻辑MUX：根据控制信号选通数据
            assign selected_data_in =
            // ========== 公共部分：纵向滑动（r_or_l不影响纵向逻辑） ==========
            (sa1_control == 1'b0) ? (
                (m_control == 1'b0) ?
                    // 下滑：数据来自下一行，最后一行取外部输入
                    (i == 10) ? data_in[j*8 +: 8] : data_temp[(i*7+j+7)*8 +: 8] :
                    // 上滑：数据来自上一行，第一行取外部输入
                    (i == 0)  ? data_in[j*8 +: 8] : data_temp[(i*7+j-7)*8 +: 8]
            ) :
            // ========== 横向滑动：右滑(r_or_l=0) / 左滑(r_or_l=1) ==========
            (r_or_l == 1'b0) ?
                // --------------- 右滑模式 ---------------
                (p_control == 1'b0) ?
                    // 右滑第1周期
                    (j == 6) ? ((i <= 6) ? data_in[i*8 +: 8] : 8'sb0) : data_temp[(i*7+j+1)*8 +: 8] :
                    // 右滑第2周期
                    (j == 6) ? ((i > 6) ? data_in[(i-7)*8 +: 8] : data_temp[(i*7+j)*8 +: 8]) : data_temp[(i*7+j)*8 +: 8]
            :
                // --------------- 左滑模式 ---------------
                (p_control == 1'b0) ?
                    // 修复：左滑边界修正为j==0（7列卷积核最左列为0，原j==1逻辑错误）
                    (j == 0) ? ((i <= 6) ? data_in[i*8 +: 8] : 8'sb0) : data_temp[(i*7+j-1)*8 +: 8] :
                    // 修复：左滑边界修正为j==0
                    (j == 0) ? ((i > 6) ? data_in[(i-7)*8 +: 8] : data_temp[(i*7+j)*8 +: 8]) : data_temp[(i*7+j)*8 +: 8];
            
            // 修复：PE实例化放入generate循环内部，生成11x7=77个PE
            // 3. 实例化 PE，将选好的数据连进去
            PE array_pe (
                .clk           (clk),
                .rst_n         (rst_n),
                .weight        (weight[(i*7+j)*8 +: 8]),
                .data_in       (selected_data_in), // 连入选择后的信号
                .data_out      (data_temp[(i*7+j)*8 +: 8]),
                .temp_product  (partial_product_temp[(i*7+j)*32 +: 32])
            );
        end
    end
endgenerate

wire signed  [31:0]  adderTreeReg       [10*7 - 1:0];//用于存储列加法树各级的中间结果
wire signed  [31:0]  inputReg           [11*7 - 1:0];//寄存77个PE的乘积结果

// 修复：列加法树for循环用generate包裹，符合Verilog语法
generate
for(i = 0;i < 7;i = i + 1)begin: col_add_tree
//寄存每一行的乘积结果，共11行
FF_32    inputBuffer0(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp[(0*7+i)*32+31:(0*7+i)*32]),.data_out(inputReg[0*7+i]));
FF_32    inputBuffer1(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp[(1*7+i)*32+31:(1*7+i)*32]),.data_out(inputReg[1*7+i]));
FF_32    inputBuffer2(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp[(2*7+i)*32+31:(2*7+i)*32]),.data_out(inputReg[2*7+i]));
FF_32    inputBuffer3(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp[(3*7+i)*32+31:(3*7+i)*32]),.data_out(inputReg[3*7+i]));
FF_32    inputBuffer4(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp[(4*7+i)*32+31:(4*7+i)*32]),.data_out(inputReg[4*7+i]));
FF_32    inputBuffer5(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp[(5*7+i)*32+31:(5*7+i)*32]),.data_out(inputReg[5*7+i]));
FF_32    inputBuffer6(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp[(6*7+i)*32+31:(6*7+i)*32]),.data_out(inputReg[6*7+i]));
FF_32    inputBuffer7(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp[(7*7+i)*32+31:(7*7+i)*32]),.data_out(inputReg[7*7+i]));
FF_32    inputBuffer8(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp[(8*7+i)*32+31:(8*7+i)*32]),.data_out(inputReg[8*7+i]));
FF_32    inputBuffer9(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp[(9*7+i)*32+31:(9*7+i)*32]),.data_out(inputReg[9*7+i]));
FF_32    inputBuffer10(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp[(10*7+i)*32+31:(10*7+i)*32]),.data_out(inputReg[10*7+i]));
//第一级加法将相邻两乘积相加，得到5组部分和
assign partial_product_temp_l2[32*(0*7+i)+31:32*(0*7+i)] = $signed(inputReg[0*7+i]) + $signed(inputReg[1*7+i]);
assign partial_product_temp_l2[32*(1*7+i)+31:32*(1*7+i)] = $signed(inputReg[2*7+i]) + $signed(inputReg[3*7+i]);
assign partial_product_temp_l2[32*(2*7+i)+31:32*(2*7+i)] = $signed(inputReg[4*7+i]) + $signed(inputReg[5*7+i]);
assign partial_product_temp_l2[32*(3*7+i)+31:32*(3*7+i)] = $signed(inputReg[6*7+i]) + $signed(inputReg[7*7+i]);
assign partial_product_temp_l2[32*(4*7+i)+31:32*(4*7+i)] = $signed(inputReg[8*7+i]) + $signed(inputReg[9*7+i]);
//寄存第一级加法结果和第11个原始乘积
FF_32    treeBuffer0(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp_l2[32*(0*7+i)+31:32*(0*7+i)]),.data_out(adderTreeReg[0*7+i]));
FF_32    treeBuffer1(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp_l2[32*(1*7+i)+31:32*(1*7+i)]),.data_out(adderTreeReg[1*7+i]));
FF_32    treeBuffer2(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp_l2[32*(2*7+i)+31:32*(2*7+i)]),.data_out(adderTreeReg[2*7+i]));
FF_32    treeBuffer3(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp_l2[32*(3*7+i)+31:32*(3*7+i)]),.data_out(adderTreeReg[3*7+i]));
FF_32    treeBuffer4(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp_l2[32*(4*7+i)+31:32*(4*7+i)]),.data_out(adderTreeReg[4*7+i]));
FF_32    treeBuffer5(.clk(clk),.rst_n(rst_n),.data_in(inputReg[10*7+i]),.data_out(adderTreeReg[5*7+i]));
//第二级加法进一步两两相加，得到3组部分和
assign partial_product_temp_l3[32*(0*7+i)+31:32*(0*7+i)] = $signed(adderTreeReg[0*7+i]) + $signed(adderTreeReg[1*7+i]);
assign partial_product_temp_l3[32*(1*7+i)+31:32*(1*7+i)] = $signed(adderTreeReg[2*7+i]) + $signed(adderTreeReg[3*7+i]);
assign partial_product_temp_l3[32*(2*7+i)+31:32*(2*7+i)] = $signed(adderTreeReg[4*7+i]) + $signed(adderTreeReg[5*7+i]);
//寄存第二级加法结果
FF_32    treeBuffer6(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp_l3[32*(0*7+i)+31:32*(0*7+i)]),.data_out(adderTreeReg[6*7+i]));
FF_32    treeBuffer7(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp_l3[32*(1*7+i)+31:32*(1*7+i)]),.data_out(adderTreeReg[7*7+i]));
FF_32    treeBuffer8(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp_l3[32*(2*7+i)+31:32*(2*7+i)]),.data_out(adderTreeReg[8*7+i]));
//第三级加法将第二级的 3 组部分和相加得到每列的最终累加和
assign partial_product_temp_l4[32*i + 31:32*i]   = $signed(adderTreeReg[6*7+i]) + $signed(adderTreeReg[7*7+i]) + $signed(adderTreeReg[8*7+i]);
//寄存第三级结果
FF_32    treeBuffer9(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp_l4[32*i + 31:32*i]),.data_out(adderTreeReg[9*7+i]));
end
endgenerate

//行加法树
wire signed  [31:0]  adderTreeReg2    [5:0];//用于存储跨列加法的中间结果
//第四级将相邻两列的结果相加，共3组
assign  partial_product_temp_l5[32*0 + 31:32*0] = $signed(adderTreeReg[9*7+0]) + $signed(adderTreeReg[9*7+1]);
assign  partial_product_temp_l5[32*1 + 31:32*1] = $signed(adderTreeReg[9*7+2]) + $signed(adderTreeReg[9*7+3]);
assign  partial_product_temp_l5[32*2 + 31:32*2] = $signed(adderTreeReg[9*7+4]) + $signed(adderTreeReg[9*7+5]);
//寄存第四级结果和第7列的原始结果
FF_32    treeBuffer2_0(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp_l5[32*0 + 31:32*0]),.data_out(adderTreeReg2[0]));
FF_32    treeBuffer2_1(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp_l5[32*1 + 31:32*1]),.data_out(adderTreeReg2[1]));
FF_32    treeBuffer2_2(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp_l5[32*2 + 31:32*2]),.data_out(adderTreeReg2[2]));
FF_32    treeBuffer2_3(.clk(clk),.rst_n(rst_n),.data_in(adderTreeReg[9*7+6]),.data_out(adderTreeReg2[3]));
//第五级将第四级数据进一步两两相加
assign  partial_product_temp_l6[32*0 + 31:32*0] = $signed(adderTreeReg2[0]) + $signed(adderTreeReg2[1]);
assign  partial_product_temp_l6[32*1 + 31:32*1] = $signed(adderTreeReg2[2]) + $signed(adderTreeReg2[3]);
//寄存第五级结果
FF_32    treeBuffer2_4(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp_l6[32*0 + 31:32*0]),.data_out(adderTreeReg2[4]));
FF_32    treeBuffer2_5(.clk(clk),.rst_n(rst_n),.data_in(partial_product_temp_l6[32*1 + 31:32*1]),.data_out(adderTreeReg2[5]));
//第六级最后两个部分和相加，得到最终输出
assign  data_out = $signed(adderTreeReg2[5]) + $signed(adderTreeReg2[4]);

endmodule

