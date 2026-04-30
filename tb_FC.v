`timescale 1ns / 1ps

module tb_FC;

// Clock and reset
reg clk;
reg rst_n;
reg enable;

// Input signals
reg signed [255:0] data_in;  // 32*8bit
reg signed [4607:0] weight;  // 32*2*9*8bit

// Output signals
wire signed [63:0] data_out;
wire signed [31:0] temp_out_0;
wire signed [31:0] temp_out_1;

// Extract temp_out signals from DUT
assign temp_out_0 = data_out[31:0];
assign temp_out_1 = data_out[63:32];

// Instantiate the Unit Under Test (UUT)
FC uut (
    .clk(clk),
    .rst_n(rst_n),
    .enable(enable),
    .data_in(data_in),
    .weight(weight),
    .data_out(data_out)
);

// Clock generation: 10ns period (100MHz)
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// Test data arrays
reg signed [7:0] data_array [0:287];
reg signed [7:0] weight_array [0:575];

integer i;

// Bias and quant parameters
parameter signed [31:0] bias_0 = 1339;
parameter signed [31:0] bias_1 = -2337;
parameter signed [31:0] M0 = 11;
parameter integer n = 15;

// Quantized output signals with floor rounding
wire signed [31:0] out_0;
wire signed [31:0] out_1;

// Intermediate values
wire signed [63:0] product_0;
wire signed [63:0] product_1;

assign product_0 = (temp_out_0 + bias_0) * M0;
assign product_1 = (temp_out_1 + bias_1) * M0;

// Floor division: arithmetic right shift implements floor for signed numbers
assign out_0 = product_0 >>> n;
assign out_1 = product_1 >>> n;

// Initialize test data
initial begin
    // Initialize data_in array (288 elements)
    // Data organized as 9 time steps × 32 channels
    data_array[0] = 32; data_array[1] = 0; data_array[2] = 78; data_array[3] = 127;
    data_array[4] = 52; data_array[5] = 0; data_array[6] = 0; data_array[7] = 26;
    data_array[8] = 19; data_array[9] = 29; data_array[10] = 0; data_array[11] = 101;
    data_array[12] = 39; data_array[13] = 14; data_array[14] = 0; data_array[15] = 76;
    data_array[16] = 37; data_array[17] = 55; data_array[18] = 98; data_array[19] = 113;
    data_array[20] = 0; data_array[21] = 51; data_array[22] = 73; data_array[23] = 46;
    data_array[24] = 51; data_array[25] = 1; data_array[26] = 106; data_array[27] = 1;
    data_array[28] = 44; data_array[29] = 29; data_array[30] = 19; data_array[31] = 5;
    data_array[32] = 55; data_array[33] = 0; data_array[34] = 48; data_array[35] = 103;
    data_array[36] = 32; data_array[37] = 0; data_array[38] = 0; data_array[39] = 21;
    data_array[40] = 4; data_array[41] = 20; data_array[42] = 0; data_array[43] = 120;
    data_array[44] = 9; data_array[45] = 32; data_array[46] = 0; data_array[47] = 63;
    data_array[48] = 39; data_array[49] = 97; data_array[50] = 102; data_array[51] = 81;
    data_array[52] = 2; data_array[53] = 36; data_array[54] = 77; data_array[55] = 53;
    data_array[56] = 29; data_array[57] = 38; data_array[58] = 86; data_array[59] = 11;
    data_array[60] = 0; data_array[61] = 21; data_array[62] = 8; data_array[63] = 28;
    data_array[64] = 61; data_array[65] = 0; data_array[66] = 15; data_array[67] = 46;
    data_array[68] = 7; data_array[69] = 0; data_array[70] = 35; data_array[71] = 60;
    data_array[72] = 0; data_array[73] = 21; data_array[74] = 9; data_array[75] = 127;
    data_array[76] = 7; data_array[77] = 54; data_array[78] = 0; data_array[79] = 43;
    data_array[80] = 28; data_array[81] = 86; data_array[82] = 97; data_array[83] = 0;
    data_array[84] = 0; data_array[85] = 3; data_array[86] = 74; data_array[87] = 61;
    data_array[88] = 59; data_array[89] = 8; data_array[90] = 54; data_array[91] = 31;
    data_array[92] = 0; data_array[93] = 62; data_array[94] = 30; data_array[95] = 39;
    data_array[96] = 53; data_array[97] = 0; data_array[98] = 37; data_array[99] = 42;
    data_array[100] = 16; data_array[101] = 6; data_array[102] = 9; data_array[103] = 50;
    data_array[104] = 29; data_array[105] = 29; data_array[106] = 27; data_array[107] = 121;
    data_array[108] = 3; data_array[109] = 16; data_array[110] = 0; data_array[111] = 83;
    data_array[112] = 52; data_array[113] = 30; data_array[114] = 119; data_array[115] = 35;
    data_array[116] = 0; data_array[117] = 0; data_array[118] = 109; data_array[119] = 77;
    data_array[120] = 33; data_array[121] = 48; data_array[122] = 100; data_array[123] = 34;
    data_array[124] = 43; data_array[125] = 8; data_array[126] = 39; data_array[127] = 8;
    data_array[128] = 72; data_array[129] = 0; data_array[130] = 14; data_array[131] = 89;
    data_array[132] = 27; data_array[133] = 30; data_array[134] = 0; data_array[135] = 3;
    data_array[136] = 1; data_array[137] = 11; data_array[138] = 0; data_array[139] = 127;
    data_array[140] = 0; data_array[141] = 42; data_array[142] = 0; data_array[143] = 58;
    data_array[144] = 58; data_array[145] = 80; data_array[146] = 100; data_array[147] = 54;
    data_array[148] = 0; data_array[149] = 29; data_array[150] = 96; data_array[151] = 59;
    data_array[152] = 26; data_array[153] = 28; data_array[154] = 101; data_array[155] = 11;
    data_array[156] = 37; data_array[157] = 29; data_array[158] = 30; data_array[159] = 13;
    data_array[160] = 77; data_array[161] = 11; data_array[162] = 24; data_array[163] = 33;
    data_array[164] = 13; data_array[165] = 3; data_array[166] = 22; data_array[167] = 10;
    data_array[168] = 0; data_array[169] = 15; data_array[170] = 5; data_array[171] = 125;
    data_array[172] = 5; data_array[173] = 43; data_array[174] = 0; data_array[175] = 36;
    data_array[176] = 54; data_array[177] = 71; data_array[178] = 95; data_array[179] = 18;
    data_array[180] = 0; data_array[181] = 22; data_array[182] = 75; data_array[183] = 64;
    data_array[184] = 31; data_array[185] = 70; data_array[186] = 89; data_array[187] = 16;
    data_array[188] = 35; data_array[189] = 39; data_array[190] = 39; data_array[191] = 11;
    data_array[192] = 59; data_array[193] = 2; data_array[194] = 27; data_array[195] = 42;
    data_array[196] = 22; data_array[197] = 11; data_array[198] = 0; data_array[199] = 21;
    data_array[200] = 29; data_array[201] = 19; data_array[202] = 12; data_array[203] = 119;
    data_array[204] = 0; data_array[205] = 7; data_array[206] = 0; data_array[207] = 87;
    data_array[208] = 66; data_array[209] = 71; data_array[210] = 107; data_array[211] = 30;
    data_array[212] = 0; data_array[213] = 75; data_array[214] = 78; data_array[215] = 65;
    data_array[216] = 28; data_array[217] = 37; data_array[218] = 104; data_array[219] = 0;
    data_array[220] = 22; data_array[221] = 57; data_array[222] = 30; data_array[223] = 36;
    data_array[224] = 42; data_array[225] = 33; data_array[226] = 15; data_array[227] = 49;
    data_array[228] = 30; data_array[229] = 7; data_array[230] = 34; data_array[231] = 84;
    data_array[232] = 33; data_array[233] = 32; data_array[234] = 52; data_array[235] = 117;
    data_array[236] = 0; data_array[237] = 35; data_array[238] = 0; data_array[239] = 100;
    data_array[240] = 33; data_array[241] = 49; data_array[242] = 88; data_array[243] = 0;
    data_array[244] = 23; data_array[245] = 55; data_array[246] = 62; data_array[247] = 50;
    data_array[248] = 36; data_array[249] = 8; data_array[250] = 72; data_array[251] = 16;
    data_array[252] = 19; data_array[253] = 94; data_array[254] = 21; data_array[255] = 41;
    data_array[256] = 41; data_array[257] = 54; data_array[258] = 44; data_array[259] = 40;
    data_array[260] = 29; data_array[261] = 0; data_array[262] = 44; data_array[263] = 88;
    data_array[264] = 1; data_array[265] = 36; data_array[266] = 65; data_array[267] = 101;
    data_array[268] = 26; data_array[269] = 16; data_array[270] = 0; data_array[271] = 74;
    data_array[272] = 10; data_array[273] = 90; data_array[274] = 80; data_array[275] = 4;
    data_array[276] = 38; data_array[277] = 83; data_array[278] = 69; data_array[279] = 74;
    data_array[280] = 34; data_array[281] = 9; data_array[282] = 59; data_array[283] = 20;
    data_array[284] = 0; data_array[285] = 97; data_array[286] = 34; data_array[287] = 37;

    // Initialize weight array (576 elements = 32 channels * 18 weights)
    // Channel 0 weights
    weight_array[0] = 10; weight_array[1] = 19; weight_array[2] = -27; weight_array[3] = -7;
    weight_array[4] = 47; weight_array[5] = -50; weight_array[6] = 15; weight_array[7] = -23;
    weight_array[8] = -4; weight_array[9] = 4; weight_array[10] = -37; weight_array[11] = 0;
    weight_array[12] = 38; weight_array[13] = -2; weight_array[14] = -19; weight_array[15] = 0;
    weight_array[16] = 14; weight_array[17] = -43;
    // Channel 1 weights
    weight_array[18] = 13; weight_array[19] = 4; weight_array[20] = -1; weight_array[21] = 28;
    weight_array[22] = -30; weight_array[23] = 28; weight_array[24] = -36; weight_array[25] = 17;
    weight_array[26] = -56; weight_array[27] = 39; weight_array[28] = -20; weight_array[29] = 76;
    weight_array[30] = -31; weight_array[31] = 75; weight_array[32] = -71; weight_array[33] = 35;
    weight_array[34] = -43; weight_array[35] = 45;
    // Channel 2 weights
    weight_array[36] = 24; weight_array[37] = -52; weight_array[38] = 64; weight_array[39] = -87;
    weight_array[40] = 59; weight_array[41] = -115; weight_array[42] = 88; weight_array[43] = -46;
    weight_array[44] = 111; weight_array[45] = -56; weight_array[46] = 84; weight_array[47] = -86;
    weight_array[48] = 100; weight_array[49] = -99; weight_array[50] = 46; weight_array[51] = -91;
    weight_array[52] = 86; weight_array[53] = -40;
    // Channel 3 weights
    weight_array[54] = 34; weight_array[55] = -40; weight_array[56] = 81; weight_array[57] = -84;
    weight_array[58] = 87; weight_array[59] = -72; weight_array[60] = 66; weight_array[61] = -99;
    weight_array[62] = 76; weight_array[63] = -125; weight_array[64] = 74; weight_array[65] = -37;
    weight_array[66] = -24; weight_array[67] = -33; weight_array[68] = 19; weight_array[69] = -18;
    weight_array[70] = -10; weight_array[71] = 20;
    // Channel 4 weights
    weight_array[72] = 61; weight_array[73] = -8; weight_array[74] = -11; weight_array[75] = 21;
    weight_array[76] = -4; weight_array[77] = 1; weight_array[78] = 47; weight_array[79] = -72;
    weight_array[80] = 40; weight_array[81] = -83; weight_array[82] = 48; weight_array[83] = -56;
    weight_array[84] = 69; weight_array[85] = 7; weight_array[86] = 37; weight_array[87] = -45;
    weight_array[88] = 69; weight_array[89] = -55;
    // Channel 5 weights
    weight_array[90] = 61; weight_array[91] = -18; weight_array[92] = 41; weight_array[93] = -73;
    weight_array[94] = 35; weight_array[95] = -55; weight_array[96] = 64; weight_array[97] = -70;
    weight_array[98] = -1; weight_array[99] = 10; weight_array[100] = 75; weight_array[101] = -86;
    weight_array[102] = 89; weight_array[103] = -100; weight_array[104] = 52; weight_array[105] = -85;
    weight_array[106] = 29; weight_array[107] = -36;
    // Channel 6 weights
    weight_array[108] = 68; weight_array[109] = -34; weight_array[110] = -17; weight_array[111] = -47;
    weight_array[112] = -29; weight_array[113] = 1; weight_array[114] = 17; weight_array[115] = -14;
    weight_array[116] = 1; weight_array[117] = 75; weight_array[118] = -54; weight_array[119] = 8;
    weight_array[120] = -42; weight_array[121] = 4; weight_array[122] = 3; weight_array[123] = 43;
    weight_array[124] = -11; weight_array[125] = 15;
    // Channel 7 weights
    weight_array[126] = -36; weight_array[127] = 13; weight_array[128] = 13; weight_array[129] = -44;
    weight_array[130] = 9; weight_array[131] = -26; weight_array[132] = -10; weight_array[133] = 35;
    weight_array[134] = 9; weight_array[135] = -1; weight_array[136] = 71; weight_array[137] = -61;
    weight_array[138] = 36; weight_array[139] = -71; weight_array[140] = 77; weight_array[141] = -92;
    weight_array[142] = 69; weight_array[143] = -76;
    // Channel 8 weights
    weight_array[144] = 93; weight_array[145] = -11; weight_array[146] = 45; weight_array[147] = -35;
    weight_array[148] = 67; weight_array[149] = -72; weight_array[150] = 104; weight_array[151] = -73;
    weight_array[152] = 53; weight_array[153] = -48; weight_array[154] = 83; weight_array[155] = -108;
    weight_array[156] = 76; weight_array[157] = -36; weight_array[158] = 61; weight_array[159] = -75;
    weight_array[160] = 12; weight_array[161] = -41;
    // Channel 9 weights
    weight_array[162] = -28; weight_array[163] = 45; weight_array[164] = -51; weight_array[165] = 26;
    weight_array[166] = -72; weight_array[167] = 15; weight_array[168] = -30; weight_array[169] = 20;
    weight_array[170] = -87; weight_array[171] = 71; weight_array[172] = -72; weight_array[173] = 61;
    weight_array[174] = -22; weight_array[175] = 50; weight_array[176] = -57; weight_array[177] = 45;
    weight_array[178] = -77; weight_array[179] = 54;
    // Channel 10 weights
    weight_array[180] = 31; weight_array[181] = -1; weight_array[182] = -28; weight_array[183] = -48;
    weight_array[184] = 4; weight_array[185] = 33; weight_array[186] = 7; weight_array[187] = -9;
    weight_array[188] = 3; weight_array[189] = 26; weight_array[190] = -9; weight_array[191] = -49;
    weight_array[192] = 18; weight_array[193] = -39; weight_array[194] = 27; weight_array[195] = -41;
    weight_array[196] = 50; weight_array[197] = -27;
    // Channel 11 weights
    weight_array[198] = -31; weight_array[199] = 70; weight_array[200] = -58; weight_array[201] = 22;
    weight_array[202] = -49; weight_array[203] = 47; weight_array[204] = -31; weight_array[205] = 54;
    weight_array[206] = -21; weight_array[207] = 44; weight_array[208] = -44; weight_array[209] = 48;
    weight_array[210] = -81; weight_array[211] = 9; weight_array[212] = -15; weight_array[213] = 28;
    weight_array[214] = -38; weight_array[215] = 67;
    // Channel 12 weights
    weight_array[216] = 35; weight_array[217] = 18; weight_array[218] = 8; weight_array[219] = -17;
    weight_array[220] = 49; weight_array[221] = -33; weight_array[222] = 52; weight_array[223] = -65;
    weight_array[224] = 1; weight_array[225] = -5; weight_array[226] = 59; weight_array[227] = -31;
    weight_array[228] = 74; weight_array[229] = -38; weight_array[230] = 38; weight_array[231] = -66;
    weight_array[232] = 50; weight_array[233] = -46;
    // Channel 13 weights
    weight_array[234] = -27; weight_array[235] = 36; weight_array[236] = -33; weight_array[237] = 35;
    weight_array[238] = 48; weight_array[239] = -50; weight_array[240] = 29; weight_array[241] = 15;
    weight_array[242] = -22; weight_array[243] = 17; weight_array[244] = 56; weight_array[245] = -66;
    weight_array[246] = -21; weight_array[247] = 6; weight_array[248] = -8; weight_array[249] = -13;
    weight_array[250] = -50; weight_array[251] = 64;
    // Channel 14 weights
    weight_array[252] = -62; weight_array[253] = 27; weight_array[254] = -35; weight_array[255] = 45;
    weight_array[256] = -38; weight_array[257] = 67; weight_array[258] = -70; weight_array[259] = 35;
    weight_array[260] = -67; weight_array[261] = 78; weight_array[262] = -72; weight_array[263] = 11;
    weight_array[264] = -35; weight_array[265] = 57; weight_array[266] = -38; weight_array[267] = 46;
    weight_array[268] = 6; weight_array[269] = -11;
    // Channel 15 weights
    weight_array[270] = -12; weight_array[271] = -13; weight_array[272] = 56; weight_array[273] = -61;
    weight_array[274] = -5; weight_array[275] = -5; weight_array[276] = 54; weight_array[277] = 14;
    weight_array[278] = 37; weight_array[279] = -67; weight_array[280] = 81; weight_array[281] = -56;
    weight_array[282] = 76; weight_array[283] = -26; weight_array[284] = 44; weight_array[285] = -6;
    weight_array[286] = 68; weight_array[287] = -72;
    // Channel 16 weights
    weight_array[288] = 15; weight_array[289] = -16; weight_array[290] = -12; weight_array[291] = -2;
    weight_array[292] = -30; weight_array[293] = -40; weight_array[294] = 34; weight_array[295] = 8;
    weight_array[296] = -45; weight_array[297] = 10; weight_array[298] = -28; weight_array[299] = 47;
    weight_array[300] = 11; weight_array[301] = -27; weight_array[302] = 16; weight_array[303] = 25;
    weight_array[304] = 34; weight_array[305] = -22;
    // Channel 17 weights
    weight_array[306] = -1; weight_array[307] = -38; weight_array[308] = 35; weight_array[309] = 9;
    weight_array[310] = 18; weight_array[311] = 2; weight_array[312] = 16; weight_array[313] = -41;
    weight_array[314] = 14; weight_array[315] = 0; weight_array[316] = -27; weight_array[317] = 11;
    weight_array[318] = -34; weight_array[319] = 11; weight_array[320] = -78; weight_array[321] = 48;
    weight_array[322] = -56; weight_array[323] = 103;
    // Channel 18 weights
    weight_array[324] = -41; weight_array[325] = 7; weight_array[326] = -15; weight_array[327] = 5;
    weight_array[328] = 2; weight_array[329] = 59; weight_array[330] = 24; weight_array[331] = 37;
    weight_array[332] = -2; weight_array[333] = 30; weight_array[334] = -60; weight_array[335] = 10;
    weight_array[336] = -48; weight_array[337] = -4; weight_array[338] = 2; weight_array[339] = 55;
    weight_array[340] = -38; weight_array[341] = -35;
    // Channel 19 weights
    weight_array[342] = 34; weight_array[343] = -14; weight_array[344] = 19; weight_array[345] = -52;
    weight_array[346] = 41; weight_array[347] = -19; weight_array[348] = 3; weight_array[349] = 31;
    weight_array[350] = 12; weight_array[351] = -37; weight_array[352] = 22; weight_array[353] = -6;
    weight_array[354] = 44; weight_array[355] = -66; weight_array[356] = 43; weight_array[357] = -1;
    weight_array[358] = -27; weight_array[359] = -39;
    // Channel 20 weights
    weight_array[360] = -106; weight_array[361] = 90; weight_array[362] = -11; weight_array[363] = 74;
    weight_array[364] = -52; weight_array[365] = 75; weight_array[366] = -81; weight_array[367] = 81;
    weight_array[368] = -65; weight_array[369] = 99; weight_array[370] = -48; weight_array[371] = 83;
    weight_array[372] = -3; weight_array[373] = 41; weight_array[374] = -15; weight_array[375] = 8;
    weight_array[376] = -19; weight_array[377] = 47;
    // Channel 21 weights
    weight_array[378] = 50; weight_array[379] = -32; weight_array[380] = 8; weight_array[381] = -20;
    weight_array[382] = 60; weight_array[383] = -29; weight_array[384] = 6; weight_array[385] = -4;
    weight_array[386] = -25; weight_array[387] = -16; weight_array[388] = -24; weight_array[389] = -2;
    weight_array[390] = -1; weight_array[391] = -5; weight_array[392] = -91; weight_array[393] = 80;
    weight_array[394] = -71; weight_array[395] = 107;
    // Channel 22 weights
    weight_array[396] = -3; weight_array[397] = 42; weight_array[398] = -53; weight_array[399] = 30;
    weight_array[400] = -47; weight_array[401] = -21; weight_array[402] = -9; weight_array[403] = 38;
    weight_array[404] = -80; weight_array[405] = 80; weight_array[406] = -49; weight_array[407] = 63;
    weight_array[408] = -3; weight_array[409] = -6; weight_array[410] = -27; weight_array[411] = 64;
    weight_array[412] = -3; weight_array[413] = 51;
    // Channel 23 weights
    weight_array[414] = -79; weight_array[415] = 40; weight_array[416] = -54; weight_array[417] = 41;
    weight_array[418] = -28; weight_array[419] = 33; weight_array[420] = -64; weight_array[421] = 10;
    weight_array[422] = -77; weight_array[423] = 52; weight_array[424] = -4; weight_array[425] = 55;
    weight_array[426] = -71; weight_array[427] = 44; weight_array[428] = -2; weight_array[429] = -9;
    weight_array[430] = 4; weight_array[431] = -43;
    // Channel 24 weights
    weight_array[432] = -27; weight_array[433] = -16; weight_array[434] = -64; weight_array[435] = 87;
    weight_array[436] = -75; weight_array[437] = 16; weight_array[438] = -59; weight_array[439] = 58;
    weight_array[440] = -8; weight_array[441] = 69; weight_array[442] = -28; weight_array[443] = 32;
    weight_array[444] = -51; weight_array[445] = 49; weight_array[446] = -27; weight_array[447] = 47;
    weight_array[448] = -21; weight_array[449] = 55;
    // Channel 25 weights
    weight_array[450] = 44; weight_array[451] = -61; weight_array[452] = 16; weight_array[453] = -37;
    weight_array[454] = 60; weight_array[455] = -39; weight_array[456] = 27; weight_array[457] = -59;
    weight_array[458] = 66; weight_array[459] = -83; weight_array[460] = 41; weight_array[461] = -62;
    weight_array[462] = 94; weight_array[463] = -43; weight_array[464] = 61; weight_array[465] = -85;
    weight_array[466] = 84; weight_array[467] = -53;
    // Channel 26 weights
    weight_array[468] = 6; weight_array[469] = 26; weight_array[470] = 10; weight_array[471] = -4;
    weight_array[472] = 22; weight_array[473] = -5; weight_array[474] = 8; weight_array[475] = 29;
    weight_array[476] = -18; weight_array[477] = 5; weight_array[478] = -15; weight_array[479] = 29;
    weight_array[480] = 16; weight_array[481] = -25; weight_array[482] = -22; weight_array[483] = -8;
    weight_array[484] = 21; weight_array[485] = -15;
    // Channel 27 weights
    weight_array[486] = -29; weight_array[487] = 72; weight_array[488] = -72; weight_array[489] = 60;
    weight_array[490] = -22; weight_array[491] = 56; weight_array[492] = -38; weight_array[493] = 56;
    weight_array[494] = -94; weight_array[495] = 97; weight_array[496] = -96; weight_array[497] = 40;
    weight_array[498] = -40; weight_array[499] = 74; weight_array[500] = -80; weight_array[501] = 62;
    weight_array[502] = -73; weight_array[503] = 53;
    // Channel 28 weights
    weight_array[504] = 31; weight_array[505] = -56; weight_array[506] = 52; weight_array[507] = -102;
    weight_array[508] = 100; weight_array[509] = -101; weight_array[510] = 114; weight_array[511] = -60;
    weight_array[512] = 54; weight_array[513] = -113; weight_array[514] = 97; weight_array[515] = -31;
    weight_array[516] = 14; weight_array[517] = -60; weight_array[518] = 17; weight_array[519] = -23;
    weight_array[520] = 46; weight_array[521] = -1;
    // Channel 29 weights
    weight_array[522] = -52; weight_array[523] = 27; weight_array[524] = 8; weight_array[525] = -9;
    weight_array[526] = -44; weight_array[527] = 4; weight_array[528] = -102; weight_array[529] = 119;
    weight_array[530] = -12; weight_array[531] = 38; weight_array[532] = -79; weight_array[533] = 76;
    weight_array[534] = -17; weight_array[535] = 42; weight_array[536] = -43; weight_array[537] = 72;
    weight_array[538] = -33; weight_array[539] = 12;
    // Channel 30 weights
    weight_array[540] = -55; weight_array[541] = 28; weight_array[542] = -5; weight_array[543] = -9;
    weight_array[544] = -26; weight_array[545] = 89; weight_array[546] = -64; weight_array[547] = 68;
    weight_array[548] = -122; weight_array[549] = 59; weight_array[550] = -94; weight_array[551] = 107;
    weight_array[552] = -78; weight_array[553] = 22; weight_array[554] = -30; weight_array[555] = 68;
    weight_array[556] = -64; weight_array[557] = 63;
    // Channel 31 weights
    weight_array[558] = -29; weight_array[559] = 12; weight_array[560] = -1; weight_array[561] = 58;
    weight_array[562] = -13; weight_array[563] = 61; weight_array[564] = -40; weight_array[565] = 6;
    weight_array[566] = -35; weight_array[567] = 73; weight_array[568] = -96; weight_array[569] = 22;
    weight_array[570] = -17; weight_array[571] = 17; weight_array[572] = -58; weight_array[573] = 74;
    weight_array[574] = -23; weight_array[575] = 20;
end

// Main test sequence
initial begin
    // Initialize signals
    rst_n = 0;
    enable = 0;
    data_in = 256'b0;
    weight = 4608'b0;

    // Display test start
    $display("========================================");
    $display("FC Testbench Started");
    $display("========================================");

    // Apply reset
    #20;
    rst_n = 1;
    #10;

    // Pack weight array into weight signal
    // Weight format: 32 channels * 18 weights * 8 bits = 4608 bits
    for (i = 0; i < 576; i = i + 1) begin
        weight[i*8 +: 8] = weight_array[i];
    end

    // Enable FC module
    enable = 1;

    // Each time step's data must be held for 2 clock cycles:
    // - Even cnt: kernel 0 accumulates data * weight
    // - Odd  cnt: kernel 1 accumulates data * weight
    // 9 time steps x 2 cycles = 18 cycles (cnt 0~17)

    // Time step 0: data[0:31] for cnt=0 (kernel 0) and cnt=1 (kernel 1)
    for (i = 0; i < 32; i = i + 1) begin
        data_in[i*8 +: 8] = data_array[i];
    end
    #20;

    // Time step 1: data[32:63] for cnt=2 and cnt=3
    for (i = 0; i < 32; i = i + 1) begin
        data_in[i*8 +: 8] = data_array[32 + i];
    end
    #20;

    // Time step 2: data[64:95] for cnt=4 and cnt=5
    for (i = 0; i < 32; i = i + 1) begin
        data_in[i*8 +: 8] = data_array[64 + i];
    end
    #20;

    // Time step 3: data[96:127] for cnt=6 and cnt=7
    for (i = 0; i < 32; i = i + 1) begin
        data_in[i*8 +: 8] = data_array[96 + i];
    end
    #20;

    // Time step 4: data[128:159] for cnt=8 and cnt=9
    for (i = 0; i < 32; i = i + 1) begin
        data_in[i*8 +: 8] = data_array[128 + i];
    end
    #20;

    // Time step 5: data[160:191] for cnt=10 and cnt=11
    for (i = 0; i < 32; i = i + 1) begin
        data_in[i*8 +: 8] = data_array[160 + i];
    end
    #20;

    // Time step 6: data[192:223] for cnt=12 and cnt=13
    for (i = 0; i < 32; i = i + 1) begin
        data_in[i*8 +: 8] = data_array[192 + i];
    end
    #20;

    // Time step 7: data[224:255] for cnt=14 and cnt=15
    for (i = 0; i < 32; i = i + 1) begin
        data_in[i*8 +: 8] = data_array[224 + i];
    end
    #20;

    // Time step 8: data[256:287] for cnt=16 and cnt=17
    for (i = 0; i < 32; i = i + 1) begin
        data_in[i*8 +: 8] = data_array[256 + i];
    end
    #20;

    // Disable after 18 cycles to prevent cnt from continuing
    enable = 0;

    // Wait for adder tree pipeline to flush (4 FF stages)
    // The results from cnt=16 (channel 0) and cnt=17 (channel 1) need 4 cycles to propagate
    #40;

    // Display final results
    $display("========================================");
    $display("Test Completed at time %0t", $time);
    $display("========================================");
    $display("Final Output Results:");
    $display("temp_out_0 (Kernel 0) = %d", $signed(temp_out_0));
    $display("temp_out_1 (Kernel 1) = %d", $signed(temp_out_1));
    $display("out_0 = (temp_out_0 + %0d) * %0d / 2^%0d = %0d", bias_0, M0, n, $signed(out_0));
    $display("out_1 = (temp_out_1 + %0d) * %0d / 2^%0d = %0d", bias_1, M0, n, $signed(out_1));
    $display("data_out = 0x%h", data_out);
    $display("========================================");
    
    // End simulation
    #50;
    $finish;
end

// Monitor output changes
always @(posedge clk) begin
    if (enable && rst_n) begin
        $display("Time=%0t | temp_out_0=%0d | temp_out_1=%0d | out_0=%0d | out_1=%0d",
                 $time, $signed(temp_out_0), $signed(temp_out_1),
                 $signed(out_0), $signed(out_1));
    end
end

endmodule
