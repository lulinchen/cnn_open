// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

`include "global.v"

module digit_osd(
	input					clk,
	input					rstn,
	input		[`W_PW:0]	pic_width,
	input		[`W_PH:0]	pic_height,
	input		[3:0]		digit_in,
	input		[`W_PW:0]	x,
	input		[`W_PH:0]	y,
	input		[`W_PW:0]	w, 
	input		[`W_PH:0]	h, 
	input					vsync,
	input					hsync,
	input					de,
	
	output	reg				vsync_o,
	output	reg				hsync_o,
	output	reg				de_o,
	output	reg				q
	);
	
	reg	[ 3:0]	digit;
	always @(`CLK_RST_EDGE)
		if (`RST)	digit <= 0;
		else 		digit <= digit_in;
	
	reg	[`W_PW+1:0] 	x1;
	reg	[`W_PH+1:0] 	y1;
	reg    [7:0][`W_PW:0]    x_d;
	always @(*)    x_d[0] = x;
	always @(`CLK_RST_EDGE)
		if (`RST)    x_d[7:1] <= 0;
		else         x_d[7:1] <= x_d;
	reg    [7:0][`W_PH:0]    y_d;
	always @(*)    y_d[0] = y;
	always @(`CLK_RST_EDGE)
		if (`RST)    y_d[7:1] <= 0;
		else         y_d[7:1] <= y_d;
	reg	[7:0][`W_PW+1:0]	x1_d;
	always @(*)	x1_d[0] = x1;
	always @(`CLK_RST_EDGE)
		if (`RST)	x1_d[7:1] <= 0;
		else 		x1_d[7:1] <= x1_d;
	reg	[7:0][`W_PH+1:0]	y1_d;
	always @(*)	y1_d[0] = y1;
	always @(`CLK_RST_EDGE)
		if (`RST)	y1_d[7:1] <= 0;
		else 		y1_d[7:1] <= y1_d;
	
	always @(`CLK_RST_EDGE)
		if (`ZST)	{x1, y1} <= 0;
		else begin
			x1 <= x + w;
			y1 <= y + h;		
		end

	reg    [7:0]    vsync_d;
	always @(*)    vsync_d[0] = vsync;
	always @(`CLK_RST_EDGE)
		if (`RST)    vsync_d[7:1] <= 0;
		else         vsync_d[7:1] <= vsync_d;
		
	wire	vsync_falling = !vsync & vsync_d[1];
	reg    [7:0]    hsync_d;
	always @(*)    hsync_d[0] = hsync;
	always @(`CLK_RST_EDGE)
		if (`RST)    hsync_d[7:1] <= 0;
		else         hsync_d[7:1] <= hsync_d;
	reg    [7:0]    de_d;
	always @(*)    de_d[0] = de;
	always @(`CLK_RST_EDGE)
		if (`RST)    de_d[7:1] <= 0;
		else         de_d[7:1] <= de_d;
	
	reg			[`W_PW:0]	 cnt_h;
	reg			[`W_PH:0]	 cnt_v;
	wire 		de_falling = !de & de_d[1];
	always @(`CLK_RST_EDGE)
		if (`RST)	cnt_h <= 0;
		else 		cnt_h <= de? cnt_h + 1 : 0;
	always @(`CLK_RST_EDGE)
		if (`RST)					cnt_v <= 0;
		else if (vsync_falling)		cnt_v <= 0;
		else if (de_falling)		cnt_v <= cnt_v + 1;
	
	reg    [7:0][`W_PW:0]    cnt_h_d;
	always @(*)    cnt_h_d[0] = cnt_h;
	always @(`CLK_RST_EDGE)
		if (`RST)    cnt_h_d[7:1] <= 0;
		else         cnt_h_d[7:1] <= cnt_h_d;
	reg    [7:0][`W_PH:0]    cnt_v_d;
	always @(*)    cnt_v_d[0] = cnt_v;
	always @(`CLK_RST_EDGE)
		if (`RST)    cnt_v_d[7:1] <= 0;
		else         cnt_v_d[7:1] <= cnt_v_d;
	
	reg				drawing;
	always @(`CLK_RST_EDGE)
		if (`RST)					drawing <= 0;
		else if (vsync_falling) 	drawing <= 1;
	
	reg		cnt_h_eq_x, cnt_h_eq_x1, cnt_v_eq_y, cnt_v_eq_y1;
	always @(`CLK_RST_EDGE)
		if (`RST)	{cnt_h_eq_x, cnt_h_eq_x1, cnt_v_eq_y, cnt_v_eq_y1} <= 0;
		else begin
			cnt_h_eq_x <=  cnt_h == x; 
			cnt_h_eq_x1 <=  cnt_h == x1; 
			cnt_v_eq_y <=  cnt_v == y; 
			cnt_v_eq_y1 <=  cnt_v == y1; 	
		end
	reg		hor_en, ver_en;
	always @(`CLK_RST_EDGE)
		if (`RST)					hor_en <= 0;
		else if (cnt_h_eq_x) 		hor_en <= 1;
		else if (cnt_h_eq_x1) 		hor_en <= 0;
	
	always @(`CLK_RST_EDGE)
		if (`RST)					ver_en <= 0;
		else if (cnt_v_eq_y)		ver_en <= 1;
		else if (cnt_v_eq_y1)		ver_en <= 0;
	wire	osd_en = hor_en & ver_en;
	//cnt_h, cnt_v --> cnt_h_eq_x --> osd_en --> cena_osd_rom --> qa_osd_rom --> osd_data --> q
	
	reg		[`W_PW:0]	hor_cnt;
	always @(`CLK_RST_EDGE)
		if (`RST)	hor_cnt <= 0;
		else 		hor_cnt <= hor_en? hor_cnt+1 : 0;
	reg		[15:0][`W_PW:0]	hor_cnt_d;
	always @(*)	hor_cnt_d[0] = hor_cnt;
	always @(`CLK_RST_EDGE)
		if (`RST)	hor_cnt_d[15:1] <= 0;
		else 		hor_cnt_d[15:1] <= hor_cnt_d;
		
	reg				cena_osd_rom;
	reg		[7:0]	aa_osd_rom;
	wire	[15:0]	qa_osd_rom;
	digit_osd_rom digit_osd_rom(
		.clk			(clk),
		.rstn			(rstn),
		.cena 			(cena_osd_rom),
		.aa 			(aa_osd_rom),
		.qa 			(qa_osd_rom)
		);
	
	reg		[0:0]		cena_osd_rom_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	cena_osd_rom_d1 <= 1;
		else 		cena_osd_rom_d1 <= cena_osd_rom;
	reg		[15:0]	osd_en_d;
	always @(*)	osd_en_d[0] = osd_en;
	always @(`CLK_RST_EDGE)
		if (`RST)	osd_en_d[15:1] <= 0;
		else 		osd_en_d[15:1] <= osd_en_d;
		
	
	
	always @(`CLK_RST_EDGE)
		if (`RST)	cena_osd_rom <= 1;
		else 		cena_osd_rom <= !(osd_en && hor_cnt[3:0] == 0);
	always @(`CLK_RST_EDGE)
		if (`RST)					aa_osd_rom <= 0;
		else if (vsync_falling)		aa_osd_rom <= 16*digit;
		else if (!cena_osd_rom)		aa_osd_rom <= aa_osd_rom + 1;
	
	reg		[0:15]	osd_data;
	always @(`CLK_RST_EDGE)
		if (`RST)						osd_data <= 0;
		else if (!cena_osd_rom_d1) 		osd_data <= qa_osd_rom;
	always @(`CLK_RST_EDGE)
		if (`RST)				q <= 0;
		else if(!osd_en_d[3])	q <= 0;
		else 					q <= osd_data[hor_cnt_d[3][3:0]];
	
	always @(`CLK_RST_EDGE)
		if (`RST)	de_o <= 0;
		else 		de_o <= de_d[5];
	always @(`CLK_RST_EDGE)
		if (`RST)	hsync_o <= 0;
		else 		hsync_o <= hsync_d[5];
	always @(`CLK_RST_EDGE)
		if (`RST)	vsync_o <= 0;
		else 		vsync_o <= vsync_d[5];
endmodule

// 16x16
module digit_osd_rom(
	input								clk,
	input								rstn,
	input		[7:0]					aa,
	input								cena,	
	output reg	[15:0]					qa

	);
	reg					[0:9][0:15][15:0]	rom;
	wire	[0:160-1][15:0]rom_alias = rom;
	always @(posedge clk) qa <= rom_alias[aa];
	
	initial begin
		rom[0] = {8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h03, 8'hE0, 8'h07, 8'h60, 8'h06, 8'h30, 8'h06, 8'h30, 8'h06, 8'h30, 8'h06, 8'h30, 8'h06, 8'h30, 8'h06, 8'h30, 8'h06, 8'h70, 8'h03, 8'hE0, 8'h01, 8'hC0, 8'h00, 8'h00, 8'h00, 8'h00};
		rom[1] = {8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hC0, 8'h01, 8'hC0, 8'h07, 8'hC0, 8'h07, 8'hC0, 8'h01, 8'hC0, 8'h01, 8'hC0, 8'h01, 8'hC0, 8'h01, 8'hC0, 8'h01, 8'hC0, 8'h01, 8'hC0, 8'h01, 8'hC0, 8'h00, 8'h00, 8'h00, 8'h00};
		rom[2] = {8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h03, 8'hE0, 8'h07, 8'h70, 8'h06, 8'h30, 8'h00, 8'h70, 8'h00, 8'h60, 8'h00, 8'hE0, 8'h00, 8'hC0, 8'h01, 8'h80, 8'h03, 8'h00, 8'h07, 8'hF0, 8'h07, 8'hF0, 8'h00, 8'h00, 8'h00, 8'h00};
		rom[3] = {8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h03, 8'hE0, 8'h07, 8'h70, 8'h06, 8'h30, 8'h00, 8'h70, 8'h00, 8'hE0, 8'h00, 8'hE0, 8'h00, 8'h70, 8'h00, 8'h30, 8'h06, 8'h30, 8'h07, 8'h60, 8'h01, 8'hC0, 8'h00, 8'h00, 8'h00, 8'h00};
		rom[4] = {8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h60, 8'h00, 8'hE0, 8'h01, 8'hE0, 8'h01, 8'hE0, 8'h03, 8'h60, 8'h07, 8'h60, 8'h06, 8'h60, 8'h0F, 8'hF8, 8'h00, 8'h60, 8'h00, 8'h60, 8'h00, 8'h60, 8'h00, 8'h00, 8'h00, 8'h00};
		rom[5] = {8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h03, 8'hF0, 8'h07, 8'h00, 8'h06, 8'h00, 8'h07, 8'h80, 8'h07, 8'hE0, 8'h06, 8'h70, 8'h00, 8'h30, 8'h00, 8'h30, 8'h0E, 8'h70, 8'h07, 8'hE0, 8'h03, 8'hC0, 8'h00, 8'h00, 8'h00, 8'h00};
		rom[6] = {8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hC0, 8'h01, 8'hC0, 8'h01, 8'h80, 8'h03, 8'h80, 8'h07, 8'hE0, 8'h07, 8'h30, 8'h06, 8'h38, 8'h06, 8'h38, 8'h06, 8'h30, 8'h07, 8'h70, 8'h03, 8'hE0, 8'h00, 8'h00, 8'h00, 8'h00};
		rom[7] = {8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h07, 8'hF0, 8'h00, 8'h30, 8'h00, 8'h70, 8'h00, 8'h60, 8'h00, 8'hE0, 8'h00, 8'hC0, 8'h01, 8'hC0, 8'h01, 8'h80, 8'h01, 8'h80, 8'h03, 8'h80, 8'h03, 8'h80, 8'h00, 8'h00, 8'h00, 8'h00};
		rom[8] = {8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h03, 8'hE0, 8'h06, 8'h70, 8'h06, 8'h30, 8'h06, 8'h70, 8'h07, 8'hE0, 8'h07, 8'hE0, 8'h06, 8'h30, 8'h0E, 8'h30, 8'h06, 8'h30, 8'h07, 8'h70, 8'h03, 8'hE0, 8'h00, 8'h00, 8'h00, 8'h00};
		rom[9] = {8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h03, 8'hE0, 8'h06, 8'h70, 8'h0E, 8'h30, 8'h0E, 8'h30, 8'h0E, 8'h70, 8'h07, 8'hE0, 8'h03, 8'hE0, 8'h00, 8'hC0, 8'h01, 8'hC0, 8'h01, 8'h80, 8'h03, 8'h80, 8'h00, 8'h00, 8'h00, 8'h00};
	end
endmodule
